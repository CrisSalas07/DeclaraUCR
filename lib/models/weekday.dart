/// Working days that can be declared: Monday to Saturday. SHARED CONTRACT.
enum Weekday {
  /// Monday.
  monday(1, 'lunes'),

  /// Tuesday.
  tuesday(2, 'martes'),

  /// Wednesday.
  wednesday(3, 'miércoles'),

  /// Thursday.
  thursday(4, 'jueves'),

  /// Friday.
  friday(5, 'viernes'),

  /// Saturday.
  saturday(6, 'sábado');

  const Weekday(this.number, this.label);

  /// 1 = Monday ... 6 = Saturday (value stored in Firestore).
  final int number;

  /// Spanish name in lower case, for sentences ("el lunes"). The only list
  /// of day names in the app: messages, grids and the PDF use it instead of
  /// [name], which is English.
  final String label;

  /// [label] with a capital letter, for headings and lists ("Lunes").
  String get title => label[0].toUpperCase() + label.substring(1);

  /// Returns the day with [number]; throws an [ArgumentError] outside 1..6.
  static Weekday fromNumber(int number) => Weekday.values.firstWhere(
    (day) => day.number == number,
    orElse: () => throw ArgumentError('Invalid weekday number: $number'),
  );
}
