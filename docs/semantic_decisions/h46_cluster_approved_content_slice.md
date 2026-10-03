# H46 클러스터 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-04
- 대상: H0046, H0047, H0082, H0083, H0084, H8038; H8034는 추정 합성 구성 요소로만 포함
- 승인 manifest: [h46_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h46_cluster_approved_content_slice.json)
- 관련 hold ledger: 변경 없음, 여섯 CORE의 word-level hold 없음
- 로컬 연구 산출물: `H0046_cluster_20261003_1278f2e0/00_cluster_summary.md` 및 각 Evidence Packet·Review·전량 용례 평가; 후속 사용자 대화가 초기 추천보다 우선
- 최종 승인 내용: `data/backups/approved_content_batch/h46_approval_20261004/00_approved_content.md`
- DB history group: `1791044686496080`

## 최종 결정

사용자는 “이제 현재까지의 최종 제안을 DB에 구현하고 Git 작업까지 완료하자.”로 후속 토론까지 반영한 추천안을 승인했다.

| Strong | 최종 meaning, seq 순서 |
|---|---|
| H0046 | 강하신 분 |
| H0047 | 힘센 / 황소 / 힘센 말 / 완고한(頑固한) |
| H0082 | 날아오르다 |
| H0083 | 날개 |
| H0084 | 날개 |
| H8038 | 세메벨·셰므에베르 (인) |

여섯 단어의 최종 비고:

- **H0046**: 하나님을 가리키는 명사적 형용사로, 여섯 용례 모두 야곱 또는 이스라엘과 결합한다. 의미의 중심은 강함이며, 한국어 성경의 전능자(全能者)는 관용 번역이다. 단어 자체나 해당 호칭 구문에 모든 능력을 뜻하는 요소는 없다. Strong은 H0082에서의 유래를 제시하지만 BDB의 어근·파생 분석과 차이가 있어 날다에서 강하다로의 파생 방향은 확정하지 않는다.
- **H0047**: 형용사가 명사적으로 쓰이면 힘센 자·용사·우두머리를 가리킨다. 시 78:25의 힘센 자들은 천사로 해석되는 번역 전통이 있다. 마음과 결합하면 담대함 또는 완고함을 나타낸다. 렘 46:15는 용사들과 힘센 황소의 해석이 갈리며, LXX에는 아피스 황소가 나타난다. 렘 50:11도 말과 황소 번역이 갈린다.
- **H0082**: 욥 39:26에서 매가 날아오르는 동작을 나타낸다. Strong은 원시 어근으로 분류하지만 BDB는 H0083의 날개에서 형성된 명사 유래 동사, 곧 날개를 움직여 날다로 분석한다. 두 사전의 분석 차이 때문에 H0083과의 역사적 파생 방향은 확정하지 않는다.
- **H0083**: 새의 날개를 가리키며 문맥에 따라 비행에 쓰이는 날개깃까지 포괄한다. 겔 17:3에서는 날개와 깃털을 나타내는 다른 말들과 함께 쓰여 긴 날개깃으로 이해할 수 있다. 날개와 깃의 번역 차이를 곧바로 독립 의미의 구분으로 보지 않는다.
- **H0084**: H0083의 여성형으로, 새의 날개와 그 깃을 포괄한다. 여성형이 암컷 전용을 뜻하지는 않는다. 시 91:4에서는 덮는 깃과 피하는 날개의 비유에 쓰이며 보호는 문맥상 기능이지 별도 어휘 의미가 아니다. 욥 39:13의 새 종류와 구문에는 해석 차이가 있다.
- **H8038**: 창 14:2에 나오는 스보임 왕이다. 세메벨은 한국어 성경 관용 표기이고 셰므에베르는 원문 대조용 한글 표기이며, 특정 시대의 실제 발음이나 므의 모음을 확정한 표기는 아니다. Strong은 셰므(H8034, 이름)와 에베르(H0083, 날개)의 합성으로 추정한다. 이 분석에 따른 구성 표기는 셰므-에베르이며, 어원은 확정되지 않았다. Strong의 날개의 이름, 곧 이름 높은 자라는 풀이는 추정 해석으로만 보존한다.

| semantic 방향 | relation id | category / type / status | direction_code |
|---|---|---|---|
| H0046 ↔ H0047 | 7710 | morphological / variant / asserted | undirected |
| H0082 ↔ H0083 | 7711 | etymological / root_shared / asserted | undirected |
| H0083 → H0084 | 7712 | morphological / derived / asserted | w1_to_w2 |
| H0083 → H8038 | 7713 | morphological / compound / hypothesized | w1_to_w2 |
| H8034 → H8038 | 7714 | morphological / compound / hypothesized | w1_to_w2 |

모든 저장 pair는 `word_id_1 < word_id_2` canonical 순서이다.

H0082→H0046 파생 관계는 보류하여 생성하지 않는다. H8034–H0083 직접 관계도 생성하지 않는다. H8034의 의미·비고·기존 관계와 expression·언어·발음 metadata·schema·seed·원천·hold ledger·앱 코드는 변경하지 않았다. 관계의 description·relation_group_id는 NULL이며 note에는 사전 근거와 가설의 한계를 보존했다.

## 핵심 판단 근거

H46의 canonical 여섯 용례는 하나님을 가리키는 야곱 또는 이스라엘의 호칭이다. BDB의 strong/the Strong과 실제 용례를 함께 반영하여 ‘강하신 분’을 택했다. ‘능한 자’는 한국어에서 수행 능력·기술로 읽힐 수 있고 ‘전능자’의 모든 능력이라는 범위는 원어 호칭의 구성 요소가 아니므로 대표 meaning으로 삼지 않았다.

H47의 사람·동물·마음 문맥을 구별하되 번역 전통을 모두 독립 의미로 늘리지 않았다. 황소·힘센 말은 반복되는 명사적 동물 용법이며, 사 46:12의 완고한 마음은 긍정적 힘셈으로 평탄화하지 않았다. 렘 46:15·50:11과 시 78:25의 대상 해석 차이는 비고에 남겼다.

H82는 욥 39:26의 매가 날아오르는 한 용례이다. Strong의 원시 어근/유래 연결과 BDB의 명사 유래 동사 분석이 달라 역사적 파생 방향을 확정하지 않는다. H82–H83은 공통 어근 어휘군으로만 연결하고 H82→H46은 생성하지 않는다.

H83·H84의 pinion 범위는 날개와 비행에 쓰이는 날개깃을 포괄한다. 한국어 번역어가 갈린다는 이유만으로 두 독립 sense를 만들지 않고 ‘날개’ 하나에 문맥상 날개깃 범위를 비고로 설명한다. H84 여성형은 여성 개체 전용이라는 의미가 아니다. 보호·정치 권력 같은 비유의 결과를 새 meaning으로 만들지 않는다.

H8038은 창 14:2의 인명이며 세메벨은 관용 표기, 셰므에베르는 원문 대조용 표기이다. 같은 이름의 표기 차이를 별도 sense로 만들지 않는다. Strong의 apparently from은 다른 확정적 from 항목 및 추정 어근 설명과 비교하여 유보 표현으로 판단했다. 구체적인 합성 가설을 두 구성 요소에서 이름으로 향하는 hypothesized 관계로 보존하되 붙임표는 비고의 명시적 추정 분석에서만 쓴다.

근거 자료: [고정 Strong 원문 전사](https://raw.githubusercontent.com/openscriptures/HebrewLexicon/21c9add13bc727d3a951361778e97e3ff7afd1ce/HebrewStrong.xml), [BDB](https://hebrewcollege.edu/wp-content/uploads/2018/10/BDB.pdf), [아비르 한국어 번역 비교](https://ibp.or.kr/wordspostachio/?bmode=view&idx=5505251), [한국어 표기 정책](../semantic_research/korean_lexical_notation_policy.md). 상세 occurrence·한국어 번역·LXX 대조는 기존 연구 산출물에 보존한다.

## 채택하지 않은 주요 대안

- H46 ‘능하신 분’·‘강한 자’·‘전능자’: 힘과 강함을 중심으로 하나님 호칭의 실제 사용까지 반영하여 ‘강하신 분’을 선택했다. 다른 번역을 모든 문맥에서 오역이라고 판정한 것은 아니다.
- H83/H84 ‘날개 / 깃’ 두 meaning: 번역상의 전체·부분 구별만으로 독립 sense를 확정하지 않고 날개깃 범위를 비고에 보존했다.
- H8038 ‘세메벨 (인)’만 유지: 원문 대조 표기의 독립 식별 가치를 반영하여 병기했다.
- H8038의 대표 meaning에 ‘셰므-에베르’ 또는 ‘날개의 이름·이름 높은 자’ 추가: 추정 경계·어원 풀이는 비고에 한정한다. 그래프 연결은 이름 전체의 의미나 역사적 어원을 확정하지 않는다.
- H82→H46 파생 가설 생성: 사전 분석 차이와 의미 전이의 직접 근거 부족으로 비생성한다.
- word-level hold: 식별·기본 의미가 충분하고 남은 문제를 비고·관계 가설 상태로 한정할 수 있어 두지 않는다.

## 남은 불확실성 및 재검토 조건

H82·H83·H46의 역사적 파생 순서, H8038의 합성 어원·이름 전체 풀이·시대별 발음, H47 일부 동물·천사 문맥과 H84 욥 39:13의 구문은 미확정이다. 검증된 전문 어원·인명·본문비평 자료가 새로운 직접 근거를 제공할 때 해당 항목만 재검토한다. 같은 자료를 반복 조회하거나 한국어 번역어 수만으로 의미를 자동 재분리하지 않는다.

Discovery는 22 nodes/21 edges, expanded 14, frontier 8, research_complete=false이다. CORE 6개의 canonical 32용례를 검토했으며 H8034는 합성 요소 문맥, 그 이후 생산적 인명·신명·약한 참조 가지는 HUB-EXCLUDED로 구분했다. 이번 승인은 여섯 CORE와 위 다섯 관계에 한정되며 전체 연결망 closure나 H8034 독립 sense 승인으로 확대하지 않는다. LXX는 human-reference이고 canonical alignment나 NT relation으로 승격하지 않는다.

## 적용 검증

- 공식 dry-run은 사본에서 17 operations 적용·undo 성공, 원본 work SHA 불변. Live apply 성공, history group `1791044686496080`의 active history 17행.
- Snapshot: `data/backups/approved_content_batch/20261003T162445646290Z/snapshot.db`; manifest copy와 result도 같은 디렉터리.
- 독립 전체 테이블 대조: WORD_TABLE 비고 6행 교체, word_meaning_set 승인 대상 6행→9행, WORD_RELATION 5행 및 CHANGE_HISTORY 17행 추가와 해당 sequence 증가만 확인. DDL 동일, 승인 밖 변경 없음.
- 실제 조회: `SELECT word_id,seq,meaning FROM word_meaning_set WHERE word_id IN (...) ORDER BY word_id,seq`로 위 여섯 대상 최종값 확인. `SELECT 비고 FROM WORD_TABLE WHERE id=?`로 manifest 비고 exact match. `SELECT * FROM WORD_RELATION WHERE word_id_1=? AND word_id_2=?`로 다섯 pair의 type/status/direction/source/note exact match. H46–H82 및 H83–H8034 직접 pair 없음.
- Work SHA: `1278f2e05560729543e1fa16478409cdd94681f2492b724281e4bf15645d20dc` → `3223f756a7e71be0e9d2977a91ffdf2eb4d79f5833c4ed7f24d6e14b4167ac34`.
- Seed SHA 불변: `e44bb989bebdc46a22bba2efac9defd06f3bdfd500577153de85adfa1bc148bb`; work/seed integrity ok, FK 0, sidecar 없음.
- Approval SHA: `d736743180d7d92ffaf6819fe56835930b2765040ebcd0273487e0a4d09208e0`.
- Manifest SHA: `df9699500a252610c7ad4c986cb851ab88d584a361ac98ad3fa5e39b27bd4821`; working bytes·index blob·applicator backup copy 동일, 새 manifest만 LF 고정.
- 공식 progress에서 여섯 CORE explicit_approved; 전체 14,298, 승인 114→120, hold 2, 미승인 14,182→14,176, anomaly 113. JSON/CSV 14,298행 일치.
- `flutter test test/database/approved_content_batch_service_test.dart`: 29건 모두 통과.
- UI 테스트 N/A — 앱 코드·UX 변경 없음. 수동 UI 테스트는 수행하지 않았다.
