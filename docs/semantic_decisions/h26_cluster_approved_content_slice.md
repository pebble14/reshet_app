# H26 클러스터 결정

- 상태: `partially_superseded`
- 기록 성격: 승인 시점 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-08-31
- 대상: H0026·H1523·H1524·H1525; H0001은 구성 관계 문맥
- 승인 manifest: [h26_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h26_cluster_approved_content_slice.json)
- 로컬 연구 산출물: `H26_cluster_20260831_14b773bb`
- DB 적용: 2026-08-31, history group `1788134879371669`
- 현재 H0026 meaning: [H0026 분석적 합성 표기 결정](h0026_analytic_name_notation_approved_content_slice.md)이 이 기록의 H0026 meaning만 supersede한다. H1523·H1524·H1525와 비고·relation 결정은 계속 active다.

## 마감 검증

- 2026-09-01 semantic progress: canonical 14,298건, `explicit_approved` 68건, `hold` 1건, `unapproved` 14,229건, anomaly 113건
- snapshot identity: `5d5417239797225b34c4d01bf37d5b63752dc8737b604427c706cc5b83307380`
- 산출물 SHA-256: JSON `dbad9548394b3b6af0baaa0403d64ca0e5c4a5a5dd457200b06e1ad235926d8d`, CSV `c7b7102f4cc93d0a00d27ef2f6cb910e711ea7c10eef5a6b876cdbae07bd2838`, Markdown `eefc7e361c6b20cef564605535847491d9ac3ecf334d4a8584bb8778e3785c9f`
- DB SHA-256: work `427a6c2f232464566adb56e5518e22f68db4a7bbfa8c02127a5318c3efc18cee`, seed `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`
- H26 네 항목은 모두 `explicit_approved / approved`이며 H26 manifest를 approval authority로 사용한다. 승인 projection, 비고 3건, 직접 relation 4건, active history 11건이 유지되었고 DB integrity 및 foreign key 검사를 통과했다.

## 최종 결정

- H0026 meaning: `아비가일·아비갈 (인)` 한 행
- H1523 meaning: `즐거워하다` 한 행
- H1524 meaning: `즐거움`, `나이` 두 행
- H1525 meaning: `즐거움` 한 행
- 비고: H0026의 구성·동명 인물·단축형, H1523의 사전상 두려움 가능성과 실제 OSHB 용례, H1524의 동형어 구분과 `나이` 용례를 각각 기록. H1525 비고는 `NULL` 유지
- relation: H0001→H0026과 H1524→H0026은 `morphological / compound / asserted`, H1523→H1524와 H1524→H1525는 `morphological / derived / asserted`
- expression/transliteration: 변경하지 않음
- hold: 없음
- 승인 범위 밖: H1523→H0026, H1525↔H0026과 H0001의 다른 하위 항목은 승인하지 않음

## 핵심 판단 근거

H0026은 본문에서 일반형 `아비가일`과 삼하 17:25의 단축형 `아비갈`이 모두 확인되므로, 실제 표기 변이를 함께 보존하는 기존 인명 관례에 따라 `아비가일·아비갈 (인)`로 정했다. 나발의 아내였다가 다윗의 아내가 된 인물과 아마사의 어머니는 서로 다른 인물이지만 같은 이름 항목에 속한다. H0001과 H1524는 Strong이 직접 제시하는 구성 요소이므로 두 항목에서 H0026으로 향하는 `compound / asserted` 관계를 승인했다.

H1523·H1524·H1525는 같은 즐거움 계열이며 실제 구절에서 H7797·H8055·H8056 등 다른 기쁨 계열 어휘와 나란히 쓰이는 경우가 있다. 이 병렬 용례를 한국어에서도 최소한 구별할 수 있도록 H1523은 `즐거워하다`, H1524·H1525는 `즐거움`을 기본 의미로 정했다. 이는 원어 사이에 절대적인 의미 장벽이 있다는 선언이 아니라, 중복된 한국어 동의어 나열을 줄이면서 어휘 계열을 일관되게 표시하려는 선택이다.

H1524의 `나이`는 H1523에서 파생된 `즐거움`을 다른 말로 번역한 것이 아니다. OSHB가 별도 동형어 1524 b로 분리하는 단 1:10의 용례이며, 해당 문맥에서 감독관이 소년들의 얼굴이 또래보다 수척해 보일 것을 염려하므로 연령 집단을 뜻한다. 따라서 빈도는 한 번뿐이지만 독립 sense로 보존할 근거가 충분하다. H1523→H1524와 H1524→H1525는 Strong의 직접 파생 분석에 약화 qualifier가 없어 `derived / asserted`로 승인했다.

Canonical pair 정렬 때문에 H1524→H0026은 DB에 `H0026_0000, H1524_0000 / w2_to_w1`로 저장하지만 semantic 방향은 H1524→H0026이다. 나머지 세 관계는 `w1_to_w2`로 저장한다.

## 채택하지 않은 주요 대안

- H0026 `아비가일 (인)`: 일반형만 보존하고 실제 단축형 `아비갈`을 누락하므로 유지하지 않았다.
- H0026의 어원 풀이를 meaning으로 사용: 인명 표제의 식별 기능보다 해석을 앞세우므로 어원은 비고와 관계에 보존했다.
- H1523 `기뻐하다` 또는 `기뻐하다, 즐거워하다`: 관련 계열과의 병렬 용례를 한국어에서 구별하기 어렵고 동의어 중복을 남기므로 채택하지 않았다.
- H1525 `기쁨, 즐거움, 환희`: 실제 sense를 늘리지 않으면서 한국어 강도 차이를 과도하게 부여하므로 `즐거움` 한 행으로 정리했다.
- H1524에서 `나이` 제외: 단 1:10의 별도 동형어 용례를 잃으므로 채택하지 않았다.
- H1523→H0026, H1525↔H0026과 H0001의 다른 하위 관계: 직접 lexical 분석이 아니라 전이·추정으로 범위를 넓히므로 승인하지 않았다.
- hold: 네 항목의 meaning·비고와 네 직접 관계를 확정할 근거가 충분하므로 두지 않았다.

## 남은 불확실성 및 재검토 조건

`즐거워하다`와 `즐거움`의 선택은 H7797·H8055·H8056 등과의 의미 범위를 완전히 분리한다는 뜻이 아니다. 이 인접 계열을 전량 연구할 때 더 일관된 한국어 배치가 확인되면 함께 재검토할 수 있다.

Strong은 H1523에 위축된 두려움의 가능성도 언급하지만 현재 확인한 OSHB 46회는 모두 즐거움 문맥으로 설명되므로 독립 meaning으로 두지 않았다. H1524의 `나이`는 단 1:10 한 번뿐인 동형어 sense지만 문맥과 형태 구분이 일치하므로 유지한다. H0001은 대형 허브여서 이번 연구는 H26의 직접 구성 관계만 판단했으며 H0001 전체 클러스터의 semantic closure를 주장하지 않는다.
