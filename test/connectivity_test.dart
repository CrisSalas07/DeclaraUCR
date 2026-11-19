import 'dart:async';

import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/state/declaration_form_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'domain/declaration_validator_test.dart' show complete, placed;
import 'support/fake_network_status.dart';

/// Loss of connectivity and an unavailable service (§5 and §7 of the
/// Proyecto 2): no crash, no silent loss, a message the person understands.
void main() {
  test('offline, nothing is attempted and the changes stay', () async {
    final repository = _RecordingRepository();
    final state = DeclarationFormState(
      repository: repository,
      network: FakeNetworkStatus(online: false),
      initial: complete(placed())..notes = 'Mis notas',
    );

    expect(await state.saveDraft(), isFalse);
    expect(state.error, OfflineException.message);
    expect(repository.calls, 0);
    // Still on the screen, ready to save when the signal comes back.
    expect(state.declaration.notes, 'Mis notas');
    expect(state.saving, isFalse);
  });

  test('offline, validating does not change the status', () async {
    final state = DeclarationFormState(
      repository: _RecordingRepository(),
      network: FakeNetworkStatus(online: false),
      initial: complete(placed()),
    );

    expect(await state.validateAndSave(), isFalse);
    expect(state.declaration.status, DeclarationStatus.draft);
  });

  test('back online, the same changes are saved', () async {
    final network = FakeNetworkStatus(online: false);
    final repository = _RecordingRepository();
    final state = DeclarationFormState(
      repository: repository,
      network: network,
      initial: complete(placed()),
    );
    await state.saveDraft();

    network.online = true;
    expect(await state.saveDraft(), isTrue);
    expect(state.error, isNull);
    expect(repository.calls, 1);
  });

  test(
    'a server that does not answer ends with a message, not a wait',
    () async {
      final state = DeclarationFormState(
        repository: _RecordingRepository(hang: true),
        // 15 s in the app; short here.
        saveTimeout: const Duration(milliseconds: 50),
        initial: complete(placed()),
      );

      final save = state.saveDraft();
      expect(state.saving, isTrue);

      expect(await save, isFalse);
      expect(state.saving, isFalse);
      expect(state.error, DeclarationFormState.timeoutMessage);
    },
  );

  test('the server unreachable during the save says "sin conexión"', () async {
    final state = DeclarationFormState(
      repository: _RecordingRepository(error: const OfflineException()),
      initial: complete(placed()),
    );

    expect(await state.saveDraft(), isFalse);
    expect(state.error, OfflineException.message);
  });
}

class _RecordingRepository implements DeclarationRepository {
  _RecordingRepository({this.hang = false, this.error});

  final bool hang;
  final Object? error;
  int calls = 0;

  @override
  Future<String> save(Declaration declaration) {
    calls++;
    if (hang) return Completer<String>().future;
    if (error != null) return Future.error(error!);
    declaration.id ??= 'd1';
    return Future.value(declaration.id);
  }

  @override
  Future<Declaration?> getById(String id) => throw UnimplementedError();

  @override
  Stream<List<Declaration>> watchAll() => throw UnimplementedError();
}
