# H307 악메다 지명 의미·비고 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-11-01 (Asia/Seoul)
- 대상: H0307 / H0307_0000
- 승인 manifest: [h307_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h307_cluster_approved_content_slice.json)
- hold authority: [현행 ledger](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음
- 상세 연구: 로컬 reshet_research_output/H307_cluster_20261101_612efce1/00_cluster_summary.md 및 Full Review
- 승인 원문·적용 전 byte 백업·독립 검증: data/backups/approved_content_batch/h307_approval_20261101/
- 공식 적용 receipt: data/backups/approved_content_batch/20261101T040520011778Z/result.json

## 최종 결정

사용자는 R1 추천안의 DB·문서·필요 파일 반영, 검증 후 커밋·작업 브랜치 push·main ff-only 병합·push·이번 작업 브랜치 로컬/원격 정리를 승인했다.

H0307 meaning seq 1은 `악메다 (지)`에서 **`악메다·아흐메타 (지)`**로 교체했다. 같은 지명의 관용명과 교재식 근사이므로 한 sense다. 비고는 NULL에서 다음으로 변경했다.

> 악메다는 한국어 성경 관용명이고 아흐메타는 아람어 본문 표기의 교재식 한글 근사다. 메대의 도시 엑바타나(Ecbatana), 오늘날 이란의 하마단을 가리키며 페르시아 왕들의 여름 거처로 알려져 있다. 스 6:2에서는 고레스의 성전 재건 조서가 기록된 두루마리가 발견된 곳이다. Strong은 페르시아계 기원으로 설명한다. 이란어계 원천 지명은 보통 ‘모이는 곳’으로 풀이되지만, 본래 명명 동기는 확정하지 않는다. KJV 난외주에는 ‘상자 안에서’라는 대안이 있으나 여기서는 지명으로 이해한다.

기존 관계 0건, 신규·교체·삭제 관계 없음이며 pair·direction·category/type/status는 N/A다. Word-level hold와 ledger 변경 없음. 원문·음역·발음·언어·schema·seed·앱 구현·비대상 데이터는 유지했다. 기존 semantic 승인을 대체하는 것이 아니므로 supersession은 없다.

## 핵심 판단 근거

Canonical HebrewStrong.xml H307은 אַחְמְתָא, n-pr-loc이며 source는 `of Persian derivation;`이다. Open Scriptures HebrewLexicon commit 21c9add13bc727d3a951361778e97e3ff7afd1ce의 원자료를 보존했다. OSHB의 유일한 용례 Ezra.6.2를 전량 분석했다. בְּ/אַחְמְתָ֗א, lemma b/307, morphology AR/Np는 전치사와 지명이다. 6:1–5의 서고 수색·고레스 조서 문맥도 대조했다. 단일 지명 sense 배정 1/1, 미검토·의미 배정 미해결·채택 본문 내 sense 모호·실제 반례는 각각 0이다. 번역 전승 차이 관련 이슈 1건은 별도 중복 태그다.

HebGrkKo exact row 1, KJV·개역개정·개역한글·새번역·원전분해 각 1절, LXX explicit lookup 1절을 모두 비교했다. LXX 참고본문의 εν πολει는 도시 안에서이며 지명의 직접 음역이나 Greek Strong alignment로 처리하지 않았다. 로컬 자료는 reference-only, LXX는 provenance·license unverified 경계를 유지한다. NETS PDF는 접근 실패하여 해당 절 근거로 사용하지 않았다.

[Strong/BDB 해당 항목](https://biblehub.com/hebrew/307.htm)과 [Stuart C. Brown, ECBATANA, Iranica](https://www.iranicaonline.org/articles/ecbatana/)의 관련 단락으로 엑바타나·하마단 식별과 통상적인 이란어계 어원 풀이를 대조했다. 비문·연결 서지 전문을 직접 읽었다고 주장하지 않는다.

악메다는 성경 관용명, 아흐메타는 본문 표기와 기존 음역을 대조한 교재식 한글 근사다. H5의 아박다·아바그타, H303의 알랍·아흘라브와 병기 원칙이 일치한다. H163의 관용명 단독 승인은 개별 선택으로 보존하며 일반 생략 규칙으로 확대하지 않는다. 현행 한국어 어휘 표기 정책의 필수 검토표와 외래어 표기법 제1·2·3·5항 적용, 제4항 제외 기준을 확인했다. 한자를 만들거나 불확실한 합성 경계에 붙임표를 넣지 않았다. 정확한 고대 발음·모음 장단·세부 음가의 복원을 뜻하지 않는다.

Source language x-pn/unresolved와 OSHB의 아람어 사용·DB 언어 아람어를 구별하며 원자료나 DB 언어를 자동 변경하지 않았다. Lexical discovery는 node 1·edge 0·frontier 0으로 전역 closure 완료이고 hub 예외는 없다.

## 채택하지 않은 주요 대안

- 악메다만 유지: 올바른 관용명이나 현재 기본 병기 정책의 원문 비교 정보를 덜 제공한다.
- 아흐메타만 사용: 기존 성경 관용명을 잃으므로 병기했다.
- 엑바타나까지 meaning에 추가: 같은 도시의 유효한 전승명이지만 아람어 철자의 직접 읽기와 구별하여 비고에 보존했다.
- 모이는 곳을 별도 sense로 추가: 원천 지명의 어원 풀이이며 현재 본문에서 일반명사 의미로 쓰인 근거가 없다.
- 상자를 두 번째 sense로 추가: KJV 난외주의 실질적 대안으로 비고에 보존했으나 canonical 품사·본문·사전·전승 지명의 결합 근거에 따라 지명 해석을 채택했다.
- 임의의 히브리어 어근·같은 절의 궁성 명사와 관계 생성: source endpoint와 직접 어원 근거가 없어 생성하지 않았다.

## 남은 불확실성 및 재검토 조건

정확한 역사적 일상 호명, 이란어계 이름의 전체 차용·축약 경로, 본래 명명 동기, 모든 고대 사본 및 상자 대안의 본문비평은 미확정이다. 이를 단어 identity의 불확실성이나 word-level hold로 확대하지 않는다.

Provenance가 분명한 전문 사전·지명 연구·critical apparatus가 현행 지명 identity를 실질적으로 뒤집거나 canonical lemma·source·occurrence 범위를 변경하면 재검토한다. 이미 검토한 KJV 난외주·번호 인접성·표기 취향·x-pn 코드만으로 자동 재연구하지 않는다.

### 적용 검증

공식 dry-run에서 meaning 1·비고 1·history 2와 undo·원본 SHA 불변을 확인했다. 적용기 테스트31개 통과 뒤 live apply 1회를 수행했다. History group 1793505921537144, ID 7508–7509이며 undone 없음이다.

전체 13테이블과 DDL을 적용 전 byte 백업과 독립 대조했다. 승인된 meaning·비고·history 2건·CHANGE_HISTORY sequence 외 차이 없음. Integrity ok·FK 위반0·sidecar 없음, expression·관계·seed 불변이다.

Work SHA: 612efce19effd4ec7ee8309167990da0448eaa6742994a249114b9e7310c9195 → f5b340dc47163d46b61fbb9d7b2e2f4c940673f40823078750c1bdec4682266c.
Seed SHA: a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1 불변.

공식 progress JSON·CSV·Markdown을 함께 재생성했다. H0307의 승인·meaning·비고 exact 일치, 비대상 14,297행·anomaly 불변을 확인했다. 승인823→824·미승인13468→13467, hold7·anomaly113 유지다. 기존 승인 manifest132개·입력 manifest·hold ledger·로컬 reference6개 SHA 불변을 확인했다. 상세 SQL 대조 결과는 로컬 independent_verification.json, 진행 검증은 progress_verification.json에 보존했다.

앱 구현·UX·schema·seed 배포 변경이 없어 UI 테스트·전체 빌드는 N/A다.
