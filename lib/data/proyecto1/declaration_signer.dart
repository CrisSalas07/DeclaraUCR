import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/domain/content_hash.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:flutter/foundation.dart';

/// The declarant's signature (DIP: the UI never sees Firestore).
abstract class DeclarationSigner {
  /// Signs the current version of declaration [id] with the [oathText] the
  /// person accepted, and sends it to their superior: it ends in
  /// PENDIENTE_FIRMA_SUPERIOR. Throws [DeclarationSaveException] with a
  /// message for the person, or [OfflineException] without connection.
  Future<void> signAndSend(String id, {required String oathText});
}

/// The signature exactly as DeclaraHorario writes it
/// (`FirestoreWorkflowService.beginDeclarantSigning` and `signAsDeclarant`),
/// since the Proyecto 1 rules accept it only that way:
///
/// 1. VALIDADA -> PENDIENTE_FIRMA_DECLARANTE (FIRMA_INICIADA), if needed.
/// 2. One transaction: the FIRMADA_POR_DECLARANTE step as an event under
///    its fixed id, the FIRMA_REGISTRADA event to PENDIENTE_FIRMA_SUPERIOR,
///    the `declarant` signature (name of the profile, server time, version,
///    oath and content hash) and the version locked with the same hash.
///
/// The hash is computed before the transaction (a transaction cannot run
/// queries); the transaction then requires the declaration to be unchanged
/// since it was read, so what is signed is what was hashed.
class FirestoreDeclarationSigner implements DeclarationSigner {
  FirestoreDeclarationSigner(this._firestore, {required this._uid});

  final FirebaseFirestore _firestore;
  final String _uid;

  /// From the server: the phone's copy must never decide what is signed.
  static const _fromServer = GetOptions(source: Source.server);

  static const _stale =
      'La declaración cambió mientras la firmaba. Vuelva a abrirla e '
      'intente de nuevo.';

  @override
  Future<void> signAndSend(String id, {required String oathText}) async {
    if (oathText.trim().isEmpty || oathText.length > 5000) {
      throw const DeclarationSaveException(
        'El texto de la declaración jurada no es válido.',
      );
    }
    try {
      final ref = _firestore.collection('declarations').doc(id);
      var data = await _owned(ref);
      final status = DeclarationStatus.fromValue(data['status'] as String);
      if (status == DeclarationStatus.validated) {
        await _beginSigning(ref);
        data = await _owned(ref);
      } else if (status != DeclarationStatus.pendingDeclarantSignature) {
        throw DeclarationSaveException(
          status == DeclarationStatus.draft
              ? 'Valide la declaración antes de firmarla.'
              : 'La declaración ya fue firmada y enviada.',
        );
      }
      await _sign(ref, data, oathText);
    } on FirebaseException catch (e) {
      debugPrint('Signing $id failed: ${e.code}');
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        throw const OfflineException();
      }
      throw DeclarationSaveException(
        e.code == 'permission-denied'
            ? 'El servidor rechazó la firma. Revise que la declaración siga '
                  'validada e intente de nuevo.'
            : 'No se pudo firmar la declaración. Intente de nuevo.',
      );
    }
  }

  Future<Map<String, dynamic>> _owned(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    final data = (await ref.get(_fromServer)).data();
    if (data == null || data['declarantUid'] != _uid) {
      throw const DeclarationSaveException('La declaración ya no existe.');
    }
    return data;
  }

  /// VALIDADA -> PENDIENTE_FIRMA_DECLARANTE, as `beginDeclarantSigning`.
  Future<void> _beginSigning(DocumentReference<Map<String, dynamic>> ref) =>
      _firestore.runTransaction((tx) async {
        final data = (await tx.get(ref)).data();
        if (data == null ||
            data['status'] != DeclarationStatus.validated.value) {
          throw const DeclarationSaveException(_stale);
        }
        final event = ref.collection('events').doc();
        final now = FieldValue.serverTimestamp();
        tx
          ..set(event, {
            'type': 'FIRMA_INICIADA',
            'userId': _uid,
            'version': data['currentVersionNumber'],
            'previousStatus': DeclarationStatus.validated.value,
            'newStatus': DeclarationStatus.pendingDeclarantSignature.value,
            'timestamp': now,
          })
          ..update(ref, {
            'status': DeclarationStatus.pendingDeclarantSignature.value,
            'lastEventId': event.id,
            'updatedAt': now,
            'currentResponsibleRole': 'declarant',
            'currentResponsibleUid': _uid,
          });
      });

  Future<void> _sign(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> before,
    String oathText,
  ) async {
    final versionId = before['currentVersionId'] as String;
    final versionNumber = before['currentVersionNumber'] as int;
    final version = ref.collection('versions').doc(versionId);
    final (versionDoc, appointments, jobs, profile) = await (
      version.get(_fromServer),
      version.collection('appointments').get(_fromServer),
      version.collection('externalJobs').get(_fromServer),
      _firestore.collection('users').doc(_uid).get(_fromServer),
    ).wait;
    final versionData = versionDoc.data();
    final fullName = profile.data()?['fullName'];
    if (versionData == null || fullName is! String) {
      throw const DeclarationSaveException(
        'No se pudo leer la declaración para firmarla.',
      );
    }
    final contentHash = ContentHash.of(
      version: versionData,
      appointments: [for (final d in appointments.docs) d.data()],
      externalJobs: [for (final d in jobs.docs) d.data()],
    );

    await _firestore.runTransaction((tx) async {
      final data = (await tx.get(ref)).data();
      if (data == null ||
          data['status'] != DeclarationStatus.pendingDeclarantSignature.value ||
          data['lastEventId'] != before['lastEventId'] ||
          data['currentVersionId'] != versionId) {
        throw const DeclarationSaveException(_stale);
      }
      final events = ref.collection('events');
      final now = FieldValue.serverTimestamp();
      Map<String, Object?> event(
        DeclarationStatus from,
        DeclarationStatus to,
      ) => {
        'type': 'FIRMA_REGISTRADA',
        'userId': _uid,
        'version': versionNumber,
        'previousStatus': from.value,
        'newStatus': to.value,
        'timestamp': now,
      };
      // The automatic FIRMADA_POR_DECLARANTE step: only an event, under
      // the id the rules build (`EventDocIds.signedByDeclarant`).
      final last = events.doc();
      tx
        ..set(
          events.doc('signed-declarant-v$versionNumber'),
          event(
            DeclarationStatus.pendingDeclarantSignature,
            DeclarationStatus.signedByDeclarant,
          ),
        )
        ..set(
          last,
          event(
            DeclarationStatus.signedByDeclarant,
            DeclarationStatus.pendingSupervisorSignature,
          ),
        )
        ..update(ref, {
          'status': DeclarationStatus.pendingSupervisorSignature.value,
          'lastEventId': last.id,
          'updatedAt': now,
          'currentResponsibleRole': 'superior',
          'currentResponsibleUid': data['superiorUid'],
        })
        ..set(version.collection('signatures').doc('declarant'), {
          'type': 'declarant',
          'uid': _uid,
          'fullName': fullName,
          'versionId': versionId,
          'versionNumber': versionNumber,
          'oathAccepted': true,
          'contentHash': contentHash,
          'oathText': oathText,
          'signedAt': now,
        })
        ..update(version, {
          'isLocked': true,
          'lockedAt': now,
          'contentHash': contentHash,
        });
    });
  }
}
