import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/main.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Small phone (360 x 690 dp): any overflow fails the test (test 05).
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1080, 2070);
    view.devicePixelRatio = 3;
  });

  testWidgets('test 03: saving without data flags the required fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      DeclaraUcrApp(
        repository: FirestoreDeclarationRepository(FakeFirebaseFirestore()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay declaraciones registradas.'), findsOneWidget);

    await tester.tap(find.text('Nueva declaración'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar borrador'));
    await tester.pumpAndSettle();

    expect(find.text('Este campo es obligatorio.'), findsWidgets);
    expect(find.textContaining('Faltan 7 campos obligatorios'), findsOneWidget);

    // Back to the list: the draft shows up with its status.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('BORRADOR'), findsOneWidget);
  });

  testWidgets('summary opens with one interval and no overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      DeclaraUcrApp(
        repository: FirestoreDeclarationRepository(FakeFirebaseFirestore()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva declaración'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Agregar intervalo'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Agregar intervalo'));
    await tester.pumpAndSettle();
    expect(find.text('Duración: 2 h'), findsOneWidget);

    await tester.tap(find.text('Ver resumen'));
    await tester.pumpAndSettle();
    final summaryList = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.text('Total de horas: 2 h'),
      200,
      scrollable: summaryList,
    );
    expect(
      find.text('Lunes: 8:00 a. m. a 10:00 a. m. · Sin institución · 2 h'),
      findsOneWidget,
    );
    // No institution nor data: cannot validate.
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Validar'))
          .onPressed,
      isNull,
    );
  });
}
