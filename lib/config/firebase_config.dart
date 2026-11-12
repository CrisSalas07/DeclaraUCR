import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Which Firebase backend the app talks to, chosen at build time.
///
/// - Default: local emulators (`demo-declaraucr`, no real data).
/// - `--dart-define=FIREBASE_ENV=production`: the hosted web app on
///   `cristopher-desarrollo-iv` (only the web platform is configured).
abstract final class FirebaseConfig {
  static const String _env = String.fromEnvironment(
    'FIREBASE_ENV',
    defaultValue: 'emulator',
  );

  static bool get useEmulators => _env != 'production';

  /// 10.0.2.2 is the host PC as seen from the Android emulator; in a browser
  /// it is localhost. Physical phone: `--dart-define=EMULATOR_HOST=<PC_IP>`.
  static String get emulatorHost =>
      const String.fromEnvironment('EMULATOR_HOST')
          .ifEmpty(kIsWeb ? 'localhost' : '10.0.2.2');

  static FirebaseOptions get options {
    if (useEmulators) return _emulatorOptions;
    if (!kIsWeb) {
      throw UnsupportedError('Production is only configured for the web.');
    }
    return _webProductionOptions;
  }

  /// `demo-*` project: the SDK only talks to the local emulators, never to
  /// real Firebase, so these options need no real keys.
  static const _emulatorOptions = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-declaraucr',
  );

  /// Firebase web config. The API key is a public project identifier, not a
  /// secret: access is enforced by Firebase Auth and `firestore.rules`.
  static const _webProductionOptions = FirebaseOptions(
    apiKey: 'AIzaSyCWti-Fe3zOGPmcsWOwj8eaQV88Of4bHF8',
    appId: '1:534637125174:web:acfdfaf1f8c520da5cc297',
    messagingSenderId: '534637125174',
    projectId: 'cristopher-desarrollo-iv',
    authDomain: 'cristopher-desarrollo-iv.firebaseapp.com',
    storageBucket: 'cristopher-desarrollo-iv.firebasestorage.app',
  );
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
