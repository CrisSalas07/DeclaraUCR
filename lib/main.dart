import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/screens/home_screen.dart';
import 'package:declara_ucr/theme/ucr_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

/// `demo-*` project: the SDK only talks to the local emulators, never to
/// real Firebase, so these options need no real keys (nothing secret here).
const _demoOptions = FirebaseOptions(
  apiKey: 'demo-api-key',
  appId: '1:000000000000:android:0000000000000000',
  messagingSenderId: '000000000000',
  projectId: 'demo-declaraucr',
);

/// 10.0.2.2 is the host PC as seen from the Android emulator. On a physical
/// phone: `--dart-define=EMULATOR_HOST=<PC_IP>`.
const _emulatorHost = String.fromEnvironment(
  'EMULATOR_HOST',
  defaultValue: '10.0.2.2',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: _demoOptions);
  FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, 8080);
  runApp(
    DeclaraUcrApp(
      repository: FirestoreDeclarationRepository(FirebaseFirestore.instance),
    ),
  );
}

class DeclaraUcrApp extends StatelessWidget {
  const DeclaraUcrApp({super.key, required this.repository});

  final DeclarationRepository repository;

  @override
  Widget build(BuildContext context) => Provider<DeclarationRepository>.value(
    value: repository,
    child: MaterialApp(
      title: 'Declaraciones Juradas UCR',
      debugShowCheckedModeBanner: false,
      theme: buildUcrTheme(),
      locale: const Locale('es', 'CR'),
      supportedLocales: const [Locale('es', 'CR'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const HomeScreen(),
    ),
  );
}
