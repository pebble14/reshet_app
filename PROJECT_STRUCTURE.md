# PROJECT_STRUCTURE.md

## 프로젝트 개요

Reshet은 Flutter 기반 단어 관계 탐색 도구이다.

핵심 기능:

- 단어 검색
- 단어 상세 정보 확인
- 단어 관계 그래프 탐색


---

# 디렉터리 구조


lib/
main.dart

database/
database_service.dart

data/
models/
word.dart
word_relation.dart

repositories/
word_repository.dart

ui/
home_screen.dart
word_detail_screen.dart
word_graph_screen.dart


---

# 주요 파일 역할

## main.dart
앱 시작점.

Flutter 애플리케이션을 초기화한다.


---

## database/database_service.dart

SQLite 데이터베이스 연결 관리.

주요 역할:

- 데이터베이스 파일 열기
- 테이블 목록 확인
- 기본 DB 접근 제공


---

## data/models

데이터 모델 정의.

### word.dart

WORD_TABLE 레코드를 표현하는 모델.

주요 필드:

- id
- language
- strongNumber
- spelling1
- pronunciation1
- meaning1


### word_relation.dart

WORD_RELATION 레코드 모델.


---

## data/repositories

데이터 접근 계층.

### word_repository.dart

WORD_TABLE과 WORD_RELATION을 조회하는 로직.


---

## ui

Flutter 화면 UI.

### home_screen.dart

단어 목록 화면.


### word_detail_screen.dart

선택한 단어의 상세 정보 화면.


### word_graph_screen.dart

단어 관계 그래프 화면.

중심 단어와 연결된 단어들을 원형으로 배치한다.