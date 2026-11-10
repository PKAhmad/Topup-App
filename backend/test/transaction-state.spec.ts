import { assertTransition, canTransition, isTerminal, TopupStatus as S } from '../src/domain/transaction-state';

describe('transaction state machine', () => {
  it('allows the happy path', () => {
    expect(canTransition(S.CREATED, S.AWAITING_PAYMENT)).toBe(true);
    expect(canTransition(S.AWAITING_PAYMENT, S.PAID)).toBe(true);
    expect(canTransition(S.PAID, S.SENDING)).toBe(true);
    expect(canTransition(S.SENDING, S.DELIVERED)).toBe(true);
  });
  it('allows the failure/refund path', () => {
    expect(canTransition(S.SENDING, S.FAILED)).toBe(true);
    expect(canTransition(S.FAILED, S.REFUND_PENDING)).toBe(true);
    expect(canTransition(S.REFUND_PENDING, S.REFUNDED)).toBe(true);
    expect(canTransition(S.REFUND_PENDING, S.REFUND_FAILED)).toBe(true);
  });
  it('forbids skipping payment (never send an unpaid topup)', () => {
    expect(canTransition(S.CREATED, S.SENDING)).toBe(false);
    expect(canTransition(S.AWAITING_PAYMENT, S.SENDING)).toBe(false);
    expect(() => assertTransition(S.CREATED, S.DELIVERED)).toThrow(/Illegal/);
  });
  it('forbids leaving terminal states', () => {
    expect(isTerminal(S.DELIVERED)).toBe(true);
    expect(isTerminal(S.REFUNDED)).toBe(true);
    expect(canTransition(S.DELIVERED, S.SENDING)).toBe(false);
    expect(canTransition(S.REFUNDED, S.PAID)).toBe(false);
  });
});
