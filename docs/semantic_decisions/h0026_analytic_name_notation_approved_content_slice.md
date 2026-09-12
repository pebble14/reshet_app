# H0026 분석적 합성 표기 결정

- 상태: `active`
- 기록 성격: 승인 시점 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-09-12
- 대상: H0026 meaning 한 행
- 정책 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 승인 manifest: [h0026_analytic_name_notation_approved_content_slice.json](../../tool/data_provenance/manifests/h0026_analytic_name_notation_approved_content_slice.json)
- DB 적용: 2026-09-12, history group `1789203793160663`
- 적용 전 snapshot: `data/backups/approved_content_batch/20260912T090312352183Z/snapshot.db`

## 최종 결정

H0026의 ordered meaning 한 행을 다음과 같이 정한다.

`아비가일·아비갈·아비-가일·아비-갈 (인)`

`아비가일`과 `아비갈`은 한국어 성경에서 확인되는 일반형과 단축형이고, `아비-가일`과 `아비-갈`은 각 형태의 합성 경계를 드러내는 분석 표기다. Word note, expression/transliteration, relation과 hold는 변경하지 않는다.

## 핵심 판단 근거

기존 H26 결정에서 H0001과 H1524가 H0026의 직접 구성 요소이며 두 관계가 `morphological / compound / asserted`로 승인되었다. 따라서 붙임표로 표시할 합성 경계에는 충분한 근거가 있다. 관용 표기 두 개는 본문 식별을 위해 보존하고, 분석 표기 두 개를 추가해 일반형과 단축형 모두의 내부 구조를 meaning에서 직접 확인할 수 있게 한다.

붙임표는 원문의 마케프를 재현하는 문자가 아니라 한국어 분석 기호다. 네 표기는 서로 다른 lexical sense가 아니므로 별도 meaning 행으로 나누지 않고 가운데점으로 한 행에 병기한다.

## 채택하지 않은 주요 대안

- `아비가일·아비갈 (인)` 유지: 본문 식별에는 충분하지만 이미 승인된 합성 구조를 meaning에서 확인할 수 없어 채택하지 않았다.
- `아비-가일·아비-갈 (인)`로 관용형 대체: 합성 구조는 간결하게 드러나지만 한국어 성경의 실제 표기를 그대로 식별하는 층위를 잃으므로 채택하지 않았다.
- 장형 또는 단축형 중 하나에만 분석 표기 추가: 두 표면형이 모두 같은 합성 구조의 변이이므로 한쪽만 분석형을 두는 비대칭을 피했다.
- 어원 풀이를 meaning으로 추가: 인명 식별과 분석 표기보다 설명이 길어지며 기존 비고와 relation에 이미 보존되어 있으므로 추가하지 않았다.

## 남은 불확실성 및 재검토 조건

현재 결정은 Strong이 직접 제시하고 기존 H26에서 승인된 H0001·H1524 구성 분석을 따른다. Provenance가 검증된 전문 인명 사전이 합성 경계나 단축 과정에 실질적으로 다른 분석을 제시하면 `아비-가일`·`아비-갈` 표기를 재검토할 수 있다.

## 적용 및 마감 검증

- Dry-run은 meaning replacement 한 건을 임시 DB에 적용한 뒤 실제 undo했고, 원본 work DB SHA-256 `eb89e99f116fa9f8f49a715d0cbc2ed6398b9a18ca763b00ee45c81d05199f3a`을 전후 동일하게 유지했다.
- Live apply 뒤 work DB SHA-256은 `71b348a889c5de2a2ddbeae5e235bdf38d28a7349de458a0d7f1cd0413fbc21f`이며 seed DB SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다.
- 적용 전 snapshot SHA-256은 `a3830c0ca2ce12e623a8e38a2dd43ea8fbe76fcfa2a006cb933351299c93566f`이고, snapshot과 현재 DB의 사용자 테이블 차이는 `word_meaning_set`의 교체 전후 각 한 행과 `CHANGE_HISTORY`의 active 한 행뿐이다.
- Work·snapshot integrity check는 `ok`, foreign key 위반은 0이고 work·seed SQLite sidecar는 없다.
- Manifest SHA-256은 `bcb26ac94a4bda215db1074ca9768038029a0a1c5dc4388dcfe5b43320e2c29c`이다.
- 기존 18개 표기정비 manifest와 새 H0026 manifest를 명시한 semantic progress는 canonical Strong 14,298건, `explicit_approved=94`, `hold=2`, `unapproved=14,202`, anomaly 113건이다. H0026은 새 manifest를 유일한 active authority로 하는 `explicit_approved / approved`이며 현재 meaning과 exact 일치한다.
- `../reshet_research_output/semantic_progress` 산출물 SHA-256은 JSON `cf1ea41fecfddf6926c99c36caa82745d8adf94cb6ed8de514bd647aab1721ea`, CSV `d348ca2b4aa5280a9abd7d080ec46311e682b6340e79d1df081a351460e75716`, Markdown `72300696f2da89cd83fc1559a8ce6bd8e879a01158040400293dce64776cc7be`이다. 외부 현재값 색인과 H26 summary·review 안내도 같은 meaning으로 갱신했다.
- Production Dart·schema·seed·UI/UX는 변경하지 않았다. Applicator 구현은 직전 표기정비 slice에서 통과한 대상 테스트 29건과 동일하며, 이번에는 exact manifest dry-run·live apply·snapshot diff로 변경 한 건을 검증했으므로 테스트를 반복 실행하지 않았다. 사용자 UI 수동 테스트는 N/A다.
