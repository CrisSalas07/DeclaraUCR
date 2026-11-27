import 'package:declara_ucr/data/demo_session.dart';
import 'package:declara_ucr/domain/declaration_validator.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the tour teacher has a complete, valid declaration', () {
    const validator = DeclarationValidator();
    final d = DemoSession.declaration(DeclarationStatus.draft);
    expect(validator.missingFields(d), isEmpty);
    expect(validator.issues(d).map((i) => i.message), isEmpty);
  });
}
