# H28 클러스터 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-09-13
- 대상: H0028; H0001·H3045는 구성 관계 문맥
- 승인 manifest: [h28_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h28_cluster_approved_content_slice.json)
- 로컬 연구 산출물: `H28_cluster_20260913_75a44ef1`
- DB 적용: 2026-09-13, history group `1789302796475698`

## 최종 결정

- H0028 meaning: `아비다·아비-다 (인)` 한 행
- 비고: 창 25:4와 대상 1:33의 같은 계보에서 미디안의 아들 한 사람, 곧 아브라함과 그두라의 손자를 가리킨다고 기록한다. `아비다`는 한국어 성경의 관용 표기, `아비-다`는 H0001과 H3045의 구성 경계를 드러낸 분석 표기이며 하이픈은 실제 히브리어 마케프가 아님을 밝힌다. Strong과 reference-only HebGrkKo의 어원 풀이 차이도 보존한다.
- relation: H0001→H0028, H3045→H0028 각각 `morphological / compound / asserted`
- expression·transliteration·pronunciation: 변경하지 않음
- hold: 없음
- 승인 범위 밖: H0001과 H3045의 독립 meaning은 이번 결정으로 승인하거나 변경하지 않음

## 핵심 판단 근거

Canonical occurrence 두 건인 창 25:4와 대상 1:33은 같은 계보를 반복하며 모두 미디안의 아들인 한 사람을 가리킨다. 별도 인물·보통명사·다른 lexical sense로 나뉘는 용례가 없으므로 meaning은 하나로 유지한다. 개역개정·개역한글·새번역과 reference-only HebGrkKo가 모두 `아비다`를 사용하므로 한국어 관용 표기도 보존한다.

Canonical Strong은 H0028을 H0001과 H3045에서 온 이름으로 직접 분석하며 추정 qualifier를 두지 않는다. 따라서 두 구성 어휘에서 H0028로 향하는 관계를 `compound / asserted`로 승인했다. DB의 canonical pair 정렬 때문에 H3045→H0028은 `H0028_0000, H3045_0000 / w2_to_w1`로 저장하지만 semantic 방향은 H3045→H0028이다.

한국어 어휘 표기 정책과 H0022·H0023·H0026·H0027의 선례에 따라 관용 표기 뒤에 분석 표기를 같은 sense의 가운데점 병기로 보존했다. `아비-다`의 하이픈은 Strong이 명시한 구성 경계를 가시화하며 실제 원문 구두점이나 마케프를 주장하지 않는다.

## 채택하지 않은 주요 대안

- 현행 `아비다 (인)` 유지: 인물 식별과 관용 표기에는 충분하지만, canonical source가 직접 뒷받침하는 H0001·H3045 구성과 현재 분석 표기 정책을 meaning에서 확인할 수 없어 채택하지 않았다.
- `아비라 (인)`: LXX 창 25:4는 `αβιρα`이지만 대상 1:33은 `αβιδα`이며, 현재 LXX source는 provenance와 license가 확인되지 않은 human-reference이므로 한국어 대표 표기를 바꾸는 근거로 채택하지 않았다.
- `지식의 아버지` 또는 `나의 아버지는 아신다`를 별도 meaning으로 추가: 이름이 지시하는 인물과 출처별 어원 풀이를 하나의 lexical projection에 혼합하므로 채택하지 않았다. 풀이 차이는 비고에 보존했다.
- hold: 인물 식별, occurrence coverage, 한국어 관용 표기와 직접 구성 관계가 충분히 확인되므로 두지 않았다.

## 남은 불확실성 및 재검토 조건

Strong의 source language는 `x-pn / source_language_unresolved` 상태다. Strong은 인물을 “a son of Abraham by Keturah”라고 설명하지만 직접 계보 문맥에서는 미디안의 아들, 곧 아브라함과 그두라의 손자다. 이름 풀이도 Strong의 `father of knowledge (i.e. knowing)`와 HebGrkKo의 “나의 아버지는 아신다” 사이에 차이가 있고, LXX 철자는 두 본문에서 일치하지 않는다. 이 항목들은 현재 인물 식별과 합성 구조를 뒤집지 않으므로 비고와 연구 산출물에 한계로 보존한다.

원천 이름의 H0001·H3045 구성을 부정하는 신뢰할 만한 히브리어·셈어 onomastic 자료가 확보되거나, 현재 human-reference LXX의 provenance와 authority가 검증되어 한국어 표기 판단을 실질적으로 바꿀 때 meaning·비고·relation을 함께 재검토할 수 있다. 번역본 하나의 표기 차이나 hub cluster의 추가 발견만으로는 자동 재검토하지 않는다.

## 적용 및 마감 검증

- Dry-run은 meaning 1건, word note 1건, relation create 2건을 임시 DB에 적용한 뒤 실제 undo했으며 원본 work DB SHA-256 `75a44ef1098742cca6cfd91194931cd1fc063c040f7219e82ed635855d711171`을 전후 동일하게 유지했다.
- Live apply 뒤 work DB SHA-256은 `db8d6a6d28801b2aff9b6bf5a6b76a0d29d58bd2b57761cea8571d9561158c69`이며 seed DB SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다.
- 적용 전 snapshot은 `data/backups/approved_content_batch/20260913T123315662676Z/snapshot.db`, SHA-256 `5113501b7a8cb822ab846c8de695c3e24fc28891461b1dc60cf26b5bd3391857`이다. Snapshot과 현재 DB의 사용자 테이블을 양방향 대조해 승인된 meaning·note 교체, relation 2행과 active history 4행 외 차이가 없음을 확인했다.
- Work·seed·snapshot integrity check는 `ok`, foreign key 위반은 0이며 work·seed SQLite sidecar는 없다.
- 새 manifest와 현행 표기정비 authority를 포함한 semantic progress에서 H0028은 `explicit_approved / approved`이고 전체 집계는 `explicit_approved=95`, `hold=2`, `unapproved=14,201`, anomaly 113건이다.
- Targeted approved-content applicator 테스트 29건이 모두 통과했다. Production Dart·schema·seed·UI/UX는 변경하지 않았고 사용자 UI 수동 테스트는 N/A다.
