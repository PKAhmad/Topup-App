import { LedgerService } from '../src/ledger/ledger.service';
import { PaymentsProvider } from '../src/payments/payments.provider';
import { ReloadlyOperator, ReloadlyTopupRequest, ReloadlyTopupResponse } from '../src/reloadly/reloadly.types';
import { InMemoryTopupRepository } from '../src/store/repositories';
import { TopupStatus } from '../src/domain/transaction-state';
import { ReloadlyGateway, TopupsService } from '../src/topups/topups.service';
import { loadConfig } from '../src/config/configuration';

const AF_OPERATOR: ReloadlyOperator = {
  id: 999, name: 'Roshan Afghanistan', country: { isoName: 'AF', name: 'Afghanistan' },
  denominationType: 'RANGE', localMinAmount: 10, localMaxAmount: 5000,
  localCurrencyCode: 'AFN', fx: { rate: 0.011, currencyCode: 'EUR' },
};

class FakeReloadly implements ReloadlyGateway {
  sendStatus: string = 'SUCCESSFUL';
  throwOnSend = false;
  statusByTxn: Record<number, string> = {};
  sentRequests: ReloadlyTopupRequest[] = [];
  async autoDetectOperator() { return AF_OPERATOR; }
  async getOperator() { return AF_OPERATOR; }
  async fxRate(_id: number, amountMajor: number) { return { requestedAmount: amountMajor * 0.011 }; }
  async sendTopup(req: ReloadlyTopupRequest): Promise<ReloadlyTopupResponse> {
    this.sentRequests.push(req);
    if (this.throwOnSend) throw new Error('provider exploded');
    return { transactionId: 4242, operatorId: req.operatorId, status: this.sendStatus };
  }
  async getTopupStatus(txnId: number): Promise<ReloadlyTopupResponse> {
    return { transactionId: txnId, operatorId: 999, status: this.statusByTxn[txnId] || 'PROCESSING' };
  }
}

class FakePayments implements PaymentsProvider {
  piCount = 0;
  refundCount = 0;
  throwOnRefund = false;
  async createPaymentIntent(input: any) {
    this.piCount++;
    return { id: `pi_test_${this.piCount}`, clientSecret: 'secret', status: 'requires_confirmation' };
  }
  async refund(_piId: string) {
    this.refundCount++;
    if (this.throwOnRefund) throw new Error('stripe refund failed');
    return { id: 're_test', status: 'succeeded' };
  }
  verifyWebhook(): any { throw new Error('not used in service tests'); }
}

function makeService() {
  const repo = new InMemoryTopupRepository();
  const ledger = new LedgerService();
  const reloadly = new FakeReloadly();
  const payments = new FakePayments();
  const cfg = loadConfig({ CHARGE_CURRENCY: 'EUR', FEE_BPS: '800', FEE_FIXED_MINOR: '35', FEE_MIN_MINOR: '49' } as any);
  const svc = new TopupsService(repo as any, ledger, reloadly as any, payments as any, cfg);
  return { svc, repo, ledger, reloadly, payments };
}

const CREATE = {
  userId: 'user-1', recipientPhone: '+93791234567', amountLocalMajor: 500, idempotencyKey: 'idem-key-0001',
};

describe('TopupsService orchestration', () => {
  it('happy path: create -> pay -> delivered, ledger settles, fee booked', async () => {
    const { svc, ledger, payments, reloadly } = makeService();
    const created = await svc.createTopup(CREATE);
    expect(created.topup.status).toBe(TopupStatus.AWAITING_PAYMENT);
    // 500 AFN * 0.011 = 5.50 EUR cost = 550; fee = max(49, 44+35)=79; total 629
    expect(created.topup.costMinor).toBe(550);
    expect(created.topup.feeMinor).toBe(79);
    expect(created.topup.totalMinor).toBe(629);
    expect(created.clientSecret).toBe('secret');

    const done = await svc.handlePaymentSucceeded(created.topup.stripePaymentIntentId!);
    expect(done?.status).toBe(TopupStatus.DELIVERED);
    expect(reloadly.sentRequests[0].customIdentifier).toBe(created.topup.id);
    expect(reloadly.sentRequests[0].useLocalAmount).toBe(true);
    expect(payments.refundCount).toBe(0);
    expect(ledger.balance('TOPUP_PAYABLE')).toBe(0);
    expect(ledger.balance('FEE_REVENUE')).toBe(-79);
    expect(ledger.balance('RELOADLY_BALANCE')).toBe(-550);
  });

  it('idempotent create: same key returns same transaction, one PaymentIntent', async () => {
    const { svc, payments } = makeService();
    const a = await svc.createTopup(CREATE);
    const b = await svc.createTopup(CREATE);
    expect(b.topup.id).toBe(a.topup.id);
    expect(b.reused).toBe(true);
    expect(payments.piCount).toBe(1);
  });

  it('provider FAILED -> automatic refund -> REFUNDED, money fully reversed', async () => {
    const { svc, ledger, payments } = makeService();
    const created = await svc.createTopup(CREATE);
    const reloadly = (svc as any)['reloadly'] as FakeReloadly;
    reloadly.sendStatus = 'FAILED';
    const done = await svc.handlePaymentSucceeded(created.topup.stripePaymentIntentId!);
    expect(done?.status).toBe(TopupStatus.REFUNDED);
    expect(payments.refundCount).toBe(1);
    expect(ledger.balance('TOPUP_PAYABLE')).toBe(0);
    expect(ledger.balance('STRIPE_CLEARING')).toBe(0);
  });

  it('provider throws on send -> automatic refund as well', async () => {
    const { svc, payments } = makeService();
    const reloadly = (svc as any)['reloadly'] as FakeReloadly;
    reloadly.throwOnSend = true;
    const created = await svc.createTopup(CREATE);
    const done = await svc.handlePaymentSucceeded(created.topup.stripePaymentIntentId!);
    expect(done?.status).toBe(TopupStatus.REFUNDED);
    expect(payments.refundCount).toBe(1);
  });

  it('refund failure parks the transaction in REFUND_FAILED, never silently', async () => {
    const { svc, payments } = makeService();
    const reloadly = (svc as any)['reloadly'] as FakeReloadly;
    reloadly.sendStatus = 'FAILED';
    payments.throwOnRefund = true;
    const created = await svc.createTopup(CREATE);
    const done = await svc.handlePaymentSucceeded(created.topup.stripePaymentIntentId!);
    expect(done?.status).toBe(TopupStatus.REFUND_FAILED);
    expect(done?.failureReason).toMatch(/refund failed/);
  });

  it('PROCESSING stays SENDING, reconcile settles it when Reloadly confirms', async () => {
    const { svc, ledger } = makeService();
    const reloadly = (svc as any)['reloadly'] as FakeReloadly;
    reloadly.sendStatus = 'PROCESSING';
    const created = await svc.createTopup(CREATE);
    const sending = await svc.handlePaymentSucceeded(created.topup.stripePaymentIntentId!);
    expect(sending?.status).toBe(TopupStatus.SENDING);
    reloadly.statusByTxn[4242] = 'SUCCESSFUL';
    const done = await svc.reconcile(created.topup.id);
    expect(done?.status).toBe(TopupStatus.DELIVERED);
    expect(ledger.balance('TOPUP_PAYABLE')).toBe(0);
  });

  it('webhook replay does not double-post the ledger', async () => {
    const { svc, ledger } = makeService();
    const created = await svc.createTopup(CREATE);
    await svc.handlePaymentSucceeded(created.topup.stripePaymentIntentId!);
    const entriesAfterFirst = ledger.allEntries().length;
    await svc.handlePaymentSucceeded(created.topup.stripePaymentIntentId!);
    expect(ledger.allEntries().length).toBe(entriesAfterFirst);
  });

  it('card payment failure ends in PAYMENT_FAILED and nothing is sent', async () => {
    const { svc, reloadly } = makeService();
    const created = await svc.createTopup(CREATE);
    const failed = await svc.handlePaymentFailed(created.topup.stripePaymentIntentId!);
    expect(failed?.status).toBe(TopupStatus.PAYMENT_FAILED);
    expect(reloadly.sentRequests.length).toBe(0);
  });

  it('detectOperator returns the app-facing operator shape for an Afghan number', async () => {
    const { svc } = makeService();
    const op = await svc.detectOperator('+93791234567');
    expect(op.operatorId).toBe(999);
    expect(op.name).toBe('Roshan Afghanistan');
    expect(op.countryIso).toBe('AF');
    expect(op.denominationType).toBe('RANGE');
    expect(op.localMinMinor).toBe(1000);
    expect(op.localMaxMinor).toBe(500000);
  });

  it('rejects amounts outside the operator range', async () => {
    const { svc } = makeService();
    await expect(svc.createTopup({ ...CREATE, amountLocalMajor: 5, idempotencyKey: 'idem-key-0002' }))
      .rejects.toThrow(/Minimum/);
    await expect(svc.createTopup({ ...CREATE, amountLocalMajor: 99999, idempotencyKey: 'idem-key-0003' }))
      .rejects.toThrow(/Maximum/);
  });
});
