/*
  home_screen.dart

  이 파일은 Reshet 앱의 메인 화면을 정의한다.
  현재는 기본 구조만 구성하고,
  이후 데이터베이스 연결 및 기능을 점진적으로 추가할 예정이다.
*/

import 'package:flutter/material.dart';
import '../database/database_service.dart';

/*
  HomeScreen 클래스

  이 화면은 앱 실행 시 가장 먼저 보이는 메인 화면이다.
  StatefulWidget으로 만든 이유:

  - 나중에 데이터베이스 연결
  - 화면 갱신
  - 상태 변화 처리

  등을 대비하기 위함이다.
*/
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// HomeScreen 위젯의 상태(State)를 관리하는 클래스
/// - 앱 시작 시 데이터베이스 초기화 수행
/// - DB 준비 완료 전까지 로딩 화면 표시
class _HomeScreenState extends State<HomeScreen> {
  /// 데이터베이스 준비 상태를 나타내는 변수
  /// true  → 로딩 중
  /// false → 준비 완료
  bool _isLoading = true;
  String _dbMessage = '';

  /// 위젯이 처음 생성될 때 1회 호출되는 생명주기 메서드
  /// 여기서 데이터베이스 초기화를 시작한다.
  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  /// 데이터베이스 초기화 및 파일 열기 수행
  /// 비동기 작업이므로 async/await 사용
  Future<void> _initializeDatabase() async {
    try {
      await DatabaseService.initialize();
      await DatabaseService.openDatabaseFile();

      _dbMessage = await DatabaseService.getTestData();

      final tables = await DatabaseService.getTableList();
      print("테이블 목록:");
      for (var table in tables) {
        print(" - $table");
      }

      // 위젯이 여전히 화면에 존재할 때만 상태 변경
      if (!mounted) return;

      // DB 준비 완료 → 로딩 종료
      setState(() {
        _isLoading = false;
      });

      print('데이터베이스 연결 성공');
    } catch (e) {
      print('데이터베이스 연결 실패: $e');
    }
  }

  /// 화면을 그리는 메서드
  /// _isLoading 값에 따라 로딩 화면 또는 본문 화면 표시
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reshet')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseService.getWords(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('에러 발생: ${snapshot.error}'));
                }

                final words = snapshot.data ?? [];

                if (words.isEmpty) {
                  return const Center(child: Text('데이터 없음'));
                }

                return ListView.builder(
                  itemCount: words.length,
                  itemBuilder: (context, index) {
                    final word = words[index];

                    return ListTile(
                      title: Text(
                        word['표기1']?.toString().isNotEmpty == true
                            ? word['표기1'].toString()
                            : (word['표기2'] ?? '').toString(),
                      ),
                      subtitle: Text(
                        word['의미1']?.toString() ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        word['스트롱넘버']?.toString() ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
