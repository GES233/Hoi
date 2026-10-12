import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: HoiApp()));
}

class HoiApp extends StatelessWidget {
  const HoiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hoi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        // 卡片不自带外边距，由各屏外层 padding + SizedBox 统一控制，
        // 避免卡片与通栏按钮水平边距不一致
        cardTheme: const CardThemeData(margin: EdgeInsets.zero),
      ),
      home: const HomeScreen(),
    );
  }
}
