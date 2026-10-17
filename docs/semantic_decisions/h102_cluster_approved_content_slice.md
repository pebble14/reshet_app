# H102 군사 집단·타격 어휘와 H6211 나방/풀 수록 결정

- 상태: active
- 기록 성격: 사용자 승인 결정·적용 기록
- 승인일·적용일: 2026-10-17 (Asia/Seoul)
- 대상: Strong 6개 의미·비고, 파생 관계 2건, 아람어 보충 단어 1개
- Strong 승인 manifest: [h102_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h102_cluster_approved_content_slice.json)
- 보충 항목의 승인 내용·출처: [h6211_aramaic_supplemental_word.json](../../tool/data_provenance/manifests/h6211_aramaic_supplemental_word.json)
- 보충 항목의 일회성 적용 기록: [기존 repository를 사용하는 migration](../../tool/data_provenance/migrations/h6211_aramaic_supplemental_word.dart)
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 연구 산출물: C:/Users/kkiih/Documents/Workspace/FlutterWorkspace/reshet_research_output/H0102_cluster_20261017_011938a8/
- 승인 원문·byte 백업·SQL 검증: data/backups/approved_content_batch/h102_approval_20261017/
- 공식 Strong snapshot·result: data/backups/approved_content_batch/20261017T020550833768Z/
- 새 hold 없음; 기존 hold ledger 6건 유지

## 최종 결정

사용자는 H102의 의미 범위, H4047 이름 병기, H5063의 걸림/부딪침/타격 비교 및 H6211 심층 검토에 대한 최신 추천을 검토했다. 이어 H6211의 선택지 4, 즉 Strong 표제 보존과 아람어 보충 항목의 분리를 채택하고 DB·문서·필요 파일, 이상 없는 경우 Git과 이번 작업 브랜치 정리까지 승인했다. 아래 최종값은 최초 연구의 H4047 단독 이름·H5063 걸림·H6211 hold-only 추천보다 우선한다.

| 단어 | 언어·표제 | 최종 meaning 순서 | 용례 경계 |
|---|---|---|---|
| H0102_0000 | 기존 히브리어 표현 유지 | 부대(部隊) | 7회/6절 |
| H5062_0000 | 기존 히브리어 표현·나가프 음역 유지 | 치다 / 부딪치다 | 46회/3회 |
| H4046_0000 | 기존 히브리어 표현 유지 | 재앙(災殃) / 타격(打擊) | 22회/4회 |
| H4047_0000 | 기존 인명 표현 유지 | 막비아스·마그피아쉬 (인) | 1회 |
| H5063_0000 | 기존 히브리어 표현 유지 | 재앙(災殃) / 부딪침 | 6회/1회 |
| H6211_0000 | 히브리어 עָשׁ 및 기존 음역·발음 유지 | 나방 | 히브리어 7회 |
| H0000_0042 | 아람어 עֲשַׂב | 풀 | 아람어 5회 |

보충 단어의 실제 Strong 필드는 NULL이다. H0000_0042는 기존 repository의 언어별 로컬 ID 할당 결과이며 새 Strong 번호가 아니다. 보충 항목의 음역·발음·발음 체계는 NULL로 두고 새 역사적 발음이나 교재식 독법을 승인하지 않았다.

### 승인 비고 전문

**H0102**

> 에스겔서에서만 복수형으로 쓰이며 왕이나 민족에 딸린 군사 집단을 가리킨다. 일정한 병력 수나 현대의 편제 규모로 한정하지 않는다. 군대의 날개라는 어원 설명을 신체의 날개라는 별도 의미로 삼지 않는다. H5062에서의 파생은 Strong의 추정이며, 차용어 등 다른 분석도 있어 확정 관계로 처리하지 않는다.

**H5062**

> 사람이나 짐승을 쳐서 다치게 하는 일뿐 아니라, 질병·재앙으로 치거나 전투에서 패하게 하는 데도 쓰인다. 니팔형은 주로 전투에서 패함을 나타내며, 이를 별도 어근 의미로 나누지 않는다. 발이 돌에 부딪치거나 걸려 넘어지는 용례는 두 번째 의미에 둔다.

**H4046**

> 질병에 의한 재앙과 사람·재산에 닥치는 큰 재앙을 포괄하며, 모든 용례를 특정 전염병으로 한정하지 않는다. 전투에서 다수가 죽거나 패하는 경우와 에스겔 24:16의 죽음에 이르는 타격은 두 번째 의미에 둔다. 갑작스러운 죽음의 구체적 원인이나 병명은 본문이 밝히지 않는다.

**H4047**

> 느헤미야 10:20(히브리어 본문 10:21)의 언약 관련 백성 지도자 명단에 나오는 인명이다. 막비아스는 한국어 성경 관용 표기, 마그피아쉬는 기존 DB의 원문 기반 한국어 음역이다. 특정 시대의 실제 발음을 새로 확정한 표기가 아니다. 이름의 구성은 H1479 또는 H5062와 H6211의 결합이라는 추정이므로 확정 합성 관계를 만들지 않는다.

**H5063**

> 출애굽기·민수기·여호수아의 6회는 사람들에게 닥치는 치명적 재앙을 가리키며 질병에 의한 경우도 포함한다. 이사야 8:14에서는 발이 돌에 부딪쳐 걸려 넘어지는 이미지로 쓰인다. 해당 용례의 부딪침은 비유적 적용도 포함한다.

**H6211**

> 히브리어 עָשׁ는 의복을 갉아먹는 나방류를 가리키며 유충에 의한 손상도 포함한다. 이 어휘의 OSHB 출현은 7회다. 전통 번역의 좀을 현대 곤충명 반대좀과 자동으로 동일시하지 않으며 특정 현생 종은 확정하지 않는다. 욥 4:19의 하루살이 번역과 욥 27:18의 나방집·거미집 해석 차이는 별도 확정 의미로 늘리지 않는다. OSHB의 같은 숫자 번호 6211 b로 집계되는 아람어 עֲשַׂב의 풀 5회는 별개 어휘이며, Strong 번호 없는 보충 항목 H0000_0042에 수록했다. 정규 Strong 번호의 12회 집계와 이 히브리어 표제의 7회를 구분한다.

**H0000_0042 — 아람어 보충 항목**

> 아람어 עֲשַׂב로 땅에 난 풀과 소가 먹는 풀을 가리킨다. Open Scriptures Hebrew Bible Project의 LexicalIndex에서 6211 b(어휘 ID ouo, BDB xp.ap.ac)로 구분하며 BDB 아람어 부록 1108쪽에서도 확인된다. 다니엘 4:15·25·32·33, 5:21의 5회이며 עִשְׂבָּא 등은 굴절형이다. 채택한 HebrewStrong.xml의 히브리어 H6211 나방 표제에 직접 수록된 뜻으로 취급하지 않고 별도 보충 어휘로 보존한다. 6211 b는 출처 식별자이며 공식 Strong 번호를 새로 부여한 것이 아니다. 목초는 먹이 문맥의 풀이로 별도 의미를 두지 않으며 H6212와의 비교를 확정 파생 관계로 만들지 않는다.

## 판단 근거와 미채택 대안

**H0102**: 에스겔 12:14·17:21의 유다 왕 군사 집단 2회, 38:6의 고멜·도가르마 군사 집단 2회, 38:9·22 및 39:4의 곡 군사 집단 3회를 전량 확인했다. 부대는 특정 현대 편제를 전제하지 않으면 이 범위를 포괄한다. 군대도 유효한 대안이지만 더 적절하다는 반례는 확인되지 않았다. 일반 무리는 군사적 제한을 약하게 전달하며, 신체의 날개는 어원 설명을 독립 의미로 바꾼 것이어서 채택하지 않았다.

**H5062**: 물리적 상해·질병·재앙·전투 패배와 그 피동을 치다에 포괄한다. 발의 충돌 3회(시91:12·잠3:23·렘13:16)는 부딪치다로 구분한다. 패하다·죽이다·병들게 하다를 문법형과 결과에 따라 별도 의미로 늘리지 않는다. 이미 승인된 나가프 음역은 재작성하지 않는다.

**H4046**: 재앙을 전염병에만 한정하면 사람·재산의 재앙과 전투 및 개인의 치명적 타격을 포괄하지 못한다. 삼상4:17·삼하17:9·18:7의 전투 손실과 겔24:16의 치명적 타격은 타격으로 묶었다. 재앙/살육/치명적 타격의 세부 3행 안도 가능하지만 이번에는 최소 2행을 채택했다. 에스겔의 아내가 죽는 구체적 병명은 확정하지 않는다.

**H4047**: 막비아스는 한국어 성경 관용명, 마그피아쉬는 이미 표현란에 있는 원문 기반 한국어 음역이다. expression에 있다는 사실만으로 meaning의 식별용 병기를 배제하지 않았다. 동일 인명의 표기 변이이므로 한 meaning 안에 가운데점으로 병기한다. 나방을 없애는 자는 Strong의 추정 어원이며 인명 대신 별도 뜻으로 넣지 않는다. 새로운 역사적 발음이나 합성 경계를 확정하지 않았다.

**H5063**: 출12:13·30:12, 민8:19·17:11·12(OSHB; 한국어 민16:46·47), 수22:17은 재앙 6회다. 사8:14의 אֶבֶן נֶגֶף는 발이 돌에 부딪쳐 넘어지는 이미지다. 걸림도 문맥을 설명하지만 부딪침이 원인의 충돌과 H5062 부딪치다를 더 직접적으로 연결한다. 타격 하나로 압축하거나 다른 어휘들의 타격 표현을 일괄 변경하지 않는다. 신약의 돌 비유를 히브리어의 모든 용례에 역투사하지 않는다.

**H6211 선택지 4**: 채택한 HebrewStrong.xml은 히브리어 עָשׁ와 moth만 수록한다. 같은 pinned revision의 LexicalIndex는 히브리어 jxg/BDB p.gf.ab/6211 a와 아람어 ouo/BDB xp.ap.ac/6211 b를 각각 별도 언어 part에 둔다. BDB 1906년판 아람어 부록 원본 1108쪽도 עֲשַׂב의 풀·초목과 다니엘의 사료 문맥을 확인해 준다. 어휘 정체가 불명확하다는 최초 전면 hold 추천은 수정하고, 확인된 두 어휘를 다음 원칙으로 수록했다.

- Strong H6211의 표제·언어·음역·발음·번호는 유지하고 meaning을 나방으로 정리한다.
- 아람어 풀은 Strong 필드 NULL의 보충 단어로 등록한다. OpenScriptures 6211 b는 출처 식별자이며 새 공식 Strong 번호가 아니다.
- 기존 문자열 나방, 반대좀, 풀, 목초는 변경 전 DB·history·이 결정 기록에 보존한다. 풀 자료를 폐기하지 않고 별도 항목으로 옮겼다.
- 반대좀은 현대 한국어에서 좀목 곤충의 이칭으로 쓰이므로 나방의 동의어로 자동 확정하지 않는다. 특정 현대 나방 종으로 좁히거나 욥4:19의 하루살이 번역·욥27:18의 거미집 해석을 독립 meaning으로 늘리지 않는다.
- 다니엘의 5회는 한국어 단4:15·25·32·33·5:21이며 OSHB 절 번호는 4:12·22·29·30·5:21이다. 목초는 먹이 문맥의 풀이이며 풀에 포괄된다.
- 두 언어를 하나의 단어에 넣는 안은 표현별 의미와 그래프 관계를 구분하기 어렵다. 같은 Strong 번호의 두 항목으로 나누는 안은 현재 매핑·진행률 계약에 영향을 준다. 표제만 두고 비고에 풀을 설명하는 안은 독립 탐색을 제한한다. 기존 비Strong 단어 구조를 활용하는 선택지 4를 채택했다.

OSHB raw lemma 6211 a/b와 원래 12회 숫자 Strong 집계는 그대로다. 공식 진행률의 H6211 canonical_occurrence_count 12는 번호 기준 집계이며 히브리어 나방의 출현 12회를 뜻하지 않는다. 실제 어휘는 히브리어 7회·아람어 5회로 구분하며 보충 항목은 Strong 승인 분모·분자에 추가하지 않는다. 자동 용례 연결 도구를 확장하거나 source annotation을 교정한 것으로 보고하지 않는다.

### 관계 결정

| 의미 방향 | 신규 relation ID | category / type / status | canonical 저장 |
|---|---:|---|---|
| H5062 → H4046 | 7881 | morphological / derived / asserted | H4046_0000–H5062_0000, w2_to_w1 |
| H5062 → H5063 | 7882 | morphological / derived / asserted | H5062_0000–H5063_0000, w1_to_w2 |

Strong의 명시적 from 설명과 전체 용례에 근거한 명사 파생 2건이다. H5062→H0102의 probably와 H1479 또는 H5062 및 H6211→H4047의 apparently 대안 합성 관계는 생성하지 않았다. H6211–H5906의 see also를 별자리와 나방의 의미/파생 관계로 만들지 않았다. H6211–H6244, 보충 단어–H6211/H6212 관계는 이번 승인 실행에 추가하지 않았다. 같은 출처 숫자 번호의 공유만으로 두 어휘 사이에 semantic 관계를 만들지 않는다.

H1479의 닫다·비고 NULL 및 다른 CONTEXT/HUB-EXCLUDED 어휘는 승인·변경하지 않는다. 기존 관계 교체·삭제0, 새 hold0이며 기존 hold6건은 유지한다.

## 원천과 출처 경계

Canonical Strong와 OSHB/TAGNT source manifest·parser·원천 파일은 변경하지 않았다. LexicalIndex/BDB는 이 개별 보충 항목의 승인 근거이며 전체 canonical Strong source로 승격하거나 전량 import하지 않았다.

- [고정 HebrewStrong.xml](https://raw.githubusercontent.com/openscriptures/HebrewLexicon/21c9add13bc727d3a951361778e97e3ff7afd1ce/HebrewStrong.xml)
- [고정 LexicalIndex.xml](https://raw.githubusercontent.com/openscriptures/HebrewLexicon/21c9add13bc727d3a951361778e97e3ff7afd1ce/LexicalIndex.xml), raw SHA 8f7a605c58899d2f44430149c143c00903976e1e91232476677972a69e5bc85f
- [고정 BDB XML](https://raw.githubusercontent.com/openscriptures/HebrewLexicon/21c9add13bc727d3a951361778e97e3ff7afd1ce/BrownDriverBriggs.xml)
- [출처의 readme·라이선스](https://raw.githubusercontent.com/openscriptures/HebrewLexicon/21c9add13bc727d3a951361778e97e3ff7afd1ce/readme.md): Open Scriptures Hebrew Bible Project, CC BY 4.0. 실제 Strong/BDB 원저작물의 public domain과 전자 자료의 귀속 조건을 구별한다.
- [Oxford에서 확보한 BDB 아람어 부록 원본](https://arshama.classics.ox.ac.uk/downloads/Aramaic%20Lexicon%20%28Biblical%20Aramaic%20only%2C%201906%29.pdf), 1906년판 1108쪽, PDF raw SHA 490c318e5bf11ded78320cda690d3fdaff5441e40620253f6c172d08181ed0cf
- [국립국어원 부대](https://krdict.korean.go.kr/eng/dicSearch/SearchView?ParaWordNo=25706), [한국민족문화대백과 좀](https://encykorea.aks.ac.kr/Article/E0052881), [NET 욥27:18 번역자 주석](https://classic.net.bible.org/verse.php?book=Job&chapter=27&verse=18)

한국어 뜻풀이·메모는 자료를 대조하여 별도로 작성했으며 사전 설명문·PDF 판면·코퍼스 원문 전체를 앱에 편입하지 않았다. 귀속과 변경 성격은 [자료 출처 안내](../legal/data_attributions.md)에 기록한다.

## 적용과 검증

기존 승인 batch 도구는 단어 생성을 지원하지 않으므로, 보충 항목은 승인 manifest에 한정한 일회성 migration에서 기존 WordRepository.generateNextWordId/createWord를 사용했다. 사본 DB에서 실제 생성·undo를 수행하고 전체13테이블·DDL 및 기존 history를 비교한14검증을 통과했다. 원본에 같은 manifest를 적용했고 word create history 1건을 남겼다. 임의 SQL INSERT/UPDATE를 live-write 경로로 사용하지 않았으며 기존 도구 계약·schema·lib 코드는 변경하지 않았다.

Strong 6개는 기존 v5 공식 applicator로 의미6·비고6·관계2, 총14 write를 적용했다. 사본 적용·실제 undo·원본 불변 dry-run과 live apply가 성공했다. 두 manifest는 실제 적용한 UTF-8 CRLF 바이트를 보존하고 새 경로의 -text whitespace=cr-at-eol 속성으로 Git blob과 적용 사본 SHA를 일치시킨다.

보충 history group 1792202656903558, ID6155는 word create1건이다. Strong history group 1792202752206418, ID6156–6169는 word update12·relation create2건이다. 새 active history는 총15행, undone0이다.

독립 SQL 101조회·69검증과 기존15,030 word행 비교에서 승인한 변경 외 차이가 없었다. 전체13테이블·DDL·공식 snapshot·변경 전 byte 백업을 대조했고 integrity ok·FK0·sidecar0·seed 불변을 확인했다. SQL 목적·실행문·결과·해석은 09_independent_db_verification.json, progress 3종 render 검증은 10_progress_artifact_verification.json에 보존한다.

Work SHA 011938a8149ad6c4610fa5524eaa7a1113c2d23e83d00fea21c5d03122ca7bb7 → 보충 항목 적용 후 600ebfbc67d6082d47933b3b5c689e51a3c721f7f9c1237b19bcdca58d98f5f4 → 최종 0955d232eade5cef0b8afd765e353a35436e6ca1035bbd08306f00adbb9bdde7. Seed SHA a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1는 불변이다. Strong manifest SHA cf2fbea8fb080fb117ada33aa26c302ce12ca561b8bf66e945b3566b71fb1034, 보충 manifest SHA f02a2d973366c087c2ae1d8b345818f49b800cc940c93c28b781436824961cc0, 승인 원문 SHA acc1173aacf2adc722b47628a5092bc1fb85d25c842423b0b0d187f2f651173f이다.

검증 결과:

- 기존 approved-content applicator 테스트31건 통과.
- 일회성 migration 정적 분석 문제 없음, 사본 생성·실제 undo·전체 테이블 복원 검증 통과.
- 추가 실행한 기존 그래프 post-save 테스트2건은 삭제된 legacy 컬럼을 fixture에 넣으려다 실패했다. 해당 test·lib·pubspec은 main과 동일하며 이번 데이터 변경과 무관한 기존 fixture 문제로 분리했다. 범위를 넓혀 테스트를 수정하지 않았다.
- 앱/UI 코드·UX·schema 변경이 없어 UI 수동 테스트·전체 앱 빌드 N/A. 수행하지 않은 UI 검증을 완료로 보고하지 않는다.
- Work DB는 기존 정책대로 Git 미추적 로컬 자산이다. Seed 교체·설치 DB 교체·배포는 이번 범위가 아니다.

공식 CLI로 표준 외부 semantic_progress JSON·CSV·Markdown을 함께 갱신했다. 전체14,298 Strong 중 승인313→319·미승인13,979→13,973·hold6·anomaly113이다. 승인 전환은 H0102·H5062·H4046·H4047·H5063·H6211만이며 비대상 행·canonical relation index·기존 원천 fingerprint는 불변이다. 비Strong 항목845→846은 별도 집계된다. CSV/Markdown은 공식 render 결과와 byte 일치한다. Snapshot identity는 2a0f65300af645e3c0aec7fede9c5ec14c5ea9d46e358def0967008e5b86d239이다.

## 연구 범위와 재검토 조건

공식 discovery는 max_nodes_reached, discovered46·expanded32·frontier14, discovery_complete=false·research_complete=false를 유지한다. CORE5(H0102/H5062/H4046/H4047/H5063)와 CONTEXT2(H1479/H6211), 원거리39노드 제외 경계를 보존하며 전역 closure를 선언하지 않는다. 원래 CORE90토큰과 CONTEXT13토큰을 전량 검토한 뒤 H6211의 개별 처리 방침을 승인한 것이다.

원본21개 보충 Packet/Review/Relation과 discovery state/queue는 보존했다. 최초 추천 요약은 내용이 동일하며 Production 승인 기록 작성 전 CRLF→LF 변경이 있었던 것을 독립 검증에 기록했다. 이를 다시 쓰거나 복구하지 않았다. 실제 적용값은 외부 00_applied_content.md/json에 별도 기록한다.

추정 어원, 특정 나방 종, 욥기의 해석, 원자료 annotation과 LXX/local의 차이를 남긴다. LXX/local은 reference-only이며 자동 정렬·역사적 발음·새 관계의 authority로 승격하지 않는다. 새 직접 원자료가 수록 범위나 단어 식별을 실질적으로 바꿀 때 또는 보충 어휘의 자동 용례 연결을 지원하기로 별도 결정할 때 재검토한다.
