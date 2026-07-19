import 'package:flutter/material.dart';

/// Bottom nav with 5 tabs: Bibliothèque, Séances, Live, Dashboard, Profil
/// (PARTIE 7). `child` is supplied by the ShellRoute in app_router.dart.
class AppShell extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const AppShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTabSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list), label: 'Bibliothèque'),
          NavigationDestination(icon: Icon(Icons.event_note), label: 'Séances'),
          NavigationDestination(icon: Icon(Icons.play_circle_fill), label: 'Live'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
