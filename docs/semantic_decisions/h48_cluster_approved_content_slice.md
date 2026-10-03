# H48 클러스터 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-04
- 대상: H0048, H0087; H0001·H7311·H0085는 승인 관계의 endpoint로만 포함
- 승인 manifest: [h48_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h48_cluster_approved_content_slice.json)
- 관련 hold ledger: 변경 없음, 두 CORE의 word-level hold 없음
- 로컬 연구 산출물: `H0048_cluster_20261004_3223f756/00_cluster_summary.md`, `semantic_assessment.json`, 각 Evidence Packet·Review·72건 용례 평가
- 최종 승인 원문과 값: `data/backups/approved_content_batch/h48_approval_20261004/00_approved_content.md`
- DB history group: `1791070710426922`

## 최종 결정

사용자는 “추천안대로 승인하고 DB 반영 및 Git 완료까지 진행”으로 직전 추천안을 승인했다. 아래 판단 근거는 승인된 연구 추천안의 근거이며, 별도로 진술하지 않은 사용자의 개인적 판단 이유를 추정하지 않는다.

| Strong | 최종 meaning (seq 1) |
|---|---|
| H0048 | 아비람·아비-람 (인) |
| H0087 | 아브람·아브-람 (인) |

두 단어의 최종 비고:

- **H0048**: ‘아비-람’은 ‘아버지’(H0001)와 ‘높다’ 계열(H7311)의 구성 경계를 드러낸 표기다. 이름은 ‘나의 아버지는 높다(존귀하다)’ 등으로 풀이되며, BDB는 ‘높으신 분은 나의 아버지’라는 풀이도 제시한다. 엘리압의 아들과 히엘의 맏아들 두 사람의 이름이다(민 16:1; 왕상 16:34). 이름 풀이의 문장 구조는 하나로 확정하지 않는다.
- **H0087**: 아브라함(H0085)의 이전 이름이다(창 17:5; 대상 1:27; 느 9:7). Strong은 아비람(H0048)의 단축형으로 설명하며, 이름은 ‘높은 아버지’ 또는 ‘아버지는 높임 받으신다’ 등으로 풀이된다. ‘아브-람’은 구성 경계를 드러낸 분석 표기다. 단축형이라는 설명은 이름 형태의 관계이며 아비람이라는 인물들과 아브람이 동일인이라는 뜻이 아니다.

| semantic 방향 | relation id | category / type / status | direction_code |
|---|---|---|---|
| H0001 → H0048 | 26 | morphological / compound / asserted | w1_to_w2 |
| H7311 → H0048 | 5379 | morphological / compound / asserted | w2_to_w1 |
| H0001 → H0087 | 25 | morphological / compound / asserted | w1_to_w2 |
| H7311 → H0087 | 5378 | morphological / compound / asserted | w2_to_w1 |
| H0087 → H0085 | 7480 | unspecified / related / asserted | w2_to_w1 |
| H0048 → H0087 | 7715 (신규) | morphological / variant / asserted | w1_to_w2 |

저장 pair는 모두 `word_id_1 < word_id_2` canonical 순서다. 기존 관계 5건은 ID를 유지하여 status·note·source를 교체했다. 관계 note는 승인 manifest의 값 그대로이며 description·relation_group_id는 NULL이다. H0087→H0085는 이전 이름에서 이후 이름으로 향하는 관련 관계로, 어원 파생이나 일반 동의어를 뜻하지 않는다.

두 CORE의 meaning과 비고 및 위 여섯 관계만 승인했다. H0001·H7311·H0085의 독립 meaning·비고, expression·언어·발음 metadata·schema·seed·원천·hold ledger·앱 코드에는 변경이 없다.

## 핵심 판단 근거

H0048의 canonical 11용례는 엘리압의 아들 10건과 히엘의 맏아들 1건으로 나뉜다. 서로 다른 인물이라는 이유만으로 같은 이름을 별도 sense로 분리하지 않는다. H0087의 61용례는 아브라함의 이전 이름을 가리킨다. 두 인명은 각각 한 meaning으로 식별하고 이름의 뜻 풀이는 비고에 배치한다.

관용 표기와 분석적 구성 표기를 가운데점으로 병기하고 인명 표지 `(인)`을 붙인다. 아비-람은 H0001과 H7311 계열의 구성 경계를, 아브-람은 그 단축 이름의 구성 경계를 보여 주는 분석 표기다. 붙임표를 원문 마케프나 특정 시대의 실제 발음으로 단정하지 않는다. 이름에 근거 없는 한자를 만들지 않으며, 불확실한 역사적 발음은 새 expression으로 쓰지 않는다.

H0048의 Strong 항목은 from H1 and H7311을 유보 표현 없이 제시하며 H0087은 contracted from H48로 설명한다. 따라서 두 구성 관계와 단축형 variant를 asserted로 보존한다. H0087의 H1·H7311 구성 관계는 H48의 구성과 단축형 설명 및 사전 풀이를 함께 검토한 형태 분석이다. H0087의 직접 structured source-reference가 H1·H7311을 명시한다고 오인하지 않도록 note에 구분한다.

창 17:5, 대상 1:27, 느 9:7은 아브람과 아브라함의 명시적 이전 이름·이후 이름 관계를 뒷받침한다. H48→H87의 형태 단축 관계는 아비람이라는 인물들과 아브람의 동일인 관계가 아니다. 이름 전체를 ‘높으신 나의 아버지’ 한 문장으로 고정하지 않고 Strong과 BDB의 풀이 차이를 비고에 보존한다.

근거: [고정 Strong 원문](https://raw.githubusercontent.com/openscriptures/HebrewLexicon/21c9add13bc727d3a951361778e97e3ff7afd1ce/HebrewStrong.xml), [BDB H48](https://biblehub.com/bdb/48.htm), [BDB H87](https://biblehub.com/bdb/87.htm), canonical OSHB 원문과 로컬 참조 자료, [한국어 표기 정책](../semantic_research/korean_lexical_notation_policy.md). 원문 용례와 LXX 차이는 로컬 연구 산출물에서 상세 대조했다.

## 채택하지 않은 주요 대안

- `아비람/아비-람`, `아브람/아브-람` 유지: 동일 이름의 표기 병기에는 가운데점을 쓰며 분석 표기의 성격과 인명을 명시한다.
- 이름 풀이를 별도 meaning으로 추가하거나 같은 이름의 인물별 sense 분리: 인명 식별과 어원 풀이·지시 대상을 구분하여 각각 한 meaning을 유지한다.
- 이름 전체의 문장 구조를 하나로 확정: 사전의 풀이가 달라 대표 meaning에서 제외하고 비고에 차이를 보존한다.
- H48→H87을 어원 파생 또는 동일인으로 분류: 직접 근거는 형태 단축이므로 morphological/variant를 선택한다.
- H87→H85를 morphological/derived 또는 synonym으로 분류: 실제 개명 문맥을 unspecified/related와 이전→이후 방향으로 보존한다.
- word-level hold: 이름 식별과 기본 의미는 충분히 확인되어 남은 이름 풀이·발음 문제를 비고에 한정한다.
- H1·H7311의 생산적 인명 가지와 H85의 독립 의미까지 동시 승인: 핵심 판단과 분리하여 CONTEXT 및 HUB-EXCLUDED로 남긴다.

## 남은 불확실성 및 재검토 조건

이름 전체의 문장 풀이와 역사적 이름 형성 과정, 시대별 실제 발음은 확정하지 않았다. 검증된 전문 인명·어원·본문 자료에서 새로운 직접 근거가 생기면 해당 값과 관계만 재검토한다. H87의 단축형 설명만으로 실제 인물의 이름 변화나 역사적 유래 순서를 추정하지 않는다.

Discovery 66 nodes/65 edges, frontier 62, `max_nodes_reached`, `research_complete=false`이다. CORE 2개의 72용례(59개 구별 절)를 전량 평가했다. CONTEXT H0001·H7311·H0085와 HUB-EXCLUDED 61개를 구분했으며 CORE 판단 완료를 전체 그래프 closure로 보고하지 않는다. LXX는 human-reference로서 upstream/license가 unverified이고 canonical alignment·헬라어 관계로 승격하지 않는다. H48/H87 source_language `x-pn`의 unresolved 상태와 기존 DB 언어를 각각 보존한다.

## 적용 검증

- 공식 dry-run: 10 operations, history 10행, 사본 적용 및 undo 성공; 원본 work SHA 불변. Live apply도 exit 0.
- Snapshot: `data/backups/approved_content_batch/20261003T233829595482Z/snapshot.db`; 같은 디렉터리에 result·manifest copy·independent_verification.json을 보존한다.
- 독립 전체 13테이블 대조: WORD_TABLE 비고 2행, word_meaning_set 승인 대상 2행, WORD_RELATION 기존 5행 교체·신규 1행, CHANGE_HISTORY 10행 및 관련 sequence 증가만 확인. DDL·승인 밖 데이터 동일.
- 실제 SQL: `SELECT word_id,seq,meaning FROM word_meaning_set WHERE word_id IN (?,?) ORDER BY word_id,seq`; `SELECT id,비고 FROM WORD_TABLE WHERE id IN (?,?) ORDER BY id`에 H0048_0000·H0087_0000을 전달하여 manifest exact match 확인.
- 관계 SQL: `SELECT id,word_id_1,word_id_2,category_code,relation_type,status_code,direction_code,note,source FROM WORD_RELATION WHERE id IN (?,?,?,?,?,?)`에 25·26·5378·5379·7480·7715를 전달하여 pair·category·type·status·direction·note·source를 manifest와 대조하여 일치. History SQL: `SELECT id,group_id,action_type,entity_type,entity_id,undone_at FROM CHANGE_HISTORY WHERE group_id=? ORDER BY id`에 `1791070710426922`를 전달하여 active 10행(update 9/create 1) 확인.
- Work SHA: `3223f756a7e71be0e9d2977a91ffdf2eb4d79f5833c4ed7f24d6e14b4167ac34` → `d58aa42d6b7a1ca798fcd4c096de42aed0a52a7fb4f530dbd0cc8b11bb354341`.
- Seed SHA 불변: `e44bb989bebdc46a22bba2efac9defd06f3bdfd500577153de85adfa1bc148bb`; work/seed integrity ok, FK 0, sidecar 없음.
- Approval SHA: `fe0b9286de236160413e6cb48821eae00d44c45ed376b4b5020c71cee78fd9d5`; manifest SHA: `d302ab9eb5696b0cd8be311efcf6c82e352aeabd33334e4034babf62ac56e92f` (working bytes·index blob·backup copy 일치, 새 manifest LF 고정).
- 공식 progress: 두 CORE explicit_approved, 승인 120→122, hold 2→2, 미승인 14,176→14,174, anomaly 113. JSON/CSV 각 14,298행 일치; 승인 비율 0.8393%→0.8533%.
- `flutter test test/database/approved_content_batch_service_test.dart`: 29건 모두 통과.
- UI 테스트 N/A — 앱 코드·UX 변경 없음; 수동 UI 테스트는 수행하지 않았다.
