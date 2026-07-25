import 'package:cloud_firestore/cloud_firestore.dart';

import 'floor_survey.dart';
import 'internet_box_plan.dart';

class BlockSurvey {
  const BlockSurvey({
    required this.id,
    required this.centralId,
    required this.centralName,
    required this.blockName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.locationAccuracy,
    required this.geohash,
    required this.defaultApartmentsPerFloor,
    required this.startsWithGroundFloor,
    required this.floors,
    required this.blockPhotoUrl,
    required this.blockPhotoStoragePath,
    required this.internetBox,
    required this.generalNotes,
    required this.status,
    required this.createdBy,
    required this.createdByName,
    this.createdAt,
  });

  final String id;
  final String centralId;
  final String centralName;
  final String blockName;
  final String address;
  final double latitude;
  final double longitude;
  final double locationAccuracy;
  final String geohash;
  final int defaultApartmentsPerFloor;
  final bool startsWithGroundFloor;
  final List<FloorSurvey> floors;
  final String blockPhotoUrl;
  final String blockPhotoStoragePath;
  final InternetBoxPlan internetBox;
  final String generalNotes;
  final String status;
  final String createdBy;
  final String createdByName;
  final DateTime? createdAt;

  int get totalFloors => floors.length;

  int get totalApartments =>
      floors.fold(0, (total, floor) => total + floor.apartmentCount);

  int get exceptionCount => floors.where((floor) => floor.isException).length;

  Map<String, dynamic> toFirestore() {
    return {
      'centralId': centralId,
      'centralName': centralName,
      'blockName': blockName,
      'address': address,
      'location': GeoPoint(latitude, longitude),
      'locationAccuracy': locationAccuracy,
      'geohash': geohash,
      'defaultApartmentsPerFloor': defaultApartmentsPerFloor,
      'startsWithGroundFloor': startsWithGroundFloor,
      'totalFloors': totalFloors,
      'totalApartments': totalApartments,
      'exceptionCount': exceptionCount,
      'floors': floors.map((floor) => floor.toMap()).toList(),
      'blockPhotoUrl': blockPhotoUrl,
      'blockPhotoStoragePath': blockPhotoStoragePath,
      'internetBox': internetBox.toMap(),
      'generalNotes': generalNotes,
      'status': status,
      'createdBy': createdBy,
      'createdByName': createdByName,
    };
  }

  factory BlockSurvey.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final map = document.data() ?? const <String, dynamic>{};
    final location = map['location'] as GeoPoint?;
    final floorMaps = (map['floors'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => FloorSurvey.fromMap(Map<String, dynamic>.from(item)))
        .toList();
    final internetBoxMap = Map<String, dynamic>.from(
      map['internetBox'] as Map? ?? const {},
    );
    final createdAt = map['createdAt'];

    return BlockSurvey(
      id: document.id,
      centralId: map['centralId'] as String? ?? '',
      centralName: map['centralName'] as String? ?? 'Unassigned',
      blockName: map['blockName'] as String? ?? 'Unnamed block',
      address: map['address'] as String? ?? '',
      latitude: location?.latitude ?? 0,
      longitude: location?.longitude ?? 0,
      locationAccuracy: ((map['locationAccuracy'] as num?) ?? 0).toDouble(),
      geohash: map['geohash'] as String? ?? '',
      defaultApartmentsPerFloor:
          (map['defaultApartmentsPerFloor'] as num?)?.toInt() ?? 0,
      startsWithGroundFloor: map['startsWithGroundFloor'] as bool? ?? false,
      floors: floorMaps,
      blockPhotoUrl: map['blockPhotoUrl'] as String? ?? '',
      blockPhotoStoragePath: map['blockPhotoStoragePath'] as String? ?? '',
      internetBox: InternetBoxPlan.fromMap(internetBoxMap),
      generalNotes: map['generalNotes'] as String? ?? '',
      status: map['status'] as String? ?? 'submitted',
      createdBy: map['createdBy'] as String? ?? '',
      createdByName: map['createdByName'] as String? ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}
