import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/domain/schedule_grid.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/schedule_task.dart';
import 'package:declara_ucr/models/workload_items.dart';
import 'package:declara_ucr/models/weekday.dart';
import 'package:declara_ucr/state/declaration_form_state.dart';
import 'package:flutter_test/flutter_test.dart';

List<GridCell> _range(Weekday day, int from, int to) => [
  for (var s = from; s < to; s += ScheduleGrid.stepMinutes) GridCell(day, s),
];

void main() {
  var n = 0;
  String id() => '${n++}';

  group('ScheduleGrid', () {
    test('joins contiguous cells with the same label, splits on change', () {
      final cells = {
        for (final c in _range(Weekday.monday, 8 * 60, 10 * 60)) c: 'HC|Redes',
        for (final c in _range(Weekday.monday, 10 * 60, 11 * 60)) c: 'EXT|MEP',
        for (final c in _range(Weekday.monday, 14 * 60, 15 * 60)) c: 'HC|Redes',
      };

      final intervals = ScheduleGrid.intervalsOf(cells, id);

      expect(
        intervals.map(
          (i) => '${i.task.name} ${i.startMinutes}-${i.endMinutes}',
        ),
        ['Redes 480-600', 'MEP 600-660', 'Redes 840-900'],
      );
    });

    test('round trip: intervals -> cells -> intervals', () {
      final original = [
        ScheduleInterval(
          id: 'a',
          day: Weekday.friday,
          startMinutes: 7 * 60 + 30,
          endMinutes: 11 * 60,
          task: const ScheduleTask(TaskKind.lesson, 'Redes'),
        ),
      ];

      final back = ScheduleGrid.intervalsOf(ScheduleGrid.cellsOf(original), id);

      expect(back.single.day, Weekday.friday);
      expect(back.single.startMinutes, 7 * 60 + 30);
      expect(back.single.endMinutes, 11 * 60);
    });

    test('older off-grid times are rounded outwards', () {
      final cells = ScheduleGrid.cellsOf([
        ScheduleInterval(
          id: 'a',
          day: Weekday.monday,
          startMinutes: 8 * 60 + 10,
          endMinutes: 9 * 60 + 5,
          task: const ScheduleTask(TaskKind.lesson, 'Redes'),
        ),
      ]);

      expect(cells.keys.map((c) => c.startMinutes), [480, 510, 540]);
    });
  });

  group('DeclarationFormState', () {
    late DeclarationFormState state;
    const hc = ScheduleTask(TaskKind.lesson, 'Redes');
    const pye = ScheduleTask(TaskKind.planning, 'Redes');
    setUp(() {
      state = DeclarationFormState(repository: _NoRepository());
      // 1 TC: 16 h lessons, 8 h attention, 16 h planning.
      state.saveCourse(
        const CourseLoad(name: 'Redes', code: 'IF0009', workloadMinutes: 2400),
      );
    });

    test('paints, erases and never places the lunch hour', () {
      expect(state.paint(_range(Weekday.monday, 11 * 60, 14 * 60), hc), isNull);
      expect(
        state.declaration.intervals.map(
          (i) => '${i.startMinutes}-${i.endMinutes}',
        ),
        ['660-720', '780-840'],
      );

      state.paint([const GridCell(Weekday.monday, 11 * 60)], null);
      expect(state.declaration.totalMinutes, 90);
    });

    test('refuses more than 10 hours in a day and keeps the schedule', () {
      state.paint(_range(Weekday.tuesday, 7 * 60, 12 * 60), hc);
      state.paint(_range(Weekday.tuesday, 13 * 60, 18 * 60), pye);

      final error = state.paint([
        const GridCell(Weekday.tuesday, 18 * 60),
      ], pye);

      expect(error, contains('10 horas'));
      expect(state.declaration.totalMinutes, 10 * 60);
    });

    test('never places more hours than the task has', () {
      state.saveCourse(
        const CourseLoad(name: 'Redes', code: 'IF0009', workloadMinutes: 300),
        index: 0,
      );
      expect(state.paint(_range(Weekday.monday, 8 * 60, 10 * 60), hc), isNull);

      final error = state.paint([const GridCell(Weekday.monday, 10 * 60)], hc);

      expect(error, 'Ya ubicó todas las horas de clases de IF0009 (2 h).');
      expect(state.declaration.totalMinutes, 2 * 60);
    });

    test('copyDay replaces the target days with the source day', () {
      state.paint(_range(Weekday.monday, 8 * 60, 10 * 60), hc);
      state.paint(_range(Weekday.wednesday, 15 * 60, 16 * 60), pye);

      state.copyDay(Weekday.monday, [Weekday.tuesday, Weekday.wednesday]);

      final byDay = {
        for (final i in state.declaration.intervals)
          i.day: '${i.task.key} ${i.startMinutes}-${i.endMinutes}',
      };
      expect(byDay[Weekday.tuesday], 'HC|Redes 480-600');
      expect(byDay[Weekday.wednesday], 'HC|Redes 480-600');
      expect(state.declaration.totalMinutes, 3 * 2 * 60);
    });

    test('renaming a course renames its blocks; removing it frees them', () {
      state.paint(_range(Weekday.monday, 8 * 60, 9 * 60), hc);

      state.saveCourse(
        const CourseLoad(
          name: 'Redes I',
          code: 'IF0009',
          workloadMinutes: 2400,
        ),
        index: 0,
      );
      expect(state.declaration.intervals.single.task.name, 'Redes I');

      state.removeCourse(0);
      expect(state.declaration.intervals, isEmpty);
    });

    test('a second course over the full time is refused', () {
      final error = state.saveCourse(
        const CourseLoad(name: 'Otro', code: '', workloadMinutes: 300),
      );

      expect(error, contains('superan el tiempo completo'));
      expect(state.declaration.courses, hasLength(1));
    });
  });
}

class _NoRepository implements DeclarationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
