import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Whether the phone has a network (DIP: screens and state never import
/// the plugin). Having a network does not guarantee the server answers:
/// saves also have a time limit and check the server first.
abstract class NetworkStatus {
  /// `true` while there is a network; emits the current value first.
  Stream<bool> watchOnline();

  /// Whether there is a network right now.
  Future<bool> isOnline();
}

/// [NetworkStatus] from the `connectivity_plus` plugin.
class PluginNetworkStatus implements NetworkStatus {
  PluginNetworkStatus([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _online(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async {
    try {
      return _online(await _connectivity.checkConnectivity());
    } catch (_) {
      // Unknown: let the save try; its time limit still applies.
      return true;
    }
  }

  @override
  Stream<bool> watchOnline() async* {
    yield await isOnline();
    yield* _connectivity.onConnectivityChanged.map(_online).distinct();
  }
}

/// No network checks (web, tests): always online.
class AlwaysOnline implements NetworkStatus {
  const AlwaysOnline();

  @override
  Future<bool> isOnline() async => true;

  @override
  Stream<bool> watchOnline() => Stream.value(true);
}

/// The server could not be reached (no network, or it did not answer).
/// Nothing was written: the changes are still on the screen.
class OfflineException implements Exception {
  const OfflineException();

  static const String message =
      'Sin conexión. Sus cambios siguen en pantalla: guárdelos cuando '
      'vuelva la señal.';

  @override
  String toString() => message;
}
