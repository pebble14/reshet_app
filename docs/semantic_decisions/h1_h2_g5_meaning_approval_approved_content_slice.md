# H1·H2·G5 의미 결정

- 상태: `partially_superseded` — H0001·H0002·G0005 meaning 표기는 후속 정책 정비 결정으로 대체됨
- 기록 성격: 2026-08-28 소급 작성
- 판단 근거 복원 수준: 높음
- 대상: H0001, H0002, G0005
- 비고 manifest: [g5_word_note_approved_content_slice.json](../../tool/data_provenance/manifests/g5_word_note_approved_content_slice.json)
- 현행 의미 승인 manifest: [h1_h2_g5_meaning_approval_approved_content_slice.json](../../tool/data_provenance/manifests/h1_h2_g5_meaning_approval_approved_content_slice.json)
- 적용 커밋: `c38c5532ff175e2d1570478c13e4f5b2f6f31d04`, `3c34abe8897c0717e9986c9eca88c893470896d6`
- 로컬 연구 산출물: `H1_cluster_20260822_ab8ec1aa`
- 후속 결정: [승인 meaning 한국어 표기 정책 정비](approved_meaning_notation_policy_correction.md)

## 최종 결정

- H0001: `아버지`; `조상(祖上)/선조(先祖)/시조(始祖)`
- H0002: `아버지`; `조상(祖上)/선조(先祖)/시조(始祖)`
- G0005: `아빠/아버지`
- G0005 비고: 아람어 אַבָּא를 헬라어로 음역한 호격이고 세 신약 용례가 모두 `아바, 아버지` 문맥이며, `아빠`는 같은 의미를 친근하게 나타낸 한국어 표현이라고 설명
- 관계: 이 승인 slice에서는 생성·교체하지 않음

H1·H2·G5의 의미는 DB 값을 바꾸지 않고 `meaning_approvals`로 현재 projection 자체를 승인했다. G5 비고만 별도 manifest에서 교체했다.

## 핵심 판단 근거

H1의 1,213회와 H2의 9회 canonical occurrence는 `아버지`와 조상·선대자 범위의 두 축으로 포괄된다. 사용자는 본래 한자어인 조상·선조·시조에 한자를 병기하는 기존 방식을 유지하기로 했다. 의미가 겹치더라도 현재 표현이 혈연·선대·시조 범위를 독자가 알아보기 쉽게 보존한다고 판단했다.

G5는 신약의 세 용례 모두 아람어 호격을 헬라어로 음역한 `Abba, Father` 문맥이다. Lexical 핵심은 `아버지`이지만, 사용자는 음역된 호칭과 한국어의 친근한 표현을 독자가 함께 이해할 수 있도록 `아빠/아버지`를 유지하기로 했다. 대신 기존 비고에 있던 G5의 `조상` 설명은 실제 세 용례가 지지하지 않으므로 제거했다.

## 채택하지 않은 주요 대안

- H1·H2를 `아버지`; `조상/선조`로 단순화하고 한자와 `시조`를 제거하는 제안을 채택하지 않았다.
- G5를 canonical gloss에 맞춰 `아버지` 하나로만 좁히지 않았다.
- G5에 `조상` sense를 유지하지 않았다. Canonical source와 3/3 occurrence에서 지지되지 않기 때문이다.
- H1–H2 관계를 asserted로 승격하거나 H2→G5 borrowed-from 관계를 생성하는 연구 제안은 이 최종 승인 manifest에 포함하지 않았다. 이는 이번 결정에서 미채택한 것이며 자동으로 영구 기각된 것으로 확대하지 않는다.

## 남은 불확실성 및 재검토 조건

H1 raw graph는 고유명사 생산성과 약한 비교 edge 때문에 closure가 미완료지만, CORE 세 단어의 1,225개 occurrence는 전량 검토되었다. 의미 승인은 충분하되 관계 제안은 별도 승인 대상으로 남는다. G5의 `아빠`는 별도 lexical sense라기보다 register·음역 이해를 돕는 병기라는 경계를 유지한다.
