# H45 클러스터 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-03
- 대상: H0045; H0001은 합성 구성 요소, H0022는 평행 명단 문맥
- 승인 manifest: [h45_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h45_cluster_approved_content_slice.json)
- 관련 hold ledger: 변경 없음, H45 word-level hold 없음
- 로컬 연구 산출물: `H0045_cluster_20261003_4512e6bd/00_cluster_summary.md`, `00_approved_content.md`, `H45_review.md`
- DB history group: `1790981306422466`

## 최종 결정

사용자는 “네 제안대로 승인하고, db와 git 작업까지 완료하라.”로 연구 추천안을 최종 채택하고 적용을 승인했다.

- H0045_0000 meaning: **아비알본·아비-알본 (인)**, seq 1, 단일 sense.
- 비고:

  > 삼하 23:31에 나오는 아르바 사람으로, 다윗의 용사 가운데 한 사람이다. ‘아비-알본’은 원문 אֲבִי־עַלְבוֹן의 구성 경계를 보이는 분석 표기다. 첫 요소는 H0001 ‘아버지’와 연결되지만 둘째 요소의 어원은 불확실하며, Strong의 ‘힘의 아버지(용감한 자)’ 풀이는 추정이다. 평행 명단인 대상 11:32에서는 아비엘(H0022)로 전해지며, 두 이름의 정확한 형태·어원 관계는 확정하지 않는다.

|semantic 방향|relation id|category/type/status|저장 pair|direction_code|
|---|---|---|---|---|
|H0001 → H0045|7709|morphological / compound / asserted|H0001_0000, H0045_0000|w1_to_w2|

관계 note·description·relation_group_id는 NULL, source는 `RESHET-EC-H45-CLUSTER-H0001-H0045`다. 기존 pair가 없어 신규 생성했다.

H45 hold 없음. H0022–H0045 및 unknown second root/H0410→H0045 관계는 생성하지 않는다. H1·H22 기존 의미·note·관계 및 hold 상태를 유지한다. Expression·언어·발음·schema·seed·원천 자료는 변경하지 않았다.

## 핵심 판단 근거

Canonical OSHB의 삼하 23:31 한 용례는 아르바 사람인 다윗의 용사를 가리킨다. 해당 원문 전체와 확보된 로컬 사전·한국어 및 영어 번역·원전분해를 모두 비교해 하나의 인명 sense로 설명했다. 아비알본은 관용 표기이고 아비-알본은 원문 אֲבִי־עַלְבוֹן의 확인된 구성 경계를 보여 주는 분석 표기다. 두 표기를 별도 sense로 만들지 않는다.

Canonical Strong의 `from H1`은 첫 요소를 명시한다. 이어지는 `unused root of uncertain derivation`과 `probably, father of strength`는 둘째 요소의 어원과 이름 풀이의 불확실성이다. H1의 직접 구성 관계는 asserted로 승인하되 이름의 정확한 뜻을 확정된 일반 의미로 만들지 않고 비고에 추정으로 보존한다. Source-reference H45→H1과 semantic 구성 방향 H1→H45를 구별했다.

H22의 세 용례와 기존 승인 기록을 현재 자료로 대조했다. 대상 11:32의 아비엘과 삼하 23:31의 아비알본은 평행 명단에 등장하며 KJV margin·참고 사전과 LXX human reference가 병행성을 뒷받침한다. 그러나 정확한 onomastic 변이 유형·어원 방향까지 확정하지 않으므로 기존 relation 비생성 결정을 유지했다. 사용자는 이 근거에 따른 추천을 채택했다.

## 채택하지 않은 주요 대안

- `아비알본 (인)` 유지: 유효한 관용 표기지만 확인된 구성 경계를 함께 보여 주는 분석 표기를 채택했다.
- `힘의 아버지` 또는 `용감한 자`를 별도 meaning으로 추가: 추정 어원 풀이이며 본문의 인명 기능을 대체하지 않으므로 채택하지 않고 비고에 보존했다.
- `아비엘·아비알본 (인)`으로 이름을 통합하거나 variant 관계 생성: 같은 명단 위치만으로 정확한 이름 관계를 확정할 수 없고 H22의 별도 가문 조상까지 혼동할 수 있어 채택하지 않았다.
- H0410 또는 추정 둘째 어근과 관계 생성: H45 lexical source가 해당 Strong을 직접 지정하지 않으므로 채택하지 않았다.
- word-level hold: 인명 의미·용례·표기는 충분하고 남은 어원 문제는 비고로 한정할 수 있어 두지 않았다.

## 남은 불확실성 및 재검토 조건

둘째 요소의 어원 및 H22와 H45의 정확한 이름 전승·형태 관계는 확정되지 않았다. Provenance가 검증된 전문 onomasticon·critical lexicon·apparatus가 새로운 직접 근거를 제공하면 해당 비고와 관계를 재검토한다. 단순한 번역 표기 차이나 같은 자료의 반복 조회로 자동 재심사를 시작하지 않는다.

OSHB 원문의 앞 token은 lemma 45+, 뒤 token은 45이며 두 요소와 마케프가 전체 이름을 이룬다. 현행 strict numeric-component counting은 표준 45 token 1개를 occurrence로 세며 앞 요소를 H1의 별도 용례나 다른 이름으로 해석하지 않는다. 원파일과 전체 절을 확인하여 한 인명 용례로 분석했다.

LXX 두 구절의 αβιηλ은 human-reference이며 upstream provenance/license 미검증 경계를 유지한다. 이를 canonical alignment, Greek Strong 또는 자동 relation으로 승격하지 않는다. Source x-pn/unresolved와 work DB 히브리어 metadata 차이는 유지한다.

Discovery 42 nodes/41 relation evidence, frontier 39, expanded 3, resume 0으로 graph closure는 미완료다. H1 생산적 hub 예외 아래 CORE H45 1/1 용례와 CONTEXT H22 3/3 용례를 검토했으며 H1의 1,213개 corpus를 독립 전수 sense 심사한 것은 아니다. 다른 39개 가지의 semantic 승인을 뜻하지 않는다.

## 적용 검증

- 공식 dry-run/undo 및 live apply exit 0. Meaning 1·note 1·relation create 1, active history 3행. Dry-run 원본 work SHA 불변.
- Snapshot: `data/backups/approved_content_batch/20261002T224825600507Z/snapshot.db`; result와 manifest copy도 같은 디렉터리.
- 독립 전체 사용자 테이블 대조: WORD_TABLE·word_meaning_set 각 1행 교체, WORD_RELATION 1행·CHANGE_HISTORY 3행 추가만 확인. DDL 동일, 최종 meaning·비고·관계 필드가 승인 manifest와 exact 일치.
- Work SHA: `4512e6bdcaae25ddd0fe774863718351350a0d0a11f5cf57a218b8982935ded6` → `1278f2e05560729543e1fa16478409cdd94681f2492b724281e4bf15645d20dc`.
- Seed SHA 불변: `e44bb989bebdc46a22bba2efac9defd06f3bdfd500577153de85adfa1bc148bb`.
- Work·seed integrity ok, FK 위반 0, sidecar 없음.
- H45 explicit_approved. 전체 승인 113→114, 미승인 14,183→14,182; hold 2·anomaly 113 유지.
- Progress snapshot identity: `e9429f17144fcc93725d6867ada7581b4677fc5fbe97896d7c7e81d4783baf21`.
- Approval document SHA: `1c292f2bfd2210c74c26b28fda5907f555db8c32c5b8a13721b784ad18a18aa2`.
- 적용 manifest SHA: `0a15e13b5c2c1c1b855a318899034b8fa564239e9ca88856f668679d053de752`. 해당 manifest만 Git `-text` 속성으로 raw bytes를 보존하여 적용본·index·committed blob의 hash 불일치를 방지한다.
- `flutter test test/database/approved_content_batch_service_test.dart`: 29건 모두 통과.
- UI 테스트 N/A — UI 변경 없는 승인 데이터 slice. 수동 UI 테스트는 수행하지 않았다.
