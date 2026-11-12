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

  test('the profile keeps the cédula and the name', () async {
    final profiles = FirestoreProfileRepository(firestore);
    await profiles.save(
      'user-a',
      const UserProfile(name: 'Ana Pérez Mora', identification: '105430987'),
    );

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
    const ana = UserProfile(name: 'Ana', identification: '105430987');
    await profiles.save('user-a', ana);

    await expectLater(
      profiles.save('user-b', ana),
      throwsA(isA<IdentificationTakenException>()),
    );
    expect(await profiles.watch('user-b').first, isNull);
    final reservation = await firestore
        .collection('identifications')
        .doc('105430987')
        .get();
    expect(reservation.data(), {'uid': 'user-a'});
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
