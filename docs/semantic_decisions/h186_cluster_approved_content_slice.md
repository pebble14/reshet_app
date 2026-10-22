# H186·H5813 인명과 H5810 강함 의미·관계 승인 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-22 (Asia/Seoul)
- 대상: H0186, H5813, H5810
- 승인 manifest: [h186_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h186_cluster_approved_content_slice.json)
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음·신규 hold 없음
- 로컬 연구 산출물: `reshet_research_output/H0186_cluster_20261022_7d479eb1/`; 최신안 `00_semantic_assessment.json`, H5810 재검토 `01_h5810_lexical_reassessment.md`
- 승인 원문·적용 전 byte 백업·독립 SQL 검증: `data/backups/approved_content_batch/h186_approval_20261022/`
- 공식 적용 receipt: `data/backups/approved_content_batch/20261022T130050522133Z/result.json`

## 최종 결정

사용자는 H186 추천에 동의하고 H5813 meaning의 원문 근사 표기를 웃지로 선택했다. H5810은 문맥별 번역을 넘어 사전·형태·의미 범위를 비교한 재추천을 요청했다. 이후 최신안에 따른 DB·문서·필요 파일 작업과 검증 후 커밋·작업 브랜치 push·main ff-only 병합·main push·이번 로컬 및 원격 작업 브랜치 정리를 승인했다. 아래는 그 최종안이며 사용자 개인의 추가 선택 이유를 추정하지 않는다.

| Strong | 최종 ordered meaning | sense |
|---|---|---:|
| H0186 | 우새·우자이 (인) | 1 |
| H5813 | 웃시·우시·웃지 (인) | 1 |
| H5810 | 강하다(強하다) | 1 |

최종 비고:

**H0186**

> 우새는 한국어 성경 관용 표기이며 우자이는 원문 형태의 교재식 한글 근사다. 느 3:25에서 발랄의 아버지로 나온다. Strong은 H5813의 변이 가능성을 제시하지만 확정된 어원은 아니다.

**H5813**

> 웃시·우시는 한국어 성경 관용 표기이며 웃지는 원문을 비교하기 위한 교재식 한글 근사 표기다. 여러 동명 인물에게 쓰인다. 대상 7:7은 우시, 스 7:4는 웃시엘로 옮기지만 스 7:4의 원문은 עֻזִּי(H5813)이며 별도 이름 עֻזִּיאֵל(H5816)과 구별한다.

**H5810**

> ‘이기다’는 강함이 대항 관계에서 드러나는 용법이다. 문맥과 구문에 따라 강해지다·강하게 하다로 옮긴다. ‘얼굴을 강하게 하다’는 뻔뻔한 태도의 관용 표현이다. 사 30:2와 시 52:7(히브리어 본문 52:9)은 사전별로 עוּז와의 어휘 분석 차이가 있어 일반적인 힘·강함 용례와 구별하여 검토한다.

관계 생성은 H5810 → H5813 하나다. 저장 pair는 `H5810_0000` / `H5813_0000`, category `morphological`, type `derived`, status `asserted`, direction `w1_to_w2`다. Strong H5813의 명시적 파생 설명을 구조화한 것이며 새 역사언어학적 증명을 뜻하지 않는다. 관계 ID는 8026이다.

H0186↔H5813은 Strong의 변이 가능성만으로 생성하지 않는다. H0186→H5810, H5813↔H5816도 생성하지 않는다. 기존 H5810→H5807 관계(ID7626, 저장 H5807/H5810, `morphological/derived/asserted/w2_to_w1`) 및 기존 unspecified 비교 관계는 그대로다. H5813의 기존 expression 음역 웆지는 이번 meaning의 웃지 결정과 별도 필드이므로 변경하지 않았다. 원어·발음·언어·schema·seed·hold ledger·앱 코드는 유지한다.

공식 dry-run은 교체3·비고3·생성1과 undo·원본 불변을 확인했고 기존 applicator 테스트31건이 통과했다. Live apply history group `1792674051783737`, ID6662–6668은 word update6·relation create1이며 undone0이다. 독립 SQL42조회·200검증에서 전체13테이블·DDL·byte 백업·공식 snapshot을 비교해 승인 projection·history·관련 sequence 외 변화 없음, integrity ok·FK0·sidecar 없음·seed 불변을 확인했다. 기존 manifest·seed·연구 산출물을 포함한 보호 입력 불변도 확인했다.

Work SHA `7d479eb153a6a8fb3df17edc7a52daff7960ab1523160e52e2a5752bf534a9b7` → `abef9e6cbae885058bce747bf74f6295970c7f3272104aa08293005d4fa9067d`. Seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1` 불변이다. Manifest SHA `625b1a6a37df03f6c2d17926678b1b6c8ecc6d953fcee29640041a27cf0eaef6`는 적용 사본과 일치하며 신규 LF 속성으로 보존한다.

표준 progress JSON·CSV·Markdown 갱신과 독립25검증·공식 renderer 대조에서 위3개만 신규 승인됐다. 승인517→520·미승인13,775→13,772·hold6·anomaly113·전체14,298이며 비대상14,295행은 exact 불변이다. Snapshot identity는 `4d693d2f144a1d50aef878841ba29a1074f0d320aee1fa8ebf5bebb90b2a293a`다. Work DB는 Git 미추적 로컬 자산이다. Seed 교체·앱 배포·전체 빌드·UI 수동 테스트는 N/A다.

## 핵심 판단 근거

- Canonical Strong HebrewLexicon commit `21c9add13bc727d3a951361778e97e3ff7afd1ce`와 OSHB morphhb commit `3d15126fb1ef74867fc1434be1942e837932691f`를 기준으로 CORE3의 전체24토큰(H186 1·H5813 11·H5810 12)을 검토했다. 사전·LXX·한국어 성경은 의미 범위와 구문을 검토하는 참고 자료이며 canonical 식별자를 자동 변경하지 않는다.
- H186은 느3:25의 인명이다. 관용명 우새와 원문 형태 비교용 우자이를 한 sense로 병기한다. Strong의 H5813 변이 설명은 가능성으로 제시되므로 확정 관계가 아닌 비고로 보존한다.
- H5813은 여러 동명 인물의 이름이다. 웃시·우시를 보존하며 웃지는 사용자가 택한 교재식 근사다. 동명 인물들의 동일성을 병기로 확정하지 않는다. 스7:4의 웃시엘 번역은 실제 짧은 원어 עֻזִּי와 별도 עֻזִּיאֵל(H5816)의 혼동을 피하도록 비고에 둔다.
- H5810은 Strong·BDB·Gesenius의 설명과 UBS/SDBH 의미 구조를 함께 대조했다. 힘·기세의 강함, 힘의 발휘와 부여가 공통 핵심이다. 이기다는 대항 관계에서 드러나는 용법으로, 모든 용례의 필수 성분은 아니다. 문맥별 번역 분류만으로 독립 sense를 만들지 않고 강하다를 대표어로 정했다. 한국어 동의어 비교도 함께 검토했으며 세다보다 객관적으로 유일한 정답이라고 주장하지 않는다.
- 표기 검토표에 따라 강하다(強하다)는 한자어 용언 전체를 병기하고 고유명사에는 한자를 만들지 않는다. 같은 인명의 표기 변형은 가운데점으로 병기한다. 불확실한 합성 경계에 붙임표를 넣지 않으며 한글 근사 표기는 특정 고대 발음의 완전 재현을 뜻하지 않는다. 상세 용법과 어원 한계는 비고에 둔다.
- 전체 자동 재귀 연구는 `max_nodes_reached`로 frontier298이 남아 있으며 closure를 선언하지 않는다. CORE3·CONTEXT6·허브 제외321의 경계를 적용해 이번 승인 범위를 한정했다. 원본 Review·packet·관계 추출물은 보존한다. 참고 사전의 원문 전체나 UBS 데이터는 제품 DB·canonical cache에 수입하지 않았다.

## 채택하지 않은 주요 대안

- H5810 강하다/이기다의 독립2 sense: 이기다의 번역 가치는 비고에 보존하지만 공통 의미와 문맥의 대항 관계를 구분하여 단일 대표 meaning을 선택했다.
- 세다: 의미가 가까운 유효 대안이나 강하다보다 더 정확하다고 단정할 차이가 확보되지 않았다. 굳세다·억세다는 튼튼함·불굴·거침 같은 성분이 대표어에 덧붙을 수 있고, 우세하다/이기다는 대항 관계를 필수화해 범위가 좁다. 힘이 있다는 강함의 정도를 충분히 나타내지 못할 수 있다.
- H5813 meaning에 웆지 사용: 사용자 선택에 따라 웃지를 채택했다. 웃시엘은 별도 이름 H5816과 혼동할 수 있어 meaning 병기 대신 스7:4 비고에만 보존한다.
- 인명을 힘셈·강함 같은 어원 뜻으로 대체: 실제 인명 기능을 잃으므로 채택하지 않는다. H186의 불확실한 어원에서 H5810까지 관계를 연쇄 생성하지 않는다.
- 특정 두 용례의 분석 차이를 이유로 H5810 전체 hold 또는 Strong 재배정: 공통 핵심 의미는 승인하고 쟁점은 비고에 한정한다.

## 남은 불확실성 및 재검토 조건

사30:2는 OSHB/Strong H5810이나 BDB의 עוּז 분석 및 UBS H5756 수록과 차이가 있다. 시52:7(히브리어52:9)은 UBS H5810/H5756에 동일 encoded reference가 중복 수록되어 어휘 분석이 완전히 합치하지 않는다. 잠8:28의 견고함과 힘찬 흐름, 상태와 사역 해석 차이도 연구 자료에 보존하며 중복 토큰으로 세지 않는다. H5810의12토큰은 모두 검토했으며 이 중2개를 분석 쟁점으로 구분했다.

H186의 어원 가설, 일부 H5813 동명 인물의 동일성, 특정 시대 발음은 확정하지 않는다. 새 원문·본문비평·사전 근거가 식별·구문·공통 의미 범위를 실질적으로 바꿀 때 해당 쟁점만 재검토한다. 단순 번역어 차이·번호 인접성·동형 철자만으로 기존 승인을 자동 폐기하지 않는다. 이번 허브 경계 밖 전체 재귀 연구는 별도 미완료 상태다.
