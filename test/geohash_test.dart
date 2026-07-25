import 'package:block_survey/utils/geohash.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Geohash.encode', () {
    test('matches a standard public geohash example', () {
      expect(Geohash.encode(42.6, -5.6, precision: 5), 'ezs42');
    });

    test('validates coordinates', () {
      expect(() => Geohash.encode(91, 0), throwsArgumentError);
      expect(() => Geohash.encode(0, 181), throwsArgumentError);
    });
  });
}
