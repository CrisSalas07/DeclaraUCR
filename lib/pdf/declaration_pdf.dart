import 'dart:typed_data';

import 'package:declara_ucr/domain/oath_text.dart';
import 'package:declara_ucr/domain/time_rules.dart';
import 'package:declara_ucr/models/declaration_document.dart';
import 'package:declara_ucr/models/weekday.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// The declaration PDF on the official form of the Oficina de Recursos
/// Humanos, "Declaración jurada de horario y jornada de trabajo": the same
/// document the web of the Proyecto 1 prints (`PdfBuilderService` of
/// DeclaraHorario), built here from the same stored data.
///
/// Landscape letter page with the person's data, the appointments at the
/// university and the other institutions (per day, "De"/"A"), observations,
/// the oath and the recorded signatures. The signature is NOT presented as a
/// certified digital signature.
///
/// Latin-1 text only (the default font): accents and "ñ" are fine.
abstract final class DeclarationPdf {
  // Widths of the columns of the schedule tables, in points. Together they
  // fill the landscape letter page minus its margins and frame.
  static const double _workplaceWidth = 108;
  static const double _positionWidth = 72;
  static const double _workdayWidth = 46;
  static const double _dateWidth = 44;
  static const double _timeWidth = 35;
  static const double _pageWidth = 734;

  /// Height of one line of the tables.
  static const double _line = 13;

  static const PdfColor _headerFill = PdfColor.fromInt(0xFFBFBFBF);
  static const PdfColor _border = PdfColors.black;

  /// The bytes of the PDF of [document]. Its [DeclarationDocument.kind]
  /// says which one: a "BORRADOR" preview without signatures, an
  /// "EN REVISIÓN" copy with the signatures so far, or the final document.
  /// [logo] (PNG) goes in the corner of the form; without it the space is
  /// left blank.
  static Future<Uint8List> build(
    DeclarationDocument document, {
    Uint8List? logo,
  }) {
    final kind = document.kind ?? DocumentKind.preview;
    final draft = kind == DocumentKind.preview;
    final review = kind == DocumentKind.review;
    final signatures = draft
        ? const <DocumentSignature>[]
        : document.signatures;
    final hash =
        document.contentHash ??
        (signatures.isEmpty ? null : signatures.first.contentHash);

    final pdf = pw.Document(
      title: 'Declaración jurada de horario y jornada de trabajo',
      author: 'DeclaraUCR',
    );
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.letter.landscape,
          margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 24),
          buildForeground: draft
              ? (_) => _watermark('BORRADOR', 96)
              : review
              ? (_) => _watermark('EN REVISIÓN', 80)
              : null,
        ),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 6),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Versión ${document.versionNumber}'
                  '${hash == null ? '' : ' · huella SHA-256 $hash'}'
                  ' · Generado por DeclaraUCR. Firma electrónica interna; '
                  'no equivale a una firma digital certificada.',
                  style: const pw.TextStyle(
                    fontSize: 6.5,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 6.5,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),
        build: (context) => [
          if (draft)
            _notice(
              'VISTA PREVIA - BORRADOR SIN FIRMAS. No es el documento '
              'oficial: el documento oficial lo genera Recursos Humanos con '
              'las firmas registradas.',
            ),
          if (review)
            _notice(
              'COPIA PARA REVISIÓN. Aún falta la aprobación de Recursos '
              'Humanos: el documento final es el que lleva su firma.',
            ),
          _title(logo),
          ..._person(document.person),
          _band(
            'A continuación declaro los horarios y jornadas convenidos con:',
            fontSize: 8.5,
            align: pw.Alignment.centerLeft,
            height: 18,
          ),
          _band(
            'UNIVERSIDAD DE COSTA RICA (sea como docente y/o administrativo)',
          ),
          ..._table(document.appointments.map(_Job.new).toList(), minLines: 5),
          _band('OTRAS INSTITUCIONES PÚBLICAS, PRIVADAS Y FUNDACIONES'),
          ..._table(document.externalJobs.map(_Job.new).toList(), minLines: 2),
          _observations(document.observations),
          _row([
            _cell(
              _pageWidth,
              null,
              OathText.of(document),
              fontSize: 8,
              align: pw.Alignment.topLeft,
              padding: const pw.EdgeInsets.fromLTRB(4, 4, 4, 10),
            ),
          ]),
          _signatures(document, signatures),
        ],
      ),
    );
    return pdf.save();
  }

  // ------------------------------------------------------------ formats

  /// A cédula as its 9 digits ("1-234-567" -> "102340567"); a passport
  /// only loses its spaces and hyphens (`IdentificationFormat.document`).
  static String document(String identification) {
    final text = identification.trim();
    final grouped = RegExp(r'^(\d)[\s-]+(\d{1,4})[\s-]+(\d{1,4})$')
        .firstMatch(text);
    if (grouped != null) {
      return '${grouped[1]}'
          '${grouped[2]!.padLeft(4, '0')}'
          '${grouped[3]!.padLeft(4, '0')}';
    }
    return text.replaceAll(RegExp(r'[\s-]'), '');
  }

  /// "88887777" -> "8888-7777"; anything else is left as it is.
  static String phone(String phone) {
    final digits = phone.trim();
    return RegExp(r'^\d{8}$').hasMatch(digits)
        ? '${digits.substring(0, 4)}-${digits.substring(4)}'
        : digits;
  }

  /// "10-8-2026", the validity of an appointment. The stored dates are
  /// midnight in Costa Rica (UTC-6), so the day is read in local time.
  static String _shortDate(DateTime date) {
    final d = date.toLocal();
    return '${d.day}-${d.month}-${d.year}';
  }

  /// "05/08/2026".
  static String _date(DateTime date) {
    final d = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  // ------------------------------------------------------------ the form

  /// Emblem, institution and title of the form.
  static pw.Widget _title(Uint8List? logo) => _row(
    [
      pw.Container(
        width: 120,
        height: 78,
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.all(4),
        child: logo == null
            ? null
            : pw.Image(pw.MemoryImage(logo), fit: pw.BoxFit.contain),
      ),
      pw.Expanded(
        child: pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(4, 6, 4, 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'UNIVERSIDAD DE COSTA RICA',
                style: pw.TextStyle(
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Oficina de Recursos Humanos',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 14),
              pw.Center(
                child: pw.Text(
                  'DECLARACIÓN JURADA DE HORARIO Y JORNADA DE TRABAJO',
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
    top: true,
    right: true,
  );

  /// Name, identification, career, email and phone of the person.
  static List<pw.Widget> _person(DocumentPerson person) {
    const labelWidth = 180.0;
    const valueWidth = 360.0;
    const restWidth = _pageWidth - labelWidth - valueWidth;
    final label = pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold);
    final value = pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold);
    const data = pw.TextStyle(fontSize: 8.5);

    pw.Widget box(
      double width,
      String text,
      pw.TextStyle style, {
      pw.Alignment align = pw.Alignment.centerLeft,
    }) => pw.Container(
      width: width,
      height: 15,
      alignment: align,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4),
      decoration: _cellBorder(),
      child: pw.Text(text, style: style, maxLines: 1),
    );

    return [
      _row([
        pw.Container(
          width: _pageWidth,
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.fromLTRB(4, 1, 110, 0),
          child: pw.Text(
            'Número de teléfono: ${phone(person.phone)}',
            style: const pw.TextStyle(fontSize: 6),
          ),
        ),
      ], right: true),
      _row([
        box(labelWidth, 'Nombre del funcionario(a):', label),
        box(valueWidth, person.fullName, value, align: pw.Alignment.center),
        box(restWidth, 'Cédula: ${document(person.identification)}', data),
      ]),
      _row([
        box(labelWidth, 'Carrera:', label),
        box(valueWidth, person.unitName, value, align: pw.Alignment.center),
        box(restWidth, 'Correo electrónico: ${person.email}', data),
      ]),
    ];
  }

  /// Header and rows of one schedule table. Rows of the same workplace share
  /// its cell; empty lines are added until there are [minLines].
  static List<pw.Widget> _table(List<_Job> jobs, {required int minLines}) {
    final rows = <pw.Widget>[_tableHeader()];
    var lines = 0;

    // Consecutive jobs at the same workplace are grouped under one cell.
    final groups = <List<_Job>>[];
    for (final job in jobs) {
      if (groups.isNotEmpty &&
          groups.last.first.workplace.trim() == job.workplace.trim()) {
        groups.last.add(job);
      } else {
        groups.add([job]);
      }
    }

    for (final group in groups) {
      final total = group.fold<int>(0, (sum, job) => sum + job.lines);
      lines += total;
      rows.add(
        _row([
          _cell(_workplaceWidth, total * _line, group.first.workplace),
          pw.Column(children: [for (final job in group) _jobRow(job)]),
        ]),
      );
    }

    for (; lines < minLines; lines++) {
      rows.add(_row([_cell(_workplaceWidth, _line, ''), _jobRow(null)]));
    }
    return rows;
  }

  /// Two-line header: data of the job, "Vigencia" and each day with its
  /// "De" and "A" columns.
  static pw.Widget _tableHeader() {
    pw.Widget twoLevels(
      String title,
      String left,
      String right,
      double partWidth,
    ) => pw.Column(
      children: [
        _cell(
          partWidth * 2,
          _line * 1.4,
          title,
          bold: true,
          fill: true,
          fontSize: 8.5,
        ),
        pw.Row(
          children: [
            _cell(partWidth, _line * 1.4, left, bold: true, fill: true),
            _cell(partWidth, _line * 1.4, right, bold: true, fill: true),
          ],
        ),
      ],
    );

    return _row([
      _cell(
        _workplaceWidth,
        _line * 2.8,
        'Lugar de Trabajo',
        bold: true,
        fill: true,
      ),
      _cell(
        _positionWidth,
        _line * 2.8,
        'Cargo o\nCategoría',
        bold: true,
        fill: true,
      ),
      _cell(
        _workdayWidth,
        _line * 2.8,
        'Jornada\nde Trabajo',
        bold: true,
        fill: true,
        fontSize: 6.5,
      ),
      pw.Column(
        children: [
          _cell(
            _dateWidth * 2,
            _line * 1.4,
            'Vigencia del\nnombramiento',
            bold: true,
            fill: true,
            fontSize: 6,
          ),
          pw.Row(
            children: [
              _cell(_dateWidth, _line * 1.4, 'Desde', bold: true, fill: true),
              _cell(_dateWidth, _line * 1.4, 'Hasta', bold: true, fill: true),
            ],
          ),
        ],
      ),
      for (final day in Weekday.values)
        twoLevels(day.title, 'De', 'A', _timeWidth),
    ]);
  }

  /// Position, workday, validity and the ranges of each day of [job]; an
  /// empty line when [job] is `null`.
  static pw.Widget _jobRow(_Job? job) {
    final lines = job?.lines ?? 1;
    final height = lines * _line;
    final ranges = job?.rangesByDay ?? const <Weekday, List<(int, int)>>{};

    String time(Weekday day, int line, bool start) {
      final list = ranges[day];
      if (list == null || line >= list.length) return '';
      return TimeRules.format(start ? list[line].$1 : list[line].$2);
    }

    return pw.Row(
      children: [
        _cell(_positionWidth, height, job?.position ?? ''),
        _cell(_workdayWidth, height, job?.workday ?? '', fontSize: 8.5),
        _cell(_dateWidth, height, job == null ? '' : _shortDate(job.from)),
        _cell(_dateWidth, height, job == null ? '' : _shortDate(job.to)),
        for (final day in Weekday.values)
          pw.Column(
            children: [
              for (var i = 0; i < lines; i++)
                pw.Row(
                  children: [
                    _cell(_timeWidth, _line, time(day, i, true), fontSize: 8),
                    _cell(_timeWidth, _line, time(day, i, false), fontSize: 8),
                  ],
                ),
            ],
          ),
      ],
    );
  }

  /// "Observaciones:" and one line per line of [observations] (at least
  /// three).
  static pw.Widget _observations(String observations) {
    final lines = observations
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    while (lines.length < 3) {
      lines.add('');
    }
    const labelWidth = 180.0;
    // A table row makes the label as tall as the lines, which may wrap.
    return _row([
      pw.SizedBox(
        width: _pageWidth,
        child: pw.Table(
          columnWidths: const {
            0: pw.FixedColumnWidth(labelWidth),
            1: pw.FlexColumnWidth(),
          },
          children: [
            pw.TableRow(
              verticalAlignment: pw.TableCellVerticalAlignment.full,
              children: [
                pw.Container(
                  alignment: pw.Alignment.bottomCenter,
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  decoration: _cellBorder(),
                  child: pw.Text(
                    'Observaciones:',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Column(
                  children: [
                    for (final line in lines)
                      pw.Container(
                        width: double.infinity,
                        constraints: const pw.BoxConstraints(minHeight: 15),
                        alignment: pw.Alignment.centerLeft,
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 3,
                        ),
                        decoration: _cellBorder(),
                        child: pw.Text(
                          line,
                          style: const pw.TextStyle(fontSize: 6.5),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ]);
  }

  /// Signature lines of the declarant, the reviewer and HR, and the date of
  /// the declaration.
  static pw.Widget _signatures(
    DeclarationDocument document,
    List<DocumentSignature> signatures,
  ) {
    final byType = {for (final s in signatures) s.type: s};
    final declared =
        byType[SignatureType.declarant]?.signedAt ??
        document.createdAt ??
        DateTime.now();

    pw.Widget column(SignatureType type, String role) {
      final signature = byType[type];
      final signedAt = signature?.signedAt;
      return pw.Expanded(
        child: pw.Column(
          children: [
            pw.Text(
              signature?.fullName ?? ' ',
              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              signature == null
                  ? '_______________________________'
                  : signedAt == null
                  ? 'Firmado electrónicamente'
                  : 'Firmado electrónicamente el ${_date(signedAt)}',
              style: const pw.TextStyle(fontSize: 7),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              role,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return _row([
      pw.Container(
        width: _pageWidth,
        padding: const pw.EdgeInsets.fromLTRB(4, 14, 4, 6),
        decoration: _cellBorder(),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            column(
              SignatureType.declarant,
              'Firma del Funcionario(a)\nDeclarante',
            ),
            column(SignatureType.superior, 'Revisor\nCarrera'),
            column(SignatureType.hr, 'Oficina de\nRecursos Humanos'),
            pw.SizedBox(
              width: 110,
              child: pw.Column(
                children: [
                  pw.Text(
                    _date(declared),
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text('Fecha', style: const pw.TextStyle(fontSize: 7)),
                ],
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  // ------------------------------------------------------------- helpers

  /// One line of the form: [children] side by side with the left border of
  /// the frame. The cells draw their own right border; lines without cells
  /// ask for the frame's with [right], and the first line for its [top].
  static pw.Widget _row(
    List<pw.Widget> children, {
    bool top = false,
    bool right = false,
  }) => pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border(
        left: const pw.BorderSide(color: _border, width: 0.6),
        top: top
            ? const pw.BorderSide(color: _border, width: 0.6)
            : pw.BorderSide.none,
        right: right
            ? const pw.BorderSide(color: _border, width: 0.6)
            : pw.BorderSide.none,
      ),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    ),
  );

  /// A full-width band with bold [text].
  static pw.Widget _band(
    String text, {
    double fontSize = 11,
    pw.Alignment align = pw.Alignment.center,
    double height = 22,
  }) => _row([
    _cell(
      _pageWidth,
      height,
      text,
      bold: true,
      fontSize: fontSize,
      align: align,
    ),
  ]);

  /// Lines on the right and bottom of a cell; the frame draws the rest.
  static pw.BoxDecoration _cellBorder({bool fill = false}) => pw.BoxDecoration(
    color: fill ? _headerFill : null,
    border: const pw.Border(
      right: pw.BorderSide(color: _border, width: 0.5),
      bottom: pw.BorderSide(color: _border, width: 0.5),
    ),
  );

  /// A cell of [width] and [height] (`null` grows with the text).
  static pw.Widget _cell(
    double width,
    double? height,
    String text, {
    bool bold = false,
    bool fill = false,
    double fontSize = 7,
    pw.Alignment align = pw.Alignment.center,
    pw.EdgeInsets padding = const pw.EdgeInsets.symmetric(horizontal: 2),
  }) => pw.Container(
    width: width,
    height: height,
    alignment: align,
    padding: padding,
    decoration: _cellBorder(fill: fill),
    child: pw.Text(
      text,
      textAlign: align == pw.Alignment.center
          ? pw.TextAlign.center
          : pw.TextAlign.left,
      maxLines: height == null ? null : (height / (fontSize + 1.5)).floor(),
      style: pw.TextStyle(
        fontSize: fontSize,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );

  /// Large diagonal [text] over the page, light enough to read through.
  static pw.Widget _watermark(String text, double size) => pw.Center(
    child: pw.Transform.rotate(
      angle: 0.45,
      child: pw.Opacity(
        opacity: 0.15,
        child: pw.Text(
          text,
          softWrap: false,
          style: pw.TextStyle(
            fontSize: size,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.red800,
          ),
        ),
      ),
    ),
  );

  /// Boxed warning at the top of the first page.
  static pw.Widget _notice(String text) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(5),
    margin: const pw.EdgeInsets.only(bottom: 6),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.red800),
    ),
    child: pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 8, color: PdfColors.red800),
    ),
  );
}

/// One appointment or job as rows of the form.
class _Job {
  _Job(DocumentJob job)
    : workplace = job.workplace,
      position = job.position,
      workday = job.workload,
      from = job.from,
      to = job.to,
      rangesByDay = _ranges(job.blocks);

  final String workplace;
  final String position;
  final String workday;
  final DateTime from;
  final DateTime to;

  /// Time ranges of each day, in order, with touching blocks joined (a
  /// lesson followed by attention is one range from start to end).
  final Map<Weekday, List<(int, int)>> rangesByDay;

  /// Lines the job takes: the most ranges in one day, at least one (two
  /// when its position or workplace needs a second line).
  int get lines => rangesByDay.values.fold<int>(
    position.length > 16 || workplace.length > 26 ? 2 : 1,
    (most, ranges) => ranges.length > most ? ranges.length : most,
  );

  static Map<Weekday, List<(int, int)>> _ranges(List<DocumentBlock> blocks) {
    final byDay = <Weekday, List<(int, int)>>{};
    final ordered = [...blocks]
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    for (final block in ordered) {
      final ranges = byDay.putIfAbsent(block.day, () => <(int, int)>[]);
      if (ranges.isNotEmpty && block.startMinutes <= ranges.last.$2) {
        final last = ranges.removeLast();
        ranges.add((
          last.$1,
          block.endMinutes > last.$2 ? block.endMinutes : last.$2,
        ));
      } else {
        ranges.add((block.startMinutes, block.endMinutes));
      }
    }
    return byDay;
  }
}
