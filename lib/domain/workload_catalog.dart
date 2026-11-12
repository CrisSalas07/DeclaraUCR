/// A workday and its length in weekly minutes.
class WorkloadOption {
  const WorkloadOption({required this.label, required this.weeklyMinutes});

  final String label;
  final int weeklyMinutes;

  /// "1/8 TC = 5 h".
  String get title => '$label = ${weeklyMinutes ~/ 60} h';
}

/// The one table of workdays of the app, reused from DeclaraHorario
/// (`WorkloadCatalog`): Guía de nombramiento §4.1 d (VD-12928-2024), from
/// 1/8 to 1 full time (TC = 40 hours). Pure Dart.
abstract final class WorkloadCatalog {
  static const List<WorkloadOption> options = <WorkloadOption>[
    WorkloadOption(label: '1/8 TC', weeklyMinutes: 5 * 60),
    WorkloadOption(label: '1/4 TC', weeklyMinutes: 10 * 60),
    WorkloadOption(label: '3/8 TC', weeklyMinutes: 15 * 60),
    WorkloadOption(label: '1/2 TC', weeklyMinutes: 20 * 60),
    WorkloadOption(label: '5/8 TC', weeklyMinutes: 25 * 60),
    WorkloadOption(label: '3/4 TC', weeklyMinutes: 30 * 60),
    WorkloadOption(label: '7/8 TC', weeklyMinutes: 35 * 60),
    WorkloadOption(label: '1 TC', weeklyMinutes: 40 * 60),
  ];

  /// Most weekly hours at the university: one full time.
  static const int maxUniversityMinutes = 40 * 60;

  /// Most weekly hours at other institutions together: 1/2 TC.
  static const int maxExternalMinutes = 20 * 60;

  /// Workdays that still fit when [usedMinutes] of [limitMinutes] are
  /// taken.
  static List<WorkloadOption> fitting(int usedMinutes, int limitMinutes) => [
    for (final option in options)
      if (usedMinutes + option.weeklyMinutes <= limitMinutes) option,
  ];

  /// "1/2 TC" for 1200, or `null` when no workday has that length.
  static String? labelFor(int weeklyMinutes) {
    for (final option in options) {
      if (option.weeklyMinutes == weeklyMinutes) return option.label;
    }
    return null;
  }
}
