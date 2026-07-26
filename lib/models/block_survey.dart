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
    this.createdByRole = 'surveyor',
    this.reviewedBy = '',
    this.reviewedByName = '',
    this.reviewNote = '',
    this.createdAt,
    this.updatedAt,
    this.reviewedAt,
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
  final String createdByRole;
  final String reviewedBy;
  final String reviewedByName;
  final String reviewNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? reviewedAt;

  bool get isPending => status == 'pending' || status == 'submitted';

  bool get isApproved => status == 'approved';

  bool get isRejected => status == 'rejected';

  bool get wasAddedDirectlyByAdmin =>
      isApproved &&
      (createdByRole == 'admin' ||
          (reviewedBy.isNotEmpty && reviewedBy == createdBy));

  String get statusLabel {
    if (isPending) {
      return 'Pending';
    }
    if (isApproved) {
      return 'Approved';
    }
    if (isRejected) {
      return 'Rejected';
    }
    return status.isEmpty ? 'Unknown' : status;
  }

  DateTime? get activityAt {
    if (!isPending && reviewedAt != null) {
      return reviewedAt;
    }
    return updatedAt ?? createdAt;
  }

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
      'createdByRole': createdByRole,
      'reviewedBy': reviewedBy,
      'reviewedByName': reviewedByName,
      'reviewNote': reviewNote,
      'reviewedAt': reviewedAt == null
          ? null
          : Timestamp.fromDate(reviewedAt!),
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
    final updatedAt = map['updatedAt'];
    final reviewedAt = map['reviewedAt'];

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
      createdByRole: map['createdByRole'] as String? ?? 'surveyor',
      reviewedBy: map['reviewedBy'] as String? ?? '',
      reviewedByName: map['reviewedByName'] as String? ?? '',
      reviewNote: map['reviewNote'] as String? ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
      reviewedAt: reviewedAt is Timestamp ? reviewedAt.toDate() : null,
    );
  }
}
