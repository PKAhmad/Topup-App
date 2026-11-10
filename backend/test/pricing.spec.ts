import { convertWithFx, quotePrice } from '../src/domain/pricing';

const cfg = { feeBps: 800, feeFixedMinor: 35, feeMinMinor: 49 };

describe('pricing', () => {
  it('computes fee = pct + fixed above the minimum', () => {
    // cost 550 -> pct ceil(44)=44, +35 = 79 (> min 49)
    expect(quotePrice(550, cfg)).toEqual({ costMinor: 550, feeMinor: 79, totalMinor: 629 });
  });
  it('applies the minimum fee on small topups', () => {
    // cost 100 -> pct 8 + 35 = 43 < 49 -> fee 49
    expect(quotePrice(100, cfg).feeMinor).toBe(49);
  });
  it('rejects zero/negative/fractional cost', () => {
    expect(() => quotePrice(0, cfg)).toThrow();
    expect(() => quotePrice(-5, cfg)).toThrow();
    expect(() => quotePrice(10.5, cfg)).toThrow();
  });
  it('converts with FX and rounds to minor units', () => {
    expect(convertWithFx(50000, 0.011)).toBe(550);
    expect(() => convertWithFx(100, 0)).toThrow();
  });
});
