// 2.0.0+8 against the REAL Firestore SDK and the Proyecto 1 rules, on the
// emulators of backend/proyecto1 (fake Firestore applies no rules and has no
// cache). From the repository root, with an Android emulator running:
//
//   firebase emulators:exec --config backend/proyecto1/firebase.json
//     --project demo-declaraucr --only auth,firestore
//     "node backend/proyecto1/seed.mjs && flutter test
//      integration_test/release_8_rules_test.dart"
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/config/firebase_config.dart';
import 'package:declara_ucr/data/network_status.dart';
import 'package:declara_ucr/data/profile_repository.dart';
import 'package:declara_ucr/data/proyecto1/period_repository.dart';
import 'package:declara_ucr/data/proyecto1/proyecto1_declaration_repository.dart';
import 'package:declara_ucr/domain/schedule_grid.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/schedule_task.dart';
import 'package:declara_ucr/models/weekday.dart';
import 'package:declara_ucr/models/workload_items.dart';
import 'package:declara_ucr/state/declaration_form_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('list refresh (T-08) and profile edit (U-07) under the rules', (
    tester,
  ) async {
    expect(FirebaseConfig.useEmulators, isTrue, reason: 'only emulators');
    // The list must never skip a draft, not even before the server confirms
    // it (the rules deny reading a version whose declaration is not there).
    final skipped = <String>[];
    final print = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message?.startsWith('Skipping declaration') ?? false) {
        skipped.add(message!);
      }
      print(message, wrapWidth: wrapWidth);
    };
    addTearDown(() => debugPrint = print);
    await Firebase.initializeApp(options: FirebaseConfig.options);
    final auth = FirebaseAuth.instance;
    final db = FirebaseFirestore.instance;
    db.useFirestoreEmulator(FirebaseConfig.emulatorHost, 8080);
    await auth.useAuthEmulator(FirebaseConfig.emulatorHost, 9099);
    await auth.signInWithEmailAndPassword(
      email: 'docente@ucr.ac.cr',
      password: '123456',
    );
    final uid = auth.currentUser!.uid;
    final periods = FirestorePeriodRepository(db, uid: uid);
    final repository = Proyecto1DeclarationRepository(
      db,
      uid: uid,
      periods: periods,
    );
    final period = (await periods.openPeriods()).single;
    final assignment = (await periods.assignmentFor(period.id))!;
    final course = assignment.courses.first;

    // The list as the app shows it, listened to the whole time.
    final lists = <List<Declaration>>[];
    final sub = repository.watchAll().listen(lists.add);
    Future<Declaration> listed(bool Function(Declaration d) when) async {
      for (var i = 0; i < 50; i++) {
        final hit = lists.isEmpty
            ? null
            : lists.last.where((d) => d.periodId == period.id && when(d));
        if (hit != null && hit.isNotEmpty) return hit.first;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
      }
      fail('The list never showed it. Last: ${lists.lastOrNull}');
    }

    // 1. A draft with the coordination's lessons only.
    final form = DeclarationFormState(
      repository: repository,
      initial: Declaration(
        periodId: period.id,
        periodName: period.name,
        validFrom: period.startDate,
        validTo: period.endDate,
        position: Positions.university.first,
        courses: [...assignment.courses],
        lessonSlots: assignment.slots,
      ),
    );
    expect(await form.saveDraft(), isTrue, reason: form.error);
    final lessons = form.declaration.totalMinutes;
    await listed((d) => d.totalMinutes == lessons);

    // 2. T-08: an hour of attention more, saved on the existing draft.
    expect(
      form.paint([
        const GridCell(Weekday.friday, 600),
        const GridCell(Weekday.friday, 630),
      ], ScheduleTask(TaskKind.attention, course.name)),
      isNull,
    );
    expect(await form.saveDraft(), isTrue, reason: form.error);
    await listed((d) => d.totalMinutes == lessons + 60);

    // 3. U-07: a new cédula, under the rules, moves the reservation.
    final profiles = FirestoreProfileRepository(db);
    final current = (await profiles.watch(uid).first)!;
    await profiles.updateOwn(
      uid,
      current,
      fullName: 'Daniela Docente Mora',
      identification: '100000095',
      phone: '88887777',
    );
    final user = (await db.doc('users/$uid').get()).data()!;
    expect(user['identification'], '100000095');
    expect(
      (await db.doc('identifications/CEDULA_100000095').get()).data(),
      {'uid': uid},
    );
    expect(
      (await db.doc('identifications/CEDULA_100000005').get()).exists,
      isFalse,
    );

    // 4. The unsigned draft takes the corrected data on its next save.
    form.edit((d) => d.notes = 'Con mis datos corregidos');
    expect(await form.saveDraft(), isTrue, reason: form.error);
    final saved = (await repository.getById(form.declaration.id!))!;
    expect(saved.declarantName, 'Daniela Docente Mora');
    expect(saved.identification, '100000095');

    // 5. Offline: the save writes nothing and says so, the form keeps the
    // change, and the list (reloaded from the phone's copy) keeps the draft.
    final listedBefore = lists.length;
    await db.disableNetwork();
    form.edit((d) => d.notes = 'Escrito sin conexión');
    expect(await form.saveDraft(), isFalse);
    expect(form.error, OfflineException.message);
    expect(form.declaration.notes, 'Escrito sin conexión');
    final offline = await listed(
      (d) => d.id == form.declaration.id && lists.length > listedBefore,
    );
    expect(offline.notes, 'Con mis datos corregidos');

    // Back online, the same save goes through.
    await db.enableNetwork();
    expect(await form.saveDraft(), isTrue, reason: form.error);
    await listed((d) => d.notes == 'Escrito sin conexión');

    await sub.cancel();
    expect(skipped, isEmpty);
    await auth.signOut();
  });
}
