// Phone input helpers — pure Dart. The user types the way they know the
// number (0791..., 0049..., +93...); we always end with clean E.164.
import '../models/models.dart';

class CountryDial {
  static const Map<String, String> dialByIso = {
    'AF': '93', 'PK': '92', 'IR': '98', 'DE': '49', 'TR': '90',
    'AE': '971', 'SA': '966', 'US': '1', 'GB': '44', 'FR': '33',
    'NL': '31', 'SE': '46',
  };
  static const Map<String, String> flagByIso = {
    'AF': '🇦🇫', 'PK': '🇵🇰', 'IR': '🇮🇷', 'DE': '🇩🇪', 'TR': '🇹🇷',
    'AE': '🇦🇪', 'SA': '🇸🇦', 'US': '🇺🇸', 'GB': '🇬🇧', 'FR': '🇫🇷',
    'NL': '🇳🇱', 'SE': '🇸🇪',
  };
  // Afghanistan first — our core users send there most.
  static const List<String> starterCountries = [
    'AF', 'PK', 'IR', 'DE', 'TR', 'AE', 'SA', 'US', 'GB', 'FR', 'NL', 'SE',
  ];
}

String buildE164(String countryIso, String rawInput) {
  final dial = CountryDial.dialByIso[countryIso];
  if (dial == null) throw ArgumentError('Unknown country: $countryIso');
  var s = rawInput.trim().replaceAll(RegExp(r'[\s\-()]'), '');
  if (s.startsWith('+')) {
    final d = s.substring(1);
    if (!RegExp(r'^[0-9]+$').hasMatch(d)) throw const FormatException('bad phone');
    return '+$d';
  }
  if (!RegExp(r'^[0-9]+$').hasMatch(s)) throw const FormatException('bad phone');
  if (s.startsWith('00')) return '+${s.substring(2)}';
  if (s.startsWith(dial) && s.length >= dial.length + 6) return '+$s';
  if (s.startsWith('0')) return '+$dial${s.substring(1)}'; // trunk 0 -> country code
  return '+$dial$s';
}

bool isPlausibleE164(String e164) => RegExp(r'^\+[0-9]{8,15}$').hasMatch(e164);

/// The country is IN the number: longest matching dial code wins.
/// Instant and offline — the selected country is only a typing aid.
String? countryIsoFromE164(String e164) {
  if (!e164.startsWith('+')) return null;
  final digits = e164.substring(1);
  String? bestIso;
  var bestLen = 0;
  CountryDial.dialByIso.forEach((iso, dial) {
    if (digits.startsWith(dial) && dial.length > bestLen) {
      bestIso = iso;
      bestLen = dial.length;
    }
  });
  return bestIso;
}

/// National number (without dial code) for prefix lookups.
String nationalNumberOf(String e164, String countryIso) {
  final dial = CountryDial.dialByIso[countryIso];
  if (dial == null || !e164.startsWith('+$dial')) return '';
  return e164.substring(1 + dial.length);
}

// ---------------------------------------------------------------------------
// Instant local operator detection (offline, from the number prefix).
// Number portability means a prefix is a strong hint, not a legal proof —
// the backend/Reloadly confirmation still runs in the background and swaps
// in the exact operator when it answers. Afghanistan is mapped completely;
// Pakistan/Iran/Turkey carry the well-known broad prefix families.
// Local placeholder ids are negative and stable per operator.
// ---------------------------------------------------------------------------

class _PrefixOp {
  final String name;
  final int localId;
  const _PrefixOp(this.name, this.localId);
}

const Map<String, _PrefixOp> _afPrefixes = {
  '70': _PrefixOp('AWCC', -101), '71': _PrefixOp('AWCC', -101),
  '79': _PrefixOp('Roshan', -102), '72': _PrefixOp('Roshan', -102),
  '77': _PrefixOp('MTN Afghanistan', -103), '76': _PrefixOp('MTN Afghanistan', -103),
  '78': _PrefixOp('Etisalat Afghanistan', -104), '73': _PrefixOp('Etisalat Afghanistan', -104),
  '74': _PrefixOp('Salaam', -105),
};

// Keys are NATIONAL-number prefixes (E.164 form — trunk zero already gone):
// Pakistan 0300… arrives as 300…, Iran 0912… as 912…, Turkey 0532… as 532….
const Map<String, Map<String, _PrefixOp>> _prefixOpsByCountry = {
  'AF': _afPrefixes,
  'PK': {
    '30': _PrefixOp('Jazz', -201), '32': _PrefixOp('Jazz', -201),
    '31': _PrefixOp('Zong', -202),
    '33': _PrefixOp('Ufone', -203),
    '34': _PrefixOp('Telenor Pakistan', -204),
    '35': _PrefixOp('SCOM', -205),
  },
  'IR': {
    '91': _PrefixOp('Hamrah Aval (MCI)', -301), '99': _PrefixOp('Hamrah Aval (MCI)', -301),
    '93': _PrefixOp('Irancell', -302), '90': _PrefixOp('Irancell', -302),
    '92': _PrefixOp('RighTel', -303),
  },
  'TR': {
    '53': _PrefixOp('Turkcell', -401),
    '54': _PrefixOp('Vodafone Türkiye', -402),
    '50': _PrefixOp('Türk Telekom', -403), '55': _PrefixOp('Türk Telekom', -403),
  },
};

/// Detect the operator from the number itself — no network call.
/// Returns null only when even the country is unknown. When the country is
/// known but the prefix is not mapped, returns a country-only result with an
/// empty name and operatorId 0 (the UI shows "automatic network").
OperatorInfo? localOperatorHint(String e164) {
  final iso = countryIsoFromE164(e164);
  if (iso == null) return null;
  final national = nationalNumberOf(e164, iso);
  final table = _prefixOpsByCountry[iso];
  if (table != null && national.isNotEmpty) {
    // Longest prefix key wins (3-digit families before 2-digit ones).
    final keys = table.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    for (final k in keys) {
      if (national.startsWith(k)) {
        final op = table[k]!;
        return OperatorInfo(
          operatorId: op.localId,
          name: op.name,
          countryIso: iso,
          denominationType: 'RANGE',
          localOnly: true,
        );
      }
    }
  }
  return OperatorInfo(
    operatorId: 0,
    name: '',
    countryIso: iso,
    denominationType: 'RANGE',
    localOnly: true,
  );
}

/// '+93791234567' -> '+93 791 234 567' for display.
String groupForDisplay(String e164) {
  if (!e164.startsWith('+')) return e164;
  final digits = e164.substring(1);
  // Longest dial-code match for display split.
  String? dial;
  for (final d in CountryDial.dialByIso.values) {
    if (digits.startsWith(d) && (dial == null || d.length > dial.length)) dial = d;
  }
  if (dial == null) return e164;
  final national = digits.substring(dial.length);
  final groups = <String>[];
  for (var i = 0; i < national.length; i += 3) {
    groups.add(national.substring(i, i + 3 > national.length ? national.length : i + 3));
  }
  return '+$dial ${groups.join(' ')}';
}
