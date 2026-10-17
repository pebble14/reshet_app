# H105 그릇 어휘 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-17 (Asia/Seoul)
- 대상: H0105
- 승인 manifest: [h105_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h105_cluster_approved_content_slice.json)
- 관련 hold ledger: 변경 없음; 기존 hold6 유지, 신규 hold 없음
- 로컬 연구 산출물: C:/Users/kkiih/Documents/Workspace/FlutterWorkspace/reshet_research_output/H0105_cluster_20261017_4a4a4893/
- 승인 원문·byte 백업·독립 SQL: data/backups/approved_content_batch/h105_approval_20261017/
- 공식 snapshot·result: data/backups/approved_content_batch/20261017T083546653883Z/
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)

## 최종 결정

사용자는 Codex의 완료된 H105 추천안 전체를 채택하고 DB 반영과 Git 완료, 이상 없는 경우 이번 작업 브랜치 정리까지 승인했다. 아래 meaning과 비고만 적용했다.

| Strong | 최종 meaning | sense | canonical 출현 |
|---|---|---:|---:|
| H0105 | 그릇 | 1 (seq1) | 2회 / 1절 |

비고 전문:

> 에스라 1:9에서 금·은으로 만든 성전 그릇을 가리킨다. 접시, 대야, 바구니 등의 풀이가 있으나 정확한 형태와 어원은 불확실하다.

신규 relation과 신규 hold는 생성하지 않았다. 기존 H0105 관계0건과 hold ledger6건을 유지했다. 원어 expression אֲגַרְטָל, 한글 음역 아가르탈, 등록 발음, 언어·Strong identity·schema·seed·앱 코드는 변경하지 않았다. 기존 active semantic 결정의 supersession은 없다.

## 핵심 판단 근거

OSHB canonical occurrence2개 전량은 에스라1:9의 금 그릇30개와 은 그릇1000개다. 둘 다 남성 복수 연계형이며 재질·수량 차이를 별도 lexical sense로 나눌 근거는 없다. 에스라1:7–11 원문 문맥은 성전 기물의 반환 목록을 보여주지만 성전용이라는 문맥을 어휘 자체의 배타적 용도로 고정하지 않았다.

Strong의 basin·charger와 한국어 번역의 접시·반, HebGrkKo 및 BDB 참고 XML의 대야·바구니 풀이는 용기라는 공통 범위 안에서 세부 형태가 갈린다. 따라서 대표 meaning은 그릇으로 간결하게 두고 구체 후보와 형태·어원 불확실성을 비고에 보존했다. 사용자가 이 evidence에 기초한 Codex 추천을 최종 채택했다.

Canonical Strong entry와2개 token, 로컬 사전 exact1행, 절 참고자료5종의 해당 절 전부, LXX explicit1절을 확인했다. LXX/local은 reference-only이며 자동 정렬이나 새 canonical occurrence를 만들지 않았다. 원본 연구9파일은 변경하지 않았다. Lexical incoming/outgoing은0이며 Strong source의 of uncertain derivation을 확정 파생 관계로 바꾸지 않았다.

## 채택하지 않은 주요 대안

| 대안 | 채택하지 않은 이유 / 보존 |
|---|---|
| 접시 | 해당 절의 한국어 번역으로 유효한 대안이다. 그러나 세부 형태를 배타적으로 확정할 근거가 부족해 비고에 보존했다. |
| 대야 | Strong basin에 대응하는 유효한 후보지만 구체적인 형태·용도를 확정하지 않았다. 비고에 보존했다. |
| 바구니 | 참고 사전에 실제 근거가 있는 풀이이며 오답으로 폐기하지 않았다. 금·은 용기를 보통의 짠 바구니 형태로 고정하지 않고 비고에 보존했다. |
| 기존 그릇, 대야, 바구니 유지 / 복수 sense 분리 | 상위 범주와 세부 형상 후보를 같은 확실성으로 병렬화하지 않았다. 두 출현에서 독립 sense를 나눌 근거도 없었다. 기존 값은 backup·history에 보존했다. |
| 성전 그릇 | 실제 문맥의 설명이지만 어휘 고유의 용도로 한정하지 않고 비고로 옮겼다. |
| 추정 어근·LXX 번역어와 relation 생성 | 명시적 상대 Strong과 확정 가능한 의미 방향이 없다. 가능성이나 번역 대응을 새 DB relation으로 승격하지 않았다. |

## 남은 불확실성 및 재검토 조건

용기의 정확한 깊이·형태·구체 기능, 어원과 원천 언어는 미확정이다. 두 token은 같은 한 절에 있으므로 독립 문맥에 걸친 넓은 사용 범위를 입증한 것은 아니다. 그릇이라는 공통 범주와 단일 sense의 판단은 가능하므로 신규 hold로 처리하지 않았다.

LXX 자료의 upstream provenance·license와 한국어 참고자료의 reference profile은 미검증 경계를 유지한다. 개역개정 참고 DB의 전역 invalid verse row1건은 H105 해당 절의 정상적인 join에 영향을 주지 않았다. 동일 절의 두 matched 표현이 각 token에 반복 표시되어도 canonical count는2다.

새 원문 용례, 동시대 자료·유물과 어휘의 확실한 대응, 형태·차용 경로를 입증하는 직접 evidence, identity·source mapping 충돌이 확인되면 재검토한다. 단순 번역어 차이·Strong 번호 인접성·발음 유사성만으로 자동 재검토하지 않는다.

### 적용·검증

공식 v5 applicator로 meaning replacement1·word note replacement1, 총2 write를 적용했다. Dry-run의 임시 사본 적용과 실제 undo가 성공했고 원본 work·seed는 불변이었다. Live apply history group1792226147840556, ID6177–6178은 active word update2행이며 undone0이다.

독립 SQL 57조회·69검증에서 전체13테이블·DDL과 byte 백업·공식 snapshot을 대조했다. 허용된 H0105 meaning·비고와 history·해당 sequence 외 변화가 없다. Integrity ok·FK0·sidecar0, 보호 입력85개와 로컬 reference6개·LXX hash 불변이다. 기존 applicator 테스트31건이 통과했다.

Work SHA 4a4a48939b2985de98773cc355d7c66548e1a7b3a2be73bd04f3e6092d26ebf6 → a4820f7deb562e0b472fafd7478710a92feb77634047b4f19079e7cd39e127f0. Seed SHA a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1는 불변이다. 승인 원문 SHA e3a5afc95aaef30c0832c0520e69814ef127d886e2a6da03ce62f5b333e1ede5, manifest SHA e852dceb577abec565c0b6697c03c620a26b629b5ad70e54f93bf67495fe7b53이며 실제 적용 UTF-8 CRLF 바이트를 Git에서도 보존한다.

공식 표준 progress3종을 갱신하고 29검증을 통과했다. 대상1개만 unapproved→explicit_approved이며 승인322→323·미승인13,970→13,969·hold6·anomaly113·분모14,298이다. 비대상 row·원천 fingerprints·canonical relation index는 불변이고 CSV/Markdown은 공식 render와 byte 일치한다. Snapshot identity는 a5953dc4f26b4c668cec47886098691b84d10001f24e6f02bdb79b7ccb3bee7a다.

DB는 Git 미추적 로컬 자산이다. seed·설치 DB 교체나 앱 배포는 수행하지 않았다. UI·UX 변경이 없어 수동 UI 테스트와 전체 앱 빌드는 N/A다.
