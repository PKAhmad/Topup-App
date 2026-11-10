import { Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';

// Double-entry ledger: every journal must balance (sum debits == sum credits).
// Accounts (all in the charge currency):
//   STRIPE_CLEARING  — money Stripe holds for us after a card payment
//   TOPUP_PAYABLE    — money owed to a customer until their topup is delivered
//   RELOADLY_BALANCE — our prepaid float at Reloadly (asset, debit-normal here as "paid out")
//   FEE_REVENUE      — our earned service fees
export type LedgerAccount =
  | 'STRIPE_CLEARING' | 'TOPUP_PAYABLE' | 'RELOADLY_BALANCE' | 'FEE_REVENUE';

export interface LedgerLine { account: LedgerAccount; debitMinor?: number; creditMinor?: number; }
export interface LedgerEntry extends Required<LedgerLine> {
  id: string; transactionId: string; currency: string; memo: string; createdAt: Date;
}

@Injectable()
export class LedgerService {
  private entries: LedgerEntry[] = [];

  post(transactionId: string, currency: string, memo: string, lines: LedgerLine[]): LedgerEntry[] {
    const debits = lines.reduce((s, l) => s + (l.debitMinor || 0), 0);
    const credits = lines.reduce((s, l) => s + (l.creditMinor || 0), 0);
    if (debits !== credits || debits <= 0) {
      throw new Error(`Unbalanced journal for ${transactionId}: debits=${debits} credits=${credits}`);
    }
    for (const l of lines) {
      if ((l.debitMinor || 0) < 0 || (l.creditMinor || 0) < 0) throw new Error('Negative ledger line');
      if ((l.debitMinor || 0) > 0 && (l.creditMinor || 0) > 0) throw new Error('Ledger line cannot be both debit and credit');
    }
    const made = lines.map((l) => ({
      id: randomUUID(), transactionId, currency, memo, createdAt: new Date(),
      account: l.account, debitMinor: l.debitMinor || 0, creditMinor: l.creditMinor || 0,
    }));
    this.entries.push(...made);
    return made;
  }

  /** Journal: card payment captured. Dr STRIPE_CLEARING / Cr TOPUP_PAYABLE (total). */
  journalPayment(txnId: string, currency: string, totalMinor: number): LedgerEntry[] {
    return this.post(txnId, currency, 'card payment captured', [
      { account: 'STRIPE_CLEARING', debitMinor: totalMinor },
      { account: 'TOPUP_PAYABLE', creditMinor: totalMinor },
    ]);
  }

  /** Journal: topup delivered. Payable splits into Reloadly cost + our fee revenue. */
  journalDelivered(txnId: string, currency: string, costMinor: number, feeMinor: number): LedgerEntry[] {
    return this.post(txnId, currency, 'topup delivered', [
      { account: 'TOPUP_PAYABLE', debitMinor: costMinor + feeMinor },
      { account: 'RELOADLY_BALANCE', creditMinor: costMinor },
      { account: 'FEE_REVENUE', creditMinor: feeMinor },
    ]);
  }

  /** Journal: refund to card. Dr TOPUP_PAYABLE / Cr STRIPE_CLEARING (total). */
  journalRefund(txnId: string, currency: string, totalMinor: number): LedgerEntry[] {
    return this.post(txnId, currency, 'refund to card', [
      { account: 'TOPUP_PAYABLE', debitMinor: totalMinor },
      { account: 'STRIPE_CLEARING', creditMinor: totalMinor },
    ]);
  }

  entriesFor(transactionId: string): LedgerEntry[] {
    return this.entries.filter((e) => e.transactionId === transactionId);
  }

  /** Net balance of an account: debits - credits. */
  balance(account: LedgerAccount): number {
    return this.entries
      .filter((e) => e.account === account)
      .reduce((s, e) => s + e.debitMinor - e.creditMinor, 0);
  }

  allEntries(): LedgerEntry[] { return [...this.entries]; }
}
