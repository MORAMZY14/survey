import 'package:block_survey/models/floor_survey.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('generateFloors', () {
    test('generates numbered floors', () {
      final floors = generateFloors(
        totalFloors: 3,
        defaultApartments: 2,
        startsWithGroundFloor: false,
      );

      expect(floors.map((floor) => floor.label), [
        'Floor 1',
        'Floor 2',
        'Floor 3',
      ]);
      expect(floors.map((floor) => floor.apartmentCount), everyElement(2));
      expect(floors.any((floor) => floor.isException), isFalse);
    });

    test('uses ground floor as the first level', () {
      final floors = generateFloors(
        totalFloors: 3,
        defaultApartments: 1,
        startsWithGroundFloor: true,
      );

      expect(floors.map((floor) => floor.label), [
        'Ground floor',
        'Floor 1',
        'Floor 2',
      ]);
    });

    test('supports a one-floor, one-apartment block', () {
      final floors = generateFloors(
        totalFloors: 1,
        defaultApartments: 1,
        startsWithGroundFloor: false,
      );

      expect(floors, hasLength(1));
      expect(floors.single.label, 'Floor 1');
      expect(floors.single.apartmentCount, 1);
    });

    test('supports an apartment-count exception', () {
      final floors = generateFloors(
        totalFloors: 2,
        defaultApartments: 2,
        startsWithGroundFloor: false,
      );
      final exceptional = floors.first.copyWith(
        apartmentCount: 1,
        isException: true,
      );

      expect(exceptional.apartmentCount, 1);
      expect(exceptional.isException, isTrue);
    });
  });
}
