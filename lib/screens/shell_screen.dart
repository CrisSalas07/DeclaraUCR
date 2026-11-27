import 'package:declara_ucr/data/onboarding_store.dart';
import 'package:declara_ucr/screens/declarations_screen.dart';
import 'package:declara_ucr/screens/history_screen.dart';
import 'package:declara_ucr/screens/home_screen.dart';
import 'package:declara_ucr/screens/zonaje_screen.dart';
import 'package:declara_ucr/screens/tutorial_screen.dart';
import 'package:declara_ucr/widgets/tour_anchor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The sections of the app after signing in, with a bottom navigation bar:
/// Inicio, Declaraciones, Zonaje and Historial. Each section keeps its
/// scroll and filters while the person moves between them.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _tourOnFirstUse();
  }

  /// The first time on this phone, the tour of the steps (U-06).
  Future<void> _tourOnFirstUse() async {
    final store = context.read<OnboardingStore>();
    try {
      if (await store.seen()) return;
      await store.markSeen();
    } catch (e) {
      // Without the phone's storage the tour is just not shown.
      debugPrint('Onboarding store failed: $e');
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const TutorialScreen(),
      ),
    );
  }

  void _go(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _index,
      children: [
        const HomeScreen(),
        const DeclarationsScreen(),
        const ZonajeScreen(),
        const HistoryScreen(),
      ],
    ),
    // "Declaraciones" must fit in a quarter of a phone: the labels do not
    // grow past 100 % (the icons go with them), and the rest of the app
    // still follows the phone's text size.
    bottomNavigationBar: MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1,
      child: NavigationBarTheme(
        data: NavigationBarTheme.of(context).copyWith(
          labelTextStyle: WidgetStatePropertyAll(
            Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 11.5),
          ),
        ),
        child: TourAnchor(
          id: 'shell.nav',
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _go,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.description_outlined),
                selectedIcon: Icon(Icons.description),
                label: 'Declaraciones',
              ),
              NavigationDestination(
                icon: Icon(Icons.directions_car_outlined),
                selectedIcon: Icon(Icons.directions_car),
                label: 'Zonaje',
              ),
              NavigationDestination(
                icon: Icon(Icons.history),
                label: 'Historial',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
