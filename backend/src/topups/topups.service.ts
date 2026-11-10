import { Inject, Injectable, Logger } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { parsePhone } from '../domain/phone';
import { quotePrice, toMajor, toMinor } from '../domain/pricing';
import { assertTransition, TopupStatus } from '../domain/transaction-state';
import { LedgerService } from '../ledger/ledger.service';
import { PaymentsProvider } from '../payments/payments.provider';
import {
  ReloadlyOperator, ReloadlyTopupRequest, ReloadlyTopupResponse,
} from '../reloadly/reloadly.types';
import { TopupRecord, TopupRepository } from '../store/repositories';
import { AppConfig } from '../config/configuration';

export interface ReloadlyGateway {
  autoDetectOperator(phoneE164: string, countryIso: string): Promise<ReloadlyOperator>;
  getOperator(operatorId: number): Promise<ReloadlyOperator>;
  fxRate(operatorId: number, amountMajor: number, currencyCode?: string): Promise<any>;
  sendTopup(req: ReloadlyTopupRequest): Promise<ReloadlyTopupResponse>;
  getTopupStatus(transactionId: number): Promise<ReloadlyTopupResponse>;
}

export interface CreateTopupInput {
  userId: string;
  recipientPhone: string;
  operatorId?: number;
  amountLocalMajor: number; // face value in the RECIPIENT's currency, major units (e.g. 500 = 500 AFN)
  idempotencyKey: string;
}

export interface CreateTopupResult { topup: TopupRecord; clientSecret: string | null; reused: boolean; }

@Injectable()
export class TopupsService {
  private readonly logger = new Logger(TopupsService.name);

  constructor(
    @Inject('TOPUP_REPO') private readonly repo: TopupRepository,
    private readonly ledger: LedgerService,
    @Inject('RELOADLY') private readonly reloadly: ReloadlyGateway,
    @Inject('PAYMENTS') private readonly payments: PaymentsProvider,
    @Inject('APP_CONFIG') private readonly cfg: AppConfig,
  ) {}

  private async transition(rec: TopupRecord, to: TopupStatus, failureReason?: string): Promise<TopupRecord> {
    assertTransition(rec.status, to);
    rec.status = to;
    if (failureReason !== undefined) rec.failureReason = failureReason;
    rec.updatedAt = new Date();
    return this.repo.update(rec);
  }

  async createTopup(input: CreateTopupInput): Promise<CreateTopupResult> {
    // Idempotency: a retried create with the same key returns the same transaction.
    const existing = await this.repo.getByIdempotencyKey(input.idempotencyKey);
    if (existing) return { topup: existing, clientSecret: null, reused: true };

    const phone = parsePhone(input.recipientPhone);
    const operator = input.operatorId
      ? await this.reloadly.getOperator(input.operatorId)
      : await this.reloadly.autoDetectOperator(phone.e164, phone.countryIso);
    if (operator.country.isoName !== phone.countryIso) {
      throw new Error(`Operator ${operator.name} is in ${operator.country.isoName}, number is in ${phone.countryIso}`);
    }
    this.validateAmount(operator, input.amountLocalMajor);

    // Cost: what Reloadly will charge our balance, in the charge currency.
    const fx = await this.reloadly.fxRate(operator.id ?? (operator as any).operatorId, input.amountLocalMajor);
    const costMajor = this.extractCostMajor(fx, operator, input.amountLocalMajor);
    const costMinor = toMinor(costMajor);
    const quote = quotePrice(costMinor, this.cfg);

    const now = new Date();
    let rec: TopupRecord = {
      id: randomUUID(),
      userId: input.userId,
      idempotencyKey: input.idempotencyKey,
      recipientPhone: phone.e164,
      countryIso: phone.countryIso,
      operatorId: (operator.id ?? (operator as any).operatorId) as number,
      operatorName: operator.name,
      amountLocalMinor: toMinor(input.amountLocalMajor),
      localCurrency: operator.localCurrencyCode || operator.country.isoName,
      costMinor: quote.costMinor,
      feeMinor: quote.feeMinor,
      totalMinor: quote.totalMinor,
      chargeCurrency: this.cfg.chargeCurrency,
      status: TopupStatus.CREATED,
      stripePaymentIntentId: null,
      reloadlyTransactionId: null,
      failureReason: null,
      createdAt: now,
      updatedAt: now,
    };
    rec = await this.repo.create(rec);

    try {
      const pi = await this.payments.createPaymentIntent({
        amountMinor: rec.totalMinor,
        currency: rec.chargeCurrency,
        idempotencyKey: `pi-${rec.id}`,
        metadata: { topupId: rec.id, recipientPhone: rec.recipientPhone },
      });
      rec.stripePaymentIntentId = pi.id;
      rec = await this.transition(rec, TopupStatus.AWAITING_PAYMENT);
      return { topup: rec, clientSecret: pi.clientSecret, reused: false };
    } catch (e) {
      await this.transition(rec, TopupStatus.PAYMENT_FAILED, `payment setup failed: ${(e as Error).message}`).catch(() => undefined);
      throw e;
    }
  }

  private validateAmount(operator: ReloadlyOperator, amountLocalMajor: number): void {
    if (!(amountLocalMajor > 0)) throw new Error('Amount must be positive');
    if (operator.denominationType === 'FIXED') {
      const fixed = operator.localFixedAmounts || [];
      if (fixed.length > 0 && !fixed.includes(amountLocalMajor)) {
        throw new Error(`${operator.name} only sells fixed amounts: ${fixed.join(', ')}`);
      }
    } else {
      if (operator.localMinAmount != null && amountLocalMajor < operator.localMinAmount) {
        throw new Error(`Minimum for ${operator.name} is ${operator.localMinAmount}`);
      }
      if (operator.localMaxAmount != null && amountLocalMajor > operator.localMaxAmount) {
        throw new Error(`Maximum for ${operator.name} is ${operator.localMaxAmount}`);
      }
    }
  }

  private extractCostMajor(fx: any, operator: ReloadlyOperator, amountLocalMajor: number): number {
    const direct = [fx?.requestedAmount, fx?.senderAmount, fx?.convertedAmount]
      .find((v) => typeof v === 'number' && v > 0);
    if (direct) return direct;
    const rate = [fx?.fxRate, fx?.rate, operator.fx?.rate].find((v) => typeof v === 'number' && v > 0);
    if (rate) return amountLocalMajor * rate;
    // Exact field names get pinned against the sandbox in the Phase 4 test pass;
    // until then failing loudly is safer than guessing a price.
    throw new Error('Could not determine Reloadly cost from FX response');
  }

  /** Stripe webhook: payment_intent.succeeded. Idempotent. */
  async handlePaymentSucceeded(paymentIntentId: string): Promise<TopupRecord | null> {
    const rec = await this.repo.getByPaymentIntentId(paymentIntentId);
    if (!rec) { this.logger.warn(`Webhook for unknown PaymentIntent ${paymentIntentId}`); return null; }
    if (rec.status !== TopupStatus.AWAITING_PAYMENT) return rec; // replay / already handled
    const paid = await this.transition(rec, TopupStatus.PAID);
    this.ledger.journalPayment(paid.id, paid.chargeCurrency, paid.totalMinor);
    return this.sendToProvider(paid);
  }

  /** Stripe webhook: payment_intent.payment_failed. */
  async handlePaymentFailed(paymentIntentId: string): Promise<TopupRecord | null> {
    const rec = await this.repo.getByPaymentIntentId(paymentIntentId);
    if (!rec || rec.status !== TopupStatus.AWAITING_PAYMENT) return rec;
    return this.transition(rec, TopupStatus.PAYMENT_FAILED, 'card payment failed');
  }

  private async sendToProvider(rec: TopupRecord): Promise<TopupRecord> {
    const sending = await this.transition(rec, TopupStatus.SENDING);
    let resp: ReloadlyTopupResponse;
    try {
      resp = await this.reloadly.sendTopup({
        operatorId: sending.operatorId,
        amount: toMajor(sending.amountLocalMinor),
        useLocalAmount: true,
        customIdentifier: sending.id, // our UUID — unique, never reused (Reloadly rule)
        recipientPhone: { countryCode: sending.countryIso, number: sending.recipientPhone },
      });
    } catch (e) {
      return this.failAndRefund(sending, `Reloadly send failed: ${(e as Error).message}`);
    }
    sending.reloadlyTransactionId = (resp.transactionId ?? resp.id ?? null) as number | null;
    await this.repo.update(sending);
    return this.applyProviderStatus(sending, resp.status);
  }

  /** Poll Reloadly for a SENDING transaction and settle it. Safe to call repeatedly. */
  async reconcile(topupId: string): Promise<TopupRecord | null> {
    const rec = await this.repo.getById(topupId);
    if (!rec || rec.status !== TopupStatus.SENDING || !rec.reloadlyTransactionId) return rec;
    const resp = await this.reloadly.getTopupStatus(rec.reloadlyTransactionId);
    return this.applyProviderStatus(rec, resp.status);
  }

  private async applyProviderStatus(rec: TopupRecord, status: string): Promise<TopupRecord> {
    if (rec.status !== TopupStatus.SENDING) return rec;
    if (status === 'SUCCESSFUL') {
      const delivered = await this.transition(rec, TopupStatus.DELIVERED);
      this.ledger.journalDelivered(delivered.id, delivered.chargeCurrency, delivered.costMinor, delivered.feeMinor);
      return delivered;
    }
    if (status === 'FAILED' || status === 'REFUNDED') {
      return this.failAndRefund(rec, `Reloadly status: ${status}`);
    }
    return rec; // PROCESSING etc. — stays SENDING, reconcile again later
  }

  private async failAndRefund(rec: TopupRecord, reason: string): Promise<TopupRecord> {
    let cur = rec;
    if (cur.status === TopupStatus.SENDING) cur = await this.transition(cur, TopupStatus.FAILED, reason);
    if (cur.status !== TopupStatus.FAILED) return cur;
    cur = await this.transition(cur, TopupStatus.REFUND_PENDING);
    try {
      if (!cur.stripePaymentIntentId) throw new Error('No PaymentIntent to refund');
      await this.payments.refund(cur.stripePaymentIntentId);
    } catch (e) {
      // Money safety: a failed refund is NEVER silent — it parks in
      // REFUND_FAILED for manual review instead of pretending all is well.
      return this.transition(cur, TopupStatus.REFUND_FAILED, `refund failed: ${(e as Error).message}`);
    }
    const refunded = await this.transition(cur, TopupStatus.REFUNDED);
    this.ledger.journalRefund(refunded.id, refunded.chargeCurrency, refunded.totalMinor);
    return refunded;
  }

  /** Operator auto-detect for the app's number screen (Phase 2). */
  async detectOperator(phoneRaw: string) {
    const phone = parsePhone(phoneRaw);
    const op = await this.reloadly.autoDetectOperator(phone.e164, phone.countryIso);
    return {
      operatorId: (op.id ?? (op as any).operatorId) as number,
      name: op.name,
      countryIso: op.country.isoName,
      denominationType: op.denominationType,
      localMinMinor: op.localMinAmount != null ? toMinor(op.localMinAmount) : null,
      localMaxMinor: op.localMaxAmount != null ? toMinor(op.localMaxAmount) : null,
      fixedLocalAmountsMajor: op.localFixedAmounts || [],
      supportsData: !!op.supportsDataPlans,
      logoUrl: op.logoUrls?.[0] || null,
    };
  }

  getTopup(id: string) { return this.repo.getById(id); }
  listUserTopups(userId: string) { return this.repo.listByUser(userId); }
}
