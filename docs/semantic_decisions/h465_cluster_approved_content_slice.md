# H465 판단·기도 및 인명 어휘군 결정

- 상태: active
- 기록 성격: 승인·적용과 동시 작성
- 판단 근거 복원 수준: 높음 — R1 전량 연구·R2 후속 검토·사용자 승인·적용 receipt 보존
- 결정일: 2026-11-17
- 대상: CORE10
- 승인 manifest: [h465_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h465_cluster_approved_content_slice.json)
- 로컬 연구 산출물: reshet_research_output/H0465_cluster_20261117_633a253d, 최신 13_semantic_assessment_R2.json 및 00_cluster_summary.md

## 최종 결정

사용자가 최신 R2 추천과 DB·문서 반영, 검증, 커밋·push·main 병합·이번 브랜치 정리까지 승인했다. 아래는 순서 있는 meaning이며 비고 전문은 manifest의 word_note_replacements에 있다.

|Strong|최종 meaning|
|---|---|
|H0465|엘리발·엘리-팔 (인)|
|H0654|에블랄·에플랄 (인)|
|H6414|재판관(裁判官)|
|H6415|판결(判決)|
|H6416|재판(裁判)에 부칠|
|H6417|판결(判決)|
|H6419|기도하다(祈禱하다) / 간청하다(懇請하다) / 판단하다(判斷하다) / 개입하다(介入하다) / 예상하다(豫想하다)|
|H6420|발랄·팔랄 (인)|
|H6421|블라야·펠랄-야 (인)|
|H8605|기도(祈禱)|

10개 어휘의 meaning14개·비고10개와 신규 관계12건을 반영했다. 인명의 가운데점 병기는 각각 한 meaning이다. H654 음역 필드는 유지한다. 새 hold 없음, 기존 hold6·H410 승인·나머지 CONTEXT 상태는 유지한다.

관계는 다음과 같다. 방향은 의미상의 원천→형성어다. 저장 pair와 direction_code는 manifest를 따른다.

|연결|category/type/status|
|---|---|
|H0410_0000 w1_to_w2 H0465_0000|morphological/compound/asserted|
|H0465_0000 w2_to_w1 H6419_0000|morphological/compound/hypothesized|
|H0654_0000 w2_to_w1 H6419_0000|morphological/derived/asserted|
|H6414_0000 undirected H6419_0000|etymological/root_shared/asserted|
|H6414_0000 w1_to_w2 H6415_0000|morphological/derived/asserted|
|H6414_0000 w1_to_w2 H6416_0000|morphological/derived/asserted|
|H6416_0000 w1_to_w2 H6417_0000|morphological/derived/asserted|
|H6419_0000 w1_to_w2 H6420_0000|morphological/derived/asserted|
|H6419_0000 w1_to_w2 H6421_0000|morphological/compound/asserted|
|H3050_0000 w1_to_w2 H6421_0000|morphological/compound/asserted|
|H6419_0000 w1_to_w2 H8605_0000|morphological/derived/asserted|
|H0465_0000 undirected H0467_0000|morphological/variant/hypothesized|

H5307↔H6419는 오기·용례 참조이므로 관계를 생성하지 않는다. H8605↔G4335·H6419↔G4336은 비교 근거로 보존하며 이번 lexical family에 translation 관계를 추가하지 않는다. H465↔H467 가설은 병행 용사 목록의 이름형에 한정하며 모든 동명인 동일성을 뜻하지 않는다.

## 핵심 판단 근거

R1은 정본172토큰/154절과 확보 reference를 전량 검토했다. 생산적 엘·야 허브와 약한 H5307 참조를 구별한 bounded CORE10 완료이며 global discovery 전체가 완료된 것은 아니다.

H654는 티베리아 전통 ל의 옆소리와 한국어 어중 ㄹ/ㄹㄹ 차이를 대조하여 에플랄을 채택한다. ㄹㄹ는 원문 첫 ל의 다게쉬·자음 중복을 주장하지 않으며 길이·삽입 모음은 근사의 한계다. 기존 음역 재사용만으로 에프랄을 우선한 R1 논거를 수정했다.

H8605의 간청은 Strong·Gesenius에 근거한 타당한 풀이지만 기도와 겹치므로 대표 meaning은 기도로 유지하고 비고에 간청·남을 위한 간구를 명시한다. 기도문·시 표제와 감사도 포괄하며 중보기도만으로 제한하지 않는다. H6419는 사45:14의 사람 대상 간청을 포함하고, BDB·UBS의 예상 분석에 따라 창48:11을 넓은 판단에 압축하지 않고 예상하다로 분리한다. 개입은 상황 사이에 나서는 기능으로 설명한다.

H6414는 전통적인 재판관 분석을 조건부 채택한다. H6415·H6417은 판결이라는 공통 기능을 보존하며 형태 차이만으로 뜻을 인위적으로 가르지 않는다. H6416은 재판 대상의 성격을 나타내는 형용사로 처리한다. 인명 어원은 작명 풀이이며 일반명사 뜻·실제 직업으로 저장하지 않는다. 현행 한국어 표기 정책에 따라 관용명·교재식 근사와 분석 경계를 구별했다.

## 채택하지 않은 주요 대안

- H654 에프랄 우선: 현행 음역이라는 사실만으로 발음 근사의 우열을 정할 수 없다.
- H8605 기도/간청: 뜻풀이 중첩과 사람 대상 청원 일반으로의 확대 가능성 때문에 비고에 포함했다. 찬송·기도처도 독립 meaning으로 추가하지 않았다.
- H6419 예상 용법을 판단에 병합: 한국어 범위가 지나치게 넓어진다. 중재만을 대표어로 삼으면 양측 합의 조정으로 좁게 읽힐 수 있어 개입을 유지했다. 살해·속죄는 해당 사건의 문맥으로 구별한다.
- H6414의 추상 판단·평가 및 hold: 경쟁 분석은 비고에 보존하되 사용자는 최신의 재판관 추천과 새 hold 없음 안을 승인했다.
- H6414/H6419의 역사 파생 방향 및 H465/H467 확정 이형 관계: 각각 공통 어근 무방향·가설 이형 관계로 제한했다.

## 남은 불확실성 및 재검토 조건

H6414의 경쟁 형태·추상명사 분석, H6419 삼상2:25·겔16:52·시106:30의 세부 해석과 역사적 의미 발달, 시109:7 기도의 대상·법정 호소 가능성, H465/H467 병행 관계·전체 이름 어원, H6421 셰와와 고대 발음은 미확정이다. 이들은 현재 승인된 일반 뜻·관계의 한계로 기록하며 자동 교정하거나 모두 word-level hold로 바꾸지 않는다. 새 직접 본문·사전·비교언어 근거가 일반 의미나 관계를 실질적으로 바꿀 때 재검토한다. 동일 gloss의 반복은 자동 재검토 사유가 아니다.

## 적용 및 검증

공식 dry-run에서 임시 적용·실제 undo·원본 SHA 불변을 확인하고 적용기31테스트 통과 후 live apply1회 수행했다. History group1794899024863981의32행, 신규관계8473–8484를 확인했다. 독립 SQL은 전체12개 사용자 테이블·DDL·비대상·기존 이력 불변 및 exact meaning·비고·관계를 검증했다. Integrity ok·FK0·seed불변. Progress 승인1085→1095·미승인13207→13197, canonical14298·hold6·anomaly113 유지. 상세 SQL·결과와 승인 원문·R2 사본·적용 전 백업은 data/backups/approved_content_batch/h465_approval_20261117에 보존한다. 공식 snapshot/receipt는 data/backups/approved_content_batch/20261117T070342842103Z에 있다.

원문·음역·발음·언어·schema·앱 코드·UX 변경 없음. Flutter 빌드·수동 UI 테스트·배포·seed 교체는 범위상 N/A다. 외부 사전 본문은 저장소에 전재하지 않는다.
