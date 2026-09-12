# H6 클러스터 결정

- 상태: `partially_superseded` — H0006·H0007 meaning 표기는 후속 정책 정비 결정으로 대체됨
- 기록 성격: 2026-08-28 소급 작성
- 판단 근거 복원 수준: 높음
- 대상: H0006~H0013, G0003
- 승인 manifest: [h6_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h6_cluster_approved_content_slice.json)
- 적용 커밋: `90b7c593cfd7cf95b48ba718ebf41722f20fc67f`
- 로컬 연구 산출물: `H6_cluster_20260825_84ee4fbc`
- 후속 결정: [승인 meaning 한국어 표기 정책 정비](approved_meaning_notation_policy_correction.md)

## 최종 결정

| Strong | 승인 의미 |
|---|---|
| H0006 | `멸망하다(滅亡-)/죽다`; `멸망시키다(滅亡-)/파괴하다(破壞-)`; `없어지다/없애다`; `잃다/길을 잃다` |
| H0007 | `멸망하다(滅亡-)/없어지다`; `멸망시키다(滅亡-)/없애다` |
| H0008 | `멸망(滅亡)` |
| H0009 | `잃어버린 것` |
| H0010 | `멸망(滅亡)` |
| H0011 | `멸망(滅亡)` |
| H0012 | `멸망(滅亡)` |
| H0013 | `멸망(滅亡)` |
| G0003 | `아바돈·아밧돈` |

비고는 H6의 어간별 의미 분포, H10의 기록형·H11 독음형 경계, H11의 멸망 장소 문맥, G3의 관용 표기·음역·H11 기원·G623 대응을 설명한다. H9의 중복 비고는 삭제했다. G3의 기존 expression/transliteration `아받돈`은 변경하지 않았다.

관계 결정은 다음과 같다.

- `H0006 ↔ H0007`: `etymological / root_shared / asserted`
- `H0006 → H0008·H0009·H0011·H0012·H0013`: `morphological / derived / asserted`
- `H0009 ↔ H0010`: `morphological / variant / uncertain`
- `H0011 → H0010`: `morphological / variant / asserted`
- `H0011 → G0003`: `transliteration / direct_transliteration / asserted`
- `G0003 → G0623`: `translation / semantic_translation / asserted`
- 기존 relation id 475 `H0006–H0010 / unspecified / related / inferred / unknown`은 삭제하지 않고 그대로 남김

## 핵심 판단 근거

H6의 185개 canonical occurrence는 멸망·죽음, 사역적 파괴, 소멸, 상실·방황 범위가 실제 어간과 문맥에 따라 반복되어 하나의 한국어 동사로는 부족했다. 반대로 H8과 H10~H13은 각 문맥의 세부 번역을 별도 sense로 늘리기보다 공통 핵심 명사 `멸망`으로 통일하고, 장소·기록형 같은 차이는 비고와 관계에서 설명했다. H9는 분실된 대상을 가리키므로 `잃어버린 것`으로 분리했다.

사용자는 H10·H11을 `멸망의 구덩이`, H12를 `진멸`로 좁혀야 하는지 재검토한 뒤, 클러스터 공통 의미를 보존하는 `멸망`이 더 담백하다는 결론에 동의했다. `파멸`도 가능하지만 별도 이득 없이 같은 family의 표현을 흩뜨리므로 채택하지 않았다.

G3는 교회 전통의 관용명 `아바돈`을 유지하면서, 헬라어가 히브리어 H11을 음역한 이름임을 독자가 알 수 있도록 한국어 표기 관습에 따른 `아밧돈`을 meaning에 병기했다. 이는 문자 대응용 transliteration 값을 바꾸는 결정이 아니었다.

## 채택하지 않은 주요 대안

- H10·H11의 대표 meaning을 `멸망의 구덩이`로 좁히지 않고 장소성은 비고에 보존했다.
- H12를 `진멸(殄滅)` 또는 `파멸`로 따로 두지 않고 cluster 공통 `멸망`을 사용했다.
- G3 expression/transliteration을 `아밧돈`으로 바꾸지 않았다. 사용자의 요구는 meaning 병기였고 기존 문자 대응값은 보존 대상이었다.
- Relation id 475 삭제는 applicator가 지원하지 않아 임의 SQL로 우회하지 않았다. 사용자가 삭제를 제외한 나머지 적용을 승인했으며, 이 잔존은 semantic 재승인을 뜻하지 않는다.

## 남은 불확실성 및 재검토 조건

H10은 기록형·독음형 경계 때문에 확신도가 상대적으로 낮고, H12·H13은 hapax다. H9–H10은 상충하는 source 설명을 `uncertain` 관계로 보존했다. Raw cluster 실행은 verse-number markup false edge 때문에 closure가 미완료였지만 CORE 9개와 meaningful relation은 독립적으로 전량 확인했다. Relation id 475는 applicator가 안전한 delete 계약을 지원하고 사용자가 다시 승인할 때만 정리한다.
