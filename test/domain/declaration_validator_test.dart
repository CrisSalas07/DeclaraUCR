import 'package:declara_ucr/domain/declaration_validator.dart';
import 'package:declara_ucr/domain/schedule_observations.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/schedule_task.dart';
import 'package:declara_ucr/models/validation_issue.dart';
import 'package:declara_ucr/models/weekday.dart';
import 'package:declara_ucr/models/workload_items.dart';
import 'package:flutter_test/flutter_test.dart';

/// 1/8 TC: 2 h lessons, 1 h attention, 2 h planning.
const redes = CourseLoad(name: 'Redes', code: 'IF0009', workloadMinutes: 300);

ScheduleInterval interval(
  String id,
  int start,
  int end, {
  Weekday day = Weekday.monday,
  TaskKind kind = TaskKind.lesson,
  String name = 'Redes',
}) => ScheduleInterval(
  id: id,
  day: day,
  startMinutes: start,
  endMinutes: end,
  task: ScheduleTask(kind, name),
);

/// The hours of [redes], all placed: HC Mon 8-10, AE Mon 10-11, PyE Tue 8-10.
List<ScheduleInterval> placed() => [
  interval('hc', 8 * 60, 10 * 60),
  interval('ae', 10 * 60, 11 * 60, kind: TaskKind.attention),
  interval(
    'pye',
    8 * 60,
    10 * 60,
    day: Weekday.tuesday,
    kind: TaskKind.planning,
  ),
];

/// Complete declaration with fictitious data and the course [redes].
Declaration complete(List<ScheduleInterval> intervals) => Declaration(
  declarantName: 'Ana Pérez Mora',
  identification: '105430987',
  position: 'Adjunto',
  appointmentType: 'Interino',
  validFrom: DateTime(2026, 3, 1),
  validTo: DateTime(2026, 7, 31),
  courses: [redes],
  intervals: intervals,
);

void main() {
  const validator = DeclarationValidator();

  test('a course derives its hours from the workday (Cuadro 5)', () {
    expect(
      [redes.lessonMinutes, redes.attentionMinutes, redes.planningMinutes],
      [120, 60, 120],
    );
    const full = CourseLoad(name: 'X', code: '', workloadMinutes: 2400);
    expect(
      [full.lessonMinutes, full.attentionMinutes, full.planningMinutes],
      [960, 480, 960],
    );
  });

  test('every hour placed makes the declaration valid', () {
    final d = complete(placed());

    expect(validator.issues(d), isEmpty);
    expect(validator.isValid(d), isTrue);
    expect(d.totalMinutes, 5 * 60);
  });

  test('mandatory case: Monday 8:00-12:00 and 11:00-14:00 overlap', () {
    final d =
        complete([
            interval('a', 8 * 60, 12 * 60),
            interval(
              'b',
              11 * 60,
              14 * 60,
              kind: TaskKind.external,
              name: 'MEP',
            ),
          ])
          ..externalJobs.add(
            const ExternalJob(
              institution: 'MEP',
              type: InstitutionType.public,
              position: 'Docente',
              weeklyMinutes: 180,
            ),
          );

    final overlaps = validator
        .scheduleIssues(d)
        .where((i) => i.conflictStartMinutes != null)
        .toList();

    expect(overlaps, hasLength(1));
    expect(overlaps.single.day, Weekday.monday);
    expect(overlaps.single.conflictStartMinutes, 11 * 60);
    expect(overlaps.single.conflictEndMinutes, 12 * 60);
    expect(overlaps.single.message, contains('11:00-12:00'));
    expect(validator.isValid(d), isFalse);
  });

  test('missing and extra hours of a task are reported', () {
    final d = complete([
      interval('hc', 8 * 60, 11 * 60),
      interval(
        'pye',
        8 * 60,
        10 * 60,
        day: Weekday.tuesday,
        kind: TaskKind.planning,
      ),
    ]);

    final messages = validator.scheduleIssues(d).map((i) => i.message);

    expect(messages, contains('Sobran 1 h de clases de IF0009 en el horario.'));
    expect(
      messages,
      contains('Faltan 1 h de atención a estudiantes de IF0009 en el horario.'),
    );
  });

  test('blocks of a course no longer declared are reported', () {
    final d = complete(placed())
      ..intervals.add(
        interval('x', 14 * 60, 15 * 60, day: Weekday.friday, name: 'Viejo'),
      );

    expect(
      validator.scheduleIssues(d).map((i) => i.message),
      contains(contains('ya no está en la declaración')),
    );
  });

  test('the validity lasts at least one calendar month', () {
    final short = complete(placed())..validTo = DateTime(2026, 3, 31);
    final month = complete(placed())..validTo = DateTime(2026, 4, 1);

    expect(
      validator.scheduleIssues(short).single.message,
      contains('01/04/2026'),
    );
    expect(validator.isValid(month), isTrue);
  });

  test('more than one full time at the university is refused', () {
    final d = complete(placed())
      ..courses.add(
        const CourseLoad(name: 'Otro', code: '', workloadMinutes: 2400),
      );

    expect(
      validator.fieldIssues(d).map((i) => i.message),
      contains(contains('superan el tiempo completo')),
    );
  });

  test('cannot validate without intervals', () {
    expect(
      validator.scheduleIssues(complete([])).single.code,
      ValidationIssueCode.emptySchedule,
    );
  });

  test('lists the pending required fields', () {
    final missing = validator.missingFields(Declaration());

    expect(missing, contains('Cédula'));
    expect(missing, contains('Cursos o proyectos'));
    expect(missing, hasLength(7));
  });

  test('an identification that is not a cédula blocks validation', () {
    final d = complete(placed())..identification = '1-1111-1111';

    expect(
      validator.fieldIssues(d).single.code,
      ValidationIssueCode.invalidField,
    );
    expect(validator.isValid(d), isFalse);
  });

  test('a position outside the list blocks validation', () {
    final d = complete(placed())..position = 'Rector';

    expect(validator.isValid(d), isFalse);
  });

  test('observations follow the official format', () {
    final d = complete(placed())..notes = 'Sin cambios.';

    expect(
      ScheduleObservations.compose(d),
      'IF0009 HC: L 8 am a 10 am. AE: L 10 am a 11 am. PyE: K 8 am a 10 am.\n'
      'Otras observaciones: Sin cambios.',
    );
  });
}
