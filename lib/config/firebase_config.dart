import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Which Firebase backend the app talks to, chosen at build time.
///
/// - Default: local emulators (`demo-declaraucr`, no real data).
/// - `--dart-define=FIREBASE_ENV=production`:
///   - Android: the Proyecto 1 backend (`declarahorario-b186f`), shared with
///     the DeclaraHorario web system. Its `firestore.rules` apply, not the
///     ones in this repository.
///   - Web: the hosted web app on `cristopher-desarrollo-iv`.
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
    if (kIsWeb) return _webProductionOptions;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidProductionOptions;
    }
    throw UnsupportedError(
      'Production is only configured for Android and the web.',
    );
  }

  /// `demo-*` project: the SDK only talks to the local emulators, never to
  /// real Firebase, so these options need no real keys.
  static const _emulatorOptions = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-declaraucr',
  );

  /// Android app "DeclaraUCR (Android)" registered in the Proyecto 1 project
  /// (`firebase apps:sdkconfig ANDROID <appId>`). Same as the web key: a
  /// public identifier, access is enforced by Firebase Auth and the rules.
  static const _androidProductionOptions = FirebaseOptions(
    apiKey: 'AIzaSyBDoexAl7lWuz7yymCdBLu1CRCV_Ifn2G0',
    appId: '1:15638785744:android:8e94f5071822db051238d5',
    messagingSenderId: '15638785744',
    projectId: 'declarahorario-b186f',
    storageBucket: 'declarahorario-b186f.firebasestorage.app',
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
