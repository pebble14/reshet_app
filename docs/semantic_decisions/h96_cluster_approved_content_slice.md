# H96·H97 방울·에글라임 어휘군 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-16 (Asia/Seoul)
- 대상: H0096, H0097
- 승인 manifest: [h96_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h96_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 신규 hold 없음·기존 6건 유지
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 로컬 연구 산출물: `C:/Users/kkiih/Documents/Workspace/FlutterWorkspace/reshet_research_output/H96_cluster_20261016_f23a32b9/`
- 최종 승인·검증: `data/backups/approved_content_batch/h96_approval_20261016/`
- 공식 snapshot·result·manifest 사본: `data/backups/approved_content_batch/20261016T082034904121Z/`

## 최종 결정

사용자는 H97 현행 meaning, 두 비고, H96→H97 가설 관계를 승인한 뒤 H96의 뜻이 물로 된 방울에만 한정되는지 질문했다. 추가 판단에서는 그런 제한이 입증되지 않았으므로 최초 ‘물방울’ 추천을 ‘방울’ 유지로 수정했다. 사용자는 이 최신 제안에 근거한 DB·문서·기타 파일 반영과, 이상 없으면 Git 완료 및 이번 작업 브랜치 정리까지 승인했다. 최초 연구 추천서의 ‘물방울’은 최종 승인값이 아니다.

| Strong / word_id | seq | 최종 meaning | 실행 |
|---|---:|---|---|
| H96 / H0096_0000 | 1 | 방울 | 기존 meaning row 보존·명시적 승인 |
| H97 / H0097_0000 | 1 | 에글라임 (지) | 기존 meaning row 보존·명시적 승인 |

두 meaning은 실제로 교체하지 않았다. Manifest의 meaning_approvals 2건으로 현재 순서·값을 승인하고, DB 쓰기는 아래 비고 2개와 신규 관계 1개만 수행했다.

H96 최종 비고:

> 욥 38:28에서는 ‘이슬 방울’을 가리킨다. Strong은 ‘물이 모여 있는 곳(reservoir)’으로 정의하고 ‘방울’을 용례 번역으로 제시하며, BDB는 물의 모임·저장분으로 보는 견해도 전한다. 별도의 ‘저수지’ 의미로 쓰인 용례는 현재 canonical 본문에서 확인되지 않는다.

H97 최종 비고:

> 사 15:8에 나오는 모압의 지명이다. Strong은 H96 אֶגֶל의 쌍수형에서 나온 이름으로 ‘두 연못’이라 풀이하지만, BDB는 이름의 뜻을 미확정으로 둔다. 이 어원 풀이와 정확한 위치는 확정하지 않는다.

| 관계 항목 | 최종값 |
|---|---|
| semantic direction | H0096 → H0097 |
| 저장 pair | H0096_0000 / H0097_0000 |
| category_code | morphological |
| relation_type | derived |
| status_code | hypothesized |
| direction_code | w1_to_w2 |
| relation ID | 7865 |
| 관계 비고 | Strong은 H97을 H96의 쌍수형에서 나온 지명으로 풀이하며 ‘두 연못’이라고 설명한다. BDB는 이름의 뜻을 미확정으로 두므로 역사적 어원을 확정하지 않는 가설 관계로 기록한다. |
| source | RESHET-EC-H96-CLUSTER-H0096-H0097 |
| description / relation_group_id | NULL / NULL |

신규 hold는 없다. 원어 expression·음역·발음·DB 언어·Strong identity·schema·seed·원천·로컬 참고자료와 기존 hold 6건은 보존했다. 기존 active semantic 승인과 충돌하지 않아 supersession도 없다. H97 source의 x-pn과 DB 히브리어 표기를 자동 통일하지 않았다.

## 핵심 판단 근거

- 정상 lexical closure는 H96·H97 전체 2개, source relation evidence 1개, frontier 0이다. OSHB canonical occurrence는 각 1회이며 총 2/2를 검토했다. 전체 로컬 참고자료 6종과 명시적 LXX 2절을 대조했다. LXX는 provenance·license 미검증의 human reference로 유지하며 자동 Hebrew–Greek alignment나 신약 Strong 연결을 만들지 않았다.
- H96의 유일한 용례 욥 38:28은 אֶגְלֵי־טָל, ‘이슬의 방울들’이다. 이 용례가 물로 된 방울을 가리킨다는 사실과 단어 자체가 물에만 한정된다는 주장은 구분한다. 별도 단어 טָל이 이슬을 제공하고 일반 사전 번역 drop은 ‘방울’로 옮길 수 있다. 현재 자료로 물 전용이라는 의미 제약을 입증하지 못하므로 기존 ‘방울’을 유지했다. 다른 액체에 쓰인 고대 용례를 확인했다고 주장하지 않는다.
- Strong의 reservoir 정의와 BDB가 전하는 모임·저장분 해석은 지우지 않고 비고에 보존했다. 한 절의 다른 해석 가능성을 독립된 두 번째 ‘저수지’ sense로 자동 승격하지 않았다.
- H97은 사 15:8의 모압 지명으로 식별되며 한국어 성경의 에글라임과 기존 DB meaning이 맞는다. Strong의 H96 쌍수형·두 연못 풀이와 BDB의 이름 뜻 미확정을 구분해 이름의 meaning은 유지하고 불확실성은 비고에 두었다.
- Source-reference H97→H96과 semantic 기원 후보 H96→H97은 반대다. 별도 지명 lexeme의 형성을 설명하므로 derived를 선택하고, 역사적 어원이 일반적으로 확정됐다고 과장하지 않도록 hypothesized로 승인했다. BDB가 H96 연결을 직접 반증했다는 뜻도 아니다.
- 물방울·방울은 고유어이고 에글라임은 외국 고유명사이므로 의미에 한자를 새로 만들지 않는다. 쌍수 설명을 근거 없는 합성 경계로 바꾸어 붙임표를 넣지 않으며, 셰와를 새 한국어 모음이나 발음으로 자동 확정하지 않는다.

## 채택하지 않은 주요 대안

| 대안 | 채택하지 않은 이유 | 현재 취급 |
|---|---|---|
| H96 물방울 | 실제 이슬 문맥에는 적절하지만 단어 자체가 물에만 한정되는지 입증되지 않음 | 문맥 번역으로 가능, 최종 meaning은 방울 |
| H96 이슬 방울 | 별도 어휘 טָל의 뜻까지 H96 자체에 포함함 | 해당 용례 설명으로 비고에 보존 |
| H96 저수지(貯水池) 또는 저장분을 추가 sense로 분리 | Strong 정의와 사전 대안은 있으나 별도 독립 용례·sense의 충분한 근거 없음 | 사전 차이를 비고에 보존, 완전한 오답으로 기각하지 않음 |
| H97 두 연못을 meaning으로 사용 | 본문의 지명을 일반명사로 바꾸고 어원 불확실성을 숨김 | Strong 풀이로 비고에 보존 |
| 관계 asserted | 비교 사전이 이름의 뜻을 미확정으로 남겨 확정 등급보다 가설이 적절함 | hypothesized로 승인 |
| 관계 비생성 또는 어휘 전체 hold | 의미 식별은 충분하고 불확실성은 비고·가설 관계로 한정 가능함 | 관계 생성, 새 hold 없음 |

## 남은 불확실성 및 재검토 조건

H96은 한 번의 성경 용례만으로 역사적 의미 범위 전체를 확정할 수 없다. ‘방울’은 물 전용이라는 제한을 추가하지 않는 대표 의미이며 다른 물질의 방울에 실제로 쓰였다는 확인을 뜻하지 않는다. 전문 사전·고대 코퍼스·critical commentary가 재질 제한이나 저장분 해석을 판별할 직접 근거를 제공하면 사용자가 다시 판단한다.

H97의 이름 원천 언어·정확한 위치·H96과의 역사적 파생은 미확정이다. 이를 구체적으로 해소하는 독립된 전문 근거가 확보되면 relation status와 비고를 재검토할 수 있다. 새로운 번역 표현·표기 취향·x-pn 코드만으로 의미를 자동 변경하거나 가설을 확정하지 않는다.

적용 검증: 공식 dry-run의 사본 적용·실제 undo·원본 불변과 live apply 성공. 기존 applicator 테스트 31건 통과. 독립 SQL 54조회·전체 13테이블·DDL·공식 snapshot·byte 백업 대조에서 승인한 비고2·관계1·history3행과 해당 sequence 외 변화 없음. History group 1792138836008136, ID6105–6107은 active word update2·relation create1이다. Work·seed·snapshot·byte 백업은 integrity ok·FK0·sidecar0이며 보호 입력165개·원본 연구11파일은 불변이다. 표준 progress JSON·CSV·Markdown에서 대상 두 행만 explicit_approved로 변경됐다. 승인294→296, 미승인13,998→13,996, hold6·anomaly113은 유지한다. 앱/UI 코드 변경이 없어 수동 UI 테스트·전체 앱 빌드는 N/A다.
