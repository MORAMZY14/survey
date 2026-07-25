class FloorSurvey {
  const FloorSurvey({
    required this.order,
    required this.label,
    required this.apartmentCount,
    this.notes = '',
    this.isException = false,
  });

  final int order;
  final String label;
  final int apartmentCount;
  final String notes;
  final bool isException;

  FloorSurvey copyWith({
    int? order,
    String? label,
    int? apartmentCount,
    String? notes,
    bool? isException,
  }) {
    return FloorSurvey(
      order: order ?? this.order,
      label: label ?? this.label,
      apartmentCount: apartmentCount ?? this.apartmentCount,
      notes: notes ?? this.notes,
      isException: isException ?? this.isException,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'order': order,
      'label': label,
      'apartmentCount': apartmentCount,
      'notes': notes,
      'isException': isException,
    };
  }

  factory FloorSurvey.fromMap(Map<String, dynamic> map) {
    return FloorSurvey(
      order: (map['order'] as num?)?.toInt() ?? 0,
      label: map['label'] as String? ?? '',
      apartmentCount: (map['apartmentCount'] as num?)?.toInt() ?? 0,
      notes: map['notes'] as String? ?? '',
      isException: map['isException'] as bool? ?? false,
    );
  }
}

List<FloorSurvey> generateFloors({
  required int totalFloors,
  required int defaultApartments,
  required bool startsWithGroundFloor,
}) {
  assert(totalFloors > 0);
  assert(defaultApartments >= 0);

  return List.generate(totalFloors, (index) {
    final label = startsWithGroundFloor
        ? (index == 0 ? 'Ground floor' : 'Floor $index')
        : 'Floor ${index + 1}';

    return FloorSurvey(
      order: index,
      label: label,
      apartmentCount: defaultApartments,
    );
  });
}
