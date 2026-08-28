# H21 결정

- 상태: `active`
- 기록 성격: 승인 시점 작성
- 판단 근거 복원 수준: 높음
- 대상: H0021; H0001은 관계 문맥
- 승인 manifest: [h21_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h21_cluster_approved_content_slice.json)
- 로컬 연구 산출물: `H21_cluster_20260828_708b04a8`
- DB 적용: 2026-08-28, history group `1787924316328349`
- Git 반영: 승인 manifest와 같은 release commit에 포함

## 최종 결정

- meaning: `아비 (인)`
- 비고: 히스기야의 어머니이자 스가랴의 딸이며, 왕하 18:2의 아비(H0021)와 병행되는 대하 29:1의 아비야(H0029)가 같은 인물임을 설명
- relation: H0001→H0021 `morphological / derived / asserted / w1_to_w2`
- H0021–H0029 relation: 생성하지 않음
- hold: 없음

## 핵심 판단 근거

H0021의 canonical occurrence는 왕하 18:2 한 건이며, 형태 `אֲבִ֖י`는 히스기야의 어머니 이름으로만 쓰인다. Strong의 정의와 KJV·한국어 번역·원전분해 참고자료도 모두 인명 `아비`에 수렴하고, 일반명사 ‘아버지’를 요구하는 occurrence나 반례는 없다. 현행 `아비 (인)`은 이 인명 의미를 보존하면서 일반명사와 구분하므로 그대로 승인했다.

Canonical Strong은 H0021을 `from H1; fatherly`라고 설명한다. Source-reference 표기는 H0021→H0001이지만 의미상 파생 방향은 기반 어휘 H0001에서 인명 H0021로 향하므로 H0001→H0021 관계를 승인했다. 관계 qualifier에 `probably`·`perhaps` 같은 약화 표지가 없고, 기존 파생 관계 계약과도 일치하므로 `asserted`를 사용한다.

왕하 18:2와 대하 29:1은 같은 왕·어머니·외조부를 제시하므로 H0021 아비와 H0029 아비야는 같은 인물로 판단했다. 다만 두 Strong 사이에 직접 canonical lexical edge가 없으므로 동일 인물 정보는 비고에 남기고 별도 relation은 만들지 않았다.

## 채택하지 않은 주요 대안

- `아비`: 의미상 가능하지만 일반명사와 겹치고 현행 인명 표시를 제거하므로 채택하지 않았다.
- `나의 아버지`: 이름의 어원 풀이 후보이지 occurrence의 인명 referent를 나타내는 대표 meaning이 아니므로 채택하지 않았다.
- `아비야`: 병행 본문의 동일 인물 이름이지만 H0021의 실제 표제어와 occurrence가 아니므로 H0021 meaning으로 사용하지 않았다.
- H0021–H0029 relation: 동일 인물이라는 문맥과 직접 lexical relation을 구분해야 하며 canonical edge가 없어 생성하지 않았다.
- hold: source language `x-pn`은 미확정이지만 인물 식별·한국어 표기·occurrence coverage를 흔들지 않으므로 두지 않았다.

## 남은 불확실성 및 재검토 조건

H0021과 H0029의 정확한 onomastic 축약·variant 관계는 직접 canonical 근거로 확정되지 않았다. Provenance가 검증된 전문 onomasticon이나 lexicon이 두 형식의 관계를 직접 확증하거나 반증할 때 H0021–H0029 relation만 재검토한다. 그 전에는 동일 인물이라는 이유만으로 variant relation을 자동 생성하지 않는다.
