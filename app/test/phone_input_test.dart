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

  group('instant local detection', () {
    test('country comes from the number itself', () {
      expect(countryIsoFromE164('+93791234567'), 'AF');
      expect(countryIsoFromE164('+491712345678'), 'DE');
      expect(countryIsoFromE164('+923001234567'), 'PK');
      expect(countryIsoFromE164('0791234567'), isNull);
    });

    test('afghan operators from prefix, offline', () {
      expect(localOperatorHint('+93701234567')!.name, 'AWCC');
      expect(localOperatorHint('+93791234567')!.name, 'Roshan');
      expect(localOperatorHint('+93771234567')!.name, 'MTN Afghanistan');
      expect(localOperatorHint('+93781234567')!.name, 'Etisalat Afghanistan');
      expect(localOperatorHint('+93741234567')!.name, 'Salaam');
      expect(localOperatorHint('+93791234567')!.localOnly, isTrue);
    });

    test('unknown afghan prefix still detects the country', () {
      final op = localOperatorHint('+93751234567')!;
      expect(op.countryIso, 'AF');
      expect(op.name, '');
      expect(op.operatorId, 0);
    });

    test('pakistan broad prefix families', () {
      expect(localOperatorHint('+923001234567')!.name, 'Jazz');
      expect(localOperatorHint('+923111234567')!.name, 'Zong');
    });

    test('unknown country returns null', () {
      expect(localOperatorHint('+9991234567'), isNull);
    });
  });

  test('plausibility', () {
    expect(isPlausibleE164('+93791234567'), isTrue);
    expect(isPlausibleE164('+9379'), isFalse);
  });
}
