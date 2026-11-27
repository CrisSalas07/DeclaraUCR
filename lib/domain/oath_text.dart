import 'package:declara_ucr/domain/time_rules.dart';
import 'package:declara_ucr/domain/workload_catalog.dart';
import 'package:declara_ucr/models/declaration_document.dart';

/// The text of the sworn declaration printed on the PDF, as DeclaraHorario
/// builds it (`OathText`, `OathTemplate` and `OathTextService`): once the
/// declarant signed, exactly the text they accepted; before, the
/// administrator's template (or the default one) filled with the data of
/// the declaration. Pure Dart.
abstract final class OathText {
  /// The oath of the official form (the Excel format of the university),
  /// word for word. It has no variables: the data of the person is already
  /// in the header of the PDF.
  static const String defaultTemplate =
      'Declaro bajo juramento que los datos proporcionados en este documento '
      'son ciertos y que conozco las sanciones establecidas por la '
      'legislación institucional y nacional vigentes, que se refieren a la '
      'declaración falsa u omisa de las jornadas y horarios laborales aquí '
      'consignados.';

  static final RegExp _variable = RegExp(r'\{([^{}\s]*)\}');

  /// The oath of [document].
  static String of(DeclarationDocument document) {
    final accepted = document.signatureOf(SignatureType.declarant)?.oathText;
    if (accepted != null && accepted.isNotEmpty) return accepted;
    final saved = document.oathTemplate?.trim();
    return fill(
      saved == null || saved.isEmpty ? defaultTemplate : saved,
      valuesFor(document),
    );
  }

  /// [template] with each `{variable}` replaced by its value in [values];
  /// unknown variables are left as they are.
  static String fill(String template, Map<String, String> values) => template
      .replaceAllMapped(_variable, (m) => values[m.group(1)] ?? m.group(0)!);

  /// The values of the variables for [document] (`OathTemplate.valuesFor`).
  static Map<String, String> valuesFor(DeclarationDocument document) {
    final person = document.person;
    final positions = <String>{
      for (final a in document.appointments)
        if (a.position.trim().isNotEmpty) a.position.trim(),
    };
    final workloads = <String>[
      for (final a in document.appointments)
        if (a.workload.trim().isNotEmpty) _workload(a.workload.trim()),
    ];
    final externalMinutes = document.externalJobs.fold<int>(
      0,
      (total, job) =>
          total +
          (job.weeklyMinutes ??
              job.blocks.fold<int>(
                0,
                (sum, b) => sum + (b.endMinutes - b.startMinutes),
              )),
    );
    return {
      'nombre': person.fullName,
      'cedula': person.identification,
      'puesto': positions.isEmpty
          ? 'persona funcionaria'
          : positions.join(' y '),
      'carrera': person.unitName,
      'sede': person.campusName,
      'periodo': document.periodName,
      'version': '${document.versionNumber}',
      'jornadaUcr': workloads.isEmpty ? '0 h' : workloads.join(' y '),
      'horasExternas': '${TimeRules.hoursLabel(externalMinutes)} por semana',
    };
  }

  /// "1/2 TC (20 h)" for a workday of the table; the text itself otherwise.
  static String _workload(String label) {
    for (final option in WorkloadCatalog.options) {
      if (option.label == label) {
        return '$label (${TimeRules.hoursLabel(option.weeklyMinutes)})';
      }
    }
    return label;
  }
}
