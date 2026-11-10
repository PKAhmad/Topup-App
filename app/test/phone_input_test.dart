import 'package:flutter_test/flutter_test.dart';
import 'package:topup_app/services/phone_input.dart';

void main() {
  group('buildE164', () {
    test('afghan trunk-zero number', () {
      expect(buildE164('AF', '0791234567'), '+93791234567');
    });
    test('already international with spaces', () {
      expect(buildE164('AF', '+93 79 123 4567'), '+93791234567');
    });
    test('00 prefix', () {
      expect(buildE164('DE', '00491712345678'), '+491712345678');
    });
    test('german trunk zero', () {
      expect(buildE164('DE', '01712345678'), '+491712345678');
    });
    test('bare national number gets the dial code', () {
      expect(buildE164('AF', '791234567'), '+93791234567');
    });
    test('rejects letters', () {
      expect(() => buildE164('AF', '079abc'), throwsFormatException);
    });
  });

  test('display grouping', () {
    expect(groupForDisplay('+93791234567'), '+93 791 234 567');
  });

  test('plausibility', () {
    expect(isPlausibleE164('+93791234567'), isTrue);
    expect(isPlausibleE164('+9379'), isFalse);
  });
}
