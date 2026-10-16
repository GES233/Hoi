import 'package:flutter/material.dart';
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
      theme: theme,
      darkTheme: darkTheme,
      highContrastTheme: HoiTheme.highContrastLight(),
      highContrastDarkTheme: HoiTheme.highContrastDark(),
      themeMode: mode,
      home: const HomeScreen(),
    );
  }
}
