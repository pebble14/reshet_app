# H471 엘리아김 어휘군 승인 결정

- 상태: active · 결정 및 최초 적용일 2026-11-23 · 복원 수준 높음
- 승인 근거: 사용자의 R2 수락 및 DB·문서·검증·Git 실행 승인
- [승인 매니페스트](../../tool/data_provenance/manifests/h471_cluster_approved_content_slice.json)
- 로컬 연구 산출물: reshet_research_output/H0471_cluster_20261123_8a56c9e3/00_cluster_summary.md (R2)

## 최종 결정

| Strong | 승인 뜻 |
|---|---|
| H0471 | 엘리야김·엘리아김·엘-야킴 (인) |
| G1662 | 엘리아김·엘리야김·엘-야킴 (인) |
| H3079 | 여호야김·예호-야킴 (인) |
| H3113 | 요야김·요-야킴 (인) |
| H3137 | 요김·요-킴 (인) |
| G0885 | 아킴·아케임 (인) |
| H3356 | 야김·야킴 (인) |
| H3359 | 여가먀·예캄-야 (인) |
| H7055 | 그므엘·그무엘·케무-엘 (인) |
| H3360 | 여가므암·예캄-암 (인) |
| H3361 | 욕므암·요크메-암 (지) |

각 뜻은 하나의 의미다. 비고 11건의 전문은 승인 매니페스트의 word_note_replacements에 있다. 새 hold는 없다.

| 관계 ID | 의미 방향 | 분류/유형 | 상태 | 저장 방향 |
|---|---|---|---|---|
| 8552 | H0471 → H3079 | unspecified/related | asserted | w1_to_w2 |
| 8553 | H3068 → H3079 | morphological/compound | asserted | w1_to_w2 |
| 8554 | H6965 → H3079 | morphological/compound | asserted | w2_to_w1 |
| 8555 | H3079 → H3113 | morphological/variant | asserted | w1_to_w2 |
| 8556 | H3113 → H3137 | morphological/variant | asserted | w1_to_w2 |
| 8557 | H6965 → H3356 | morphological/derived | asserted | w2_to_w1 |
| 8558 | H3050 → H3359 | morphological/compound | asserted | w1_to_w2 |
| 8559 | H6965 → H3359 | morphological/compound | asserted | w2_to_w1 |
| 8560 | H0410 → H7055 | morphological/compound | asserted | w1_to_w2 |
| 8561 | H6965 → H7055 | morphological/compound | hypothesized | w1_to_w2 |
| 8562 | H6965 → H3360 | morphological/compound | asserted | w2_to_w1 |
| 8563 | H5971 → H3360 | morphological/compound | hypothesized | w2_to_w1 |
| 8564 | H6965 → H3361 | morphological/compound | hypothesized | w2_to_w1 |
| 8565 | H5971 → H3361 | morphological/compound | hypothesized | w2_to_w1 |
| 3168 | H0410 → H0471 | morphological/compound | asserted | w1_to_w2 |
| 6351 | H6965 → H0471 | morphological/compound | asserted | w2_to_w1 |
| 3169 | H0471 → G1662 | transliteration/direct_transliteration | asserted | w2_to_w1 |

## 핵심 판단 근거

- H0471의 라메드 셰와는 묵음으로 읽고, H3360의 어두 셰와는 약모음으로 읽으며 멤의 셰와는 묵음으로 읽는다. 엘-야킴과 예캄-암을 유지했다.
- G1662는 H0471과 같은 이름의 헬라어 전승형이다. 개역 계열·새번역의 관용명과 원천 이름의 분석형을 뜻에 두고, 엘리아케임 및 엘리아킴은 비고에 기록했다.
- 왕하 23:34와 대하 36:4의 실제 개명은 H0471에서 H3079로 향한다. H3079·H3113·H3137의 형태 대응은 해당 이름을 쓴 인물들의 식별과 구별한다.

## 채택하지 않은 대안과 재검토 조건

- 아킴의 히브리어 원천으로 요김·야김·야긴과 비교할 근거가 있으나 마태의 실제 히브리어 이름은 미확정이다. 특정 원천을 뒷받침하는 자료가 생기면 병기 및 관계를 재검토한다.
- H7055의 앞 요소와 H3360·H3361의 일부 구성에는 경쟁 분석이 있어 가설 관계를 적용했다. 욕므암·욕느암의 동일 지명 관계와 엘리가·엘리아김의 단축형 관계는 보류했다. 렘 27:1의 본문 이견은 H3079 비고에 기록했다.

## 적용과 검증

- 공식 사본 적용·undo와 적용기 테스트 31개 통과. 독립 SQL로 사용자 테이블 12개, DDL, 비대상 행 및 기존 이력을 대조했다. 작업 DB·seed·백업·스냅샷의 무결성은 ok이며 외래 키 위반과 sidecar는 0건이다.
- 이력 그룹 1795433147824524, 변경 이력 39행(ID 8502–8540).
- 공식 진행표 승인 1,160→1,171, 미승인 13,131→13,120, hold 7, 이상 항목 113. 비대상 14,287행과 JSON·CSV·Markdown의 일치를 확인했다.
- 작업 DB SHA-256: 1a245a7fb57937328206ea702a29d9cb2d063632b39aa07a1ca6f7dc3a84e8aa
- 진행표 스냅샷 SHA-256: 9f0e82d7959308af38a3d3eeabaf9913ac0d30c89a4533e6a45afb44e7cc55d4
- 적용 영수증: data/backups/approved_content_batch/20261123T112546048018Z/result.json
- 로컬 독립 검증: data/backups/approved_content_batch/h471_approval_20261123/independent_verification.json
