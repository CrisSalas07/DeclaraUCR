// The declarant's signature against the REAL rules of the Proyecto 1, on
// the emulators of backend/proyecto1 (fake Firestore does not apply rules).
// It runs the app's own code: create, validate, read the oath and sign, then
// the reviewer reads what was signed. From the repository root:
//
//   flutter create --platforms=windows .   (only once; do not commit it)
//   firebase emulators:exec --config backend/proyecto1/firebase.json
//     --project demo-declaraucr --only auth,firestore
//     "node backend/proyecto1/seed.mjs && flutter test
//      integration_test/sign_rules_test.dart -d windows
//      --dart-define=EMULATOR_HOST=127.0.0.1"
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/config/firebase_config.dart';
import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/data/proyecto1/declaration_document_reader.dart';
import 'package:declara_ucr/data/proyecto1/declaration_signer.dart';
import 'package:declara_ucr/data/proyecto1/period_repository.dart';
import 'package:declara_ucr/data/proyecto1/proyecto1_declaration_repository.dart';
import 'package:declara_ucr/domain/content_hash.dart';
import 'package:declara_ucr/domain/oath_text.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/models/workload_items.dart';
import 'package:declara_ucr/state/declaration_form_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the declarant signs from the app under the Proyecto 1 rules', (
    tester,
  ) async {
    expect(FirebaseConfig.useEmulators, isTrue, reason: 'only emulators');
    await Firebase.initializeApp(options: FirebaseConfig.options);
    final auth = FirebaseAuth.instance;
    final db = FirebaseFirestore.instance;
    db.useFirestoreEmulator(FirebaseConfig.emulatorHost, 8080);
    await auth.useAuthEmulator(FirebaseConfig.emulatorHost, 9099);

    // 1. The declarant creates and validates her declaration, as the app.
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
    final declaration = form.declaration;
    expect(declaration.intervals, isNotEmpty, reason: 'lessons placed');
    final id = await repository.save(declaration);
    declaration.status = DeclarationStatus.validated;
    await repository.save(declaration);

    // 2. She reads the oath from the server and signs it.
    final document = await FirestoreDeclarationDocumentReader(
      db,
      uid: uid,
    ).read(id);
    final oath = OathText.of(document);
    expect(oath, contains('Daniela Docente'));
    final signer = FirestoreDeclarationSigner(db, uid: uid);
    await signer.signAndSend(id, oathText: oath);

    final ref = db.collection('declarations').doc(id);
    final stored = (await ref.get()).data()!;
    expect(stored['status'], 'PENDIENTE_FIRMA_SUPERIOR');

    // Signing twice is refused by the app (and would be by the rules).
    await expectLater(
      signer.signAndSend(id, oathText: oath),
      throwsA(isA<DeclarationSaveException>()),
    );

    // 3. The reviewer, now responsible, reads exactly what was signed.
    await auth.signOut();
    await auth.signInWithEmailAndPassword(
      email: 'revisor@ucr.ac.cr',
      password: '123456',
    );
    expect(stored['currentResponsibleUid'], auth.currentUser!.uid);
    final version = ref
        .collection('versions')
        .doc(stored['currentVersionId'] as String);
    final versionData = (await version.get()).data()!;
    final signature = (await version
            .collection('signatures')
            .doc('declarant')
            .get())
        .data()!;
    final recomputed = ContentHash.of(
      version: versionData,
      appointments: [
        for (final d in (await version.collection('appointments').get()).docs)
          d.data(),
      ],
      externalJobs: [
        for (final d in (await version.collection('externalJobs').get()).docs)
          d.data(),
      ],
    );
    expect(versionData['isLocked'], isTrue);
    expect(versionData['contentHash'], recomputed);
    expect(signature['contentHash'], recomputed);
    expect(signature['fullName'], 'Daniela Docente');
    expect(signature['oathText'], oath);
    expect(signature['signedAt'], isA<Timestamp>());
    await auth.signOut();
  });
}
