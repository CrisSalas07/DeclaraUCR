import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/data/declaration_mapper.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:flutter/foundation.dart';

/// Access to declarations (R5). Same pattern as DeclaraHorario: the UI and
/// the state layer only know this interface, never Firestore (DIP).
abstract class DeclarationRepository {
  /// Registered declarations, most recent first (R1).
  Stream<List<Declaration>> watchAll();

  /// The saved declaration, or `null` if it does not exist (draft recovery).
  /// Throws a [FormatException] if the stored document is malformed.
  Future<Declaration?> getById(String id);

  /// Creates or updates the declaration and returns its id.
  Future<String> save(Declaration declaration);
}

class FirestoreDeclarationRepository implements DeclarationRepository {
  FirestoreDeclarationRepository(
    FirebaseFirestore firestore, {
    this._mapper = const DeclarationMapper(),
  }) : _collection = firestore.collection('declarations');

  final CollectionReference<Map<String, dynamic>> _collection;
  final DeclarationMapper _mapper;

  @override
  Stream<List<Declaration>> watchAll() => _collection
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(_tryMap).nonNulls.toList());

  /// One malformed document must not hide the whole list: it is skipped and
  /// logged.
  Declaration? _tryMap(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      return _mapper.fromMap(doc.id, doc.data());
    } on FormatException catch (e) {
      debugPrint('Skipping declaration: ${e.message}');
      return null;
    }
  }

  @override
  Future<Declaration?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    final data = doc.data();
    return data == null ? null : _mapper.fromMap(doc.id, data);
  }

  @override
  Future<String> save(Declaration declaration) async {
    declaration.updatedAt = DateTime.now();
    final doc = declaration.id == null || declaration.id!.isEmpty
        ? _collection.doc()
        : _collection.doc(declaration.id);
    await doc.set(_mapper.toMap(declaration));
    declaration.id = doc.id;
    return doc.id;
  }
}
