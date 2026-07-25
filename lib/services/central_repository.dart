import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/central.dart';

class CentralRepository {
  CentralRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _centrals =>
      _firestore.collection('centrals');

  Stream<List<Central>> watchCentrals({bool activeOnly = false}) {
    return _centrals.snapshots().map((snapshot) {
      final centrals = snapshot.docs.map(Central.fromFirestore).where((
        central,
      ) {
        return !activeOnly || central.active;
      }).toList();
      centrals.sort(
        (first, second) =>
            first.name.toLowerCase().compareTo(second.name.toLowerCase()),
      );
      return centrals;
    });
  }

  Future<void> createCentral(String name) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to create a Central.');
    }

    final cleanName = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleanName.length < 2 || cleanName.length > 80) {
      throw ArgumentError.value(
        name,
        'name',
        'Central name must be between 2 and 80 characters.',
      );
    }
    final normalizedName = Central.normalizeName(cleanName);
    final reference = _centrals.doc(Central.documentIdForName(cleanName));

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) {
        throw const CentralAlreadyExistsException();
      }

      transaction.set(reference, {
        'name': cleanName,
        'normalizedName': normalizedName,
        'active': true,
        'createdBy': user.uid,
        'createdByName':
            user.displayName ?? user.email?.split('@').first ?? 'Admin',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> setCentralActive(Central central, bool active) {
    return _centrals.doc(central.id).update({
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class CentralAlreadyExistsException implements Exception {
  const CentralAlreadyExistsException();

  @override
  String toString() => 'A Central with this name already exists.';
}
