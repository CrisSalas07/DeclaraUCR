import 'package:declara_ucr/data/zonaje_repository.dart';
import 'package:declara_ucr/domain/time_rules.dart';
import 'package:declara_ucr/domain/zonaje_eligibility.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/declaration_status.dart';
import 'package:declara_ucr/models/zonaje_request.dart';
import 'package:declara_ucr/state/loadable.dart';
import 'package:declara_ucr/theme/ucr_theme.dart';
import 'package:declara_ucr/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Zonaje request (Reglamento General de Zonaje y Bonificación): the
/// person writes both homes and the distance, picks the salary regime and
/// whether they receive bonificación. The workday comes from the courses
/// of their latest VALIDADA declaration, never typed. The rules R16 to R19
/// are checked as they fill it in; HR review is out of scope.
class ZonajeScreen extends StatefulWidget {
  const ZonajeScreen({super.key});

  @override
  State<ZonajeScreen> createState() => _ZonajeScreenState();
}

class _ZonajeScreenState extends State<ZonajeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _previous = TextEditingController();
  final _current = TextEditingController();
  final _distance = TextEditingController();
  SalaryRegime? _regime;
  bool _hasBonus = false;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_previous, _current, _distance]) {
      c.dispose();
    }
    super.dispose();
  }

  double? get _km => double.tryParse(_distance.text.replaceAll(',', '.'));

  String? _address(String? v) {
    final text = (v ?? '').trim();
    if (text.isEmpty) return 'Este campo es obligatorio.';
    if (text.length < 10) return 'Escriba provincia, cantón y distrito.';
    return null;
  }

  String? _distanceError(String? _) {
    final km = _km;
    if (km == null) return 'Escriba la distancia en kilómetros.';
    if (km <= 0 || km > ZonajeLimits.maxDistanceKm) {
      return 'Use un valor entre 1 y ${ZonajeLimits.maxDistanceKm.toInt()} km.';
    }
    return null;
  }

  Future<void> _send(Declaration source) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<ZonajeRepository>().send(
        ZonajeRequest(
          previousAddress: _previous.text,
          currentAddress: _current.text,
          distanceKm: (_km! * 10).roundToDouble() / 10,
          regime: _regime!,
          hasBonus: _hasBonus,
          weeklyMinutes: source.coursesMinutes,
          declarationId: source.id!,
        ),
      );
      _formKey.currentState!.reset();
      for (final c in [_previous, _current, _distance]) {
        c.clear();
      }
      setState(() {
        _regime = null;
        _hasBonus = false;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Solicitud de zonaje enviada.')),
      );
    } catch (e) {
      debugPrint('Sending zonaje failed: $e');
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo enviar. Revise la conexión e intente de '
            'nuevo.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final declarations =
        context.watch<Loadable<List<Declaration>>>().value ??
        const <Declaration>[];
    final requests =
        context.watch<Loadable<List<ZonajeRequest>>>().value ??
        const <ZonajeRequest>[];
    final validated = declarations
        .where((d) => d.status == DeclarationStatus.validated && d.id != null)
        .toList();
    final source = validated.isEmpty ? null : validated.first;
    final pending = requests.any((r) => r.status == ZonajeStatus.requested);
    final reasons = _regime == null || _km == null
        ? null
        : ZonajeEligibility.check(
            regime: _regime!,
            distanceKm: _km!,
            weeklyMinutes: source?.coursesMinutes ?? 0,
            hasBonus: _hasBonus,
          );
    final canSend =
        source != null && !pending && reasons != null && reasons.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Zonaje')),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (source == null)
              const InfoBanner(
                icon: Icons.info_outline,
                title: 'Valide primero una declaración',
                lines: [
                  'La jornada para el zonaje se toma de los cursos de su '
                      'declaración validada más reciente.',
                ],
              )
            else
              InfoBanner(
                icon: Icons.schedule_outlined,
                title:
                    'Jornada en cursos: '
                    '${TimeRules.hoursLabel(source.coursesMinutes)}',
                lines: const ['De su declaración validada más reciente.'],
                tone: BannerTone.success,
              ),
            if (pending) ...[
              const SizedBox(height: 12),
              const InfoBanner(
                icon: Icons.hourglass_top_outlined,
                title: 'Ya tiene una solicitud SOLICITADA',
                lines: ['Espere la revisión de Recursos Humanos.'],
              ),
            ],
            const SizedBox(height: 16),
            SectionCard(
              icon: Icons.home_outlined,
              title: 'Domicilios',
              children: [
                TextFormField(
                  controller: _previous,
                  maxLength: ZonajeLimits.maxAddressLength,
                  minLines: 1,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Domicilio anterior *',
                    hintText: 'Provincia, cantón, distrito y señas',
                  ),
                  validator: _address,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _current,
                  maxLength: ZonajeLimits.maxAddressLength,
                  minLines: 1,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Domicilio actual *',
                    hintText: 'Provincia, cantón, distrito y señas',
                  ),
                  validator: _address,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _distance,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Distancia entre domicilios (km) *',
                    helperText: 'Recursos Humanos la confirmará.',
                    suffixText: 'km',
                  ),
                  validator: _distanceError,
                ),
                const SizedBox(height: 16),
              ],
            ),
            SectionCard(
              icon: Icons.payments_outlined,
              title: 'Condición salarial',
              children: [
                DropdownButtonFormField<SalaryRegime>(
                  initialValue: _regime,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Régimen salarial *',
                  ),
                  items: [
                    for (final r in SalaryRegime.values)
                      DropdownMenuItem(value: r, child: Text(r.label)),
                  ],
                  validator: (v) => v == null ? 'Seleccione una opción.' : null,
                  onChanged: (v) => setState(() => _regime = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Recibo bonificación'),
                  value: _hasBonus,
                  onChanged: (v) => setState(() => _hasBonus = v),
                ),
              ],
            ),
            SectionCard(
              icon: Icons.rule_outlined,
              title: 'Requisitos',
              subtitle: 'Reglamento de Zonaje y Bonificación',
              children: [
                _Rule(
                  'Salario compuesto',
                  _regime == null ? null : _regime == SalaryRegime.composite,
                ),
                _Rule(
                  'Más de ${ZonajeLimits.minDistanceKm.toInt()} km entre '
                  'domicilios',
                  _km == null ? null : _km! > ZonajeLimits.minDistanceKm,
                ),
                _Rule(
                  'Jornada de al menos ½ tiempo (20 h)',
                  (source?.coursesMinutes ?? 0) >=
                      ZonajeLimits.minWeeklyMinutes,
                ),
                _Rule('Sin bonificación', !_hasBonus),
                if (reasons != null && reasons.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final r in reasons)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        ZonajeEligibility.message(r),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 8),
              ],
            ),
            FilledButton.icon(
              onPressed: canSend && !_busy ? () => _send(source) : null,
              icon: const Icon(Icons.send_outlined),
              label: const Text('Enviar solicitud'),
            ),
            const SizedBox(height: 24),
            if (requests.isNotEmpty) ...[
              Text(
                'Mis solicitudes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final r in requests) ZonajeRequestTile(request: r),
            ],
          ],
        ),
      ),
    );
  }
}

/// A requirement with a check, a cross, or a dash while unknown.
class _Rule extends StatelessWidget {
  const _Rule(this.label, this.met);

  final String label;
  final bool? met;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            met == null
                ? Icons.remove_circle_outline
                : met!
                ? Icons.check_circle
                : Icons.cancel_outlined,
            size: 20,
            color: met == null
                ? scheme.outline
                : met!
                ? UcrColors.blue
                : scheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

/// One zonaje request: date, distance and status.
class ZonajeRequestTile extends StatelessWidget {
  const ZonajeRequestTile({super.key, required this.request});

  final ZonajeRequest request;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: const Icon(Icons.directions_car_outlined, color: UcrColors.blue),
      title: Text(
        'Zonaje · ${request.distanceKm.toString().replaceAll('.', ',')} km',
      ),
      subtitle: Text(
        '${formatDate(request.createdAt)} · '
        '${TimeRules.hoursLabel(request.weeklyMinutes)} en cursos',
      ),
      trailing: Text(
        request.status.value,
        style: Theme.of(context).textTheme.labelLarge,
      ),
    ),
  );
}
