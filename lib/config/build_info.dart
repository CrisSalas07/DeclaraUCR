import 'package:declara_ucr/config/firebase_config.dart';

/// Which build is running, as `tool/build_apk.dart` stamps it with
/// `--dart-define`. Shown in the app so every test session and every report
/// names the exact version (Proyecto 2, sections 6 and 8).
abstract final class BuildInfo {
  static const String version = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: 'desarrollo',
  );

  static const String commit = String.fromEnvironment(
    'GIT_COMMIT',
    defaultValue: 'local',
  );

  /// "Versión 2.0.0+2 · 78dd6ee", plus the backend when it is not the real one.
  static String get label {
    final backend = FirebaseConfig.useEmulators ? ' · emuladores' : '';
    return 'Versión $version · $commit$backend';
  }
}
