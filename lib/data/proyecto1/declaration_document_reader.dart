import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/data/proyecto1/proyecto1_mapper.dart';
import 'package:declara_ucr/models/declaration_document.dart';
import 'package:flutter/foundation.dart';

export 'package:declara_ucr/models/declaration_document.dart';

/// Reads a declaration as stored, to print it (DIP: the UI never sees
/// Firestore).
abstract class DeclarationDocumentReader {
  /// The current version of declaration [id] of this person, its content,
  /// signatures and oath. Throws [DocumentUnavailableException] when it
  /// cannot be read now.
  Future<DeclarationDocument> read(String id);
}

/// The document could not be read; [message] is in Spanish, shown as is.
class DocumentUnavailableException implements Exception {
  const DocumentUnavailableException(this.message);

  static const offline = DocumentUnavailableException(
    'Sin conexión: el PDF se genera con los datos del servidor. Revise la '
    'conexión e intente de nuevo.',
  );

  final String message;

  @override
  String toString() => message;
}

/// [DeclarationDocumentReader] on the Proyecto 1 schema, for one person.
class FirestoreDeclarationDocumentReader implements DeclarationDocumentReader {
  FirestoreDeclarationDocumentReader(this._firestore, {required this._uid});

  final FirebaseFirestore _firestore;
  final String _uid;

  /// From the server, never the phone's copy: a signature recorded in the
  /// web a minute ago must be on the PDF, and a stale document must not be
  /// printed as if it were current.
  static const _fromServer = GetOptions(source: Source.server);

  @override
  Future<DeclarationDocument> read(String id) async {
    try {
      return await _read(id);
    } on DocumentUnavailableException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('Reading declaration $id failed: ${e.code}');
      if (_isOffline(e)) throw DocumentUnavailableException.offline;
      throw const DocumentUnavailableException(
        'No se pudo leer la declaración para generar el PDF. Intente de nuevo.',
      );
    } on FormatException catch (e) {
      debugPrint('Malformed declaration $id: ${e.message}');
      throw const DocumentUnavailableException(
        'La declaración guardada tiene datos incompletos: no se puede '
        'generar el PDF.',
      );
    }
  }

  Future<DeclarationDocument> _read(String id) async {
    final ref = _firestore.collection('declarations').doc(id);
    final declaration = (await ref.get(_fromServer)).data();
    if (declaration == null || declaration['declarantUid'] != _uid) {
      throw const DocumentUnavailableException('La declaración no existe.');
    }
    final version = ref
        .collection('versions')
        .doc(declaration['currentVersionId'] as String);
    final versionDoc = version.get(_fromServer);
    final appointments = version.collection('appointments').get(_fromServer);
    final jobs = version.collection('externalJobs').get(_fromServer);
    final signatures = version.collection('signatures').get(_fromServer);
    final period = _firestore
        .collection('periods')
        .doc(declaration['periodId'] as String)
        .get(_fromServer);
    final oath = _oathTemplate();
    // The first failure, as it is (not wrapped), while all run at once.
    await Future.wait<Object?>([
      versionDoc,
      appointments,
      jobs,
      signatures,
      period,
      oath,
    ], eagerError: true);

    final versionData = (await versionDoc).data();
    if (versionData == null) {
      throw const DocumentUnavailableException(
        'No se encontró la versión actual de la declaración.',
      );
    }
    return Proyecto1Mapper.document(
      declaration: declaration,
      version: versionData,
      appointments: [for (final d in (await appointments).docs) d.data()],
      externalJobs: [for (final d in (await jobs).docs) d.data()],
      signatures: [for (final d in (await signatures).docs) d.data()],
      periodName: (await period).data()?['name'] as String? ?? '',
      oathTemplate: await oath,
    );
  }

  /// The administrator's template; `null` (the default one) when there is
  /// none or it cannot be read, as `OathTextService.template` does. Without
  /// connection it fails like the other reads.
  Future<String?> _oathTemplate() async {
    try {
      final data =
          (await _firestore.collection('config').doc('oath').get(_fromServer))
              .data();
      return data?['template'] as String?;
    } on FirebaseException catch (e) {
      if (_isOffline(e)) rethrow;
      return null;
    }
  }

  static bool _isOffline(FirebaseException e) =>
      e.code == 'unavailable' || e.code == 'deadline-exceeded';
}
