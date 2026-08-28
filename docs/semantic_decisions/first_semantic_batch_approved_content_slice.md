# 첫 5-Strong 승인 배치 결정

- 상태: `active`
- 기록 성격: 2026-08-28 소급 작성
- 판단 근거 복원 수준: 제한적
- 대상: H1618, H4200, H4461, H5807, H6378와 직접 파생 관계 3건
- 승인 manifest: [first_semantic_batch_approved_content_slice.json](../../tool/data_provenance/manifests/first_semantic_batch_approved_content_slice.json)
- 적용 커밋: `a7ec825d2659701fad4db83c04daa65c0dfdbbd6`

## 최종 결정

| Strong | 승인 의미 |
|---|---|
| H1618 | 딱지가 생기는 피부병 |
| H4200 | 곳간(저장고) |
| H4461 | 치수 |
| H5807 | 힘 |
| H6378 | 병 |

관계는 `H4058 → H4461`, `H5810 → H5807`, `H6379 → H6378`을 `morphological / derived / asserted`로 승인했다.

## 핵심 판단 근거

남아 있는 manifest와 provenance가 보여 주는 공통 판단은 source-only 영어 gloss의 중복·열거를 그대로 유지하지 않고, 각 항목의 핵심 대상을 자연스러운 한국어 대표어 하나로 정리했다는 것이다. 파생 관계는 canonical source가 기반 Strong을 직접 가리킨 세 pair만 포함했다.

## 채택하지 않은 주요 대안

- H1618의 `scurf`, `scab`, `scurvy`를 각각 별도 sense로 만들지 않았다.
- H4200의 `granary/garner`, H5807의 `might/strength`, H6378의 `flask/box/vial`을 번역어 수만큼 분리하지 않았다.
- H4461에서 `치수` 대신 `측량`, `척도` 등을 택하지 않은 상세 비교 기록은 남아 있지 않으므로 이 대안들이 명시적으로 기각되었다고 확대 해석하지 않는다.

## 남은 불확실성 및 재검토 조건

이 초기 배치는 당시의 상세 용례 분석과 사용자 대안 토론이 보존되지 않았다. 따라서 현행 승인값은 유효하지만, 향후 각 Strong의 전용 cluster 연구에서 대표어가 canonical 용례 전체를 포괄하지 못한다는 근거가 나오면 새 결정으로 대체할 수 있다.
