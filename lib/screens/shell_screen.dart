import 'package:declara_ucr/screens/declarations_screen.dart';
import 'package:declara_ucr/screens/history_screen.dart';
import 'package:declara_ucr/screens/home_screen.dart';
import 'package:declara_ucr/screens/zonaje_screen.dart';
import 'package:flutter/material.dart';

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

  void _go(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _index,
      children: [
        HomeScreen(onNavigate: _go),
        const DeclarationsScreen(),
        const ZonajeScreen(),
        const HistoryScreen(),
      ],
    ),
    bottomNavigationBar: NavigationBar(
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
        NavigationDestination(icon: Icon(Icons.history), label: 'Historial'),
      ],
    ),
  );
}

/// Section indexes, for buttons that jump between sections.
abstract final class Sections {
  static const int home = 0;
  static const int declarations = 1;
  static const int zonaje = 2;
  static const int history = 3;
}
