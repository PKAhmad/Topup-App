import { LedgerService } from '../src/ledger/ledger.service';

describe('ledger', () => {
  it('rejects an unbalanced journal', () => {
    const ledger = new LedgerService();
    expect(() => ledger.post('t1', 'EUR', 'bad', [
      { account: 'STRIPE_CLEARING', debitMinor: 100 },
      { account: 'TOPUP_PAYABLE', creditMinor: 90 },
    ])).toThrow(/Unbalanced/);
  });
  it('payment then delivery zeroes the payable and books cost + fee', () => {
    const ledger = new LedgerService();
    ledger.journalPayment('t1', 'EUR', 629);
    ledger.journalDelivered('t1', 'EUR', 550, 79);
    expect(ledger.balance('TOPUP_PAYABLE')).toBe(0);
    expect(ledger.balance('STRIPE_CLEARING')).toBe(629);
    expect(ledger.balance('RELOADLY_BALANCE')).toBe(-550);
    expect(ledger.balance('FEE_REVENUE')).toBe(-79);
  });
  it('payment then refund returns clearing to zero', () => {
    const ledger = new LedgerService();
    ledger.journalPayment('t2', 'EUR', 629);
    ledger.journalRefund('t2', 'EUR', 629);
    expect(ledger.balance('TOPUP_PAYABLE')).toBe(0);
    expect(ledger.balance('STRIPE_CLEARING')).toBe(0);
  });
});
