import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/data/proyecto1/proyecto1_declaration_repository.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/models/schedule_task.dart';
import 'package:declara_ucr/models/weekday.dart';
import 'package:declara_ucr/state/declaration_form_state.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/declaration_validator_test.dart'
    show complete, interval, placed;
import '../support/proyecto1_fixture.dart';

void main() {
  late FakeFirebaseFirestore db;
  late Proyecto1DeclarationRepository repository;

  setUp(() async {
    db = FakeFirebaseFirestore();
    await Proyecto1Fixture.seed(db);
    repository = Proyecto1Fixture.declarations(db);
  });

  DocumentReference<Map<String, dynamic>> declarationDoc(String id) =>
      db.collection('declarations').doc(id);

  Future<List<Map<String, dynamic>>> eventsOf(String id) async => [
    for (final doc in (await declarationDoc(
      id,
    ).collection('events').get()).docs)
      doc.data(),
  ];

  test('tests 01/04: saves a draft and recovers it unchanged', () async {
    final state = DeclarationFormState(
      repository: repository,
      initial: complete(placed())..notes = 'Nota',
    );
    expect(await state.saveDraft(), isTrue);
    final id = state.declaration.id!;
    final saved = await repository.getById(id);

    expect(saved!.status, DeclarationStatus.draft);
    expect(saved.declarantName, 'Ana Pérez Mora');
    expect(saved.identification, '105430987');
    // The validity is the period's.
    expect(saved.validFrom, Proyecto1Fixture.periodStart.toLocal());
    expect(saved.courses.single.code, 'IF0009');
    expect(saved.intervals.map((i) => i.task.key), [
      'HC|Redes',
      'AE|Redes',
      'PyE|Redes',
    ]);
    expect(saved.intervals.last.day, Weekday.tuesday);
    expect(saved.totalMinutes, 5 * 60);
    expect(saved.notes, 'Nota');
    expect(saved.versionNumber, 1);
  });

  test('a new draft is written as the Proyecto 1 createDraft batch', () async {
    final state = DeclarationFormState(
      repository: repository,
      initial: complete(placed()),
    );
    await state.saveDraft();
    final id = state.declaration.id!;

    final declaration = (await declarationDoc(id).get()).data()!;
    expect(declaration['declarantUid'], Proyecto1Fixture.uid);
    expect(declaration['periodId'], '2026_II');
    expect(declaration['superiorUid'], 'rev');
    expect(declaration['campusId'], 'sede-sur');
    expect(declaration['status'], 'BORRADOR');
    expect(declaration['currentVersionNumber'], 1);

    final version =
        (await declarationDoc(id)
                .collection('versions')
                .doc(declaration['currentVersionId'] as String)
                .get())
            .data()!;
    expect(version['isLocked'], isFalse);
    expect(version['declarantSnapshot']['campusName'], 'Sede del Sur');
    expect(version['observations'], startsWith('IF0009 HC: L 8 am a 10 am.'));

    final appointment =
        (await declarationDoc(id)
                .collection('versions')
                .doc(declaration['currentVersionId'] as String)
                .collection('appointments')
                .get())
            .docs
            .single
            .data();
    expect(
      appointment['workplace'],
      'Universidad de Costa Rica · Sede del Sur · Informática Empresarial',
    );
    expect(appointment['workload'], '1/8 TC');
    expect(
      (appointment['startDate'] as Timestamp).toDate().toUtc(),
      Proyecto1Fixture.periodStart,
    );
    expect((appointment['blocks'] as List).first, {
      'day': 1,
      'startMinutes': 480,
      'endMinutes': 600,
      'category': 'lesson',
      'course': 'Redes',
    });

    final events = await eventsOf(id);
    expect(events.single['type'], 'DECLARACION_CREADA');
    expect(declaration['lastEventId'], isNotNull);
    final slot = await db
        .collection('declarationSlots')
        .doc('2026_II_${Proyecto1Fixture.uid}')
        .get();
    expect(slot.data(), {'declarationId': id});
  });

  test('test 02: with an overlap it does not become VALIDADA', () async {
    final state = DeclarationFormState(
      repository: repository,
      // Attention overlaps the lessons: Monday 9:00-10:00.
      initial: complete([
        interval('hc', 8 * 60, 10 * 60),
        interval('ae', 9 * 60, 10 * 60, kind: TaskKind.attention),
        interval(
          'pye',
          8 * 60,
          10 * 60,
          day: Weekday.tuesday,
          kind: TaskKind.planning,
        ),
      ]),
    );

    expect(await state.validateAndSave(), isFalse);
    expect(state.declaration.status, DeclarationStatus.draft);

    state.edit(
      (d) => d.intervals[1]
        ..startMinutes = 10 * 60
        ..endMinutes = 11 * 60,
    );
    expect(await state.validateAndSave(), isTrue);
    final id = state.declaration.id!;
    expect((await repository.getById(id))!.status, DeclarationStatus.validated);

    // markValidated: the event and the hours of the version.
    final declaration = (await declarationDoc(id).get()).data()!;
    final version =
        (await declarationDoc(id)
                .collection('versions')
                .doc(declaration['currentVersionId'] as String)
                .get())
            .data()!;
    expect(version['validationPassed'], isTrue);
    expect(version['hoursSummary'], {
      'expectedMinutes': 300,
      'declaredMinutes': 300,
      'differenceMinutes': 0,
    });
    expect(
      (await eventsOf(id)).map((e) => e['type']),
      containsAll(['DECLARACION_CREADA', 'VALIDACION_EJECUTADA']),
    );
  });

  test('editing a VALIDADA declaration sends it back to BORRADOR', () async {
    final state = DeclarationFormState(
      repository: repository,
      initial: complete(placed()),
    );
    expect(await state.validateAndSave(), isTrue);

    state.edit((d) => d.notes = 'Cambio');
    expect(state.declaration.status, DeclarationStatus.draft);
    expect(await state.saveDraft(), isTrue);

    final id = state.declaration.id!;
    final saved = (await repository.getById(id))!;
    expect(saved.status, DeclarationStatus.draft);
    expect(saved.notes, 'Cambio');
    final reopened = (await eventsOf(id))
        .firstWhere((e) => e['type'] == 'HORARIO_MODIFICADO');
    expect(reopened['previousStatus'], 'VALIDADA');
    expect(reopened['newStatus'], 'BORRADOR');
  });

  test('saving a draft carries the corrected profile (U-07)', () async {
    final state = DeclarationFormState(
      repository: repository,
      initial: complete(placed()),
    );
    expect(await state.saveDraft(), isTrue);
    final id = state.declaration.id!;
    await db.collection('users').doc(Proyecto1Fixture.uid).update({
      'fullName': 'Ana Pérez Solano',
      'identification': '105430988',
    });

    state.edit((d) => d.notes = 'Después');
    expect(await state.saveDraft(), isTrue);
    final saved = (await repository.getById(id))!;
    expect(saved.declarantName, 'Ana Pérez Solano');
    expect(saved.identification, '105430988');
  });

  test('the list shows what was saved, also after a content save', () async {
    final state = DeclarationFormState(
      repository: repository,
      initial: complete(placed()),
    );
    final updates = repository.watchAll().skip(1);
    await state.saveDraft();
    expect((await repository.watchAll().first).single.notes, '');

    state.edit((d) => d.notes = 'Más tarde');
    final next = updates.firstWhere(
      (list) => list.isNotEmpty && list.single.notes == 'Más tarde',
    );
    await state.saveDraft();
    expect((await next).single.status, DeclarationStatus.draft);
  });

  test('one declaration per period', () async {
    await DeclarationFormState(
      repository: repository,
      initial: complete(placed()),
    ).saveDraft();
    final second = DeclarationFormState(
      repository: repository,
      initial: complete(placed()),
    );

    expect(await second.saveDraft(), isFalse);
    expect(second.error, 'Ya tiene una declaración en este período.');
  });

  test('without the coordination assignment it cannot be created', () async {
    db = FakeFirebaseFirestore();
    await Proyecto1Fixture.seed(db, assignment: false);
    final state = DeclarationFormState(
      repository: Proyecto1Fixture.declarations(db),
      initial: complete(placed()),
    );

    expect(await state.saveDraft(), isFalse);
    expect(state.error, contains('aún no le asignó cursos'));
    expect((await db.collection('declarations').get()).docs, isEmpty);
  });

  test('without a reviewer it cannot be created', () async {
    db = FakeFirebaseFirestore();
    await Proyecto1Fixture.seed(
      db,
      user: {...Proyecto1Fixture.profile}..remove('superiorUid'),
    );
    final state = DeclarationFormState(
      repository: Proyecto1Fixture.declarations(db),
      initial: complete(placed()),
    );

    expect(await state.saveDraft(), isFalse);
    expect(state.error, contains('superior'));
  });

  test('a declaration in the signing flow is read only', () async {
    final state = DeclarationFormState(
      repository: repository,
      initial: complete(placed()),
    );
    await state.validateAndSave();
    final id = state.declaration.id!;
    // The web moved it on to the reviewer.
    await declarationDoc(id).update({'status': 'PENDIENTE_FIRMA_SUPERIOR'});

    final opened = DeclarationFormState(
      repository: repository,
      initial: await repository.getById(id),
    );
    expect(opened.editable, isFalse);
    opened.edit((d) => d.notes = 'No');
    expect(opened.declaration.notes, isNot('No'));
  });

  test("another person's declarations are neither listed nor opened", () async {
    await declarationDoc('ajena').set({
      'declarantUid': 'user-b',
      'periodId': '2026_II',
      'status': 'BORRADOR',
      'currentVersionId': 'v1',
      'currentVersionNumber': 1,
    });

    expect(await repository.watchAll().first, isEmpty);
    expect(await repository.getById('ajena'), isNull);
  });

  test('a malformed document is skipped, not shown or crashed on', () async {
    await declarationDoc('rota')
        .set({'declarantUid': Proyecto1Fixture.uid, 'status': 'FIRMADA_FALSA'});
    await DeclarationFormState(
      repository: repository,
      initial: complete(placed()),
    ).saveDraft();

    expect(await repository.watchAll().first, hasLength(1));
  });
}
