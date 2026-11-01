# H308 아하스배 인명 의미·비고 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-11-01 (Asia/Seoul)
- 대상: H0308 / H0308_0000
- 승인 manifest: [h308_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h308_cluster_approved_content_slice.json)
- 관련 hold ledger: [현행 ledger](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음
- 로컬 연구 산출물: reshet_research_output/H308_cluster_20261101_f5b340dc/00_cluster_summary.md 및 H308_review.md
- 승인·백업·독립 검증: data/backups/approved_content_batch/h308_approval_20261101/
- 공식 receipt: data/backups/approved_content_batch/20261101T042507737681Z/result.json

## 최종 결정

사용자는 직전 R1 추천안의 DB·문서·기타 필요 파일 반영과 검증, 커밋·작업 브랜치 push·main ff-only 병합·push·이번 작업 브랜치 로컬/원격 정리를 승인했다.

H0308 meaning seq1을 아하스배 (인)에서 **아하스배·아하스바이 (인)**로 교체했다. 같은 이름의 관용명·교재식 근사를 병기한 한 sense다. 비고 NULL을 다음으로 변경했다.

> 아하스배는 한국어 성경 관용명이고 아하스바이는 히브리어 표기의 교재식 한글 근사다. 삼하 23:34에서 다윗의 용사 엘리벨렛의 아버지로 나온다. 이름의 어원과 구성 요소는 불확실하다. 대상 11:35의 평행 명단에는 엘리발의 아버지 울이 나오며, KJV 난외주도 아하스배를 대안으로 제시한다. 다만 두 이름을 확정된 이명이나 형태 변이로 동일시하지 않는다.

기존 관계0, 신규·교체·삭제0, hold 없음. H218과의 확정 이명·variant 관계는 생성하지 않았다. 관계 category/type/status/direction은 N/A다. 기존 H218·H304·H307 승인값과 원문·음역·발음·언어·schema·seed·앱 구현은 유지했다. 기존 승인을 대체하지 않으므로 supersession 없음.

## 핵심 판단 근거

Canonical Strong H308은 אֲחַסְבַּי, source는 of uncertain derivation; 이다. Open Scriptures HebrewLexicon commit 21c9add13bc727d3a951361778e97e3ff7afd1ce 원자료를 보존했다. OSHB의 유일한 용례 삼하23:34에서 HNp·lemma308의 인명은 다윗의 용사 엘리벨렛의 부친을 가리킨다. Canonical1/1 전량 검토, 주 배정1·미검토0·의미 배정 미해결0·sense 모호0·실제 반례0이다.

HebGrkKo exact1, 5종 verse reference의 본 용례 각1과 평행 명단 각1, LXX 명시적2절을 대조했다. LXX는 provenance/license unverified인 human reference이며 자동 alignment·lemma·Greek Strong 추론을 하지 않았다. 새번역은 verse-level이고 한국어 reference profile의 unverified 경계를 유지한다.

아하스배는 한국어 관용명, 아하스바이는 원문과 기존 음역·원전분해를 대조한 교재식 근사다. [H304](h162_cluster_approved_content_slice.md)의 알래·아흘라이 및 [H307](h307_cluster_approved_content_slice.md)의 병기 원칙과 일치한다. [표기 정책](../semantic_research/korean_lexical_notation_policy.md) 검토표 및 외래어 제1·2·3·5항 적용·제4항 제외 기준을 따랐다. 한자를 만들거나 불확실한 합성 경계를 붙임표로 분절하지 않았다.

[Strong/BDB 해당 항목](https://biblehub.com/hebrew/308.htm)은 어원 불명·남성 부친·평행 명단의 본문 문제 가능성을 보여 준다. Canonical XML의 n-pr-f와 부친 문맥·BDB masculine은 충돌하지만 원자료를 자동 교정하지 않았다. H218의 울은 평행 명단과 KJV 난외주의 대응으로 보존하되 확정 이명으로 병합하지 않았다. BDB 전문·critical apparatus는 열람하지 않았으며 BLB Outline의 어원 후보는 검색 발췌만 확인해 확정 근거로 채택하지 않았다.

## 채택하지 않은 주요 대안

- 아하스배 단독: 유효한 관용명이지만 현재 기본 병기 원칙의 원문 비교 정보를 덜 제공한다.
- 아하스바이 단독: 한국어 성경 관용명을 잃으므로 병기했다.
- 울을 같은 meaning 또는 variant로 통합: 평행 명단·난외주의 가능성보다 강한 동일시이므로 비고에만 보존했다.
- 추정 어원을 별도 sense·합성 관계로 추가: 확정된 구성 근거가 없어 채택하지 않았다.
- 여성명 source 표기를 이유로 word-level hold: 현재 인명과 부친 역할을 판단할 수 있으므로 문제를 metadata·어원·본문 전승에 한정했다.

## 남은 불확실성 및 재검토 조건

정확한 어원·구성, 울과의 동일인 여부·본문 전승, source 품사 metadata, 역사적 일상 발음은 미확정이다. 한글 근사는 교재식 읽기이며 역사적 음성 복원이 아니다. 출처가 분명한 전문 사전·이름 연구·critical apparatus가 해당 판단을 실질적으로 바꾸면 재검토한다. 같은 자료 재집계나 표기 취향만으로 자동 재연구하지 않는다.

### 적용 검증

공식 dry-run·undo·원본 SHA 불변, 적용기 테스트31개 통과 후 live apply1회. 전체13테이블·DDL 독립 대조에서 승인 meaning·비고·history2행·해당 sequence 외 변경 없음. Meaning surrogate ID 재생성은 공식 replacement 동작으로 구별했고 비대상 meaning ID는 보존됐다. Integrity ok·FK0·sidecar 없음·seed SHA 불변이다.

History group1793507109159119, ID7510–7511, undone 없음. Work SHA f5b340dc47163d46b61fbb9d7b2e2f4c940673f40823078750c1bdec4682266c → 33ad858047a43e64b483d6b64d21de5b1ea6c413a67e4411168e20f62a5d9b06. Seed SHA a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1 불변.

공식 progress3종을 재생성하여 H308 승인·meaning·비고 exact 일치를 확인했다. 승인824→825·미승인13467→13466, hold7·anomaly113 유지. 기존 승인·source·reference·hold fingerprint 불변이다. 앱 UI·구현·UX·schema·seed 배포 변경이 없어 UI 테스트·전체 빌드는 N/A다.
