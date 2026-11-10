import 'package:flutter_test/flutter_test.dart';
import 'package:topup_app/l10n/strings.dart';

void main() {
  test('every UI string exists in Pashto, Dari and English', () {
    final missing = <String>[];
    for (final key in Strings.keys) {
      for (final lang in Strings.languages) {
        if (!Strings.has(lang, key) || Strings.t(lang, key).isEmpty) {
          missing.add('$key/$lang');
        }
      }
    }
    expect(missing, isEmpty, reason: 'Missing translations: $missing');
  });
}
