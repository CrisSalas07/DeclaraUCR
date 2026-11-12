import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/zonaje_request.dart';

/// The declarant's history: declarations and zonaje requests by year,
/// newest first (DeclaraHorario `DeclarantHistory`, without periods: the
/// year is the start of the validity). Pure Dart.
abstract final class DeclarantHistory {
  static int? yearOfDeclaration(Declaration d) =>
      d.validFrom?.year ?? d.updatedAt?.year;

  /// Every year with a declaration or a request, newest first.
  static List<int> years(
    List<Declaration> declarations,
    List<ZonajeRequest> requests,
  ) {
    final years = <int>{
      ...declarations.map(yearOfDeclaration).nonNulls,
      ...requests.map((r) => r.createdAt?.year).nonNulls,
    };
    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  /// The [declarations] of [year] (any year when `null`), newest first.
  static List<Declaration> declarationsOf(
    List<Declaration> declarations, {
    int? year,
  }) =>
      declarations
          .where((d) => year == null || yearOfDeclaration(d) == year)
          .toList()
        ..sort(
          (a, b) => _newestFirst(
            a.validFrom ?? a.updatedAt,
            b.validFrom ?? b.updatedAt,
          ),
        );

  /// The zonaje [requests] of [year] (any year when `null`), newest first.
  static List<ZonajeRequest> requestsOf(
    List<ZonajeRequest> requests, {
    int? year,
  }) =>
      requests.where((r) => year == null || r.createdAt?.year == year).toList()
        ..sort((a, b) => _newestFirst(a.createdAt, b.createdAt));

  static int _newestFirst(DateTime? a, DateTime? b) =>
      (b ?? DateTime(0)).compareTo(a ?? DateTime(0));
}
