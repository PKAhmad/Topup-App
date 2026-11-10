// Phone input helpers — pure Dart. The user types the way they know the
// number (0791..., 0049..., +93...); we always end with clean E.164.
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
