# Semantic 결정 기록

이 디렉터리는 Reshet 어휘 연구에서 사용자가 최종 승인한 의미·비고·관계와 그 판단 근거를 단어 또는 논리적 클러스터 단위로 기록한다. 전체 조사 일지를 복제하지 않고, 나중에 프로젝트 열람자·사용자·Codex가 **무엇을 왜 선택했는지** 빠르게 확인하는 것이 목적이다.

## 문서의 역할

- 승인 manifest는 정확히 적용되거나 승인된 값과 provenance를 기록한다.
- work DB는 현재 projection을 기록한다.
- Evidence Packet·Review·cluster summary는 상세 증거와 후보를 보존한다.
- 이 디렉터리의 기록은 증거에서 최종 선택으로 이어진 판단을 간결하게 설명한다.

값이 충돌하면 현재 사용자 지시, 현재 DB와 active 승인 manifest를 우선한다. 이 기록만으로 DB나 manifest를 수정해서는 안 된다. 과거 판단을 변경할 때는 기존 기록을 덮어써서 이력을 지우지 말고 새 승인 manifest와 결정 기록을 추가한 뒤 이전 기록을 `superseded` 또는 `partially_superseded`로 표시한다.

## 상태와 복원 수준

- `active`: 현재 결정이 그대로 유효하다.
- `partially_superseded`: 일부 의미나 관계가 후속 승인으로 대체되었고 나머지는 유효하다.
- `superseded`: 전체 결정이 후속 승인으로 대체되었다.
- 복원 수준 `높음`: 연구 산출물, 사용자 판단 대화, manifest와 Git 이력이 함께 남아 있다.
- 복원 수준 `중간`: 연구 산출물과 적용 기록은 있으나 당시의 대안 토론 일부가 남아 있지 않다.
- 복원 수준 `제한적`: manifest와 provenance로 최종값은 확인되지만 당시의 선택 이유는 최소한만 복원할 수 있다.

`소급 작성`은 이 문서가 결정 당시가 아니라 2026-08-28에 작성되었다는 뜻이다. 복원 수준이 낮은 항목에서는 확인되지 않은 이유를 추정해 채우지 않는다.

## 결정 색인

| 결정 단위 | 대상 | 상태 | 복원 수준 | 최초 적용일 | 기록 |
|---|---|---|---|---|---|
| P2 승인 배치 | H2020, H5005, H6306, H6772와 파생 관계 | `partially_superseded` | 제한적 | 2026-08-10 | [기록](p2_approved_content_slice.md) |
| H1672·H1674 | 걱정하다·걱정 | `active` | 중간 | 2026-08-13 | [기록](h1672_h1674_approved_content_slice.md) |
| 첫 5-Strong 배치 | H1618, H4200, H4461, H5807, H6378 | `partially_superseded` | 제한적 | 2026-08-13 | [기록](first_semantic_batch_approved_content_slice.md) |
| 두 번째 semantic 배치 | H1564, H2251, H3958, H5229; H1833 hold | `partially_superseded` | 중간 | 2026-08-14 | [기록](second_semantic_batch_approved_content_slice.md) |
| P1 historical 승인 복원 | H1653, H1655, H1656 | `partially_superseded` | 제한적 | 2026-08-14 | [기록](p1_historical_approval_approved_content_slice.md) |
| H2646 | 덮개·방 | `partially_superseded` | 중간 | 2026-08-14 | [기록](h2646_approved_content_slice.md) |
| 세 번째 semantic 배치 | H1563, H1652, H5228, H5229, H6770, H6772, H2645와 관계 | `active` | 중간 | 2026-08-14·20 | [기록](third_semantic_batch_approved_content_slice.md) |
| H1·H2·G5 | 아버지 계열과 G5 호격 | `partially_superseded` | 높음 | 2026-08-22 | [기록](h1_h2_g5_meaning_approval_approved_content_slice.md) |
| H3 클러스터 | H3, H4, H24와 합성 관계 | `active` | 높음 | 2026-08-22 | [기록](h3_cluster_approved_content_slice.md) |
| H5 인명 | 아박다·아바그타 | `active` | 높음 | 2026-08-25 | [기록](h5_name_approved_content_slice.md) |
| H6 클러스터 | 멸망·상실 계열과 아바돈 | `partially_superseded` | 높음 | 2026-08-25 | [기록](h6_cluster_approved_content_slice.md) |
| H14 클러스터 | 원함·갈망·적대 관련 14개 Strong | `partially_superseded` | 높음 | 2026-08-25 | [기록](h14_cluster_approved_content_slice.md) |
| H18 클러스터 | 구유·살찌우다·곡물 창고 | `active` | 높음 | 2026-08-27 | [기록](h18_cluster_approved_content_slice.md) |
| H19 | 칼의 번뜩임 | `active` | 높음 | 2026-08-27 | [기록](h19_cluster_approved_content_slice.md) |
| H20 | 수박 | `active` | 높음 | 2026-08-28 | [기록](h20_cluster_approved_content_slice.md) |
| H21 | 아비와 H1 파생 관계 | `active` | 높음 | 2026-08-28 | [기록](h21_cluster_approved_content_slice.md) |
| H22 | 아비엘과 H1·H410 합성 관계 | `active` | 높음 | 2026-08-29 | [기록](h22_cluster_approved_content_slice.md) |
| H23 클러스터 | 아비아삽·아비-아사프와 에비아삽·에브야사프 | `active` | 높음 | 2026-08-30 | [기록](h23_cluster_approved_content_slice.md) |
| H25 | 기브온의 아버지와 H1·H1391 구성 관계 | `active` | 높음 | 2026-08-30 | [기록](h25_cluster_approved_content_slice.md) |
| H26 클러스터 | 아비가일·아비갈과 H1523–H1525 즐거움 계열 | `partially_superseded` | 높음 | 2026-08-31 | [기록](h26_cluster_approved_content_slice.md) |
| H27 클러스터 | 판단·송사·단·다니엘·미디안 계열 25개 승인과 H1777·H4092 hold | `partially_superseded` | 높음 | 2026-09-12 | [기록](h27_cluster_approved_content_slice.md) |
| H1777 | 심판·변호·다툼·다스림 의미와 창세기 6:3 해석 비고, hold 해제 | `active` | 높음 | 2026-09-12 | [기록](h1777_meaning_note_approved_content_slice.md) |
| 승인 meaning 표기 정책 정비 | 기존 승인 18개 Strong의 한국어 meaning 표기 | `active` | 높음 | 2026-09-12 | [기록](approved_meaning_notation_policy_correction.md) |
| H0026 분석 표기 | 아비가일·아비갈·아비-가일·아비-갈 | `active` | 높음 | 2026-09-12 | [기록](h0026_analytic_name_notation_approved_content_slice.md) |

## 열람 및 후속 판단 원칙

1. 새 제안을 만들기 전에 관련 Strong이 이 색인에 있는지 확인한다.
2. 관련 기록의 최종 결정·배제 대안·잔여 불확실성을 읽은 뒤 active manifest와 현재 DB projection을 대조한다.
3. 기존 결정을 단순히 다시 제안하지 않는다. 새 근거가 기존 판단을 실질적으로 바꿀 때만 재검토 후보로 보고한다.
4. 새 근거가 있어도 Codex가 기존 결정을 자동으로 폐기하지 않는다. 사용자가 최종 결정한다.
5. 로컬 연구 산출물 이름은 상세 근거를 찾기 위한 식별자다. 연구 산출물은 Git tracked authority가 아니며 다른 checkout에 존재하지 않을 수 있다.
