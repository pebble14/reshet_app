# H22 결정

- 상태: `active`
- 기록 성격: 승인 시점 작성
- 판단 근거 복원 수준: 높음
- 대상: H0022; H0001·H0410은 합성 관계 문맥, H0045는 평행 명단 문맥
- 승인 manifest: [h22_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h22_cluster_approved_content_slice.json)
- 로컬 연구 산출물: `H22_cluster_20260829_550155e1`
- DB 적용: 2026-08-29, history group `1787969418635585`
- Git 반영: 승인 manifest와 같은 release commit에 포함

## 최종 결정

- meaning: `아비엘 (인)`
- 비고: 두 이스라엘 사람의 이름과 각 인물의 문맥, H0001·H0410의 결합에 따른 일반적 이름 풀이, 대상 11:32와 삼하 23:31의 아비엘·아비알본 평행을 함께 기록
- relation: H0001→H0022, H0410→H0022 각각 `morphological / compound / asserted`
- H0022–H0045 relation: 생성하지 않음
- hold: 없음
- 승인 범위 밖: H0001의 기존 승인은 그대로 유지하며 H0410·H0045의 독립 meaning은 이번 결정으로 승인하지 않음

## 핵심 판단 근거

H0022의 canonical occurrence 세 건은 삼상 9:1·14:51의 사울 가문 조상과 대상 11:32의 다윗 용사라는 두 이스라엘 사람을 가리킨다. 모두 같은 인명 표제어의 실제 이름 용례이며 별도의 보통명사 sense나 인물별 meaning 분리를 요구하지 않는다. 현행 `아비엘 (인)`은 표제어를 자연스럽게 보존하고 인명임을 분명히 하므로 그대로 승인했다.

Canonical Strong은 H0022를 H0001과 H0410에서 온 이름으로 직접 분석하고 두 구성 요소를 아버지와 엘/하나님에 연결한다. 따라서 구성 어휘에서 합성 인명으로 향하는 H0001→H0022와 H0410→H0022 두 관계를 승인했다. 원천에 추정 qualifier가 없고 구성 관계가 명시적이므로 `asserted`를 사용한다. DB의 canonical pair 정렬 때문에 두 번째 관계는 H0022·H0410 순서와 `w2_to_w1`로 저장하지만 semantic 방향은 H0410→H0022다.

대상 11:32의 아비엘과 평행 명단인 삼하 23:31의 아비알본(H0045)은 같은 명단 위치를 설명하는 중요한 문맥이다. 그러나 H0022와 H0045 사이의 직접 canonical lexical edge나 정확한 variant 유형을 확정하는 근거는 없으므로 이 사실은 비고에만 보존하고 relation은 만들지 않았다.

## 채택하지 않은 주요 대안

- `엘(하나님)은 나의 아버지`: 이름의 일반적 풀이이지 occurrence에서 사람을 가리키는 대표 meaning이 아니므로 meaning 대신 비고에 기록했다.
- 인물별 복수 meaning: 두 referent는 하나의 고유명사를 공유하므로 lexical sense를 둘로 나누지 않았다.
- H0022–H0045 variant relation: 평행 명단의 대응만으로 정확한 lexical relation 유형을 단정할 수 없어 생성하지 않았다.
- H0410·H0045 독립 승인: 이번 검토의 대상은 H0022와 그 관계이며 두 Strong의 전체 semantic projection을 별도로 심사한 것이 아니므로 승인 범위에서 제외했다.
- hold: source language가 `x-pn / unresolved`이고 이름 형식의 세부 관계가 남아 있지만 H0022의 인명 의미·표기·canonical occurrence coverage와 두 구성 관계를 막지는 않으므로 두지 않았다.

## 남은 불확실성 및 재검토 조건

H0022 이름 풀이의 세부 문법과 H0045 아비알본과의 정확한 onomastic 관계는 현재 근거로 하나의 relation type까지 확정하지 않는다. Provenance가 검증된 전문 onomasticon이나 critical lexicon이 H0022–H0045의 직접 관계를 명시하거나 H0001·H0410 구성 분석을 실질적으로 바꿀 때 관련 비고와 relation만 재검토한다. LXX human reference의 `αβιηλ` 대조는 보조 자료이며 provenance가 검증되기 전에는 canonical authority로 승격하지 않는다.
