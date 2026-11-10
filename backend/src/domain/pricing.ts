// Pricing: all money is integer minor units (cents). No floats anywhere.
// Customer total = Reloadly cost (converted into the charge currency) + our fee.
// fee = max(feeMin, ceil(cost * feeBps / 10000) + feeFixed)

export interface FeeConfig { feeBps: number; feeFixedMinor: number; feeMinMinor: number; }

export interface Quote {
  costMinor: number;
  feeMinor: number;
  totalMinor: number;
}

export function quotePrice(costMinor: number, cfg: FeeConfig): Quote {
  if (!Number.isInteger(costMinor) || costMinor <= 0) {
    throw new Error(`costMinor must be a positive integer, got ${costMinor}`);
  }
  const pctFee = Math.ceil((costMinor * cfg.feeBps) / 10000);
  const feeMinor = Math.max(cfg.feeMinMinor, pctFee + cfg.feeFixedMinor);
  return { costMinor, feeMinor, totalMinor: costMinor + feeMinor };
}

/** Convert a local-currency minor amount with an FX rate (charge per 1 local unit). */
export function convertWithFx(localMinor: number, fxRate: number): number {
  if (!(fxRate > 0)) throw new Error(`fxRate must be positive, got ${fxRate}`);
  return Math.round(localMinor * fxRate);
}

/** Major units (what Reloadly's API speaks) <-> minor units (what we store). */
export const toMinor = (major: number): number => Math.round(major * 100);
export const toMajor = (minor: number): number => minor / 100;
