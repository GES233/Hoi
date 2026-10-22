import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';

/// 外观与对比度偏好
enum HoiThemePreference {
  highContrastLight('高对比浅色', Icons.wb_sunny_rounded),
  highContrastDark('高对比深色', Icons.nightlight_round),
  softLight('柔和浅色', Icons.light_mode_outlined),
  softDark('柔和深色', Icons.dark_mode_outlined),
  system('跟随系统', Icons.brightness_auto_outlined);

  const HoiThemePreference(this.label, this.icon);
  final String label;
  final IconData icon;
}

class ThemePreferenceNotifier extends Notifier<HoiThemePreference> {
  @override
  HoiThemePreference build() => HoiThemePreference.highContrastLight;

  void select(HoiThemePreference preference) => state = preference;
}

final themePreferenceProvider =
    NotifierProvider<ThemePreferenceNotifier, HoiThemePreference>(
      ThemePreferenceNotifier.new,
    );

/// Hoi 视觉设计系统：支持「高对比度（浅/深）」与「温润柔和（浅/深）」两套主题体系。
class HoiTheme {
  HoiTheme._();

  static const Color seedColor = Color(0xFF1E6F50);

  /// 简体中文字体回退链。Windows 上 Material 的默认正文族是 Segoe UI（零汉字），
  /// Android 的 Noto Sans CJK 默认面偏日文，所以显式给出简中字体，
  /// 避免汉字补字落到繁体/日文字体上而显示成繁体骨架。不存在的族名会被忽略。
  static const cjkFontFallbacks = <String>[
    'Microsoft YaHei UI',
    'Microsoft YaHei',
    'Noto Sans CJK SC',
    'Noto Sans SC',
    'Source Han Sans SC',
    'PingFang SC',
  ];

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      surface: const Color(0xFFF5F7F4),
    );
    return _buildTheme(
      scheme: scheme,
      scaffoldBackground: const Color(0xFFF4F6F3),
      cardBackground: Colors.white,
      inputFill: const Color(0xFFF1F4F0),
      highContrast: false,
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF111714),
    );
    return _buildTheme(
      scheme: scheme,
      scaffoldBackground: const Color(0xFF0E1310),
      cardBackground: const Color(0xFF171F1B),
      inputFill: const Color(0xFF202A25),
      highContrast: false,
    );
  }

  /// 高对比度浅色主题：墨黑正文、深翠绿主色、1.5px 清晰描边、层次分明的底色对比
  static ThemeData highContrastLight() {
    final base = ColorScheme.fromSeed(
      seedColor: const Color(0xFF005A3C),
      brightness: Brightness.light,
    );
    final scheme = base.copyWith(
      primary: const Color(0xFF005A3C),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFC2F0DC),
      onPrimaryContainer: const Color(0xFF002919),
      secondary: const Color(0xFF1D4ED8),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFDBEAFE),
      onSecondaryContainer: const Color(0xFF0F296B),
      tertiary: const Color(0xFF9A3412),
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFFFEDD5),
      onTertiaryContainer: const Color(0xFF431407),
      surface: const Color(0xFFFFFFFF),
      onSurface: const Color(0xFF090D0B),
      onSurfaceVariant: const Color(0xFF26332D),
      surfaceContainerLow: const Color(0xFFEDF2EE),
      surfaceContainerHighest: const Color(0xFFD5E0D9),
      outline: const Color(0xFF4B5E54),
      outlineVariant: const Color(0xFF8A9E93),
    );
    return _buildTheme(
      scheme: scheme,
      scaffoldBackground: const Color(0xFFE4EBE6),
      cardBackground: Colors.white,
      inputFill: const Color(0xFFEDF2EE),
      highContrast: true,
    );
  }

  /// 高对比度深色主题：纯黑背景、高亮荧光翠绿主色、纯白正文、锐利卡片边界
  static ThemeData highContrastDark() {
    final base = ColorScheme.fromSeed(
      seedColor: const Color(0xFF34D399),
      brightness: Brightness.dark,
    );
    final scheme = base.copyWith(
      primary: const Color(0xFF34D399),
      onPrimary: const Color(0xFF022C1E),
      primaryContainer: const Color(0xFF064E3B),
      onPrimaryContainer: const Color(0xFFD1FAE5),
      secondary: const Color(0xFF60A5FA),
      onSecondary: const Color(0xFF082042),
      secondaryContainer: const Color(0xFF1E3A8A),
      onSecondaryContainer: const Color(0xFFDBEAFE),
      tertiary: const Color(0xFFFBBF24),
      onTertiary: const Color(0xFF3B2100),
      tertiaryContainer: const Color(0xFF78350F),
      onTertiaryContainer: const Color(0xFFFEF3C7),
      surface: const Color(0xFF121915),
      onSurface: const Color(0xFFF8FAFC),
      onSurfaceVariant: const Color(0xFFD1DDD6),
      surfaceContainerLow: const Color(0xFF1B2520),
      surfaceContainerHighest: const Color(0xFF2A3830),
      outline: const Color(0xFF758F80),
      outlineVariant: const Color(0xFF465B4F),
    );
    return _buildTheme(
      scheme: scheme,
      scaffoldBackground: const Color(0xFF060907),
      cardBackground: const Color(0xFF121915),
      inputFill: const Color(0xFF1B2520),
      highContrast: true,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme scheme,
    required Color scaffoldBackground,
    required Color cardBackground,
    required Color inputFill,
    required bool highContrast,
  }) {
    final borderSide = BorderSide(
      color: highContrast
          ? scheme.outlineVariant
          : scheme.outlineVariant.withValues(alpha: 0.55),
      width: highContrast ? 1.5 : 1.0,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      // 只补回退，不替换主族：西文与数字仍走平台默认字体，汉字命中简中字体
      fontFamilyFallback: cjkFontFallbacks,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          // 这里绕过了 textTheme，需自行带上回退链，否则标题汉字仍走系统补字
          fontFamilyFallback: cjkFontFallbacks,
        ),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        color: cardBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: borderSide,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: highContrast ? borderSide : BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: highContrast ? borderSide : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: highContrast
                ? scheme.outlineVariant
                : scheme.outlineVariant.withValues(alpha: 0.4),
            width: highContrast ? 1.2 : 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.primary,
            width: highContrast ? 2.0 : 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.error,
            width: highContrast ? 1.5 : 1.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 2.0),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          side: BorderSide(
            color: highContrast ? scheme.outline : scheme.outlineVariant,
            width: highContrast ? 1.5 : 1.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: highContrast
            ? scheme.outlineVariant
            : scheme.outlineVariant.withValues(alpha: 0.45),
        thickness: highContrast ? 1.2 : 1.0,
        space: 16,
      ),
    );
  }

  /// 运动类别的对应图标
  static IconData categoryIcon(ExerciseCategory category) => switch (category) {
    ExerciseCategory.cardio => Icons.directions_run_rounded,
    ExerciseCategory.resistance => Icons.fitness_center_rounded,
    ExerciseCategory.core => Icons.self_improvement_rounded,
    ExerciseCategory.functional => Icons.sports_gymnastics_rounded,
  };

  /// 运动类别的语义强调色
  static Color categoryColor(ColorScheme scheme, ExerciseCategory category) =>
      switch (category) {
        ExerciseCategory.cardio => scheme.primary,
        ExerciseCategory.resistance => scheme.tertiary,
        ExerciseCategory.core => scheme.secondary,
        ExerciseCategory.functional =>
          scheme.brightness == Brightness.dark
              ? const Color(0xFFF59E0B)
              : const Color(0xFFB45309),
      };

  /// 餐次的对应图标
  static IconData mealIcon(MealType mealType) => switch (mealType) {
    MealType.breakfast => Icons.wb_twilight_rounded,
    MealType.lunch => Icons.wb_sunny_outlined,
    MealType.dinner => Icons.nights_stay_outlined,
    MealType.snack => Icons.local_cafe_outlined,
  };
}

/// 统一的胶囊标签组件（高对比度下自动增加清晰描边）
class HoiPill extends StatelessWidget {
  const HoiPill({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.backgroundColor,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = color ?? scheme.primary;
    final bg = backgroundColor ?? fg.withValues(alpha: 0.15);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
