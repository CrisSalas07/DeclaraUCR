import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/models/weekday.dart';
import 'package:declara_ucr/state/declaration_form_state.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'domain/declaration_validator_test.dart' show complete, interval;

void main() {
  late FakeFirebaseFirestore firestore;
  late DeclarationRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreDeclarationRepository(firestore);
  });

  test('tests 01/04: saves a draft and recovers it unchanged', () async {
    final state = DeclarationFormState(
      repository: repository,
      initial: complete([
        interval('a', 8 * 60, 12 * 60, day: Weekday.saturday),
      ]),
    );

    expect(await state.saveDraft(), isTrue);
    final saved = await repository.getById(state.declaration.id!);

    expect(saved!.status, DeclarationStatus.draft);
    expect(saved.declarantName, 'Ana Pérez Mora');
    expect(saved.validFrom, DateTime(2026, 3, 1));
    expect(saved.intervals.single.day, Weekday.saturday);
    expect(saved.totalMinutes, 4 * 60);
  });

  test('test 02: with an overlap it does not become VALIDADA', () async {
    final state = DeclarationFormState(
      repository: repository,
      initial: complete([
        interval('a', 8 * 60, 12 * 60),
        interval('b', 11 * 60, 14 * 60),
      ]),
    );

    expect(await state.validateAndSave(), isFalse);
    expect(state.declaration.status, DeclarationStatus.draft);

    state.edit((d) => d.intervals.last.startMinutes = 12 * 60);
    expect(await state.validateAndSave(), isTrue);
    final saved = await repository.getById(state.declaration.id!);
    expect(saved!.status, DeclarationStatus.validated);
  });

  test('editing a VALIDADA declaration sends it back to BORRADOR', () async {
    final state = DeclarationFormState(
      repository: repository,
      initial: complete([interval('a', 8 * 60, 12 * 60)]),
    );
    await state.validateAndSave();

    state.edit((d) => d.observations = 'Cambio');

    expect(state.declaration.status, DeclarationStatus.draft);
  });

  test('the home list shows what was saved', () async {
    await DeclarationFormState(
      repository: repository,
      initial: complete([interval('a', 8 * 60, 10 * 60)]),
    ).saveDraft();

    final list = await repository.watchAll().first;

    expect(list.single.status, DeclarationStatus.draft);
  });

  test('a malformed document is skipped, not shown or crashed on', () async {
    await firestore.collection('declarations').add({
      'status': 'FIRMADA_FALSA',
      'intervals': 'not a list',
      'updatedAt': Timestamp.now(),
    });
    await DeclarationFormState(
      repository: repository,
      initial: complete([interval('a', 8 * 60, 10 * 60)]),
    ).saveDraft();

    final list = await repository.watchAll().first;

    expect(list, hasLength(1));
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
