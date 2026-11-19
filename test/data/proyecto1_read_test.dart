import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/data/proyecto1/period_repository.dart';
import 'package:declara_ucr/data/proyecto1/proyecto1_declaration_repository.dart';
import 'package:declara_ucr/data/proyecto1/proyecto1_mapper.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/models/schedule_task.dart';
import 'package:declara_ucr/models/weekday.dart';
import 'package:declara_ucr/models/workload_items.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Documents written as DeclaraHorario (Proyecto 1) writes them.
Future<void> _seed(FakeFirebaseFirestore db) async {
  Timestamp at(int month, int day) =>
      Timestamp.fromDate(DateTime.utc(2026, month, day, 6));

  await db.collection('periods').doc('2026_II').set({
    'name': 'II Ciclo - 2026',
    'startDate': at(8, 10),
    'endDate': at(12, 5),
    'enabled': true,
  });
  await db.collection('periods').doc('2026_I').set({
    'name': 'I Ciclo - 2026',
    'startDate': at(3, 9),
    'endDate': at(7, 4),
    'enabled': false,
  });
  await db.collection('workloadAssignments').doc('2026_II_ana').set({
    'declarantUid': 'ana',
    'periodId': '2026_II',
    'courses': [
      {
        'name': 'Desarrollo de Software IV',
        'code': 'IF0009',
        'courseId': 'if0009',
        'lessonMinutes': 180,
        'workloadMinutes': 600,
      },
    ],
    'slots': [
      {
        'day': 1,
        'startMinutes': 480,
        'endMinutes': 660,
        'course': 'Desarrollo de Software IV',
      },
    ],
  });

  final declaration = db.collection('declarations').doc('d1');
  await declaration.set({
    'declarantUid': 'ana',
    'declarantName': 'Ana Pérez Mora',
    'periodId': '2026_II',
    'superiorUid': 'rev',
    'campusId': 'sede-sur',
    'status': 'DEVUELTA',
    'currentVersionId': 'v2',
    'currentVersionNumber': 2,
    'pendingObservation': 'Falta la planificación del viernes.',
    'lastEventId': 'e9',
    'updatedAt': at(9, 1),
  });
  final version = declaration.collection('versions').doc('v2');
  await version.set({
    'number': 2,
    'declarantSnapshot': {
      'fullName': 'Ana Pérez Mora',
      'identification': '105430987',
      'phone': '88881234',
      'email': 'ana@ucr.ac.cr',
      'unitName': 'Informática Empresarial',
      'campusName': 'Sede del Sur',
    },
    'observations':
        'IF0009 HC: L 8 am a 11 am.\nOtras observaciones: Tutorías en línea.',
    'isLocked': false,
  });
  await version.collection('appointments').doc('a1').set({
    'workplace': 'Universidad de Costa Rica · Sede del Sur',
    'position': 'Adjunto',
    'workload': '1/4 TC',
    'startDate': at(8, 10),
    'endDate': at(12, 5),
    'blocks': [
      {
        'day': 1,
        'startMinutes': 480,
        'endMinutes': 660,
        'category': 'lesson',
        'course': 'Desarrollo de Software IV',
      },
      {
        'day': 2,
        'startMinutes': 480,
        'endMinutes': 570,
        'category': 'attention',
        'course': 'Desarrollo de Software IV',
      },
      {'day': 3, 'startMinutes': 780, 'endMinutes': 900, 'course': 'TCU'},
    ],
    'projects': [
      {'name': 'TCU', 'weeklyMinutes': 120},
    ],
  });
  await version.collection('externalJobs').doc('x1').set({
    'institution': 'MEP',
    'institutionType': 'public',
    'position': 'Docente',
    'workload': '1/8 TC',
    'weeklyMinutes': 300,
    'startDate': at(8, 10),
    'endDate': at(12, 5),
    'blocks': [
      {'day': 6, 'startMinutes': 480, 'endMinutes': 780},
    ],
  });

  // Someone else's declaration, and one that cannot be read.
  await db.collection('declarations').doc('other').set({
    'declarantUid': 'luis',
    'periodId': '2026_II',
    'status': 'BORRADOR',
    'currentVersionId': 'v1',
    'currentVersionNumber': 1,
  });
  await db.collection('declarations').doc('broken').set({
    'declarantUid': 'ana',
    'periodId': '2026_II',
    'status': 'BORRADOR',
    'currentVersionId': 'missing',
    'currentVersionNumber': 1,
  });
}

void main() {
  late FakeFirebaseFirestore db;
  late PeriodRepository periods;
  late Proyecto1DeclarationRepository repository;

  setUp(() async {
    db = FakeFirebaseFirestore();
    await _seed(db);
    periods = FirestorePeriodRepository(db, uid: 'ana');
    repository = Proyecto1DeclarationRepository(
      db,
      uid: 'ana',
      periods: periods,
    );
  });

  test('lists only open periods', () async {
    final open = await periods.openPeriods();
    expect(open.map((p) => p.id), ['2026_II']);
    expect(open.single.name, 'II Ciclo - 2026');
  });

  test('a period closed after a first read is no longer offered', () async {
    expect(await periods.openPeriods(), hasLength(1));
    await db.collection('periods').doc('2026_II').update({'enabled': false});
    expect(await periods.openPeriods(), isEmpty);
  });

  test('reads the assignment of the person, with its lesson slots', () async {
    final assignment = (await periods.assignmentFor('2026_II'))!;
    final course = assignment.courses.single;
    expect(course.shortName, 'IF0009');
    // The coordination's lesson hours, not the 2/5 rule (240 min).
    expect(course.lessonMinutes, 180);
    expect(course.attentionMinutes, 90);
    expect(course.planningMinutes, 330);
    expect(assignment.slots.single.day, Weekday.monday);
    expect(await periods.assignmentFor('2026_I'), isNull);
  });

  test('builds the declaration from its Proyecto 1 documents', () async {
    final list = await repository.watchAll().first;
    // Luis's is not listed and the broken one is skipped.
    expect(list.map((d) => d.id), ['d1']);
    final d = list.single;

    expect(d.status, DeclarationStatus.returned);
    expect(d.pendingObservation, 'Falta la planificación del viernes.');
    expect(d.periodId, '2026_II');
    expect(d.periodName, 'II Ciclo - 2026');
    expect(d.versionId, 'v2');
    expect(d.versionNumber, 2);
    expect(d.declarantName, 'Ana Pérez Mora');
    expect(d.identification, '105430987');
    expect(d.position, 'Adjunto');
    expect(d.validFrom, DateTime.utc(2026, 8, 10, 6).toLocal());
    expect(d.courses.single.name, 'Desarrollo de Software IV');
    expect(d.projects.single.name, 'TCU');
    expect(d.externalJobs.single.type, InstitutionType.public);
    expect(d.notes, 'Tutorías en línea.');

    final kinds = {for (final i in d.intervals) i.task.kind: i.task.name};
    expect(kinds, {
      TaskKind.lesson: 'Desarrollo de Software IV',
      TaskKind.attention: 'Desarrollo de Software IV',
      TaskKind.project: 'TCU',
      TaskKind.external: 'MEP',
    });
    expect(d.totalMinutes, 180 + 90 + 120 + 300);
  });

  test('getById only returns the person own declarations', () async {
    expect((await repository.getById('d1'))?.versionNumber, 2);
    expect(await repository.getById('other'), isNull);
    expect(await repository.getById('nope'), isNull);
  });

  test('notes are what follows "Otras observaciones"', () {
    expect(Proyecto1Mapper.notesOf('L 8 am a 10 am.'), '');
    expect(
      Proyecto1Mapper.notesOf('L 8 am.\nOtras observaciones: Nota 1'),
      'Nota 1',
    );
  });

  test('a course without lesson hours from the coordination uses 2/5', () {
    const course = CourseLoad(name: 'X', code: '', workloadMinutes: 600);
    expect(course.lessonMinutes, 240);
  });
}
