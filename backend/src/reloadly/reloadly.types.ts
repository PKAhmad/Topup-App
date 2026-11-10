export interface ReloadlyCountry {
  isoName: string;
  name: string;
  currencyCode: string;
  currencyName?: string;
  flag?: string;
  callingCodes?: string[];
  [k: string]: unknown;
}

export interface ReloadlyOperator {
  id: number;
  operatorId?: number;
  name: string;
  country: { isoName: string; name: string };
  denominationType: 'FIXED' | 'RANGE';
  currencyCode?: string; // sender (account) currency
  localCurrencyCode?: string;
  minAmount?: number; // sender currency, major
  maxAmount?: number;
  localMinAmount?: number; // recipient currency, major
  localMaxAmount?: number;
  fixedAmounts?: number[]; // sender currency denominations
  localFixedAmounts?: number[]; // recipient currency denominations
  fx?: { rate: number; currencyCode: string };
  discount?: number;
  logoUrls?: string[];
  supportsDataPlans?: boolean;
  [k: string]: unknown;
}

export interface ReloadlyBalance { balance: number; currencyCode: string; [k: string]: unknown; }

export interface ReloadlyTopupRequest {
  operatorId: number;
  amount: number; // major units
  useLocalAmount: boolean;
  customIdentifier: string; // MUST be unique per transaction — we send our transaction UUID
  recipientPhone: { countryCode: string; number: string };
  senderPhone?: { countryCode: string; number: string };
}

export type ReloadlyTxnStatus = 'SUCCESSFUL' | 'PROCESSING' | 'FAILED' | 'REFUNDED' | string;

export interface ReloadlyTopupResponse {
  id?: number;
  transactionId?: number;
  operatorId: number;
  status: ReloadlyTxnStatus;
  customIdentifier?: string;
  deliveredAmount?: number;
  deliveredAmountCurrencyCode?: string;
  requestedAmount?: number;
  requestedAmountCurrencyCode?: string;
  balanceInfo?: { newBalance?: number; currencyCode?: string };
  [k: string]: unknown;
}

export class ReloadlyError extends Error {
  constructor(
    public readonly httpStatus: number,
    public readonly errorCode: string | null,
    message: string,
    public readonly body?: unknown,
  ) { super(message); this.name = 'ReloadlyError'; }
}
