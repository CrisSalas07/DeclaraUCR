import 'package:declara_ucr/domain/schedule_observations.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/schedule_task.dart';
import 'package:declara_ucr/models/weekday.dart';
import 'package:flutter_test/flutter_test.dart';

ScheduleInterval _at(Weekday day, int from, int to) => ScheduleInterval(
  id: '${day.number}-$from',
  day: day,
  startMinutes: from * 60,
  endMinutes: to * 60,
  task: ScheduleTask(TaskKind.lesson, 'IF0004'),
);

void main() {
  // The official form (U-10): "HC: L 8 am a 12 pm y M 1 pm a 5 pm".
  test('two ranges are joined with "y", like the official form', () {
    expect(
      ScheduleObservations.ranges([
        _at(Weekday.wednesday, 13, 17),
        _at(Weekday.monday, 8, 12),
      ]),
      'L 8 am a 12 pm y M 1 pm a 5 pm',
    );
  });

  test('three or more ranges: commas, and "y" before the last one', () {
    expect(
      ScheduleObservations.ranges([
        _at(Weekday.monday, 8, 10),
        _at(Weekday.tuesday, 8, 10),
        _at(Weekday.thursday, 13, 15),
      ]),
      'L 8 am a 10 am, K 8 am a 10 am y J 1 pm a 3 pm',
    );
  });

  test('a single range stays as it is', () {
    expect(
      ScheduleObservations.ranges([_at(Weekday.friday, 7, 9)]),
      'V 7 am a 9 am',
    );
  });
}
