import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/data/onboarding_store.dart';
import 'package:declara_ucr/data/profile_repository.dart';
import 'package:declara_ucr/data/proyecto1/declaration_document_reader.dart';
import 'package:declara_ucr/data/proyecto1/declaration_signer.dart';
import 'package:declara_ucr/data/proyecto1/period_repository.dart';
import 'package:declara_ucr/data/zonaje_repository.dart';
import 'package:declara_ucr/models/app_user.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/models/schedule_task.dart';
import 'package:declara_ucr/models/weekday.dart';
import 'package:declara_ucr/models/workload_items.dart';
import 'package:declara_ucr/models/zonaje_request.dart';
import 'package:declara_ucr/state/loadable.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// A made-up teacher for the guided tour: the real screens are shown with
/// her data, and nothing she "does" is stored anywhere.
abstract final class DemoSession {
  static const user = AppUser(
    uid: 'demo',
    email: 'ana.vargas@ucr.ac.cr',
    displayName: 'Ana Lucía Vargas Mora',
  );

  static const profile = UserProfile(
    fullName: 'Ana Lucía Vargas Mora',
    identification: '112340567',
    phone: '88881234',
    email: 'ana.vargas@ucr.ac.cr',
    campusId: 'demo',
    unitId: 'demo',
    superiorUid: 'demo-superior',
  );

  static final period = Period(
    id: '2026_II',
    name: 'II Ciclo - 2026',
    startDate: DateTime(2026, 8, 10),
    endDate: DateTime(2026, 12, 5),
    enabled: true,
  );

  static const _programming = CourseLoad(
    name: 'Programación I',
    code: 'IF1300',
    workloadMinutes: 600,
  );
  static const _databases = CourseLoad(
    name: 'Bases de datos',
    code: 'IF4100',
    workloadMinutes: 600,
  );
  static const _project = ProjectHours(
    name: 'Alfabetización digital en comunidades',
    weeklyMinutes: 240,
  );
  static const _school = ExternalJob(
    institution: 'Colegio Técnico Profesional de Upala',
    type: InstitutionType.public,
    position: 'Profesor',
    weeklyMinutes: 360,
  );

  static const _lessons = [
    LessonSlot(
      day: Weekday.monday,
      startMinutes: 8 * 60,
      endMinutes: 10 * 60,
      course: 'Programación I',
    ),
    LessonSlot(
      day: Weekday.wednesday,
      startMinutes: 8 * 60,
      endMinutes: 10 * 60,
      course: 'Programación I',
    ),
    LessonSlot(
      day: Weekday.tuesday,
      startMinutes: 13 * 60,
      endMinutes: 15 * 60,
      course: 'Bases de datos',
    ),
    LessonSlot(
      day: Weekday.thursday,
      startMinutes: 13 * 60,
      endMinutes: 15 * 60,
      course: 'Bases de datos',
    ),
  ];

  /// Every hour placed, lessons included, so the summary has nothing to
  /// correct.
  static List<ScheduleInterval> _intervals() {
    var n = 0;
    ScheduleInterval at(Weekday day, int from, int to, ScheduleTask task) =>
        ScheduleInterval(
          id: 'demo-${n++}',
          day: day,
          startMinutes: from * 60,
          endMinutes: to * 60,
          task: task,
        );
    const p = 'Programación I', b = 'Bases de datos';
    return [
      for (final s in _lessons)
        ScheduleInterval(
          id: 'demo-${n++}',
          day: s.day,
          startMinutes: s.startMinutes,
          endMinutes: s.endMinutes,
          task: ScheduleTask(TaskKind.lesson, s.course),
        ),
      at(Weekday.monday, 10, 11, const ScheduleTask(TaskKind.attention, p)),
      at(Weekday.wednesday, 10, 11, const ScheduleTask(TaskKind.attention, p)),
      at(Weekday.friday, 8, 12, const ScheduleTask(TaskKind.planning, p)),
      at(Weekday.tuesday, 15, 16, const ScheduleTask(TaskKind.attention, b)),
      at(Weekday.thursday, 15, 16, const ScheduleTask(TaskKind.attention, b)),
      at(Weekday.monday, 13, 17, const ScheduleTask(TaskKind.planning, b)),
      at(
        Weekday.wednesday,
        13,
        17,
        ScheduleTask(TaskKind.project, _project.name),
      ),
      at(
        Weekday.saturday,
        8,
        12,
        ScheduleTask(TaskKind.external, _school.institution),
      ),
      at(
        Weekday.friday,
        13,
        15,
        ScheduleTask(TaskKind.external, _school.institution),
      ),
    ];
  }

  /// The declaration of this cycle, in [status].
  static Declaration declaration(DeclarationStatus status) => Declaration(
    id: 'demo-2026-II',
    declarantName: profile.fullName,
    identification: profile.identification,
    position: 'Adjunto',
    validFrom: period.startDate,
    validTo: period.endDate,
    courses: [_programming, _databases],
    projects: [_project],
    externalJobs: [_school],
    notes: 'Los sábados imparto lecciones en el colegio.',
    intervals: _intervals(),
    status: status,
    updatedAt: DateTime(2026, 8, 20),
    periodId: period.id,
    periodName: period.name,
    lessonSlots: _lessons,
  );

  /// Last cycle's, already through the whole process.
  static Declaration get _previous => declaration(DeclarationStatus.closed)
    ..id = 'demo-2026-I'
    ..periodId = '2026_I'
    ..periodName = 'I Ciclo - 2026'
    ..validFrom = DateTime(2026, 3, 9)
    ..validTo = DateTime(2026, 7, 4)
    ..updatedAt = DateTime(2026, 7, 10);

  static List<Declaration> get declarations => [
    declaration(DeclarationStatus.draft),
    _previous,
  ];

  static final zonaje = [
    ZonajeRequest(
      id: 'demo-zonaje',
      periodId: '2026_I',
      previousAddress: 'San José, Montes de Oca, San Pedro',
      currentAddress: 'Alajuela, Upala, Upala',
      declaredDistanceKm: 245,
      confirmedDistanceKm: 245,
      regime: SalaryRegime.composite,
      weeklyMinutes: 1200,
      status: ZonajeStatus.approved,
      createdAt: DateTime(2026, 3, 16),
      hrObservation: 'Distancia confirmada con la certificación del TSE.',
      reviewedAt: DateTime(2026, 3, 30),
    ),
  ];

  /// What the signed-in screens read, with this teacher's data. Put below
  /// the real providers, it shadows them.
  static List<SingleChildWidget> providers() {
    final declarations = _DemoDeclarations(DemoSession.declarations);
    return [
      Provider<OnboardingStore>.value(value: MemoryOnboardingStore()),
      Provider<AppUser?>.value(value: user),
      Provider<PeriodRepository>.value(value: _DemoPeriods()),
      Provider<DeclarationRepository>.value(value: declarations),
      Provider<ZonajeRepository>.value(value: _DemoZonaje()),
      Provider<DeclarationDocumentReader>.value(value: const _NoDocuments()),
      Provider<DeclarationSigner>.value(value: const _NoSigning()),
      Provider<Loadable<UserProfile?>>.value(
        value: const Loadable.data(profile),
      ),
      Provider<UserProfile?>.value(value: profile),
      Provider<Loadable<List<Declaration>>>.value(
        value: Loadable.data(declarations.items),
      ),
      Provider<Loadable<List<ZonajeRequest>>>.value(
        value: Loadable.data(zonaje),
      ),
    ];
  }
}

/// Reads the demo data; saving keeps nothing.
class _DemoDeclarations implements DeclarationRepository {
  _DemoDeclarations(this.items);

  final List<Declaration> items;

  @override
  Stream<List<Declaration>> watchAll() => Stream.value(items);

  @override
  Future<Declaration?> getById(String id) async =>
      items.where((d) => d.id == id).firstOrNull;

  @override
  Future<String> save(Declaration declaration) async =>
      declaration.id ?? 'demo-new';
}

class _DemoPeriods implements PeriodRepository {
  @override
  Future<List<Period>> openPeriods() async => [DemoSession.period];

  @override
  Future<Period?> getById(String id) async => DemoSession.period;

  @override
  Future<WorkloadAssignment?> assignmentFor(String periodId) async =>
      WorkloadAssignment(
        periodId: periodId,
        courses: const [DemoSession._programming, DemoSession._databases],
        slots: DemoSession._lessons,
      );
}

class _DemoZonaje implements ZonajeRepository {
  @override
  Stream<List<ZonajeRequest>> watchAll() => Stream.value(DemoSession.zonaje);
}

/// The tour never opens a PDF nor signs: its screens do not take taps.
class _NoDocuments implements DeclarationDocumentReader {
  const _NoDocuments();

  @override
  Future<DeclarationDocument> read(String id) =>
      throw UnsupportedError('Demo data has no documents');
}

class _NoSigning implements DeclarationSigner {
  const _NoSigning();

  @override
  Future<void> signAndSend(String id, {required String oathText}) =>
      throw UnsupportedError('Demo data is never signed');
}
