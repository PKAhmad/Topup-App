import { afghanOperatorHint, normalizePhone, parsePhone } from '../src/domain/phone';

describe('phone', () => {
  it('parses an Afghan number', () => {
    const p = parsePhone('+93 79 123 4567');
    expect(p.countryIso).toBe('AF');
    expect(p.e164).toBe('+93791234567');
    expect(p.nationalNumber).toBe('791234567');
  });
  it('parses 00-prefixed German number', () => {
    const p = parsePhone('0049 171 2345678');
    expect(p.countryIso).toBe('DE');
    expect(p.e164).toBe('+491712345678');
  });
  it('rejects local format without country code', () => {
    expect(() => normalizePhone('0791234567')).toThrow();
  });
  it('rejects garbage', () => {
    expect(() => parsePhone('+93abc')).toThrow();
  });
  it('gives Afghan operator hints by prefix', () => {
    expect(afghanOperatorHint('+93791234567')).toBe('Roshan');
    expect(afghanOperatorHint('+93701234567')).toBe('AWCC');
    expect(afghanOperatorHint('+491712345678')).toBeNull();
  });
});
