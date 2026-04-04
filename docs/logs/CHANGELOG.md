# CHANGELOG

## 2026-04-04

### 변경
- 문서 구조를 `/docs` 기준으로 정리했다.
- read source 전환 1차 기반을 repository 내부에 도입했다.
- 기본 read source policy는 아직 `LEGACY`로 유지한다.
- normalized read adapter와 fallback 판정/관측 모델을 연결했다.
- 실제 normalized read 활성 전환은 아직 수행하지 않았다.
- `WordDetailScreen` 전용 제한 경로 `getWordDetailMapByIdForReadSourcePhase2Only`를 추가했다.
- 상세 화면은 `widget.word` 초기 표시를 유지한 채 백그라운드에서만 phase 2 read를 시도한다.
- fallback reason에 `user_visible_display_mismatch`를 추가하고 in-memory observation 항목을 확장했다.
- repository 테스트에 detail-only success / empty fallback / display-mismatch fallback 검증을 추가했다.
- `docs/database/read_source_migration.md`에 phase 2 제한 적용 범위, rollback, 관측 기준을 반영했다.
