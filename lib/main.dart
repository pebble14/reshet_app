/*
  main.dart

  Flutter 바인딩과 저장된 테마 설정을 준비하고 ReshetApp을 실행하는
  애플리케이션 시작점이다.
*/

import 'dart:async';

import 'package:flutter/material.dart';
import 'theme_mode_preference.dart';
import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialThemeMode = await ThemeModePreference.load();
  runApp(ReshetApp(initialThemeMode: initialThemeMode));
}

/*
  ReshetApp 클래스

  앱 제목과 테마, HomeScreen 진입을 설정하고 실행 중 테마 상태를 소유한다.
*/
class ReshetApp extends StatefulWidget {
  const ReshetApp({super.key, this.initialThemeMode = ThemeMode.system});

  final ThemeMode initialThemeMode;

  @override
  State<ReshetApp> createState() => _ReshetAppState();
}

class _ReshetAppState extends State<ReshetApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

  void _changeThemeMode(ThemeMode themeMode) {
    if (themeMode == _themeMode) {
      return;
    }
    setState(() => _themeMode = themeMode);
    unawaited(ThemeModePreference.save(themeMode));
  }

  @override
  Widget build(BuildContext context) {
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blueGrey,
      brightness: Brightness.light,
    );
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blueGrey,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Reshet',
      debugShowCheckedModeBanner: false, // 우측 상단 DEBUG 배너 제거
      theme: ThemeData(colorScheme: lightColorScheme, useMaterial3: true),
      darkTheme: ThemeData(colorScheme: darkColorScheme, useMaterial3: true),
      themeMode: _themeMode,
      home: HomeScreen(
        themeMode: _themeMode,
        onThemeModeChanged: _changeThemeMode,
      ),
    );
  }
}
