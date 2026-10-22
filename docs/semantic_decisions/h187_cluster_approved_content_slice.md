# H187 우살·우잘 고유명 의미·비고 승인 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-22 (Asia/Seoul)
- 대상: H0187
- 승인 manifest: [h187_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h187_cluster_approved_content_slice.json)
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음·신규 hold 없음
- 로컬 연구 산출물: `reshet_research_output/H0187_cluster_20261022_abef9e6c/`; `00_cluster_summary.md`, `00_semantic_assessment.json`, 전수 용례·관계 평가 및 raw Review 보존
- 승인 원문·적용 전 byte 백업·독립 검증: `data/backups/approved_content_batch/h187_approval_20261022/`
- 공식 적용 receipt: `data/backups/approved_content_batch/20261022T133328108688Z/result.json`

## 최종 결정

사용자는 H187 연구 추천안을 채택하고 DB·문서·필요 파일 반영, 각 단계 안전 검증 후 커밋·작업 브랜치 push·main ff-only 병합·main push·이번 로컬 및 원격 작업 브랜치 정리를 승인했다. 아래는 그 승인값이며 별도의 사용자 개인적 판단 이유를 추정하지 않는다.

| Strong | 최종 ordered meaning | sense | 처리 |
|---|---|---:|---|
| H0187 | 우살·우잘 (인, 지) | 1 | 관용 표기와 원문 비교용 근사를 같은 이름의 표기로 병기 |

최종 비고:

> 우살은 한국어 성경 관용 표기이고 우잘은 원문 형태를 비교하기 위한 교재식 한글 근사다. 창 10:27·대상 1:21에서는 욕단의 아들 이름이다. 겔 27:19를 OSHB는 전치사와 고유명사로 분석하며 새번역은 ‘우잘에서’로 옮긴다. 개역 계열의 ‘길쌈하는 실’, KJV의 ‘오가다’ 등 다른 독법도 있다. 어원과 이 지명의 정확한 위치는 확정하지 않는다.

관계 생성·교체·삭제와 새 word hold는 없다. H235→H187 파생 관계도 생성하지 않는다. category/type/status/direction은 N/A다. 같은 고유명사 표기를 한 meaning으로 둔 것은 인물과 지명의 역사적 동일성을 확정한 것이 아니다. 기존 expression אוּזָל·음역 우잘·발음·언어, 모든 기존 관계·hold ledger·비대상 어휘·schema·seed·앱 코드는 유지한다.

의미 교체1·비고 추가1을 공식 dry-run·undo와 기존 applicator 테스트31건 후 실제 적용했다. History group `1792676009378764`, ID6669–6670은 H0187 word update2이며 undone0이다. 독립 검증의 기록된 SQL50조회·58검증에서 전체13테이블·DDL·적용 전 byte 백업·공식 snapshot을 비교해 승인 projection·history·history sequence 외 변화 없음, integrity ok·FK0·sidecar 없음·seed 불변을 확인했다. 문서 작성 전 보호 입력234개 중 승인 work DB만 변경됐고 원본 연구15파일은 불변이다.

Work SHA `abef9e6cbae885058bce747bf74f6295970c7f3272104aa08293005d4fa9067d` → `419adfde3371b7dcf542f460f22b4339ca6e550bbdc2532c4dabe7e28485fc2a`. Seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1` 불변이다. 실제 적용은 1회다. 적용 receipt의 CRLF manifest SHA는 `ffff7cf946b1cc338ff6efb7ad75de5142b3837426969c0e8e15fc54dfa0bc86`, Git에 저장하는 LF manifest SHA는 `7466feefd237b5d201072301033a68f1ce44eca48d8b359db79416f1070b263d`다. 차이는 CRLF→LF뿐이며 parsed JSON이 exact 일치한다. LF manifest를 적용 전 byte 백업에 공식 dry-run하여 같은2건·undo·원본 불변을 재확인했고 현재 파일과 index bytes도 일치한다. 원본 적용 receipt와 manifest 사본은 보존했다. 줄바꿈 검증은 `06_manifest_eol_verification.json`에 남긴다.

표준 progress JSON·CSV·Markdown 갱신과 독립24검증·공식 renderer 대조에서 H0187만 신규 승인됐다. 승인520→521·미승인13,772→13,771·hold6·anomaly113·전체14,298이며 비대상14,297행과 lexical index·anomaly는 exact 불변이다. Snapshot identity는 `9200884c96cd8e22c7442f09098c35a0d01716e957c9f60986eac354cfa39e4f`다. Work DB는 Git 미추적 로컬 자산이며 seed 교체·앱 배포·전체 빌드·UI 수동 테스트는 N/A다.

## 핵심 판단 근거

- Canonical Strong HebrewLexicon commit `21c9add13bc727d3a951361778e97e3ff7afd1ce`의 H187 원 entry와 OSHB morphhb commit `3d15126fb1ef74867fc1434be1942e837932691f`의 전체3토큰을 검토했다. 재귀 discovery는 단독 H187, 관계 evidence0, frontier0으로 closure가 완료됐다. 허브 예외와 제외 node는 없다.
- 창10:27·대상1:21은 욕단의 자손을 열거하는 문맥의 인명이다. 우살은 한국어 성경 관용 표기를 보존한다. 우잘은 현재 expression의 음역 및 새번역 겔27:19에도 실제 근거가 있는 교재식 한글 근사이며 특정 고대 발음의 완전 재현으로 주장하지 않는다.
- 겔27:19의 מְ/אוּזָּ֔ל을 OSHB는 lemma m/187, morphology HR/Np로 분석한다. 새번역의 우잘에서와 달리 개역 계열은 길쌈하는 실, KJV는 오가다 독법과 Meuzal 대안, 원전분해는 H235 푸알 분사 분석을 보인다. 분석한3토큰은 모두 분류했지만 이 중1개의 독법은 미확정이다. 경쟁 독법을 누락하거나 별도 H187 일반 meaning으로 수입하지 않는다.
- 로컬 사전의 H235 파생 설명은 Strong H187의 `of uncertain derivation`과 구별한다. H235 원 항목에도 겔27:19의 지명·실 대안이 있으나 동일 구절의 competing lexical analysis가 파생 관계의 증거는 아니다. 관계를 가설 상태로 만드는 대신 불확실성을 연구·비고에 보존한다.
- 로컬5종의 전체3절, HebGrkKo exact 행 및 applicable LXX explicit 조회를 비교했다. LXX 창10:27·겔27:19는 조회됐으나 대상1:21은 unmatched이며 이를 확인 완료로 세지 않는다. LXX provenance·license는 미검증이고 automatic alignment·Greek Strong 연결은 하지 않는다. BDB의 도시 동일시와 NET의 Izal 해석도 지명의 정확한 위치를 확정하는 근거로 통합하지 않는다.
- 필수 표기 검토표에 따라 같은 이름의 표기 차이는 가운데점으로 병기하고 독법·어원·위치의 한계는 비고에 둔다. 고유명사에 한자를 만들지 않고 불확실한 합성 경계에 붙임표를 넣지 않는다. 한글 병기를 위해 기존 expression·발음 필드를 자동 수정하지 않는다.

## 채택하지 않은 주요 대안

- 기존 우살 (인, 지) 유지: 여전히 유효한 간결한 대안이나 사용자는 우잘과의 식별·표기 병기를 포함한 추천안을 채택했다.
- 우잘 단독: 원문 비교와 새번역에 대응하지만 기존 관용 인명 우살의 식별을 잃어 채택하지 않았다.
- 인명·지명 meaning을 별도2개로 분리: 지시 기능을 구별하는 유효 대안이나 현재 이름 표기를 중복 저장할 필요는 낮다고 판단했다. 분류 표시와 비고로 구별하되 역사적 동일성을 단정하지 않는다.
- 가다·실·오가다 또는 이름의 어원 풀이를 추가 meaning으로 저장: H187의 고유명 기능과 해당 구절의 경쟁 분석을 혼동하므로 배제했다. 관련 독법은 비고·연구 자료에 보존했다.
- H235→H187 파생 관계 생성: canonical의 어원 불확실과 독립 근거 부족으로 asserted뿐 아니라 hypothesized 생성도 하지 않는다. 번호 인접성·가족 관계·LXX 표기를 lexical relation으로 만들지 않는다.
- H187 전체 hold: 고유명사 식별과 두 인명 용례는 충분히 확인됐고 남은 불확실성을 비고로 보존할 수 있어 새 hold를 만들지 않았다.

## 남은 불확실성 및 재검토 조건

겔27:19의 지명/분사·실 독법, 지명의 정확한 위치, H235 파생설, 원천 언어와 특정 시대 발음은 확정하지 않는다. OSHB 분류로 세 token을 설명할 수 있다는 사실은 세 번째 구절에 대한 본문비평적 결론이나 인명·지명의 역사적 동일성을 증명하지 않는다. source x-pn/unresolved 상태도 임의로 보정하지 않았다.

새 원문·본문비평·원 사전·역사언어 자료가 이름의 식별, 겔27:19 구문 또는 어원 연결을 실질적으로 바꿀 때 해당 쟁점만 재검토한다. 단순 번역어 차이·번호 인접성·같은 표면형만으로 기존 승인이나 관계 비생성 결정을 자동 변경하지 않는다. 원본 연구와 공식 적용 receipt는 이력으로 보존한다.
