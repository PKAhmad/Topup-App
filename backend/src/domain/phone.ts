// Phone parsing: everything in the system is E.164 (+<dial><national>).
// Country detection is by longest matching dial code; the OPERATOR is always
// confirmed by Reloadly auto-detect — prefix hints below are UI help only.

export interface ParsedPhone {
  e164: string;
  countryIso: string;
  nationalNumber: string;
}

const DIAL_CODES: Record<string, string> = {
  AF: '93', DE: '49', US: '1', CA: '1', GB: '44', PK: '92', IR: '98',
  TR: '90', AE: '971', SA: '966', QA: '974', KW: '965', FR: '33',
  NL: '31', SE: '46', NO: '47', DK: '45', AT: '43', CH: '41', IN: '91',
  TJ: '992', UZ: '998', TM: '993', KZ: '7', RU: '7', AU: '61',
};

// Afghan operator prefix HINTS (first 2 digits of the national number,
// i.e. the familiar 070/079/... prefixes without the trunk 0).
// Source of truth is Reloadly auto-detect; hints only pre-select in the UI.
export const AF_OPERATOR_PREFIX_HINTS: Record<string, string> = {
  '70': 'AWCC', '71': 'AWCC',
  '79': 'Roshan', '72': 'Roshan',
  '77': 'MTN Afghanistan', '76': 'MTN Afghanistan',
  '78': 'Etisalat Afghanistan', '73': 'Etisalat Afghanistan',
  '74': 'Salaam',
};

export function normalizePhone(raw: string): string {
  let p = (raw || '').replace(/[\s\-()]/g, '');
  if (p.startsWith('00')) p = '+' + p.slice(2);
  if (!p.startsWith('+')) throw new Error(`Phone number must be international format: ${raw}`);
  if (!/^\+[0-9]{7,15}$/.test(p)) throw new Error(`Invalid phone number: ${raw}`);
  return p;
}

export function parsePhone(raw: string): ParsedPhone {
  const e164 = normalizePhone(raw);
  const digits = e164.slice(1);
  let best: { iso: string; dial: string } | null = null;
  for (const [iso, dial] of Object.entries(DIAL_CODES)) {
    if (digits.startsWith(dial) && (!best || dial.length > best.dial.length)) {
      best = { iso, dial };
    }
  }
  if (!best) throw new Error(`Unsupported country for phone: ${e164}`);
  return { e164, countryIso: best.iso, nationalNumber: digits.slice(best.dial.length) };
}

export function afghanOperatorHint(e164: string): string | null {
  const parsed = parsePhone(e164);
  if (parsed.countryIso !== 'AF') return null;
  return AF_OPERATOR_PREFIX_HINTS[parsed.nationalNumber.slice(0, 2)] || null;
}
