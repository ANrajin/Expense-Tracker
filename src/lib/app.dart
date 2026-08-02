import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/categories/categories_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/transactions/history_screen.dart';

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

  static const _screens = [
    DashboardScreen(),
    HistoryScreen(),
    ReportsScreen(),
    CategoriesScreen(),
  ];

  static const _labels = ['Dashboard', 'History', 'Reports', 'Categories'];
  static const _icons = [
    Icons.grid_view_rounded,
    Icons.receipt_long_rounded,
    Icons.bar_chart_rounded,
    Icons.category_rounded,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(activeTabProvider);
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
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
