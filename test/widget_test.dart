import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/data/profile_repository.dart';
import 'package:declara_ucr/data/zonaje_repository.dart';
import 'package:declara_ucr/main.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth_repository.dart';

const _ana = UserProfile(name: 'Ana Pérez Mora', identification: '105430987');

/// The app over an in-memory Firestore. [withProfile] gives the signed-in
/// test user a profile, as after a normal sign-up.
Future<Widget> _app({
  AppUserMode mode = AppUserMode.signedOut,
  bool withProfile = true,
}) async {
  final firestore = FakeFirebaseFirestore();
  final profiles = FirestoreProfileRepository(firestore);
  if (withProfile) {
    await profiles.save(FakeAuthRepository.verifiedUser.uid, _ana);
  }
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
    testWidgets('signed out: shows the login screen', (tester) async {
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();

      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Nueva declaración'), findsNothing);
    });

    testWidgets('rejects a non-institutional e-mail before calling Firebase', (
      tester,
    ) async {
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo institucional'),
        'ana@gmail.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña'),
        'x',
      );
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(
        find.text('Use su correo institucional @ucr.ac.cr.'),
        findsOneWidget,
      );
    });

    testWidgets('wrong password shows a generic error', (tester) async {
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo institucional'),
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
        find.widgetWithText(TextFormField, 'Correo institucional'),
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

    testWidgets('creating an account asks the cédula and opens the home', (
      tester,
    ) async {
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();
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
        find.widgetWithText(TextFormField, 'Correo institucional'),
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

      expect(find.text('Hola, Luis'), findsOneWidget);
      expect(find.text('302220333'), findsOneWidget);
    });

    testWidgets('signing up with a taken cédula asks for another one', (
      tester,
    ) async {
      // Ana's profile already holds 105430987.
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();
      for (final (label, value) in [
        ('Nombre completo', 'Luis Mora'),
        ('Número de cédula', '105430987'),
        ('Correo institucional', 'luis.mora@ucr.ac.cr'),
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
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.text('Hola, Luis'), findsOneWidget);
    });

    testWidgets('an account without cédula completes it once', (tester) async {
      await tester.pumpWidget(
        await _app(mode: AppUserMode.signedIn, withProfile: false),
      );
      await tester.pumpAndSettle();
      expect(find.text('Complete su perfil'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Número de cédula'),
        '105430987',
      );
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Hola, Ana'), findsOneWidget);
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
