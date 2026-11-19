import 'package:declara_ucr/models/declaration_status.dart';
import 'package:flutter/material.dart';

/// Where a declaration is in its journey, like a parcel tracker:
/// Elaboración → Firmada → Revisor → Recursos Humanos → Aprobada. The same
/// steps as the web of the Proyecto 1 (`DeclarationProgress` and
/// `StepProgress` of DeclaraHorario). The declarant signs in the phone or the
/// web; a returned declaration is corrected in the web (a new version).
///
/// Done steps have a check, the current one is highlighted, a returned
/// declaration shows its step in red and an annulled one has no progress.
class DeclarationProgress extends StatelessWidget {
  const DeclarationProgress({super.key, required this.status});

  final DeclarationStatus status;

  /// Steps of the process, in order (the visible names: "Revisor").
  static const List<String> steps = [
    'Elaboración',
    'Firmada',
    'Revisor',
    'Recursos Humanos',
    'Aprobada',
  ];

  /// Index of the current step of [status]; [steps].length when finished.
  static int currentStep(DeclarationStatus status) => switch (status) {
    DeclarationStatus.draft ||
    DeclarationStatus.validated ||
    DeclarationStatus.pendingDeclarantSignature ||
    DeclarationStatus.returned ||
    DeclarationStatus.annulled => 0,
    DeclarationStatus.signedByDeclarant ||
    DeclarationStatus.pendingSupervisorSignature => 2,
    DeclarationStatus.signedBySupervisor ||
    DeclarationStatus.sentToHr ||
    DeclarationStatus.receivedByHr => 3,
    DeclarationStatus.closed => steps.length,
  };

  /// One sentence for the person: where it is and what comes next.
  static String caption(DeclarationStatus status) => switch (status) {
    DeclarationStatus.draft => 'En elaboración: complete y valide su horario.',
    DeclarationStatus.validated ||
    DeclarationStatus.pendingDeclarantSignature =>
      'Validada: falta firmarla y enviarla a su revisor.',
    DeclarationStatus.signedByDeclarant ||
    DeclarationStatus.pendingSupervisorSignature =>
      'Firmada y enviada: su revisor la está revisando.',
    DeclarationStatus.signedBySupervisor || DeclarationStatus.sentToHr =>
      'Aprobada por su revisor: llegó a Recursos Humanos.',
    DeclarationStatus.receivedByHr =>
      'Recursos Humanos la recibió y la está revisando.',
    DeclarationStatus.closed => 'Aprobada y firmada por Recursos Humanos.',
    DeclarationStatus.returned =>
      'Devuelta con una observación: corríjala en el sistema web y envíela '
          'de nuevo.',
    DeclarationStatus.annulled => 'Anulada.',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final current = currentStep(status);
    final returned = status == DeclarationStatus.returned;
    final cancelled = status == DeclarationStatus.annulled;

    Color colorOf(int index) {
      if (cancelled) return scheme.outline;
      if (index < current) return scheme.primary;
      if (index == current) return returned ? scheme.error : scheme.primary;
      return scheme.outlineVariant;
    }

    /// The line that reaches step [index] is colored once it is reached.
    Color lineTo(int index) =>
        !cancelled && index <= current ? scheme.primary : scheme.outlineVariant;

    return Semantics(
      label:
          'Seguimiento: ${current >= steps.length
              ? 'Aprobada'
              : returned
              ? 'Devuelta'
              : steps[current]}. '
          '${caption(status)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            key: const ValueKey('declaration-progress'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < steps.length; i++)
                Expanded(
                  child: _Step(
                    label: i == current && returned ? 'Devuelta' : steps[i],
                    done: i < current && !cancelled,
                    active: i == current && !cancelled,
                    returned: returned,
                    color: colorOf(i),
                    lineBefore: i == 0 ? null : lineTo(i),
                    lineAfter: i == steps.length - 1 ? null : lineTo(i + 1),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            caption(status),
            style: text.bodyMedium?.copyWith(
              color: returned ? scheme.error : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.done,
    required this.active,
    required this.returned,
    required this.color,
    required this.lineBefore,
    required this.lineAfter,
  });

  final String label;
  final bool done;
  final bool active;
  final bool returned;
  final Color color;
  final Color? lineBefore;
  final Color? lineAfter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget line(Color? c) => Expanded(
      child: c == null ? const SizedBox() : Container(height: 3, color: c),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            line(lineBefore),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: done
                    ? color
                    : active
                    ? (returned
                          ? scheme.errorContainer
                          : scheme.primaryContainer)
                    : scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: active ? 3 : 2),
              ),
              child: Icon(
                done
                    ? Icons.check
                    : active && returned
                    ? Icons.undo
                    : active
                    ? Icons.circle
                    : null,
                size: 16,
                color: done
                    ? scheme.onPrimary
                    : returned
                    ? scheme.onErrorContainer
                    : scheme.onPrimaryContainer,
              ),
            ),
            line(lineAfter),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: active ? color : scheme.onSurfaceVariant,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
