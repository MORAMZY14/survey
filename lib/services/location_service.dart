import 'package:geolocator/geolocator.dart';

class SurveyLocationException implements Exception {
  const SurveyLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocationService {
  Future<Position> determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const SurveyLocationException(
        'GPS is turned off. Enable location services and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const SurveyLocationException('Location permission was denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw const SurveyLocationException(
        'Location permission is permanently denied. Open app settings to '
        'enable it.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
