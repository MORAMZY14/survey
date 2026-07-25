class InternetBoxPlan {
  const InternetBoxPlan({
    required this.mountingArea,
    required this.notes,
    required this.markerX,
    required this.markerY,
    this.photoUrl = '',
    this.photoStoragePath = '',
  });

  final String mountingArea;
  final String notes;

  /// Horizontal point on the displayed block photo, normalized from 0 to 1.
  final double markerX;

  /// Vertical point on the displayed block photo, normalized from 0 to 1.
  final double markerY;

  final String photoUrl;
  final String photoStoragePath;

  InternetBoxPlan copyWith({
    String? mountingArea,
    String? notes,
    double? markerX,
    double? markerY,
    String? photoUrl,
    String? photoStoragePath,
  }) {
    return InternetBoxPlan(
      mountingArea: mountingArea ?? this.mountingArea,
      notes: notes ?? this.notes,
      markerX: markerX ?? this.markerX,
      markerY: markerY ?? this.markerY,
      photoUrl: photoUrl ?? this.photoUrl,
      photoStoragePath: photoStoragePath ?? this.photoStoragePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mountingArea': mountingArea,
      'notes': notes,
      'photoMarker': {'x': markerX, 'y': markerY},
      'photoUrl': photoUrl,
      'photoStoragePath': photoStoragePath,
    };
  }

  factory InternetBoxPlan.fromMap(Map<String, dynamic> map) {
    final marker = Map<String, dynamic>.from(
      map['photoMarker'] as Map? ?? const {},
    );

    return InternetBoxPlan(
      mountingArea: map['mountingArea'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      markerX: ((marker['x'] as num?) ?? 0.5).toDouble(),
      markerY: ((marker['y'] as num?) ?? 0.5).toDouble(),
      photoUrl: map['photoUrl'] as String? ?? '',
      photoStoragePath: map['photoStoragePath'] as String? ?? '',
    );
  }
}
