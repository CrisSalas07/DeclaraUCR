import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/data/profile_repository.dart';
import 'package:declara_ucr/data/zonaje_repository.dart';
import 'package:declara_ucr/main.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth_repository.dart';

/// Ana's profile as the web system leaves it after administration assigned
/// her career and reviewer.
const Map<String, Object> _ana = {
  'fullName': 'Ana Pérez Mora',
  'identification': '105430987',
  'identificationType': 'CEDULA',
  'phone': '88881234',
  'email': 'ana.perez@ucr.ac.cr',
  'roles': ['declarant'],
  'active': true,
  'campusId': 'sede-sur',
  'unitId': 'ie',
  'superiorUid': 'rev',
};

/// The app over an in-memory Firestore with one campus and career.
/// [profile] is the signed-in test user's stored profile (none if `null`);
/// its cédula is reserved, as after a normal sign-up.
Future<Widget> _app({
  AppUserMode mode = AppUserMode.signedOut,
  Map<String, Object>? profile = _ana,
}) async {
  final firestore = FakeFirebaseFirestore();
  await firestore.collection('campuses').doc('sede-sur').set({
    'name': 'Sede del Sur',
    'active': true,
  });
  await firestore.collection('units').doc('ie').set({
    'name': 'Informática Empresarial',
    'active': true,
    'campusId': 'sede-sur',
  });
  final uid = FakeAuthRepository.verifiedUser.uid;
  if (profile != null) {
    await firestore.collection('users').doc(uid).set(profile);
    await firestore
        .collection('identifications')
        .doc('CEDULA_${profile['identification']}')
        .set({'uid': uid});
  }
  final profiles = FirestoreProfileRepository(firestore);
  return DeclaraUcrApp(
    auth: FakeAuthRepository(
      signedIn: mode == AppUserMode.signedIn
          ? FakeAuthRepository.verifiedUser
          : null,
      profiles: profiles,
    ),
    profiles: profiles,
    repositoryFor: (uid) =>
        FirestoreDeclarationRepository(firestore, ownerUid: uid),
    zonajeFor: (uid) => FirestoreZonajeRepository(firestore, ownerUid: uid),
  );
}

/// Picks the campus and the career on "Complete su perfil" and saves.
Future<void> _chooseWorkplace(WidgetTester tester) async {
  await tester.tap(
    find.widgetWithText(DropdownButtonFormField<String>, 'Sede'),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sede del Sur').last);
  await tester.pumpAndSettle();
  await tester.tap(
    find.widgetWithText(DropdownButtonFormField<String>, 'Carrera'),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Informática Empresarial').last);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Guardar'));
  await tester.tap(find.text('Guardar'));
  await tester.pumpAndSettle();
}

enum AppUserMode { signedOut, signedIn }

Future<void> _openNewDeclaration(WidgetTester tester) async {
  await tester.tap(find.text('Declaraciones'));
  await tester.pumpAndSettle();
  await tester.tap(
    find.widgetWithText(FloatingActionButton, 'Nueva declaración'),
  );
  await tester.pumpAndSettle();
}

void main() {
  // Small phone (360 x 690 dp): any overflow fails the test (test 05).
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1080, 2070);
    view.devicePixelRatio = 3;
  });

  group('session', () {
    testWidgets('the login card ends its entrance fully visible', (
      tester,
    ) async {
      await tester.pumpWidget(await _app());
      await tester.pump();
      final fades = find.byType(FadeTransition);
      expect(fades, findsWidgets);
      await tester.pumpAndSettle();
      for (final fade in tester.widgetList<FadeTransition>(fades)) {
        expect(fade.opacity.value, 1);
      }
    });

    testWidgets('signed out: shows the login screen', (tester) async {
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();

      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Nueva declaración'), findsNothing);
    });

    testWidgets('rejects an e-mail domain the Proyecto 1 does not accept', (
      tester,
    ) async {
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'ana@yahoo.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'x',
      );
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Use su correo @ucr.ac.cr (o Gmail, Outlook, Hotmail, Live o Zoho).',
        ),
        findsOneWidget,
      );
    });

    testWidgets('wrong password shows a generic error', (tester) async {
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        FakeAuthRepository.verifiedUser.email,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'otra',
      );
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    });

    testWidgets('sign in, then sign out from the profile', (tester) async {
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        FakeAuthRepository.verifiedUser.email,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        FakeAuthRepository.password,
      );
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Hola, Ana'), findsOneWidget);
      expect(find.text('105430987'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Perfil y cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Iniciar sesión'), findsOneWidget);
    });

    testWidgets('creating an account asks cédula, phone and workplace', (
      tester,
    ) async {
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Crear cuenta'));
      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre completo'),
        'Luis Mora',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Número de cédula'),
        '1-234',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Teléfono'),
        '88881234',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'),
        'luis.mora@ucr.ac.cr',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'Segura123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar contraseña'),
        'Segura123',
      );
      final submit = find.widgetWithText(FilledButton, 'Crear cuenta');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      // Only digits get in, and 4 of them are not a cédula.
      expect(
        find.text(
          'Use los 9 dígitos de la cédula, sin guiones (ej. 105430987).',
        ),
        findsOneWidget,
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Número de cédula'),
        '302220333',
      );
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      // A new account has no campus or career yet: asked once.
      expect(find.text('Complete su perfil'), findsOneWidget);
      await _chooseWorkplace(tester);

      expect(find.text('Hola, Luis'), findsOneWidget);
      expect(find.text('302220333'), findsOneWidget);
      // Only administration assigns the reviewer.
      expect(find.text('Aún no tiene revisor asignado.'), findsOneWidget);
    });

    testWidgets('signing up with a taken cédula asks for another one', (
      tester,
    ) async {
      // Ana's profile already holds 105430987.
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Crear cuenta'));
      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();
      for (final (label, value) in [
        ('Nombre completo', 'Luis Mora'),
        ('Número de cédula', '105430987'),
        ('Teléfono', '88881234'),
        ('Correo electrónico', 'luis.mora@ucr.ac.cr'),
        ('Contraseña', 'Segura123'),
        ('Confirmar contraseña', 'Segura123'),
      ]) {
        await tester.enterText(
          find.widgetWithText(TextFormField, label),
          value,
        );
      }
      final submit = find.widgetWithText(FilledButton, 'Crear cuenta');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.text('Complete su perfil'), findsOneWidget);
      expect(
        find.text('Esa cédula ya está registrada en otra cuenta.'),
        findsOneWidget,
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Número de cédula'),
        '302220333',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Teléfono'),
        '88881234',
      );
      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      await _chooseWorkplace(tester);
      expect(find.text('Hola, Luis'), findsOneWidget);
    });

    testWidgets('an account without profile completes it once', (tester) async {
      await tester.pumpWidget(
        await _app(mode: AppUserMode.signedIn, profile: null),
      );
      await tester.pumpAndSettle();
      expect(find.text('Complete su perfil'), findsOneWidget);
      // The name comes from the account.
      expect(find.text('Ana Pérez Mora'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Número de cédula'),
        '105430987',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Teléfono'),
        '8888',
      );
      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Use los 8 dígitos del teléfono, sin guiones (ej. 88881234).',
        ),
        findsOneWidget,
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Teléfono'),
        '88881234',
      );
      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      await _chooseWorkplace(tester);

      expect(find.text('Hola, Ana'), findsOneWidget);
    });

    testWidgets('a campus set by administration is shown, not asked', (
      tester,
    ) async {
      await tester.pumpWidget(
        await _app(
          mode: AppUserMode.signedIn,
          profile: {..._ana}..remove('unitId'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Asignada por Administración'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<String>, 'Carrera'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Informática Empresarial').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Guardar'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Hola, Ana'), findsOneWidget);
    });

    testWidgets('an account without the declarant role cannot continue', (
      tester,
    ) async {
      await tester.pumpWidget(
        await _app(
          mode: AppUserMode.signedIn,
          profile: {
            ..._ana,
            'roles': ['superior'],
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Esta aplicación es para personas declarantes.'),
        findsOneWidget,
      );
      expect(find.textContaining('rol de Revisor'), findsOneWidget);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Iniciar sesión'), findsOneWidget);
    });

    testWidgets('a disabled account cannot continue', (tester) async {
      await tester.pumpWidget(
        await _app(
          mode: AppUserMode.signedIn,
          profile: {..._ana, 'active': false},
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Su cuenta está desactivada.'), findsOneWidget);
    });
  });

  testWidgets('sections: Inicio, Declaraciones, Zonaje and Historial', (
    tester,
  ) async {
    await tester.pumpWidget(await _app(mode: AppUserMode.signedIn));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Zonaje').last);
    await tester.pumpAndSettle();
    expect(find.text('Valide primero una declaración'), findsOneWidget);

    await tester.tap(find.text('Historial').last);
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay historial.'), findsOneWidget);
  });

  testWidgets('test 03: saving without data flags the required fields', (
    tester,
  ) async {
    await tester.pumpWidget(await _app(mode: AppUserMode.signedIn));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Declaraciones'));
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay declaraciones registradas.'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(FloatingActionButton, 'Nueva declaración'),
    );
    await tester.pumpAndSettle();
    // Name and cédula come from the profile.
    expect(find.text('2 de 7 datos obligatorios'), findsOneWidget);
    expect(
      find.text('Universidad de Costa Rica · Sede del Sur'),
      findsOneWidget,
    );
    await tester.tap(find.text('Guardar borrador'));
    await tester.pumpAndSettle();

    expect(find.text('Este campo es obligatorio.'), findsWidgets);
    expect(find.textContaining('Faltan 5 datos obligatorios'), findsOneWidget);

    // Back to the list: the draft shows up with its status and count.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('BORRADOR'), findsOneWidget);
    expect(find.bySemanticsLabel('Borradores: 1'), findsOneWidget);
  });

  testWidgets('a course gives its hours, placed on the grid, to the summary', (
    tester,
  ) async {
    await tester.pumpWidget(await _app(mode: AppUserMode.signedIn));
    await tester.pumpAndSettle();
    await _openNewDeclaration(tester);

    // Course with sigla and workday: 1/8 TC = 2 h HC, 1 h AE, 2 h PyE.
    await tester.scrollUntilVisible(
      find.text('Agregar curso'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.text('Agregar curso')),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar curso'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre del curso *'),
      'Redes',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Sigla'), 'if0009');
    await tester.tap(find.text('Jornada del curso *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1/8 TC = 5 h').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Clases: 2 h · Atención: 1 h · Planificación: 2 h'),
      findsOneWidget,
    );
    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();
    expect(find.text('IF0009 · Redes'), findsOneWidget);

    // Lessons: tap one half hour, then long-press and slide over three
    // more: Monday 8:00-10:00.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('cell-1-480')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const ValueKey('cell-1-480'))),
      alignment: 0.2,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cell-1-480')));
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('cell-1-510'))),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey('cell-1-570'))),
    );
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Lunes: 2 h'), findsOneWidget);

    // The lessons are complete: one more half hour is refused.
    await tester.tap(find.byKey(const ValueKey('cell-1-600')));
    await tester.pumpAndSettle();
    expect(
      find.text('Ya ubicó todas las horas de clases de IF0009 (2 h).'),
      findsOneWidget,
    );

    await tester.tap(find.text('Ver resumen'));
    await tester.pumpAndSettle();
    expect(find.text('Total de horas: 2 h'), findsOneWidget);
    // Hours by category: the lessons are complete, attention is not.
    await tester.scrollUntilVisible(
      find.text('2 h de 2 h'),
      200,
      scrollable: find.ancestor(
        of: find.text('Total de horas: 2 h'),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('0 h de 1 h'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Lunes: 8:00 a. m. a 10:00 a. m. · clases de IF0009 · 2 h'),
      200,
      scrollable: find.ancestor(
        of: find.text('Total de horas: 2 h'),
        matching: find.byType(Scrollable),
      ),
    );
    // Attention and planning are still missing: cannot validate.
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Validar'))
          .onPressed,
      isNull,
    );
  });
}
