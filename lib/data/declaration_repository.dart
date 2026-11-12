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

/// Firestore implementation scoped to one owner: it only reads and writes
/// the declarations of [_ownerUid]. `firestore.rules` enforces the same on
/// the server; the client check here is defense in depth.
class FirestoreDeclarationRepository implements DeclarationRepository {
  FirestoreDeclarationRepository(
    FirebaseFirestore firestore, {
    required this._ownerUid,
    this._mapper = const DeclarationMapper(),
  }) : _collection = firestore.collection('declarations');

  static const _ownerField = 'ownerUid';

  final CollectionReference<Map<String, dynamic>> _collection;
  final String _ownerUid;
  final DeclarationMapper _mapper;

  // Sorted on the client: filtering by owner and ordering by date on the
  // server would need a composite index.
  @override
  Stream<List<Declaration>> watchAll() => _collection
      .where(_ownerField, isEqualTo: _ownerUid)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map(_tryMap).nonNulls.toList()
              ..sort((a, b) => _byDateDesc(a.updatedAt, b.updatedAt)),
      );

  static int _byDateDesc(DateTime? a, DateTime? b) =>
      (b ?? DateTime(0)).compareTo(a ?? DateTime(0));

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
    if (data == null || data[_ownerField] != _ownerUid) return null;
    return _mapper.fromMap(doc.id, data);
  }

  @override
  Future<String> save(Declaration declaration) async {
    declaration.updatedAt = DateTime.now();
    final doc = declaration.id == null || declaration.id!.isEmpty
        ? _collection.doc()
        : _collection.doc(declaration.id);
    await doc.set({..._mapper.toMap(declaration), _ownerField: _ownerUid});
    declaration.id = doc.id;
    return doc.id;
  }
}
