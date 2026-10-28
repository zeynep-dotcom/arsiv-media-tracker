import 'package:flutter/material.dart';

import 'package:arsiv_app/core/theme/app_theme.dart';
import 'package:arsiv_app/screens/discover/discover_screen.dart';
import 'package:arsiv_app/screens/library/library_screen.dart';
import 'package:arsiv_app/screens/search/search_screen.dart';
import 'package:arsiv_app/screens/stats/stats_screen.dart';

/// Alt menülü ana iskelet: Keşfet, Ara, Kütüphanem, İstatistik.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [
    DiscoverScreen(),
    SearchScreen(),
    LibraryScreen(),
    StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.background,
          indicatorColor: AppColors.red.withValues(alpha: 0.18),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? Colors.white
                  : AppColors.textSecondary,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppColors.red
                  : AppColors.textSecondary,
            ),
          ),
        ),
        child: NavigationBar(
          height: 68,
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Keşfet',
            ),
            NavigationDestination(
              icon: Icon(Icons.search),
              label: 'Ara',
            ),
            NavigationDestination(
              icon: Icon(Icons.video_library_outlined),
              selectedIcon: Icon(Icons.video_library),
              label: 'Kütüphanem',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'İstatistik',
            ),
          ],
        ),
      ),
    );
  }
}
