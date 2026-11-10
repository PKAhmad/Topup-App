// Standalone verification of the pure-Dart core with the plain Dart SDK
// (no Flutter in this VM): dart tool/verify_pure.dart
// The same assertions live as flutter tests in test/ for CI.
import '../lib/l10n/strings.dart';
import '../lib/services/phone_input.dart';
import '../lib/services/speech_composer.dart';

int passed = 0;
void eq(Object? actual, Object? expected, String label) {
  final a = '$actual';
  final e = '$expected';
  if (a != e) {
    throw StateError('FAIL $label\n  expected: $e\n  actual:   $a');
  }
  passed++;
  print('ok - $label');
}

void main() {
  eq(SpeechComposer.phoneReadback('+93791234567'),
      '[prompt_number_is, digit_9, digit_3, digit_7, digit_9, digit_1, digit_2, digit_3, digit_4, digit_5, digit_6, digit_7, prompt_confirm_number]',
      'phone readback');
  eq(SpeechComposer.numberWords(500, 'ps'), '[digit_5, scale_hundred]', 'ps 500');
  eq(SpeechComposer.numberWords(250, 'ps'), '[digit_2, scale_hundred, word_and, tens_50]', 'ps 250');
  eq(SpeechComposer.numberWords(75, 'ps'), '[digit_5, tensx_70]', 'ps 75');
  eq(SpeechComposer.numberWords(75, 'fa'), '[tens_70, word_and, digit_5]', 'fa 75');
  eq(SpeechComposer.numberWords(75, 'en'), '[tens_70, digit_5]', 'en 75');
  eq(SpeechComposer.numberWords(15, 'ps'), '[teen_15]', 'ps 15');
  eq(SpeechComposer.numberWords(20, 'ps'), '[tens_20]', 'ps 20 standalone');
  eq(SpeechComposer.numberWords(1250, 'ps'),
      '[digit_1, scale_thousand, word_and, digit_2, scale_hundred, word_and, tens_50]', 'ps 1250');
  eq(SpeechComposer.numberWords(100000, 'ps'), '[digit_1, scale_hundred, scale_thousand]', 'ps 100000');
  eq(SpeechComposer.moneySpeech(629, 'EUR', 'en'), '[digit_6, word_point, digit_2, digit_9, cur_EUR]', 'money 6.29 EUR');
  eq(SpeechComposer.moneySpeech(600, 'EUR', 'en'), '[digit_6, cur_EUR]', 'money 6.00 EUR');
  eq(SpeechComposer.amountEcho(500, 'AFN', 'ps'), '[prompt_you_chose, digit_5, scale_hundred, cur_AFN]', 'amount echo');
  eq(buildE164('AF', '0791234567'), '+93791234567', 'e164 trunk');
  eq(buildE164('AF', '+93 79 123 4567'), '+93791234567', 'e164 intl');
  eq(buildE164('DE', '01712345678'), '+491712345678', 'e164 de');
  eq(buildE164('AF', '791234567'), '+93791234567', 'e164 bare');
  eq(groupForDisplay('+93791234567'), '+93 791 234 567', 'grouping');
  eq(isPlausibleE164('+93791234567'), true, 'plausible');
  eq(isPlausibleE164('+9379'), false, 'implausible');
  // String parity: every key in all three languages, non-empty.
  var parity = 0;
  for (final key in Strings.keys) {
    for (final lang in Strings.languages) {
      if (!Strings.has(lang, key) || Strings.t(lang, key).isEmpty) {
        throw StateError('Missing string $key/$lang');
      }
      parity++;
    }
  }
  passed++;
  print('ok - string parity ($parity cells)');
  print('\nALL $passed CHECKS PASSED');
}
