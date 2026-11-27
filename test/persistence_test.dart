import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/data/profile_repository.dart';
import 'package:declara_ucr/data/zonaje_repository.dart';
import 'package:declara_ucr/models/zonaje_request.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/state/declaration_form_state.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/proyecto1_fixture.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late DeclarationRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = Proyecto1Fixture.declarations(firestore);
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

  group('editing the own profile (U-07)', () {
    const stored = UserProfile(
      fullName: 'Ana Pérez Mora',
      identification: '105430987',
      phone: '88881234',
      email: 'ana.perez@ucr.ac.cr',
      roles: {UserRole.declarant},
      active: true,
      unitId: 'ie',
    );

    Future<Map<String, dynamic>?> read(String path) async =>
        (await firestore.doc(path).get()).data();

    test('a new cédula is reserved and the old one released', () async {
      final profiles = FirestoreProfileRepository(firestore);
      await profiles.create('user-a', ana);
      await profiles.updateOwn(
        'user-a',
        stored,
        fullName: ' Ana Pérez Solano ',
        identification: '105430988',
        phone: '88884321',
      );

      final user = (await read('users/user-a'))!;
      expect(user['fullName'], 'Ana Pérez Solano');
      expect(user['identification'], '105430988');
      expect(user['phone'], '88884321');
      expect(user['email'], 'ana.perez@ucr.ac.cr');
      expect(await read('identifications/CEDULA_105430988'), {'uid': 'user-a'});
      expect(await read('identifications/CEDULA_105430987'), isNull);
      final entry = (await read('teacherDirectory/user-a'))!;
      expect(entry['fullName'], 'Ana Pérez Solano');
      expect(entry['identification'], '105430988');
    });

    test("another account's cédula is refused and nothing changes", () async {
      final profiles = FirestoreProfileRepository(firestore);
      await profiles.create('user-a', ana);
      await profiles.create(
        'user-b',
        const UserProfile(
          fullName: 'Beto',
          identification: '205550111',
          phone: '88880000',
          email: 'beto@ucr.ac.cr',
        ),
      );
      await expectLater(
        profiles.updateOwn(
          'user-a',
          stored,
          fullName: 'Ana',
          identification: '205550111',
          phone: '88881234',
        ),
        throwsA(isA<IdentificationTakenException>()),
      );
      expect((await read('users/user-a'))!['identification'], '105430987');
      expect(await read('identifications/CEDULA_105430987'), {'uid': 'user-a'});
    });

    test('the same cédula keeps its reservation', () async {
      final profiles = FirestoreProfileRepository(firestore);
      await profiles.create('user-a', ana);
      await profiles.updateOwn(
        'user-a',
        stored,
        fullName: 'Ana Pérez',
        identification: '105430987',
        phone: '88881234',
      );
      expect((await read('users/user-a'))!['fullName'], 'Ana Pérez');
      expect(await read('identifications/CEDULA_105430987'), {'uid': 'user-a'});
    });
  });

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

  test('lists the zonaje requests made in the web, newest first', () async {
    final requests = firestore.collection('zonajeRequests');
    Map<String, Object> request(String period, String status, int day) => {
      'declarantUid': 'user-a',
      'periodId': period,
      'previousAddress': 'San José, Central, Carmen',
      'currentAddress': 'Puntarenas, Golfito, Golfito',
      'declaredDistanceKm': 280.5,
      'salaryRegime': 'COMPUESTO',
      'weeklyMinutes': 1200,
      'status': status,
      'createdAt': Timestamp.fromDate(DateTime(2026, 9, day)),
    };
    await requests.doc('2026_I_user-a').set({
      ...request('2026_I', 'RECHAZADA', 1),
      'hrObservation': 'La certificación del TSE no es legible.',
    });
    await requests.doc('2026_II_user-a').set({
      ...request('2026_II', 'APROBADA', 20),
      'confirmedDistanceKm': 275,
    });
    await requests.doc('2026_II_user-b').set({
      ...request('2026_II', 'SOLICITADA', 5),
      'declarantUid': 'user-b',
    });
    await requests.doc('broken').set({'declarantUid': 'user-a'});

    final list = await FirestoreZonajeRepository(
      firestore,
      uid: 'user-a',
    ).watchAll().first;

    expect(list.map((r) => r.periodId), ['2026_II', '2026_I']);
    expect(list.first.status, ZonajeStatus.approved);
    expect(list.first.distanceKm, 275);
    expect(list.last.hrObservation, 'La certificación del TSE no es legible.');
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
