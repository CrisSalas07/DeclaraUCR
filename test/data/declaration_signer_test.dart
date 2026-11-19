import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/data/proyecto1/declaration_signer.dart';
import 'package:declara_ucr/domain/content_hash.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ana's declaration as DeclaraHorario stores it, in [status].
Future<void> _seed(
  FakeFirebaseFirestore db, {
  String status = 'VALIDADA',
}) async {
  Timestamp at(int month, int day) =>
      Timestamp.fromDate(DateTime.utc(2026, month, day, 6));
  await db.collection('users').doc('ana').set({'fullName': 'Ana Mora Solís'});
  final declaration = db.collection('declarations').doc('d1');
  await declaration.set({
    'declarantUid': 'ana',
    'superiorUid': 'rev',
    'periodId': '2026_II',
    'status': status,
    'currentVersionId': 'v1',
    'currentVersionNumber': 1,
    'lastEventId': 'e0',
  });
  final version = declaration.collection('versions').doc('v1');
  await version.set({
    'number': 1,
    'declarantSnapshot': {
      'fullName': 'Ana Mora Solís',
      'identification': '105430987',
      'phone': '88887777',
      'email': 'ana@ucr.ac.cr',
      'unitName': 'Informática Empresarial',
      'campusName': 'Recinto de Golfito',
    },
    'observations': 'Lunes: clases.',
    'isLocked': false,
  });
  await version.collection('appointments').doc('a1').set({
    'workplace': 'Universidad de Costa Rica · Recinto de Golfito',
    'position': 'Interino',
    'workload': '1/2 TC',
    'startDate': at(8, 10),
    'endDate': at(12, 5),
    'blocks': [
      {
        'day': 1,
        'startMinutes': 480,
        'endMinutes': 600,
        'category': 'lesson',
        'course': 'IF0009',
      },
    ],
  });
}

void main() {
  late FakeFirebaseFirestore db;
  late DeclarationSigner signer;

  setUp(() {
    db = FakeFirebaseFirestore();
    signer = FirestoreDeclarationSigner(db, uid: 'ana');
  });

  Future<Map<String, dynamic>> doc(String path) async =>
      (await db.doc(path).get()).data()!;

  test('signs a validated declaration and sends it to the reviewer', () async {
    await _seed(db);
    await signer.signAndSend('d1', oathText: 'Yo, Ana, juro.');

    final declaration = await doc('declarations/d1');
    expect(declaration['status'], 'PENDIENTE_FIRMA_SUPERIOR');
    expect(declaration['currentResponsibleRole'], 'superior');
    expect(declaration['currentResponsibleUid'], 'rev');

    final version = await doc('declarations/d1/versions/v1');
    final expectedHash = ContentHash.of(
      version: {...version}..remove('contentHash'),
      appointments: [await doc('declarations/d1/versions/v1/appointments/a1')],
      externalJobs: const [],
    );
    expect(version['isLocked'], isTrue);
    expect(version['contentHash'], expectedHash);

    final signature = await doc(
      'declarations/d1/versions/v1/signatures/declarant',
    );
    expect(signature, containsPair('type', 'declarant'));
    expect(signature, containsPair('uid', 'ana'));
    expect(signature, containsPair('fullName', 'Ana Mora Solís'));
    expect(signature, containsPair('versionNumber', 1));
    expect(signature, containsPair('oathAccepted', true));
    expect(signature, containsPair('oathText', 'Yo, Ana, juro.'));
    expect(signature['contentHash'], expectedHash);

    // The audit trail of the web: started, signed (fixed id), sent.
    final events = (await db.collection('declarations/d1/events').get()).docs;
    final steps = {
      for (final e in events)
        '${e.data()['previousStatus']}>${e.data()['newStatus']}': e.id,
    };
    expect(steps.keys, {
      'VALIDADA>PENDIENTE_FIRMA_DECLARANTE',
      'PENDIENTE_FIRMA_DECLARANTE>FIRMADA_POR_DECLARANTE',
      'FIRMADA_POR_DECLARANTE>PENDIENTE_FIRMA_SUPERIOR',
    });
    expect(
      steps['PENDIENTE_FIRMA_DECLARANTE>FIRMADA_POR_DECLARANTE'],
      'signed-declarant-v1',
    );
    expect(
      declaration['lastEventId'],
      steps['FIRMADA_POR_DECLARANTE>PENDIENTE_FIRMA_SUPERIOR'],
    );
  });

  test('a signing started in the web is finished here', () async {
    await _seed(db, status: 'PENDIENTE_FIRMA_DECLARANTE');
    await signer.signAndSend('d1', oathText: 'Juro.');
    expect(
      (await doc('declarations/d1'))['status'],
      'PENDIENTE_FIRMA_SUPERIOR',
    );
  });

  test('a draft, a signed one or another person\'s is not signed', () async {
    for (final status in ['BORRADOR', 'PENDIENTE_FIRMA_SUPERIOR']) {
      db = FakeFirebaseFirestore();
      signer = FirestoreDeclarationSigner(db, uid: 'ana');
      await _seed(db, status: status);
      await expectLater(
        signer.signAndSend('d1', oathText: 'Juro.'),
        throwsA(isA<DeclarationSaveException>()),
        reason: status,
      );
      expect((await doc('declarations/d1'))['status'], status);
    }

    db = FakeFirebaseFirestore();
    await _seed(db);
    await expectLater(
      FirestoreDeclarationSigner(
        db,
        uid: 'beto',
      ).signAndSend('d1', oathText: 'Juro.'),
      throwsA(isA<DeclarationSaveException>()),
    );
    expect((await doc('declarations/d1'))['status'], 'VALIDADA');
  });

  test('without the oath text nothing is signed', () async {
    await _seed(db);
    await expectLater(
      signer.signAndSend('d1', oathText: '  '),
      throwsA(isA<DeclarationSaveException>()),
    );
    expect((await doc('declarations/d1'))['status'], 'VALIDADA');
  });
}
