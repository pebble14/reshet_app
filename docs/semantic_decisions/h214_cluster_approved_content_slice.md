# H214 저장·창고·에셀 클러스터 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-25 (Asia/Seoul)
- 대상: H0214_0000, H0686_0000, H0687_0000
- 승인 manifest: [h214_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h214_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음·신규 hold 없음
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 로컬 연구 산출물: `reshet_research_output/H0214_cluster_20261025_84d78b2f/`; 전체 요약·CORE3 Full Review·89회 용례 분류, `04_etymology_language_recheck.md`
- 승인 원문·적용 전 byte 백업·독립 검증: `data/backups/approved_content_batch/h214_approval_20261025/`
- 공식 적용 receipt: `data/backups/approved_content_batch/20261025T020028553489Z/result.json`

## 최종 결정

사용자는 최초 연구와 어원·본문비평 추가 검토 후의 최신 추천안을 채택하고 DB·문서·필요 metadata, commit·작업 branch push·main ff-only 병합과 push·로컬/원격 작업 branch 정리까지 승인했다. 아래 상태는 공식 applicator 적용·독립 DB 검증·표준 progress 검증이 통과한 뒤 기록했다. 초기 연구의 R1 asserted 추천과 긴 한국어 문구는 후속 추천으로 대체됐고 manifest에는 최종 승인안만 포함했다.

|Strong|최종 ordered meaning|sense 수|
|---|---|--:|
|H0214 אוֹצָר|1. `창고(倉庫)` / 2. `재물(財物)`|2|
|H0686 אָצַר|1. `쌓아 두다` / 2. `창고(倉庫)를 맡기다`|2|
|H0687 אֶצֶר|1. `에셀·에체르 (인)`|1|

세 항목의 기존 meaning을 각각 교체했다. H214의 저장·비축 범위는 비고에 보존하고, H686의 둘째 meaning은 현행 마소라/OSHB 본문에 근거한 느13:13 용법으로 한정한다. H687의 가운데점은 같은 인명의 관용 표기와 원문 자음 대응의 근사를 병기하며 의미를 나누지 않는다. 원문·발음·음역·언어 metadata는 변경하지 않았다.

### 최종 word note

**H0214**

> 금·은 같은 보물과 식량·기름·포도주 등 모아 둔 물자를 가리키며, 이를 보관하는 곳에도 쓰인다. 문맥에 따라 보물·비축물·곳간·보고·병기창 등으로 옮긴다. 자연현상을 두는 하나님의 창고나 여호와 경외를 보배에 견주는 비유에도 쓰인다. Strong은 H686에서의 파생을 제시하지만 Klein은 어원을 미확정으로 다룬다.

**H0686**

> 재물이나 물자를 모아 두는 말로, 수동형은 ‘쌓아 두어지다’라는 뜻이다. 암 3:10은 폭력·약탈을 쌓는다는 표현이며 그로 얻은 재물의 축적을 가리킨다는 해석도 있다. 느 13:13의 현행 마소라 본문은 H214를 바탕으로 한 ‘창고를 맡기다’ 용법으로 풀이한다. 이 절에는 ‘명령하다’ 계열 형태로 읽자는 본문비평 제안도 있다.

**H0687**

> 세일의 아들로 기록된 호리 족속의 족장. ‘에셀’은 성경 관용 표기, ‘에체르’는 원문 אצר의 자음 대응을 드러낸 근사 표기다. Strong과 Gesenius는 이름을 ‘보물’로 풀이하지만 BDB는 ‘언약’이라는 대안도 제시한다. 이름의 어원은 미확정이며, עזר 계열의 다른 ‘에셀’과 구별된다.

### 최종 관계와 hold

|semantic from|semantic to|category_code|relation_type|status_code|direction_code|최종 DB ID|
|---|---|---|---|---|---|--:|
|H0686|H0214|morphological|derived|hypothesized|w2_to_w1|8096|
|H0686|H0687|morphological|derived|hypothesized|w1_to_w2|8097|

저장 pair는 각각 `(H0214_0000,H0686_0000)`, `(H0686_0000,H0687_0000)`로 canonical 순서다. Semantic 방향은 source-reference graph의 화살표와 구분한다. Strong의 두 `from H686` 문구에는 추정 수식어가 없다는 사실을 보존하며, 관계 status는 추가 사전의 불확실성을 반영하여 사용자 승인으로 가설을 선택했다.

H214↔H687 직접 관계 및 H214→H686 역방향 관계는 생성하지 않는다. 느13:13의 대안 읽기를 H686의 ‘명령하다’ 의미나 H6680 관계로 추가하지 않는다. 기존 relation 교체·삭제는 없고, 신규 hold·hold 해제도 없다. 기존 전체 hold6건과 비대상 어휘는 보존했다. Supersedes 대상 기존 semantic 승인이나 결정 기록은 없다.

적용 범위는 의미 교체3·비고 교체3·관계 생성2, 총8개 write operation이다. Dry-run·undo·원본 불변 및 applicator 회귀 테스트31개를 먼저 통과했고 live apply를1회 수행했다. 독립 검증62건·실제 SQL44조회에서 전체13테이블을 적용 전 byte 백업 및 공식 snapshot과 대조해 승인 projection·history8·관련 sequence 외 변화가 없었다. History group `1792893629823819`, ID `6865–6872`는 word update6·relation create2이며 undone0이다. Integrity ok·FK0·sidecar 없음·seed 불변이며 보호 입력175개 중 work DB만 바뀌고 원본 연구17파일은 불변이다.

표준 progress JSON·CSV·Markdown과 독립23검증·공식 renderer 대조에서 대상3개가 explicit_approved가 됐다. 승인597→600·미승인13,695→13,692·hold6·anomaly113·전체14,298이고 비대상14,295행·anomaly·lexical index는 exact 불변이다. Work DB는 Git 미추적 로컬 자산이며 Git에는 manifest·문서·필요 줄바꿈 metadata를 게시한다. Seed 교체·앱 배포·Flutter UI 테스트·사용자 수동 UI 테스트는 N/A다.

## 핵심 판단 근거

- 세 항목은 공식 양방향 lexical discovery에서 정상 closure3·frontier0으로 닫힌 저장 family다. Strong XML과 OSHB를 canonical 근거로 사용하고 로컬 사전·번역·LXX는 참고 경계를 유지했다.
- 전체89토큰을 검토했다. H214는 저장 장소와 내용물의 두 축으로79회를 설명하며 주 배정51/28, 경계 ambiguous14건을 보존한다. 이 수치는 공식 의미 annotation이 아닌 연구 분류다. H686은 저장4회와 창고 업무 부여1회, H687은 같은 인명5회다.
- H214의 재물은 금·은 같은 보물뿐 아니라 음식·기름·포도주 비축도 포괄한다. ‘쌓아 둔’ 설명을 비고로 옮겨 한국어 대표 meaning을 짧게 정리하고, 장소/내용물의 초점 차이와 사33:6의 비유를 보존했다.
- [Klein אוֹצָר](https://www.sefaria.org/Klein_Dictionary,_%D7%90%D7%95%D6%B9%D7%A6%D6%B8%D7%A8)와 [אצר](https://www.sefaria.org/Klein_Dictionary,_%D7%90%D7%A6%D7%A8)의 공식 entry 전체는 명사의 어원과 파생을 불확실하게 다룬다. Strong의 from을 삭제하거나 확정된 역사적 차용 방향으로 확대하지 않고 R1을 가설로 승인했다.
- [Gesenius 문법 §53](https://www.studylight.org/lexicons/eng/gesenius/53.html)과 [NET 느13:13 주석](https://classic.net.bible.org/verse.php?book=Neh&chapter=13&verse=13)은 명사 기반 용법 외에 다른 본문 읽기를 논의한다. 현행 MT/OSHB 의미는 보존하면서 비고에 본문비평의 한계를 명시했다.
- H687은 [Gesenius/BDB 재록](https://www.studylight.org/lexicons/eng/hebrew/687.html)의 보물 풀이와 언약 대안을 함께 고려했다. 이름의 식별과 어원 확정성을 구분하여 이름은 승인하고 파생은 가설로 둔다. עזר 계열 다른 에셀은 별도 이름이며 본 승인에서 수정하지 않는다.
- [Eshel 외(2022)](https://doi.org/10.1086/721690)의 관련 비문·포도주 저장 논의는 의미 범위를 보강하지만 부분 복원은 조건부다. 이 논문을 특정 파생 방향, 새로운 canonical occurrence, 독립 sense의 확정 근거로 승격하지 않았다.
- 사용자는 용례 이외의 추가 어원 조사와 한국어 정돈을 요청했고 그 후속 추천안을 채택했다. 사용자가 말하지 않은 개인적 선택 이유는 추가하지 않았다.

## 채택하지 않은 주요 대안

- H214 ‘창고’ 하나 또는 ‘보물’ 하나: 저장 장소와 운반·약탈되는 내용물을 함께 설명하기 어렵다. 평범한 식량 비축도 범위에 포함해야 한다.
- H214 ‘쌓아 둔 재물’ 대표 meaning: 가능한 설명이지만 의미란은 재물로 줄이고 축적·보관 문맥은 비고에 둔다. ‘저장물’은 덜 자연스럽고 ‘보물/비축물/창고’ 셋은 내용물 범위를 세분하는 비용이 있어 채택하지 않았다.
- H686 저장 meaning 하나와 비고만 사용: 느13:13의 현행 본문 용법을 직접 나타내기 위해 둘째 meaning을 두었다. 수동형·분사·폭력/약탈의 문맥만으로 셋째 meaning을 만들지는 않는다.
- H686 ‘창고지기로 세우다’: 기능은 맞지만 한국어를 ‘창고를 맡기다’로 다듬었다. 일반적인 ‘임명하다’는 맡기는 직무 범위가 지나치게 넓어진다.
- H687 ‘보물’ 또는 ‘언약’을 독립 meaning으로 추가: 성경 용례는 인명이므로 이름의 어원 후보는 비고에 둔다. 관용 ‘에셀’만 유지하거나 ‘에체르’만 쓰는 대안 중 두 층위 병기를 채택했다.
- R1 asserted: Strong 설명만으로 처음 제안했으나 추가 Klein 검토의 불확실성을 반영한 최신 가설안이 승인됐다. R2 역시 확정 관계로 올리지 않는다. 모든 어원 edge 비생성은 가능한 보수적 대안이나 사용자는 두 가설 edge를 채택했다.
- 단어 전체 hold 및 source expression 교정: 일반 의미·인명 식별을 승인할 근거가 충분하고 어원·본문·첫 모음의 불확실성은 비고와 가설 관계로 제한한다.

## 남은 불확실성 및 재검토 조건

H214의 역사적 파생 방향·최초 어원과 H687의 보물/언약 경쟁 어원은 미확정이다. 아람어·아랍어 비교나 저장의 공통 이미지만으로 차용 방향과 의미 발달 순서를 정하지 않는다. H687의 source x-pn과 Strong/OSHB 첫 모음 차이도 원문 필드의 자동 교정 근거가 아니다.

느13:13의 현행 וָאוֹצְרָה는 OSHB H686 히필로 보존한다. 다른 형태로 읽자는 문법·NET의 제안을 Qere나 현재 DB 본문으로 바꾸지 않는다. NET이 언급한 Lucianic Greek·Peshitta·Vulgate의 해당 비평판을 독립적으로 모두 대조한 것은 아니며 HALOT/DCH 전문을 직접 확인했다고 주장하지 않는다. 새 critical apparatus·고대 인명 자료·비교어원 논증이 실제로 현재 선택을 가를 때 재검토한다.

로컬 한국어 자료4개에서 절번호 차이4건을 수동 비교했지만 전체 versification profile은 unverified다. LXX는79개 문맥을 explicit lookup으로 조사하여76개 문맥을 확인했고3개는 미확정으로 남겼다. Upstream provenance·license는 미검증이며 자동 정렬·lemma 추론·Greek 관계 생성에 쓰지 않는다. HebGrkKo의 H687 8회와 논문의 H214 80회 같은 외부 집계를 canonical 통계로 사용하지 않고 OSHB5회/79회를 유지한다.

새 원문 evidence 없이 번역 표현 차이, 같은 사전의 재수록 증가, 단순 음역 취향만으로 승인 값을 자동 변경하지 않는다. 상세 evidence와 전체 자료 감사표는 로컬 research artifact에 보존한다.
