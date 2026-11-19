import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/domain/content_hash.dart';
import 'package:flutter_test/flutter_test.dart';

// The same documents given to ContentHashService of DeclaraHorario: blocks
// with and without category or course, an empty course, projects, an
// external job without weeklyMinutes, accents, "ñ", line breaks and
// unsorted lists.
Map<String, dynamic> fixtureVersion() => {
  'number': 2,
  'declarantSnapshot': {
    'fullName': 'Ana Mora Solís',
    'identification': '105430987',
    'phone': '88887777',
    'email': 'ana@ucr.ac.cr',
    'unitName': 'Informática Empresarial',
    'campusName': 'Recinto de Golfito',
  },
  'observations': 'Lunes: clases de IF0009.\nÑandú «comillas» y acentos áéí.',
};

List<Map<String, dynamic>> fixtureAppointments() => [
  {
    'workplace': 'Universidad de Costa Rica · Recinto de Golfito · Informática',
    'position': 'Interino',
    'workload': '1/2 TC',
    'startDate': Timestamp.fromDate(DateTime.utc(2026, 8, 10, 6)),
    'endDate': Timestamp.fromDate(DateTime.utc(2026, 12, 5, 6)),
    'blocks': [
      {
        'day': 3,
        'startMinutes': 600,
        'endMinutes': 660,
        'category': 'attention',
        'course': 'IF0009',
      },
      {
        'day': 1,
        'startMinutes': 480,
        'endMinutes': 600,
        'category': 'lesson',
        'course': 'IF0009',
      },
      {'day': 2, 'startMinutes': 780, 'endMinutes': 840},
      {
        'day': 2,
        'startMinutes': 840,
        'endMinutes': 900,
        'category': 'planning',
        'course': '',
      },
    ],
    'projects': [
      {'name': 'TCU 650', 'weeklyMinutes': 120},
      {'name': 'Acción social', 'weeklyMinutes': 60},
    ],
  },
  {
    'workplace': 'Universidad de Costa Rica · Recinto de Golfito · Informática',
    'position': 'Propietario',
    'workload': '1/8 TC',
    'startDate': Timestamp.fromDate(DateTime.utc(2026, 8, 10, 6)),
    'endDate': Timestamp.fromDate(DateTime.utc(2026, 12, 5, 6)),
    'blocks': [],
  },
];

List<Map<String, dynamic>> fixtureExternalJobs() => [
  {
    'institution': 'Colegio de Golfito',
    'institutionType': 'public',
    'position': 'Docente',
    'workload': '1/4 TC',
    'weeklyMinutes': 600,
    'startDate': Timestamp.fromDate(DateTime.utc(2026, 8, 10, 6)),
    'endDate': Timestamp.fromDate(DateTime.utc(2026, 12, 5, 6)),
    'blocks': [
      {'day': 4, 'startMinutes': 780, 'endMinutes': 1080},
    ],
  },
  {
    'institution': 'Fundación Sur',
    'institutionType': 'foundation',
    'position': 'Asesora',
    'workload': '1/8 TC',
    'startDate': Timestamp.fromDate(DateTime.utc(2026, 8, 10, 6)),
    'endDate': Timestamp.fromDate(DateTime.utc(2026, 12, 5, 6)),
    'blocks': [
      {'day': 6, 'startMinutes': 480, 'endMinutes': 780},
    ],
  },
];

void main() {
  test('gives exactly the hash of DeclaraHorario (Proyecto 1)', () {
    // Computed by DeclaraHorario's ContentHashService (commit 2affc13) on
    // the same documents. If this changes, signatures made in the phone
    // would carry a different fingerprint than the web's.
    expect(
      ContentHash.of(
        version: fixtureVersion(),
        appointments: fixtureAppointments(),
        externalJobs: fixtureExternalJobs(),
      ),
      'f993ef050ad0aa524aa873067110d3d350272c7e2d0e04193c5dc177087db8a3',
    );
  });

  test('the order the documents are read in does not matter', () {
    String hash(bool reversed) => ContentHash.of(
      version: fixtureVersion(),
      appointments: reversed
          ? fixtureAppointments().reversed.toList()
          : fixtureAppointments(),
      externalJobs: reversed
          ? fixtureExternalJobs().reversed.toList()
          : fixtureExternalJobs(),
    );
    expect(hash(true), hash(false));
  });

  test('any change in the content changes the hash', () {
    final changed = fixtureVersion()..['observations'] = 'Otra cosa';
    expect(
      ContentHash.of(
        version: changed,
        appointments: fixtureAppointments(),
        externalJobs: fixtureExternalJobs(),
      ),
      isNot('f993ef050ad0aa524aa873067110d3d350272c7e2d0e04193c5dc177087db8a3'),
    );
  });
}
