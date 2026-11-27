import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/data/proyecto1/declaration_document_reader.dart';
import 'package:declara_ucr/domain/oath_text.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/models/weekday.dart';
import 'package:declara_ucr/pdf/declaration_pdf.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// A declaration of Ana as DeclaraHorario stores it, in [status], with the
/// signatures given.
Future<void> _seed(
  FakeFirebaseFirestore db, {
  String status = 'VALIDADA',
  List<Map<String, dynamic>> signatures = const [],
  String? oathTemplate,
}) async {
  Timestamp at(int month, int day) =>
      Timestamp.fromDate(DateTime.utc(2026, month, day, 6));
  await db.collection('periods').doc('2026_II').set({
    'name': 'II Ciclo - 2026',
    'startDate': at(8, 10),
    'endDate': at(12, 5),
    'enabled': true,
  });
  if (oathTemplate != null) {
    await db.collection('config').doc('oath').set({'template': oathTemplate});
  }
  final declaration = db.collection('declarations').doc('d1');
  await declaration.set({
    'declarantUid': 'ana',
    'periodId': '2026_II',
    'status': status,
    'currentVersionId': 'v1',
    'currentVersionNumber': 1,
  });
  final version = declaration.collection('versions').doc('v1');
  await version.set({
    'number': 1,
    'declarantSnapshot': {
      'fullName': 'Ana Mora Solís',
      'identification': '1-0543-0987',
      'phone': '88887777',
      'email': 'ana@ucr.ac.cr',
      'unitName': 'Informática Empresarial',
      'campusName': 'Recinto de Golfito',
    },
    'observations': 'Lunes: lecciones de IF0009.',
    'createdAt': at(8, 20),
  });
  await version.collection('appointments').doc('a1').set({
    'workplace': 'Universidad de Costa Rica · Recinto de Golfito',
    'position': 'Interino',
    'workload': '1/2 TC',
    'startDate': at(8, 10),
    'endDate': at(12, 5),
    'blocks': [
      {'day': 1, 'startMinutes': 480, 'endMinutes': 600, 'category': 'lesson'},
      // Touches the lesson: printed as one range, 08:00-11:00.
      {
        'day': 1,
        'startMinutes': 600,
        'endMinutes': 660,
        'category': 'attention',
      },
    ],
  });
  await version.collection('externalJobs').doc('e1').set({
    'institution': 'Colegio de Golfito',
    'position': 'Docente',
    'workload': '1/4 TC',
    'weeklyMinutes': 600,
    'startDate': at(8, 10),
    'endDate': at(12, 5),
    'blocks': [
      {'day': 3, 'startMinutes': 780, 'endMinutes': 1080},
    ],
  });
  for (final s in signatures) {
    await version.collection('signatures').doc(s['type'] as String).set(s);
  }
}

void main() {
  late FakeFirebaseFirestore db;
  late DeclarationDocumentReader reader;

  setUp(() {
    db = FakeFirebaseFirestore();
    reader = FirestoreDeclarationDocumentReader(db, uid: 'ana');
  });

  test('reads the stored declaration as the web prints it', () async {
    await _seed(db);
    final doc = await reader.read('d1');
    expect(doc.status, DeclarationStatus.validated);
    expect(doc.kind, DocumentKind.preview);
    expect(doc.fileName, 'vista-previa-declaracion-v1.pdf');
    expect(doc.person.fullName, 'Ana Mora Solís');
    expect(doc.periodName, 'II Ciclo - 2026');
    expect(doc.appointments.single.blocks, hasLength(2));
    expect(doc.appointments.single.blocks.first.day, Weekday.monday);
    expect(doc.externalJobs.single.workplace, 'Colegio de Golfito');
    expect(doc.signatures, isEmpty);
  });

  test("another person's declaration is not read", () async {
    await _seed(db);
    final other = FirestoreDeclarationDocumentReader(db, uid: 'beto');
    expect(
      () => other.read('d1'),
      throwsA(isA<DocumentUnavailableException>()),
    );
  });

  test('before signing, the oath is the one of the official form', () async {
    await _seed(db);
    expect(
      OathText.of(await reader.read('d1')),
      'Declaro bajo juramento que los datos proporcionados en este documento '
      'son ciertos y que conozco las sanciones establecidas por la '
      'legislación institucional y nacional vigentes, que se refieren a la '
      'declaración falsa u omisa de las jornadas y horarios laborales aquí '
      'consignados.',
    );
  });

  test('the variables of a template are filled with the data', () async {
    await _seed(
      db,
      oathTemplate:
          '{nombre}, {cedula}, {puesto}, {carrera}, {version}, {periodo}, '
          '{jornadaUcr}, {horasExternas}',
    );
    expect(
      OathText.of(await reader.read('d1')),
      'Ana Mora Solís, 1-0543-0987, Interino, Informática Empresarial, 1, '
      'II Ciclo - 2026, 1/2 TC (20 h), 10 h por semana',
    );
  });

  test("the administrator's template is used when there is one", () async {
    await _seed(db, oathTemplate: 'Yo, {nombre}, juro. {desconocida}');
    expect(
      OathText.of(await reader.read('d1')),
      'Yo, Ana Mora Solís, juro. {desconocida}',
    );
  });

  test('once signed, the PDF prints the oath the declarant accepted', () async {
    await _seed(
      db,
      status: 'PENDIENTE_FIRMA_SUPERIOR',
      signatures: [
        {
          'type': 'declarant',
          'fullName': 'Ana Mora Solís',
          'signedAt': Timestamp.fromDate(DateTime.utc(2026, 8, 21, 15)),
          'oathText': 'Texto aceptado.',
          'contentHash': 'abc123',
        },
      ],
    );
    final doc = await reader.read('d1');
    expect(doc.kind, DocumentKind.review);
    expect(doc.fileName, 'declaracion-en-revision-v1.pdf');
    expect(OathText.of(doc), 'Texto aceptado.');
    expect(doc.signatureOf(SignatureType.declarant)?.contentHash, 'abc123');
  });

  test('no PDF while it is a draft, returned or annulled', () {
    for (final status in [
      DeclarationStatus.draft,
      DeclarationStatus.returned,
      DeclarationStatus.annulled,
    ]) {
      expect(DeclarationDocument.kindFor(status), isNull, reason: '$status');
    }
    expect(
      DeclarationDocument.kindFor(DeclarationStatus.closed),
      DocumentKind.finalDocument,
    );
  });

  test(
    'builds the PDF for the preview, the review copy and the final',
    () async {
      for (final status in ['VALIDADA', 'ENVIADA_A_RRHH', 'FINALIZADA']) {
        db = FakeFirebaseFirestore();
        reader = FirestoreDeclarationDocumentReader(db, uid: 'ana');
        await _seed(db, status: status);
        final bytes = await DeclarationPdf.build(await reader.read('d1'));
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-', reason: status);
      }
    },
  );

  test('formats the identification and the phone as the web', () {
    expect(DeclarationPdf.document('1-234-567'), '102340567');
    expect(DeclarationPdf.document('AB 12-34'), 'AB1234');
    expect(DeclarationPdf.phone('88887777'), '8888-7777');
    expect(DeclarationPdf.phone('+506 8888'), '+506 8888');
  });
}
