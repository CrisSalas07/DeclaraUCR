import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/data/profile_repository.dart';
import 'package:declara_ucr/data/zonaje_repository.dart';
import 'package:declara_ucr/models/zonaje_request.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/models/schedule_task.dart';
import 'package:declara_ucr/models/weekday.dart';
import 'package:declara_ucr/state/declaration_form_state.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'domain/declaration_validator_test.dart' show complete, interval, placed;

void main() {
  late FakeFirebaseFirestore firestore;
  late DeclarationRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreDeclarationRepository(firestore, ownerUid: 'user-a');
  });

  test('tests 01/04: saves a draft and recovers it unchanged', () async {
    final state = DeclarationFormState(
      repository: repository,
      initial: complete(placed())..notes = 'Nota',
    );

    expect(await state.saveDraft(), isTrue);
    final saved = await repository.getById(state.declaration.id!);

    expect(saved!.status, DeclarationStatus.draft);
    expect(saved.declarantName, 'Ana Pérez Mora');
    expect(saved.identification, '105430987');
    expect(saved.validFrom, DateTime(2026, 3, 1));
    expect(saved.courses.single.code, 'IF0009');
    expect(saved.intervals.map((i) => i.task.key), [
      'HC|Redes',
      'AE|Redes',
      'PyE|Redes',
    ]);
    expect(saved.intervals.last.day, Weekday.tuesday);
    expect(saved.totalMinutes, 5 * 60);
    expect(saved.notes, 'Nota');
    final doc = await firestore
        .collection('declarations')
        .doc(state.declaration.id)
        .get();
    expect(
      doc.data()!['observations'],
      startsWith('IF0009 HC: L 8 am a 10 am.'),
    );
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
    final saved = await repository.getById(state.declaration.id!);
    expect(saved!.status, DeclarationStatus.validated);
  });

  test('editing a VALIDADA declaration sends it back to BORRADOR', () async {
    final state = DeclarationFormState(
      repository: repository,
      initial: complete(placed()),
    );
    expect(await state.validateAndSave(), isTrue);

    state.edit((d) => d.notes = 'Cambio');

    expect(state.declaration.status, DeclarationStatus.draft);
  });

  test('the home list shows what was saved', () async {
    await DeclarationFormState(
      repository: repository,
      initial: complete(placed()),
    ).saveDraft();

    final list = await repository.watchAll().first;

    expect(list.single.status, DeclarationStatus.draft);
  });

  test('a malformed document is skipped, not shown or crashed on', () async {
    await firestore.collection('declarations').add({
      'ownerUid': 'user-a',
      'status': 'FIRMADA_FALSA',
      'intervals': 'not a list',
      'updatedAt': Timestamp.now(),
    });
    await DeclarationFormState(
      repository: repository,
      initial: complete(placed()),
    ).saveDraft();

    final list = await repository.watchAll().first;

    expect(list, hasLength(1));
  });

  test("another user's declarations are neither listed nor opened", () async {
    final other = FirestoreDeclarationRepository(firestore, ownerUid: 'user-b');
    final state = DeclarationFormState(
      repository: other,
      initial: complete(placed()),
    );
    await state.saveDraft();

    expect(await repository.watchAll().first, isEmpty);
    expect(await repository.getById(state.declaration.id!), isNull);
    expect(await other.watchAll().first, hasLength(1));
  });

  const ana = UserProfile(
    fullName: 'Ana Pérez Mora',
    identification: '105430987',
    phone: '88881234',
    email: 'ana.perez@ucr.ac.cr',
  );

  test('sign-up stores the profile in the Proyecto 1 format', () async {
    final profiles = FirestoreProfileRepository(firestore);
    await profiles.create('user-a', ana);

    final stored = await firestore.collection('users').doc('user-a').get();
    // Exactly the fields the Proyecto 1 rules accept at sign-up.
    expect(stored.data(), {
      'fullName': 'Ana Pérez Mora',
      'identification': '105430987',
      'identificationType': 'CEDULA',
      'phone': '88881234',
      'email': 'ana.perez@ucr.ac.cr',
      'roles': ['declarant'],
      'active': true,
    });

    // The fake applies a transaction just after it returns.
    final profile = await profiles.watch('user-a').firstWhere((p) => p != null);
    final state = DeclarationFormState(
      repository: repository,
      profile: profile,
    );
    expect(state.declaration.identification, '105430987');
    expect(state.declaration.declarantName, 'Ana Pérez Mora');
  });

  test('a cédula belongs to one account only', () async {
    final profiles = FirestoreProfileRepository(firestore);
    await profiles.create('user-a', ana);

    await expectLater(
      profiles.create('user-b', ana),
      throwsA(isA<IdentificationTakenException>()),
    );
    expect(await profiles.watch('user-b').first, isNull);
    final reservation = await firestore
        .collection('identifications')
        .doc('CEDULA_105430987')
        .get();
    expect(reservation.data(), {'uid': 'user-a'});
  });

  test('reads a profile written by the web system', () {
    final profile = FirestoreProfileRepository.fromMap({
      'fullName': 'Ana Pérez Mora',
      'identification': '105430987',
      'identificationType': 'CEDULA',
      'phone': '88881234',
      'email': 'ana@gmail.com',
      'roles': ['declarant', 'someFutureRole'],
      'active': true,
      'campusId': 'sede-sur',
      'unitId': 'ie',
      'superiorUid': 'rev',
      'salaryRegime': 'COMPUESTO',
    });
    expect(profile.roles, {UserRole.declarant});
    expect(profile.needsCampus || profile.needsCareer, isFalse);
    expect(profile.hasSuperior, isTrue);

    // Without the flag an account counts as disabled, like in the web.
    final noFlag = FirestoreProfileRepository.fromMap({
      'fullName': 'X',
      'identification': '105430987',
      'roles': ['declarant'],
    });
    expect(noFlag.active, isFalse);
    expect(noFlag.needsCampus, isTrue);
    expect(noFlag.needsCareer, isTrue);

    // The old mobile format is not a profile of the Proyecto 1.
    expect(
      () => FirestoreProfileRepository.fromMap({
        'name': 'Ana',
        'identification': '105430987',
      }),
      throwsFormatException,
    );
  });

  test(
    'choosing campus and career lists the teacher for the coordination',
    () async {
      final profiles = FirestoreProfileRepository(firestore);
      await firestore.collection('campuses').doc('sede-sur').set({
        'name': 'Sede del Sur',
        'active': true,
      });
      await firestore.collection('campuses').doc('vieja').set({
        'name': 'Sede cerrada',
        'active': false,
      });
      await firestore.collection('units').doc('ie').set({
        'name': 'Informática Empresarial',
        'active': true,
        'campusId': 'sede-sur',
      });
      expect((await profiles.activeCampuses()).map((c) => c.name), [
        'Sede del Sur',
      ]);
      expect((await profiles.activeCareers('sede-sur')).map((c) => c.id), [
        'ie',
      ]);

      await profiles.create('user-a', ana);
      await profiles.chooseWorkplace(
        'user-a',
        ana,
        campusId: 'sede-sur',
        unitId: 'ie',
      );

      final user = (await firestore.collection('users').doc('user-a').get())
          .data()!;
      expect(user['campusId'], 'sede-sur');
      expect(user['unitId'], 'ie');
      final entry =
          (await firestore.collection('teacherDirectory').doc('user-a').get())
              .data()!;
      expect(entry['fullName'], 'Ana Pérez Mora');
      expect(entry['unitId'], 'ie');
      expect(entry['identification'], '105430987');
    },
  );

  test('a campus set by administration is never rewritten', () async {
    final profiles = FirestoreProfileRepository(firestore);
    await firestore.collection('users').doc('user-a').set({'campusId': 'a'});
    const assigned = UserProfile(
      fullName: 'Ana',
      identification: '105430987',
      campusId: 'a',
    );
    await profiles.chooseWorkplace(
      'user-a',
      assigned,
      campusId: 'b',
      unitId: 'ie',
    );
    final user = (await firestore.collection('users').doc('user-a').get())
        .data()!;
    expect(user['campusId'], 'a');
    expect(user['unitId'], 'ie');
  });

  test('a zonaje request is sent as SOLICITADA and listed', () async {
    final zonaje = FirestoreZonajeRepository(firestore, ownerUid: 'user-a');
    await zonaje.send(
      const ZonajeRequest(
        previousAddress: 'San José, Central, Carmen',
        currentAddress: 'Puntarenas, Golfito, Golfito',
        distanceKm: 280.5,
        regime: SalaryRegime.composite,
        hasBonus: false,
        weeklyMinutes: 1200,
        declarationId: 'd1',
      ),
    );

    final list = await zonaje.watchAll().first;

    expect(list.single.status, ZonajeStatus.requested);
    expect(list.single.distanceKm, 280.5);
    expect(
      await FirestoreZonajeRepository(
        firestore,
        ownerUid: 'user-b',
      ).watchAll().first,
      isEmpty,
    );
  });

  test('a save failure shows a generic message, not the exception', () async {
    final state = DeclarationFormState(repository: _FailingRepository());

    expect(await state.saveDraft(), isFalse);
    expect(state.error, isNot(contains('secret')));
    expect(state.declaration.status, DeclarationStatus.draft);
  });
}

class _FailingRepository implements DeclarationRepository {
  @override
  Future<String> save(Declaration declaration) =>
      Future.error(StateError('secret internal detail'));

  @override
  Future<Declaration?> getById(String id) => throw UnimplementedError();

  @override
  Stream<List<Declaration>> watchAll() => throw UnimplementedError();
}
