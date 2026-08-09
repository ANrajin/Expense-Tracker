import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/categories/categories_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/data_management/data_management_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/transactions/history_screen.dart';
import 'features/wealth/wealth_screen.dart';

const settingsBoxName = 'settings';

final settingsBoxProvider = Provider<Box>((ref) => Hive.box(settingsBoxName));

/// Manual light/dark override, defaulting to the device's system theme.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(settingsBoxProvider));
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._box) : super(_read(_box));

  final Box _box;
  static const _key = 'themeMode';

  static ThemeMode _read(Box box) {
    final raw = box.get(_key, defaultValue: 'system') as String;
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  void setDark(bool isDark) {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    _box.put(_key, isDark ? 'dark' : 'light');
  }
}

final activeTabProvider = StateProvider<int>((ref) => 0);

class ExpenseTrackerApp extends ConsumerWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const AppShell(),
    );
  }
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  // The three lists stay index-aligned. Categories used to hold the fourth
  // slot; it moved to the drawer when Wealth took its place (specs.md §7).
  static const _screens = [
    DashboardScreen(),
    HistoryScreen(),
    ReportsScreen(),
    WealthScreen(),
  ];

  static const _labels = ['Dashboard', 'History', 'Reports', 'Wealth'];
  static const _icons = [
    Icons.grid_view_rounded,
    Icons.receipt_long_rounded,
    Icons.bar_chart_rounded,
    Icons.account_balance_wallet_rounded,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(activeTabProvider);
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 12, 12, 0),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      tooltip: 'Menu',
                      icon: Icon(Icons.menu_rounded, color: colors.textPrimary),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  Text(
                    'Expense Tracker',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: isDark ? 'Switch to light' : 'Switch to dark',
                    icon: Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: colors.textPrimary,
                    ),
                    onPressed: () =>
                        ref.read(themeModeProvider.notifier).setDark(!isDark),
                  ),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(index: index, children: _screens),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(activeTabProvider.notifier).state = i,
        backgroundColor: colors.surface,
        indicatorColor: colors.primarySoft,
        destinations: [
          for (var i = 0; i < _labels.length; i++)
            NavigationDestination(icon: Icon(_icons[i]), label: _labels[i]),
        ],
      ),
    );
  }
}

/// Side drawer for app-wide actions that don't belong in the bottom nav.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Drawer(
      backgroundColor: colors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              child: Text(
                'Expense Tracker',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Divider(height: 1, color: colors.border),
            _DrawerEntry(
              icon: Icons.category_rounded,
              label: 'Categories',
              onTap: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.push(
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                );
              },
            ),
            _DrawerEntry(
              icon: Icons.storage_rounded,
              label: 'Data Management',
              onTap: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => const DataManagementScreen(),
                  ),
                );
              },
            ),
            _DrawerEntry(
              icon: Icons.exit_to_app_rounded,
              label: 'Exit',
              // Pops the app off the Android back stack rather than killing the
              // process, so it doesn't register as a crash in Android vitals.
              onTap: () {
                Navigator.of(context).pop();
                SystemNavigator.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerEntry extends StatelessWidget {
  const _DrawerEntry({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      leading: Icon(icon, size: 20, color: colors.textPrimary),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }
}
