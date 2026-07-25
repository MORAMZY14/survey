import 'package:block_survey/models/central.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Central identity', () {
    test('normalizes spaces and capitalization', () {
      expect(
        Central.normalizeName('  El-Hadra   Central  '),
        'el-hadra central',
      );
    });

    test('creates one safe document id for equivalent names', () {
      final first = Central.documentIdForName('El-Hadra');
      final second = Central.documentIdForName('  EL-HADRA  ');

      expect(first, second);
      expect(first, isNot(contains('/')));
      expect(first, isNot(contains('=')));
    });
  });
}
