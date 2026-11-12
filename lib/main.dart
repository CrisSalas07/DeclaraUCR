import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:declara_ucr/config/firebase_config.dart';
import 'package:declara_ucr/data/auth_repository.dart';
import 'package:declara_ucr/data/declaration_repository.dart';
import 'package:declara_ucr/data/profile_repository.dart';
import 'package:declara_ucr/data/zonaje_repository.dart';
import 'package:declara_ucr/models/app_user.dart';
import 'package:declara_ucr/models/declaration.dart';
import 'package:declara_ucr/models/zonaje_request.dart';
import 'package:declara_ucr/screens/auth/complete_profile_screen.dart';
import 'package:declara_ucr/screens/auth/login_screen.dart';
import 'package:declara_ucr/screens/shell_screen.dart';
import 'package:declara_ucr/state/loadable.dart';
import 'package:declara_ucr/theme/ucr_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: FirebaseConfig.options);
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    if (FirebaseConfig.useEmulators) {
      firestore.useFirestoreEmulator(FirebaseConfig.emulatorHost, 8080);
      await auth.useAuthEmulator(FirebaseConfig.emulatorHost, 9099);
    }
    final profiles = FirestoreProfileRepository(firestore);
    runApp(
      DeclaraUcrApp(
        auth: FirebaseAuthRepository(auth, profiles),
        profiles: profiles,
        repositoryFor: (uid) =>
            FirestoreDeclarationRepository(firestore, ownerUid: uid),
        zonajeFor: (uid) => FirestoreZonajeRepository(firestore, ownerUid: uid),
      ),
    );
  } catch (e) {
    debugPrint('Startup failed: $e');
    runApp(const _StartupErrorApp());
  }
}

/// Shown when Firebase fails to start, instead of a blank screen.
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildUcrTheme(),
    home: const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No se pudo iniciar la aplicación. Revise la conexión y vuelva '
            'a intentarlo.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}

/// Picks the screen from the session: login, completing the profile, or
/// the sections of the signed-in person.
///
/// Everything per person (repositories, profile, declarations and zonaje
/// requests) is provided above the [MaterialApp], so every pushed route
/// sees it. The providers and the app are keyed by user: signing in or out
/// drops the whole navigation stack and every stream of the previous
/// session.
class DeclaraUcrApp extends StatefulWidget {
  const DeclaraUcrApp({
    super.key,
    required this.auth,
    required this.profiles,
    required this.repositoryFor,
    required this.zonajeFor,
  });

  final AuthRepository auth;
  final ProfileRepository profiles;
  final DeclarationRepository Function(String uid) repositoryFor;
  final ZonajeRepository Function(String uid) zonajeFor;

  @override
  State<DeclaraUcrApp> createState() => _DeclaraUcrAppState();
}

class _DeclaraUcrAppState extends State<DeclaraUcrApp> {
  late final Stream<AppUser?> _users = widget.auth.userChanges();

  static Loadable<T> _failed<T>(String what, Object? error) {
    // Technical details go to the log, never to the user.
    debugPrint('Loading $what failed: $error');
    return Loadable<T>.failed();
  }

  List<SingleChildWidget> _sessionProviders(AppUser user) {
    final declarations = widget.repositoryFor(user.uid);
    final zonaje = widget.zonajeFor(user.uid);
    return [
      Provider<DeclarationRepository>.value(value: declarations),
      Provider<ZonajeRepository>.value(value: zonaje),
      StreamProvider<Loadable<UserProfile?>>(
        create: (_) => widget.profiles
            .watch(user.uid)
            .map((p) => Loadable<UserProfile?>.data(p)),
        initialData: const Loadable.loading(),
        catchError: (_, e) => _failed('profile', e),
      ),
      ProxyProvider<Loadable<UserProfile?>, UserProfile?>(
        update: (_, profile, _) => profile.value,
      ),
      StreamProvider<Loadable<List<Declaration>>>(
        create: (_) => declarations.watchAll().map(Loadable.data),
        initialData: const Loadable.loading(),
        catchError: (_, e) => _failed('declarations', e),
      ),
      StreamProvider<Loadable<List<ZonajeRequest>>>(
        create: (_) => zonaje.watchAll().map(Loadable.data),
        initialData: const Loadable.loading(),
        catchError: (_, e) => _failed('zonaje requests', e),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<AppUser?>(
    stream: _users,
    initialData: widget.auth.currentUser,
    builder: (context, snap) {
      final user = snap.data;
      return MultiProvider(
        key: ValueKey(user?.uid),
        providers: [
          Provider<AuthRepository>.value(value: widget.auth),
          Provider<ProfileRepository>.value(value: widget.profiles),
          Provider<AppUser?>.value(value: user),
          if (user != null) ..._sessionProviders(user),
        ],
        child: MaterialApp(
          title: 'DeclaraUCR · Declaraciones Juradas',
          debugShowCheckedModeBanner: false,
          theme: buildUcrTheme(),
          locale: const Locale('es', 'CR'),
          supportedLocales: const [Locale('es', 'CR'), Locale('es')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: user == null ? const LoginScreen() : const _ProfileGate(),
        ),
      );
    },
  );
}

/// Waits for the profile: without a cédula, asks for it once.
class _ProfileGate extends StatelessWidget {
  const _ProfileGate();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<Loadable<UserProfile?>>();
    if (profile.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (profile.failed) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No se pudo cargar su perfil. Revise la conexión y vuelva a '
              'abrir la aplicación.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    if (profile.value == null) return const CompleteProfileScreen();
    return const ShellScreen();
  }
}
