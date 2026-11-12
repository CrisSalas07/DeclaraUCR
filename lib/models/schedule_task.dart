/// What a block of the weekly schedule is for. [code] is the abbreviation
/// of the official form (DeclaraHorario `ScheduleObservations`): HC = horas
/// clase, AE = atención a estudiantes, PyE = planificación y evaluación.
enum TaskKind {
  lesson('HC', 'Clases'),
  attention('AE', 'Atención'),
  planning('PyE', 'Planificación'),
  project('PROY', 'Proyecto'),
  external('EXT', 'Otra institución');

  const TaskKind(this.code, this.label);

  /// Stored in Firestore and used in the observations.
  final String code;

  /// Short Spanish name for chips.
  final String label;

  bool get isCourse => this == lesson || this == attention || this == planning;

  static TaskKind fromCode(String code) => TaskKind.values.firstWhere(
    (kind) => kind.code == code,
    orElse: () => throw ArgumentError('Unknown TaskKind: $code'),
  );
}

/// One thing the declarant places on the grid: [kind] of the course,
/// project or institution called [name] ("AE" of "Redes").
class ScheduleTask {
  const ScheduleTask(this.kind, this.name);

  final TaskKind kind;
  final String name;

  /// Label of the grid cells: "AE|Redes".
  String get key => '${kind.code}|$name';

  static ScheduleTask fromKey(String key) {
    final separator = key.indexOf('|');
    if (separator < 0) throw ArgumentError('Invalid task key: $key');
    return ScheduleTask(
      TaskKind.fromCode(key.substring(0, separator)),
      key.substring(separator + 1),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ScheduleTask && other.kind == kind && other.name == name;

  @override
  int get hashCode => Object.hash(kind, name);
}
