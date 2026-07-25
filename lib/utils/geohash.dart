abstract final class Geohash {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Encodes a latitude/longitude into a standard base32 geohash.
  static String encode(
    double latitude,
    double longitude, {
    int precision = 10,
  }) {
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError.value(latitude, 'latitude', 'Must be -90 to 90.');
    }
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError.value(longitude, 'longitude', 'Must be -180 to 180.');
    }
    if (precision < 1 || precision > 12) {
      throw ArgumentError.value(
        precision,
        'precision',
        'Must be between 1 and 12.',
      );
    }

    var latitudeRange = <double>[-90, 90];
    var longitudeRange = <double>[-180, 180];
    var evenBit = true;
    var bit = 0;
    var character = 0;
    final result = StringBuffer();

    while (result.length < precision) {
      final range = evenBit ? longitudeRange : latitudeRange;
      final value = evenBit ? longitude : latitude;
      final midpoint = (range[0] + range[1]) / 2;

      if (value >= midpoint) {
        character = (character << 1) | 1;
        range[0] = midpoint;
      } else {
        character <<= 1;
        range[1] = midpoint;
      }

      evenBit = !evenBit;
      bit++;

      if (bit == 5) {
        result.write(_base32[character]);
        bit = 0;
        character = 0;
      }
    }

    return result.toString();
  }
}
