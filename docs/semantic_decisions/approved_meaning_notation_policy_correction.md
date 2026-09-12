# 승인 meaning 한국어 표기 정책 정비 결정

- 상태: `active`
- 기록 성격: 승인 시점 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-09-12
- 대상: G0005, H0001, H0002, H0006, H0007, H0017, H0340, H1564, H1618, H1655, H2020, H2646, H3958, H4200, H4461, H5005, H6306, H6378
- 정책 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 승인 manifest: [approved_meaning_notation_policy_correction.json](../../tool/data_provenance/manifests/approved_meaning_notation_policy_correction.json)
- DB 적용: 2026-09-12, history group `1789199423626046`
- 적용 전 snapshot: `data/backups/approved_content_batch/20260912T075022811114Z/snapshot.db`

## 최종 결정

이번 결정은 기존 lexical 의미 범위를 다시 연구하거나 확장하는 배치가 아니라, 이미 승인된 meaning의 한국어 표기를 active 정책에 맞게 정비하는 배치다. 최종 ordered projection은 다음과 같다.

| Strong | 최종 meaning |
| --- | --- |
| G0005 | `아빠·아버지` |
| H0001 | `아버지`; `조상(祖上)·선조(先祖)·시조(始祖)` |
| H0002 | `아버지`; `조상(祖上)·선조(先祖)·시조(始祖)` |
| H0006 | `멸망하다(滅亡하다)·죽다`; `멸망시키다(滅亡시키다)·파괴하다(破壞하다)`; `없어지다·없애다`; `잃다·길을 잃다` |
| H0007 | `멸망하다(滅亡하다)·없어지다`; `멸망시키다(滅亡시키다)·없애다` |
| H0017 | `근심` |
| H0340 | `원수(怨讐)로 대하다(對하다)` |
| H1564 | `형체(形體)가 갖추어지지 않은 것` |
| H1618 | `딱지가 생기는 피부병(皮膚病)` |
| H1655 | `몸·신체(身體)` |
| H2020 | `구원(救援)` |
| H2646 | `덮개`; `방(房)` |
| H3958 | `보석(寶石)의 한 종류` |
| H4200 | `곳간·저장고(貯藏庫)` |
| H4461 | `치수(치寸)` |
| H5005 | `간음(姦淫)` |
| H6306 | `속량(贖良)` |
| H6378 | `병(甁)` |

Word note, relation과 hold는 변경하지 않는다. H1655는 동일 lexical sense의 한국어 표현 두 행 `몸`, `신체`를 한 행 `몸·신체(身體)`로 합쳤고, 나머지 Strong은 기존 meaning 행 수와 순서를 유지했다.

## 핵심 판단 근거

동일한 lexical sense 안에서 함께 제시하는 한국어 표현은 slash 대신 가운데점 `·`으로 병기했다. 한자어는 정확한 한자가 확인된 경우 한자어 전체에 병기하고, 동사는 `멸망하다(滅亡하다)`, `파괴하다(破壞하다)`, `대하다(對하다)`처럼 `-하다`까지 괄호 안에 적었다. H0017은 `근심(憂)`의 불완전한 단일 글자 병기를 제거해 `근심`으로 두었다.

H4461의 `치수(치寸)`는 일반 정책의 기계적 자동화 결과가 아니라 사용자가 이 어휘에 대해 명시적으로 확정한 개별 표기다. 개별 어휘에 관한 사용자 결정이 일반 정책보다 우선한다는 정책 경계에 따라 그대로 적용했다.

이번 결정은 이전 클러스터·배치의 증거와 lexical 판단을 폐기하지 않는다. 과거 manifest와 로컬 연구 산출물은 당시 승인과 증거의 기록으로 보존하고, 관련 결정 기록을 `partially_superseded`로 표시하여 현재 projection을 이 문서로 연결한다.

## 채택하지 않은 주요 대안

- 기존 slash와 어간 생략식 `(滅亡-)`, `(破壞-)`을 그대로 유지: active 표기 정책과 맞지 않아 채택하지 않았다.
- H1655의 `몸`, `신체`를 별도 sense 두 행으로 유지: 동일 lexical sense의 한국어 표현이므로 한 행의 가운데점 병기로 정리했다.
- 표기 정비를 계기로 word note·relation·hold 또는 어휘 의미 범위를 다시 판단: 이번 승인 범위를 벗어나므로 변경하지 않았다.
- 과거 결정 문서와 manifest의 당시 값을 현재 값으로 조용히 덮어쓰기: 이력을 보존하기 위해 새 결정 기록과 supersession 연결을 사용했다.

## 남은 불확실성 및 재검토 조건

이번 배치는 한국어 표기 정합화가 목적이므로 기존 lexical 의미 범위와 관계 판단의 정확성을 새로 확정하지 않는다. H1655의 `몸`과 `신체`가 실제 용례에서 서로 다른 lexical sense임을 뒷받침하는 새 근거가 확보되면 행 분리를 재검토할 수 있다. H4461은 사용자의 개별 결정이 바뀌거나 더 적합한 표기 근거가 승인될 때만 재검토한다.

## 적용 및 마감 검증

- Dry-run은 18개 meaning replacement를 임시 DB에 적용한 뒤 실제 undo했고, 원본 work DB SHA-256 `fc77559add7ccdd64af1360db1673287cd40dadae0eed5adc16f102f418ae0d7`을 전후 동일하게 유지했다.
- Live apply 뒤 work DB SHA-256은 `eb89e99f116fa9f8f49a715d0cbc2ed6398b9a18ca763b00ee45c81d05199f3a`이며 seed DB SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다.
- Snapshot과 비교한 사용자 테이블 차이는 승인 대상 `word_meaning_set` projection과 `CHANGE_HISTORY` 18행뿐이다. Work·snapshot integrity check는 `ok`, foreign key 위반은 0이고 work·seed SQLite sidecar는 없다.
- 의미 적용 당시 backup manifest SHA-256은 `ea03e105a759c76c27abe2a5531d7f158275eb59268eaadc407f18228e962721`이다. 적용 뒤 진행 보고가 이전 첫 배치의 실제 ID를 엄격히 대조하면서 4개 supersession 문자열의 명칭 오기를 발견했으며, 최종 manifest에서 `RESHET-EC-FIRST-5-STRONG-APPROVED-CONTENT-SLICE`로 바로잡았다. 최종 manifest SHA-256은 `7d8b32d45b83e07b7cdc4b309eb3fa453374532b7dab3f694e9582606af69665`이고 두 파일의 차이는 이 4개 metadata 문자열뿐이며 meaning operation payload는 동일하다.
- 새 manifest를 명시적으로 포함한 semantic progress는 canonical 14,298건, `explicit_approved=94`, `hold=2`, `unapproved=14,202`, anomaly 113건이다. 18개 대상 모두 새 manifest를 유일한 active approval authority로 가지며 현재 DB projection과 exact 일치한다.
- `../reshet_research_output/semantic_progress`의 JSON·CSV·Markdown도 같은 현재 DB와 새 manifest로 재생성했다. 출력 루트에 `00_CURRENT_APPROVED_MEANING_NOTATION_20260912.md`를 추가하고 관련 클러스터 summary·review·연구 메모 19개 상단에 현재 승인값과 연구 당시 스냅샷 경계를 표시했다. Evidence Packet·research state·database audit JSON은 당시 증거와 입력을 재현하는 immutable 스냅샷으로 보존했다.
- Applicator 대상 Flutter 테스트 29건은 모두 통과했다. Production Dart·schema·seed·UI/UX는 변경하지 않았으므로 사용자 UI 수동 테스트는 N/A다.
