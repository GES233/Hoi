import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: HoiApp()));
}

class HoiApp extends ConsumerWidget {
  const HoiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pref = ref.watch(themePreferenceProvider);
    final (theme, darkTheme, mode) = switch (pref) {
      HoiThemePreference.highContrastLight => (
        HoiTheme.highContrastLight(),
        HoiTheme.highContrastDark(),
        ThemeMode.light,
      ),
      HoiThemePreference.highContrastDark => (
        HoiTheme.highContrastLight(),
        HoiTheme.highContrastDark(),
        ThemeMode.dark,
      ),
      HoiThemePreference.softLight => (
        HoiTheme.light(),
        HoiTheme.dark(),
        ThemeMode.light,
      ),
      HoiThemePreference.softDark => (
        HoiTheme.light(),
        HoiTheme.dark(),
        ThemeMode.dark,
      ),
      HoiThemePreference.system => (
        HoiTheme.light(),
        HoiTheme.dark(),
        ThemeMode.system,
      ),
    };

    return MaterialApp(
      title: 'Hoi',
      debugShowCheckedModeBanner: false,
      // 显式声明简体中文：缺省时 Localizations 会回落到 en_US，
      // Text 就会以 en 的 locale 向系统索要汉字字形，字形由系统补字任意决定
      // （Windows 上易落到微软正黑/Yu Gothic，汉字显示成繁体或日式骨架），
      // 同时 MaterialLocalizations.scriptCategory 也从 englishLike 变为 dense，
      // 中文才能拿到紧凑的 CJK 行高几何。
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: theme,
      darkTheme: darkTheme,
      highContrastTheme: HoiTheme.highContrastLight(),
      highContrastDarkTheme: HoiTheme.highContrastDark(),
      themeMode: mode,
      home: const HomeScreen(),
    );
  }
}
