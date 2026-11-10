// The transaction state machine — the heart of the backend.
// Money rule: a topup is sent to Reloadly ONLY from PAID, and a failed send
// ALWAYS ends in a refund (REFUNDED) or REFUND_FAILED (manual review).
// Nothing leaves these transitions: no skipping, no going backwards.

export enum TopupStatus {
  CREATED = 'CREATED',
  AWAITING_PAYMENT = 'AWAITING_PAYMENT',
  PAYMENT_FAILED = 'PAYMENT_FAILED',
  PAID = 'PAID',
  SENDING = 'SENDING',
  DELIVERED = 'DELIVERED',
  FAILED = 'FAILED',
  REFUND_PENDING = 'REFUND_PENDING',
  REFUNDED = 'REFUNDED',
  REFUND_FAILED = 'REFUND_FAILED',
}

const TRANSITIONS: Record<TopupStatus, TopupStatus[]> = {
  [TopupStatus.CREATED]: [TopupStatus.AWAITING_PAYMENT, TopupStatus.PAYMENT_FAILED],
  [TopupStatus.AWAITING_PAYMENT]: [TopupStatus.PAID, TopupStatus.PAYMENT_FAILED],
  [TopupStatus.PAYMENT_FAILED]: [],
  [TopupStatus.PAID]: [TopupStatus.SENDING],
  [TopupStatus.SENDING]: [TopupStatus.DELIVERED, TopupStatus.FAILED],
  [TopupStatus.DELIVERED]: [],
  [TopupStatus.FAILED]: [TopupStatus.REFUND_PENDING],
  [TopupStatus.REFUND_PENDING]: [TopupStatus.REFUNDED, TopupStatus.REFUND_FAILED],
  [TopupStatus.REFUNDED]: [],
  [TopupStatus.REFUND_FAILED]: [TopupStatus.REFUND_PENDING], // manual retry of the refund
};

export function canTransition(from: TopupStatus, to: TopupStatus): boolean {
  return (TRANSITIONS[from] || []).includes(to);
}

export function assertTransition(from: TopupStatus, to: TopupStatus): void {
  if (!canTransition(from, to)) {
    throw new Error(`Illegal topup status transition: ${from} -> ${to}`);
  }
}

export function isTerminal(status: TopupStatus): boolean {
  return (TRANSITIONS[status] || []).length === 0;
}
