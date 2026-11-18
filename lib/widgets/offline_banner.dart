import 'package:declara_ucr/theme/ucr_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Whether the phone has a network, provided above the app.
class Connection {
  const Connection({required this.online});

  final bool online;
}

/// Wraps every screen (`MaterialApp.builder`): without a network, a strip
/// on top says so, and that the lists show what the phone kept. The strip
/// takes the status bar inset, so the screen below does not add it again.
class OfflineFrame extends StatelessWidget {
  const OfflineFrame({super.key, required this.child});

  final Widget child;

  static const String message =
      'Sin conexión: ve lo último guardado en el teléfono. Para guardar '
      'cambios necesita conexión.';

  @override
  Widget build(BuildContext context) {
    final online = context.watch<Connection?>()?.online ?? true;
    if (online) return child;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Semantics(
          liveRegion: true,
          container: true,
          child: Material(
            color: UcrColors.ink,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      color: UcrColors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message,
                        style: text.bodySmall?.copyWith(color: UcrColors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}
