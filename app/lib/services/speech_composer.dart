// Speech composer — pure Dart, the heart of the voice feature.
//
// Pashto device TTS is unreliable (the Karyab lesson), so the app speaks
// with PRE-RECORDED clips. Fixed sentences are single clips (prompt_*).
// Anything dynamic — a phone number, an amount — is COMPOSED from small
// recorded pieces: digits, teens, tens, hundred/thousand, "and", "point",
// and currency words. One recording session (~55 short clips per language)
// covers every number the app will ever say.
//
// Clip keys (file = assets/audio/<lang>/<key>.mp3):
//   digit_0..digit_9            صفر..نهه
//   teen_11..teen_19            یوولس..نولس (irregular, recorded whole)
//   tens_10, tens_20..tens_90   standalone tens: لس، شل، دېرش، څلوېښت...
//   tensx_20..tensx_90          suffix tens used after a unit in Pashto
//                               (25 = پنځه ویشت, so tensx_20 = ویشت)
//   scale_hundred (سل), scale_thousand (زر), word_and (او), word_point (اشاریه)
//   cur_AFN (افغانۍ), cur_EUR (یورو), cur_USD (ډالر), cur_PKR (روپۍ)
//   prompt_<key>                full fixed sentences, see docs/VOICE-SCRIPT.md
class SpeechComposer {
  static String digitClip(int d) => 'digit_$d';
  static String currencyClip(String currency) => 'cur_${currency.toUpperCase()}';

  /// The number read-back: the single most important safety step.
  /// A top-up to a wrong number cannot be undone, so the app reads the
  /// number back digit by digit and the user confirms with the green button.
  static List<String> phoneReadback(String e164) {
    final digits = e164.replaceAll(RegExp(r'[^0-9]'), '');
    return [
      'prompt_number_is',
      ...digits.split('').map((c) => digitClip(int.parse(c))),
      'prompt_confirm_number',
    ];
  }

  /// Compose the spoken form of an integer 0..999999.
  /// Word order differs by language:
  ///  - Pashto: unit before tens (75 = پنځه اویا), "او" after hundred/thousand
  ///  - Dari:   tens, then "و", then unit (75 = هفتاد و پنج)
  ///  - English: tens then unit (75 = seventy five)
  static List<String> numberWords(int n, String lang) {
    if (n < 0 || n > 999999) throw ArgumentError('numberWords range 0..999999, got $n');
    if (n == 0) return [digitClip(0)];
    final out = <String>[];
    final thousands = n ~/ 1000;
    final rest = n % 1000;
    if (thousands > 0) {
      out.addAll(_under1000(thousands, lang));
      out.add('scale_thousand');
    }
    if (rest > 0) {
      if (thousands > 0 && (lang == 'ps' || lang == 'fa')) out.add('word_and');
      out.addAll(_under1000(rest, lang));
    }
    return out;
  }

  static List<String> _under1000(int n, String lang) {
    final out = <String>[];
    final hundreds = n ~/ 100;
    final rest = n % 100;
    if (hundreds > 0) {
      out.add(digitClip(hundreds));
      out.add('scale_hundred');
    }
    if (rest > 0) {
      if (hundreds > 0 && (lang == 'ps' || lang == 'fa')) out.add('word_and');
      out.addAll(_under100(rest, lang));
    }
    return out;
  }

  static List<String> _under100(int n, String lang) {
    if (n < 10) return [digitClip(n)];
    if (n >= 11 && n <= 19) return ['teen_$n'];
    final tens = (n ~/ 10) * 10;
    final unit = n % 10;
    if (unit == 0) return ['tens_$tens'];
    switch (lang) {
      case 'ps': // پنځه اویا — unit first, suffix form of the ten
        return [digitClip(unit), 'tensx_$tens'];
      case 'fa': // هفتاد و پنج — ten, "and", unit
        return ['tens_$tens', 'word_and', digitClip(unit)];
      default: // seventy five
        return ['tens_$tens', digitClip(unit)];
    }
  }

  /// "You chose: 500 Afghanis" — selection echo on the amount screen.
  static List<String> amountEcho(int amountMajor, String currency, String lang) {
    return [
      'prompt_you_chose',
      ...numberWords(amountMajor, lang),
      currencyClip(currency),
    ];
  }

  /// Money the customer pays, e.g. 629 minor EUR -> "six point two nine euros".
  static List<String> moneySpeech(int minorUnits, String currency, String lang) {
    final major = minorUnits ~/ 100;
    final cents = minorUnits % 100;
    final out = <String>[...numberWords(major, lang)];
    if (cents > 0) {
      out.add('word_point');
      out.add(digitClip(cents ~/ 10));
      out.add(digitClip(cents % 10));
    }
    out.add(currencyClip(currency));
    return out;
  }

  /// Review-screen sentence: send X to <number>, total Y.
  static List<String> reviewSpeech({
    required int amountMajor,
    required String localCurrency,
    required String e164,
    required int totalMinor,
    required String chargeCurrency,
    required String lang,
  }) {
    final digits = e164.replaceAll(RegExp(r'[^0-9]'), '');
    return [
      'prompt_you_send',
      ...numberWords(amountMajor, lang),
      currencyClip(localCurrency),
      'prompt_to_number',
      ...digits.split('').map((c) => digitClip(int.parse(c))),
      'prompt_total_is',
      ...moneySpeech(totalMinor, chargeCurrency, lang),
    ];
  }
}
