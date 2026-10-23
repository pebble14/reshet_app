# H192 메로다크 이름 계열 의미·비고·변이 관계 승인 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-23 (Asia/Seoul)
- 대상: H0192·H1255·H4757·H4781
- 승인 manifest: [h192_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h192_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음·신규 hold 없음
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 로컬 연구 산출물: `reshet_research_output/H0192_cluster_20261023_4525081e_full/`; 전체4 Review·원문 보충·출현 분류·관계 평가 보존
- 승인 원문·적용 전 byte 백업·독립 검증: `data/backups/approved_content_batch/h192_approval_20261023/`
- 공식 적용 receipt: `data/backups/approved_content_batch/20261023T003321080314Z/result.json`

## 최종 결정

사용자는 CodeX의 현재 추천안 전체를 채택하고, DB·문서·기타 필요 파일에 반영한 뒤 앞 단계의 안전한 완료를 확인하면서 커밋·작업 브랜치 push·main fast-forward 병합·main push·이번 로컬 및 원격 작업 브랜치 정리까지 진행하도록 승인했다.

|Strong|최종 ordered meaning|sense|처리|
|---|---|---:|---|
|H0192|1. 에윌므로닥·에윌-메로다크 (인)|1|의미 교체·승인|
|H1255|1. 부로닥발라단·베로다크-발라단 (인)|1|의미 교체·승인|
|H4757|1. 므로닥발라단·메로다크-발라단 (인)|1|의미 교체·승인|
|H4781|1. 므로닥·메로다크·마르둑 (신명)|1|의미 교체·승인|

최종 비고:

**H0192**

> 아카드어 이름 Amēl-Marduk로도 알려진 바빌로니아 왕이다. Strong은 아람어에서 온 이름으로 설명하며, ‘아마 메로닥의 군사(軍士)’라는 풀이를 제시한다. 참고사전의 ‘마르두크의 사람’ 풀이와는 구별하며, H191 ‘어리석은’에서 나온 이름으로 단정하지 않는다.

**H1255**

> 열왕기하 20:12에 나오는 바빌로니아 왕으로, 이사야 39:1의 므로닥발라단(H4757)과 같은 사람이다. 본문에서 그의 아버지로 나오는 발라단(H1081)과 구별한다.

**H4757**

> 이사야 39:1에 나오는 바빌로니아 왕으로, 열왕기하 20:12의 부로닥발라단(H1255)과 같은 사람이다. Strong 표제어 מְרֹאדַךְ בַּלְאָדָן과 본문의 מְרֹדַךְ בַּלְאֲדָן 사이에는 철자·모음 차이가 있다.

**H4781**

> 바빌론에서 섬기던 신 Marduk을 가리킨다. 예레미야 50:2에서는 벨과 나란히 나오며, 바빌론의 무너짐과 함께 그 신과 신상(神像)이 꺾이는 모습을 말한다.

최종 관계:

|ID|semantic 관계|category_code|relation_type|status_code|direction_code|
|---|---|---|---|---|---|
|8029|H1255 ↔ H4757|morphological|variant|asserted|undirected|

Canonical pair는 `(H1255_0000,H4757_0000)`이다. 발생 방향은 확정하지 않는다. H4781과 H192/H4757의 성분 연결은 연구 문맥으로 남기고 새 compound 관계는 생성하지 않는다. H191의 동형 첫 요소 및 본문의 아버지 H1081에서도 lexical 관계를 생성하지 않는다. 기존 hold6·비대상 어휘·기존 관계·원어·음역·발음·언어·schema·seed·앱 코드는 유지한다.

공식 dry-run은 meaning4·비고4·관계1의 write9건, undo 성공 및 원본 DB 불변을 확인했다. Applicator 테스트31건 후 실제 DB에1회 적용했다. History group `1792715602352389`, ID6678–6686는 word update8·relation create1이고 모두 active다. 독립 SQL55조회·104검증에서 전체13테이블·DDL·byte 백업·공식 snapshot을 비교해 승인 projection·새 history·관련 sequence 외 변화 없음, work/seed/snapshot/백업 integrity ok·FK0·sidecar없음을 확인했다. 보호 입력238개 중 work DB만 바뀌었고 원본 연구31파일은 불변이다.

Work SHA `4525081ee72dd83a5d43bcbf66e52a62727fd64667687bfd6d342310c63b410f` → `fdd5741b1782242bb795ca938f07bc8f211556b57cce2e5c02419bd4074982fd`; seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1` 불변이다. Manifest SHA `f0889f3d83c66d8c40a5ad211db68a6cb7affb7b64786f40ff37a34c93ac6e7c`는 실제 적용 사본·현재 파일·Git index의 bytes가 일치하며, 이번 경로의 -text 속성으로 적용 원본 줄바꿈을 보존한다.

표준 progress JSON·CSV·Markdown 갱신과 독립21검증·공식 renderer 대조에서 네 항목만 신규 승인됐다. 승인524→528·미승인13,768→13,764·hold6·anomaly113·전체14,298이며 비대상14,294행과 anomaly는 exact 불변이다. Snapshot identity는 `60a46b8303066cc71ca512d30246ddfb18567c14e5443a04a5bda2da37f2d4cc`이다. Work DB는 Git 미추적 로컬 자산이며 seed 교체·앱 배포·전체 빌드·사용자 UX 테스트는 N/A다.

## 핵심 판단 근거

- Canonical Strong HebrewLexicon과 OSHB의 전체 관련 evidence를 확인했다. H192의 최초 자동 closure는1개였고, 실제 사전에서 확인한 메로다크 이름 요소를 비교하기 위해 H4781을 보충 seed로 삼아 관련4개 node 전체를 검토했다. 구조화 edge3·frontier0이며, H192와 나머지 세 어휘 사이의 수동 성분 연결을 canonical source edge로 꾸미지 않았다.
- H192의 두 용례는 여호야긴을 풀어준 바빌로니아 왕을 가리킨다. H1255와 H4757은 히스기야에게 글과 선물을 보낸 다른 왕의 이름 변이이고 H4781은 바빌론 신명이다. 두 왕과 신명을 같은 대상으로 합치지 않는다.
- 관용명과 원문 비교용 교재식 근사를 한 meaning에 병기한다. H1255의 실제 개역 표기 부로닥발라단과 H4757의 므로닥발라단을 보존한다. H4781의 마르둑은 확보된 새번역에서 확인한 같은 신명이다. 가운데점은 표기 병기이며 별도 sense가 아니다.
- 붙임표는 전승된 이름의 두 요소를 보여 주는 분석 기호다. 기존 베로-/메로-·발라단 읽기의 근사를 보존하며 특정 시대의 역사적 음가를 확정하지 않는다. 발아단이라는 더 세분된 읽기를 이번에 일괄 도입하지 않는다.
- H1255의 a variation of H4757은 직접적인 변이 근거다. 왕하20:12와 사39:1의 동일 인물 문맥 및 사전·번역 비교가 일치하므로 asserted/undirected variant로 채택한다. 반면 상호 Compare나 H192의 probably라는 어원 설명은 확정 compound 관계로 강화하지 않는다.
- 공식 source profile 집계는5개의 이름 occurrence이다. 현행 parser가 192+/1255+/4757+ 앞부분4토큰을 Packet surface에 포함하지 않는 한계를 확인해, 원문39파일을 읽고 전체 이름9토큰·5절 문맥을 별도 보충했다. 공식5를 물리 token 총수9와 혼동하지 않으며 parser/공식 count는 변경하지 않았다.
- 로컬 사전 exact4행과 전체5용례×5자료의25비교 슬롯을 전량 확인했다. LXX는 명시적6절 조회 뒤5문맥만 사람이 비교했고 다른 내용인 Jeremiah50:2는 제외했다. 별도27:2 조회는 바빌론·벨·마로다크 문맥 비교이며 자동 Hebrew-Greek alignment나 승인된 versification map이 아니다. 모든 로컬·LXX 자료는 reference-only 경계를 유지한다.
- 사용자는 현재 추천안을 채택했다. 이 기록의 근거는 해당 추천안의 evidence-backed 판단이며, 사용자가 별도로 말하지 않은 개인적 선택 이유를 추가하지 않았다.

## 채택하지 않은 주요 대안

- 현재 이름만 유지: 같은 대상의 충분한 식별 표현이지만, 사용자는 관용명과 원문 요소를 보여 주는 근사의 병기를 채택했다. H1255의 기존 브로닥발라단은 확보 개역 본문의 부로닥발라단으로 정리한다.
- H192를 아멜-마르두크로 대체하거나 메로닥의 군사/마르두크의 사람을 별도 meaning으로 추가: 원천 언어 이름과 경쟁 어원 풀이는 비고·연구에 보존한다. 성경의 고유명사와 별도 sense로 만들지 않는다.
- H1255/H4757을 하나의 동일 표기로 통일: 같은 사람이라는 판단과 b/m 전승형의 차이를 구별하기 위해 각각의 관용명·원문 근사를 유지한다. 알레프를 더 드러내는 발아단은 가능한 대안이지만 기존 읽기와의 일관성 및 최소 표기 원칙을 채택했다.
- H4781을 신상·태양신·폭풍의 아들 등의 별도 meaning으로 분리: 신명, 문맥상 신상 서술, 어원 가설·신화 역할은 구별한다. 이름의 기본 지시 대상만 단일 sense로 승인한다.
- H4781→H192/H4757 compound 및 H191→H192 관계: 성분 비교의 가치는 인정하되 reference의 qualifier와 원천 언어·전승형 사이의 차이를 넘어서는 관계 승인은 하지 않는다. 아버지 H1081과의 부자 관계도 lexical relation이 아니다.
- 전체 hold: 인물과 신명의 식별 및 기본 sense는 충분하고 남은 불확실성은 비고로 한정할 수 있으므로 채택하지 않았다.

## 남은 불확실성 및 재검토 조건

H192의 Strong 설명(아람어에서 온 이름·probably soldier)과 참고사전의 아카드어 man 풀이는 다르다. 한쪽을 다른 쪽으로 보정하지 않는다. H1255/H4757의 b/m 변이 발생 원인, Strong 표제어와 본문의 철자·모음 차이, 이름의 세부 역사적 음가 및 신명의 최초 뜻도 확정하지 않는다. source x-pn과 현재 DB 언어는 구별하며 언어 필드는 변경하지 않았다.

참고사전 H192의 잘못된 성경 참조 및 H4781 말미의 구스·사18장 혼입 문단은 canonical occurrence·의미·관계 근거로 사용하지 않았다. LXX 절 순서·이름 전사·병행 사건의 일자 차이도 원자료대로 남긴다. 출처가 분명한 원문·어원·본문비평 자료가 동일 대상 식별이나 어휘 형성 경로를 직접 뒤집을 때 재검토한다. 단순 번역어 차이·유사 철자·셰와 모음 차이만으로 자동 재검토나 데이터 변경을 하지 않는다.

현행 + lemma의 일반 처리와 Review 문맥 표시는 별도 도구 보완 후보이다. 이번에는 앞부분을 수동 보충해 semantic 근거를 확보했으며, 공식 집계·parser·앱 코드를 수정한 작업으로 기록하지 않는다.
