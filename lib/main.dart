/*
  main.dart

  이 파일은 Flutter 애플리케이션의 시작점이다.
  프로그램이 실행되면 가장 먼저 main() 함수가 호출된다.

  역할:
  1. 앱 실행 시작
  2. 최상위 위젯(App)을 실행
*/

import 'dart:async';

import 'package:flutter/material.dart';
import 'theme_mode_preference.dart';
import 'ui/home_screen.dart'; // 우리가 만들 첫 화면

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialThemeMode = await ThemeModePreference.load();
  runApp(ReshetApp(initialThemeMode: initialThemeMode));
}

/*
  ReshetApp 클래스

  이 클래스는 앱 전체의 기본 설정을 담당한다.
  - 앱 제목
  - 테마 설정
  - 첫 화면 지정

  앱 전체 테마 선택을 실행 중에 즉시 반영하기 위해 상태를 소유한다.
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
      ), // 첫 화면
    );
  }
}
