import { Injectable } from '@nestjs/common';
import Stripe from 'stripe';

// Payments abstraction: Stripe in production, a fake in tests.
// The app NEVER touches card data — the Flutter app confirms the
// PaymentIntent with Stripe's SDK using the clientSecret we return.

export interface CreatePaymentIntentInput {
  amountMinor: number;
  currency: string;
  idempotencyKey: string;
  metadata: Record<string, string>;
}
export interface PaymentIntentResult { id: string; clientSecret: string; status: string; }
export interface RefundResult { id: string; status: string; }
export interface PaymentWebhookEvent { type: string; paymentIntentId: string | null; raw: unknown; }

export interface PaymentsProvider {
  createPaymentIntent(input: CreatePaymentIntentInput): Promise<PaymentIntentResult>;
  refund(paymentIntentId: string): Promise<RefundResult>;
  verifyWebhook(payload: Buffer | string, signature: string): PaymentWebhookEvent;
}

@Injectable()
export class StripePaymentsProvider implements PaymentsProvider {
  private stripe: Stripe | null = null;
  constructor(private readonly cfg: { secretKey: string; webhookSecret: string }) {}

  private client(): Stripe {
    if (!this.cfg.secretKey) throw new Error('STRIPE_SECRET_KEY not configured (Phase 0: fill .env)');
    if (!this.stripe) this.stripe = new Stripe(this.cfg.secretKey);
    return this.stripe;
  }

  async createPaymentIntent(input: CreatePaymentIntentInput): Promise<PaymentIntentResult> {
    const pi = await this.client().paymentIntents.create(
      {
        amount: input.amountMinor,
        currency: input.currency.toLowerCase(),
        metadata: input.metadata,
        automatic_payment_methods: { enabled: true },
      },
      { idempotencyKey: input.idempotencyKey },
    );
    return { id: pi.id, clientSecret: pi.client_secret || '', status: pi.status };
  }

  async refund(paymentIntentId: string): Promise<RefundResult> {
    const refund = await this.client().refunds.create({ payment_intent: paymentIntentId });
    return { id: refund.id, status: refund.status || 'unknown' };
  }

  verifyWebhook(payload: Buffer | string, signature: string): PaymentWebhookEvent {
    if (!this.cfg.webhookSecret) throw new Error('STRIPE_WEBHOOK_SECRET not configured');
    const event = this.client().webhooks.constructEvent(payload, signature, this.cfg.webhookSecret);
    const obj: any = (event.data as any)?.object || {};
    return {
      type: event.type,
      paymentIntentId: obj.object === 'payment_intent' ? obj.id : obj.payment_intent || null,
      raw: event,
    };
  }
}
