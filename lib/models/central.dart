import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Central {
  const Central({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.active,
    required this.createdBy,
    required this.createdByName,
    this.createdAt,
  });

  final String id;
  final String name;
  final String normalizedName;
  final bool active;
  final String createdBy;
  final String createdByName;
  final DateTime? createdAt;

  factory Central.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final createdAt = data['createdAt'];

    return Central(
      id: document.id,
      name: data['name'] as String? ?? 'Unnamed Central',
      normalizedName: data['normalizedName'] as String? ?? '',
      active: data['active'] as bool? ?? true,
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }

  static String normalizeName(String name) {
    return name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  static String documentIdForName(String name) {
    final normalized = normalizeName(name);
    return base64Url.encode(utf8.encode(normalized)).replaceAll('=', '');
  }
}
