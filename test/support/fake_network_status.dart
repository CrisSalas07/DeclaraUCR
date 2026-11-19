import 'dart:async';

import 'package:declara_ucr/data/network_status.dart';

/// [NetworkStatus] the test turns on and off.
class FakeNetworkStatus implements NetworkStatus {
  FakeNetworkStatus({this._online = true});

  bool _online;
  final _changes = StreamController<bool>.broadcast();

  set online(bool value) {
    _online = value;
    _changes.add(value);
  }

  @override
  Future<bool> isOnline() async => _online;

  @override
  Stream<bool> watchOnline() async* {
    yield _online;
    yield* _changes.stream;
  }
}
