import 'package:declara_ucr/domain/time_rules.dart';
import 'package:declara_ucr/domain/workload_catalog.dart';
import 'package:declara_ucr/models/zonaje_request.dart';
import 'package:declara_ucr/screens/declarations_screen.dart' show EmptyMessage;
import 'package:declara_ucr/state/loadable.dart';
import 'package:declara_ucr/theme/ucr_theme.dart';
import 'package:declara_ucr/widgets/common.dart';
import 'package:declara_ucr/widgets/tour_anchor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Zonaje, read only: the status of the person's requests and HR's answer.
/// The request itself is made in the web system of the Proyecto 1, which
/// asks for the home on a map and the TSE certificate (adaptation decision:
/// no map in the phone).
class ZonajeScreen extends StatelessWidget {
  const ZonajeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loaded = context.watch<Loadable<List<ZonajeRequest>>>();
    final requests = loaded.value ?? const <ZonajeRequest>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Zonaje')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const InfoBanner(
            icon: Icons.info_outline,
            title: 'La solicitud se hace en el sistema web',
            lines: [
              'Allí se indica el domicilio y se adjunta la certificación del '
                  'TSE. Aquí puede ver el estado de sus solicitudes y la '
                  'respuesta de Recursos Humanos.',
            ],
          ),
          const SizedBox(height: 16),
          if (loaded.loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (loaded.failed)
            const EmptyMessage(
              icon: Icons.cloud_off_outlined,
              title: 'No se pudieron cargar sus solicitudes.',
              body: 'Revise la conexión y vuelva a abrir la aplicación.',
            )
          else if (requests.isEmpty)
            const EmptyMessage(
              icon: Icons.directions_car_outlined,
              title: 'Aún no tiene solicitudes de zonaje.',
              body: 'Cuando la envíe desde el sistema web, aparecerá aquí.',
            )
          else
            for (final (i, r) in requests.indexed)
              TourAnchor(
                id: 'zonaje.card.$i',
                child: _RequestCard(request: r),
              ),
        ],
      ),
    );
  }
}

/// "2026_II" → "II Ciclo - 2026", as the period names of the Proyecto 1.
String periodLabel(String? periodId) {
  final match = RegExp(r'^(\d{4})_(I{1,3})$').firstMatch(periodId ?? '');
  if (match == null) return periodId ?? 'Sin período';
  return '${match[2]} Ciclo - ${match[1]}';
}

String _km(double km) =>
    '${km.toStringAsFixed(km.truncateToDouble() == km ? 0 : 1).replaceAll('.', ',')} km';

/// Color of each status, readable with dark ink (as the declaration chips).
Color _statusColor(ZonajeStatus status, ColorScheme scheme) => switch (status) {
  ZonajeStatus.requested => UcrColors.skyBlue,
  ZonajeStatus.approved => UcrColors.green,
  ZonajeStatus.rejected => scheme.errorContainer,
  ZonajeStatus.annulled => scheme.surfaceContainerHighest,
};

class _ZonajeStatusChip extends StatelessWidget {
  const _ZonajeStatusChip(this.status);

  final ZonajeStatus status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: _statusColor(status, Theme.of(context).colorScheme),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status.label,
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: UcrColors.ink),
    ),
  );
}

/// One request with everything the person needs to know about it.
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final ZonajeRequest request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final text = Theme.of(context).textTheme;
    return SectionCard(
      icon: Icons.directions_car_outlined,
      title: 'Zonaje · ${periodLabel(r.periodId)}',
      subtitle: 'Enviada el ${formatDate(r.createdAt)}',
      trailing: _ZonajeStatusChip(r.status),
      children: [
        ReadOnlyLine(label: 'Domicilio anterior', value: r.previousAddress),
        ReadOnlyLine(label: 'Domicilio actual', value: r.currentAddress),
        ReadOnlyLine(
          label: 'Distancia declarada',
          value: _km(r.declaredDistanceKm),
        ),
        if (r.confirmedDistanceKm != null)
          ReadOnlyLine(
            label: 'Distancia confirmada por RRHH',
            value: _km(r.confirmedDistanceKm!),
          ),
        ReadOnlyLine(
          label: 'Jornada asignada',
          value:
              WorkloadCatalog.labelFor(r.weeklyMinutes) ??
              TimeRules.hoursLabel(r.weeklyMinutes),
        ),
        ReadOnlyLine(label: 'Régimen salarial', value: r.regime.label),
        if (r.status == ZonajeStatus.rejected &&
            (r.hrObservation ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          InfoBanner(
            icon: Icons.comment_outlined,
            tone: BannerTone.error,
            title: 'Observación de Recursos Humanos',
            lines: [
              r.hrObservation!,
              'Puede corregirla y reenviarla desde el sistema web.',
            ],
          ),
        ],
        if (r.status == ZonajeStatus.annulled &&
            (r.annulReason ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          InfoBanner(
            icon: Icons.block_outlined,
            title: 'Motivo de la anulación',
            lines: [r.annulReason!],
          ),
        ],
        if (r.status == ZonajeStatus.requested)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Recursos Humanos de su sede la está revisando.',
              style: text.bodySmall,
            ),
          ),
      ],
    );
  }
}

/// One zonaje request in the history: period, distance and status.
class ZonajeRequestTile extends StatelessWidget {
  const ZonajeRequestTile({super.key, required this.request});

  final ZonajeRequest request;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: const Icon(Icons.directions_car_outlined, color: UcrColors.blue),
      title: Text('Zonaje · ${periodLabel(request.periodId)}'),
      subtitle: Text(
        '${formatDate(request.createdAt)} · ${_km(request.distanceKm)}',
      ),
      trailing: _ZonajeStatusChip(request.status),
    ),
  );
}
