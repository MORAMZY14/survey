import 'package:cloud_firestore/cloud_firestore.dart';

class SurveyDeletionLog {
  const SurveyDeletionLog({
    required this.surveyId,
    required this.blockName,
    required this.centralId,
    required this.centralName,
    required this.originalCreatedBy,
    required this.originalCreatedByName,
    required this.deletedBy,
    required this.deletedByName,
    this.deletedAt,
  });

  final String surveyId;
  final String blockName;
  final String centralId;
  final String centralName;
  final String originalCreatedBy;
  final String originalCreatedByName;
  final String deletedBy;
  final String deletedByName;
  final DateTime? deletedAt;

  factory SurveyDeletionLog.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final map = document.data() ?? const <String, dynamic>{};
    final deletedAt = map['deletedAt'];

    return SurveyDeletionLog(
      surveyId: map['surveyId'] as String? ?? document.id,
      blockName: map['blockName'] as String? ?? 'Unnamed block',
      centralId: map['centralId'] as String? ?? '',
      centralName: map['centralName'] as String? ?? 'Unassigned',
      originalCreatedBy: map['originalCreatedBy'] as String? ?? '',
      originalCreatedByName:
          map['originalCreatedByName'] as String? ?? 'Unknown user',
      deletedBy: map['deletedBy'] as String? ?? '',
      deletedByName: map['deletedByName'] as String? ?? 'Administrator',
      deletedAt: deletedAt is Timestamp ? deletedAt.toDate() : null,
    );
  }
}
