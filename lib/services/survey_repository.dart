import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/block_survey.dart';

class SurveyRepository {
  SurveyRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _surveys =>
      _firestore.collection('blockSurveys');

  Stream<List<BlockSurvey>> watchSurveys() {
    return _surveys
        .orderBy('createdAt', descending: true)
        .limit(500)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(BlockSurvey.fromFirestore).toList(),
        );
  }

  Stream<List<BlockSurvey>> watchSurveysByUser(String userId) {
    return _surveys
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(500)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(BlockSurvey.fromFirestore).toList(),
        );
  }

  Future<String> createSurvey({
    required BlockSurvey survey,
    required XFile blockPhoto,
    XFile? internetBoxPhoto,
  }) async {
    final document = _surveys.doc();
    final uploadedReferences = <Reference>[];

    try {
      final blockUpload = await _uploadPhoto(
        photo: blockPhoto,
        path: _photoPath(
          userId: survey.createdBy,
          surveyId: document.id,
          baseName: 'block',
          photo: blockPhoto,
        ),
      );
      uploadedReferences.add(blockUpload.reference);

      _UploadedPhoto? boxUpload;
      if (internetBoxPhoto != null) {
        boxUpload = await _uploadPhoto(
          photo: internetBoxPhoto,
          path: _photoPath(
            userId: survey.createdBy,
            surveyId: document.id,
            baseName: 'internet_box_location',
            photo: internetBoxPhoto,
          ),
        );
        uploadedReferences.add(boxUpload.reference);
      }

      final data = survey.toFirestore()
        ..['blockPhotoUrl'] = blockUpload.downloadUrl
        ..['blockPhotoStoragePath'] = blockUpload.reference.fullPath
        ..['internetBox'] = survey.internetBox
            .copyWith(
              photoUrl: boxUpload?.downloadUrl ?? '',
              photoStoragePath: boxUpload?.reference.fullPath ?? '',
            )
            .toMap()
        ..['createdAt'] = FieldValue.serverTimestamp()
        ..['updatedAt'] = FieldValue.serverTimestamp();

      await document.set(data);
      return document.id;
    } catch (_) {
      for (final reference in uploadedReferences) {
        try {
          await reference.delete();
        } catch (_) {
          // Best-effort cleanup. The original error is more useful to callers.
        }
      }
      rethrow;
    }
  }

  Future<_UploadedPhoto> _uploadPhoto({
    required XFile photo,
    required String path,
  }) async {
    final Uint8List bytes = await photo.readAsBytes();
    final reference = _storage.ref(path);
    await reference.putData(
      bytes,
      SettableMetadata(
        contentType: photo.mimeType ?? _contentType(photo.path),
        cacheControl: 'private,max-age=3600',
      ),
    );
    return _UploadedPhoto(
      reference: reference,
      downloadUrl: await reference.getDownloadURL(),
    );
  }

  String _photoPath({
    required String userId,
    required String surveyId,
    required String baseName,
    required XFile photo,
  }) {
    final extension = _extension(photo.path);
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return 'block_surveys/$userId/$surveyId/'
        '${baseName}_$timestamp.$extension';
  }

  String _extension(String path) {
    final normalized = path.replaceAll(String.fromCharCode(92), '/');
    final name = normalized.split('/').last;
    final parts = name.split('.');
    if (parts.length < 2) {
      return 'jpg';
    }
    final extension = parts.last.toLowerCase();
    return switch (extension) {
      'jpeg' || 'jpg' || 'png' || 'webp' || 'heic' => extension,
      _ => 'jpg',
    };
  }

  String _contentType(String path) {
    return switch (_extension(path)) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };
  }
}

class _UploadedPhoto {
  const _UploadedPhoto({required this.reference, required this.downloadUrl});

  final Reference reference;
  final String downloadUrl;
}
