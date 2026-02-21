/*
  main.dart

  이 파일은 Flutter 애플리케이션의 시작점이다.
  프로그램이 실행되면 가장 먼저 main() 함수가 호출된다.

  역할:
  1. 앱 실행 시작
  2. 최상위 위젯(App)을 실행
*/

import 'package:flutter/material.dart';
import 'ui/home_screen.dart'; // 우리가 만들 첫 화면

void main() {
  runApp(const ReshetApp());
}

/*
  ReshetApp 클래스

  이 클래스는 앱 전체의 기본 설정을 담당한다.
  - 앱 제목
  - 테마 설정
  - 첫 화면 지정

  StatelessWidget을 사용하는 이유:
  앱의 전체 설정은 실행 중에 변하지 않기 때문이다.
*/
class ReshetApp extends StatelessWidget {
  const ReshetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reshet',
      debugShowCheckedModeBanner: false, // 우측 상단 DEBUG 배너 제거
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const HomeScreen(), // 첫 화면
    );
  }
}
