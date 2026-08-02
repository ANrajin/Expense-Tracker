import 'package:flutter/material.dart';

/// Semantic colors from the spec's Design System table that don't map onto
/// Material's default ColorScheme roles (income/expense, soft variants, chip bg).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.primary,
    required this.primarySoft,
    required this.income,
    required this.expense,
    required this.expenseSoft,
    required this.chipBg,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color primary;
  final Color primarySoft;
  final Color income;
  final Color expense;
  final Color expenseSoft;
  final Color chipBg;

  static const light = AppColors(
    background: Color(0xFFF3F7F5),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEAF4EE),
    textPrimary: Color(0xFF161B18),
    textSecondary: Color(0xFF5C6864),
    border: Color(0xFFE1E7E3),
    primary: Color(0xFF2E7D32),
    primarySoft: Color(0xFFE3F1E4),
    income: Color(0xFF2E7D32),
    expense: Color(0xFFD32F2F),
    expenseSoft: Color(0xFFFBEAEA),
    chipBg: Color(0xFFEEF2EF),
  );

  static const dark = AppColors(
    background: Color(0xFF101311),
    surface: Color(0xFF1B211D),
    surfaceAlt: Color(0xFF1E2A22),
    textPrimary: Color(0xFFEDF2EF),
    textSecondary: Color(0xFF9AA6A1),
    border: Color(0x1FFFFFFF),
    primary: Color(0xFF66BB6A),
    primarySoft: Color(0xFF1E2E20),
    income: Color(0xFF66BB6A),
    expense: Color(0xFFEF5350),
    expenseSoft: Color(0xFF2E1E1E),
    chipBg: Color(0xFF242B26),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? primary,
    Color? primarySoft,
    Color? income,
    Color? expense,
    Color? expenseSoft,
    Color? chipBg,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      expenseSoft: expenseSoft ?? this.expenseSoft,
      chipBg: chipBg ?? this.chipBg,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseSoft: Color.lerp(expenseSoft, other.expenseSoft, t)!,
      chipBg: Color.lerp(chipBg, other.chipBg, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

class AppTheme {
  AppTheme._();

  static final ThemeData light = _build(AppColors.light, Brightness.light);
  static final ThemeData dark = _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        brightness: brightness,
      ).copyWith(
        primary: colors.primary,
        surface: colors.surface,
        error: colors.expense,
      ),
      dividerColor: colors.border,
    );
    return base.copyWith(extensions: [colors]);
  }
}
