import 'package:flutter_test/flutter_test.dart';
import 'package:topup_app/services/speech_composer.dart';

void main() {
  group('phone readback', () {
    test('reads every digit between the two prompts', () {
      expect(
        SpeechComposer.phoneReadback('+93791234567'),
        [
          'prompt_number_is',
          'digit_9', 'digit_3', 'digit_7', 'digit_9', 'digit_1', 'digit_2',
          'digit_3', 'digit_4', 'digit_5', 'digit_6', 'digit_7',
          'prompt_confirm_number',
        ],
      );
    });
  });

  group('numberWords Pashto', () {
    test('round hundred', () {
      expect(SpeechComposer.numberWords(500, 'ps'), ['digit_5', 'scale_hundred']);
    });
    test('hundred + and + tens', () {
      expect(SpeechComposer.numberWords(250, 'ps'),
          ['digit_2', 'scale_hundred', 'word_and', 'tens_50']);
    });
    test('unit before suffix-ten (75 = پنځه اویا)', () {
      expect(SpeechComposer.numberWords(75, 'ps'), ['digit_5', 'tensx_70']);
    });
    test('teens are whole words', () {
      expect(SpeechComposer.numberWords(15, 'ps'), ['teen_15']);
    });
    test('thousands compose with and', () {
      expect(
        SpeechComposer.numberWords(1250, 'ps'),
        ['digit_1', 'scale_thousand', 'word_and', 'digit_2', 'scale_hundred', 'word_and', 'tens_50'],
      );
    });
    test('zero', () {
      expect(SpeechComposer.numberWords(0, 'ps'), ['digit_0']);
    });
  });

  group('numberWords Dari and English', () {
    test('dari 75 = tens + and + unit', () {
      expect(SpeechComposer.numberWords(75, 'fa'), ['tens_70', 'word_and', 'digit_5']);
    });
    test('english 75 = tens + unit', () {
      expect(SpeechComposer.numberWords(75, 'en'), ['tens_70', 'digit_5']);
    });
    test('english 250 has no and', () {
      expect(SpeechComposer.numberWords(250, 'en'), ['digit_2', 'scale_hundred', 'tens_50']);
    });
  });

  group('money speech', () {
    test('euros with cents', () {
      expect(SpeechComposer.moneySpeech(629, 'EUR', 'en'),
          ['digit_6', 'word_point', 'digit_2', 'digit_9', 'cur_EUR']);
    });
    test('round euros skip the point', () {
      expect(SpeechComposer.moneySpeech(600, 'EUR', 'en'), ['digit_6', 'cur_EUR']);
    });
    test('amount echo in Pashto', () {
      expect(SpeechComposer.amountEcho(500, 'AFN', 'ps'),
          ['prompt_you_chose', 'digit_5', 'scale_hundred', 'cur_AFN']);
    });
  });
}
