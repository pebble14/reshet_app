# H104 편지·강제 역무 어휘군 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-17 (Asia/Seoul)
- 대상: H0104, H0107, G0029
- 승인 manifest: [h104_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h104_cluster_approved_content_slice.json)
- 관련 hold ledger: 변경 없음; 기존 hold6 유지, 새 hold 없음
- 로컬 연구 산출물: C:/Users/kkiih/Documents/Workspace/FlutterWorkspace/reshet_research_output/H0104_cluster_20261017_0955d232/
- 승인 원문·byte 백업·독립 SQL: data/backups/approved_content_batch/h104_approval_20261017/
- 공식 적용 snapshot·result: data/backups/approved_content_batch/20261017T030424002355Z/
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)

## 최종 결정

사용자는 Codex의 완료된 H104 클러스터 추천안 전체를 채택하고 DB·문서·필요한 파일 반영, 이상 없는 경우 Git과 이번 작업 브랜치 정리까지 승인했다. 아래 의미·비고·관계만 적용했다. 기존 그리스어·아람어 표현 정비 결정과 원어·음역·발음 값은 유지한다.

| Strong | 최종 meaning | sense / canonical 출현 |
|---|---|---|
| H0104 | 편지(便紙/片紙) | 1 / 3회 |
| H0107 | 편지(便紙/片紙) | 1 / 10회 |
| G0029 | 억지로 일을 시키다 | 1 / 3회 |

세 항목 모두 meaning seq=1 한 행이다. 便紙/片紙는 같은 한국어 단어의 한자 이표기이며 별도 sense 구분이 아니다.

### 승인 비고 전문

**H0104**

> 에스라 4:8·11, 5:6에서 왕에게 보내는 편지를 가리킨다. Strong은 페르시아어 기원으로 설명하지만, 아카드어 egirtu와의 관계 및 차용 경로에 관한 다른 분석이 있어 고대 페르시아어에서 직접 빌려온 말로 확정하지 않는다.

**H0107**

> 왕이 내리는 편지를 가리킬 때에는 문맥에 따라 조서(詔書)나 친서(親書)로 옮긴다. 일반적인 서신 교환이나 협박 편지에도 쓰이므로 왕의 명령에만 한정된 말은 아니다.

**G0029**

> 공적 역무나 운송을 위해 사람을 강제로 동원하는 배경의 말로, 문맥에 따라 징발하다(徵發하다)로 옮길 수 있다. 신약에서는 일정 거리를 가게 하거나 십자가를 지고 가게 하는 데 쓰인다(마태복음 5:41; 27:32; 마가복음 15:21). ἄγγαρος(급사)에서 형성된 동사이며, 이 명사는 이란계 차용어로 보는 분석이 있으나 정확한 원천형과 H104와의 직접 어원 관계는 확정하지 않는다.

### 관계와 유지 결정

- 신규 relation ID 7883: H0104_0000 ↔ H0107_0000, etymological / root_shared / asserted / undirected. 저장 pair는 H0104_0000 < H0107_0000이다.
- 신규 관계 비고: 같은 편지 어휘의 아람어·히브리어 대응형이다. Strong은 H107을 H104의 feminine of로 설명하지만 두 정본 표제 모두 여성명사이며, 여기서는 남성에서 여성으로의 전환이나 직접 차용 방향을 확정하지 않는다.
- G0029_0000–H0104_0000 기존 ID45는 unspecified / related / inferred / unknown과 원래 source·note를 포함한 전체 row를 그대로 유지했다. compare를 확정 차용·공통어근 관계로 승격하지 않았다.
- G29–H107의 전이적 관계와 상세 차용·파생 방향 관계를 생성하지 않았다. 신규 word hold 없음, 기존 ledger6 유지.

## 핵심 판단 근거

H104의 에스라4:8·4:11·5:6은 왕에게 보내는 고발·보고 편지다. H107의10회는 유월절 초청2, 통행·목재 공급 관련 왕의 편지3, 공개 편지·서신 교환·협박3, 부림 관련 통지2다. 편지 하나가 전량을 설명하며 조서·상소문은 전달 문서의 문맥상 기능이다.

G29의 마5:41·27:32·막15:21은 일정 거리를 가거나 십자가를 운반하도록 강제하는 동일한 역무 의미다. 마5:41은 주체를 누구든지로 제시하며, 신약에서 일반화된 강제 의미를 설명하는 사전 근거도 있어 억지로 일을 시키다를 대표어로 채택했다. 기존 징발하다는 유효한 문맥 번역으로 비고에 보존했다.

H107 source의 feminine of H104와 양쪽 정본의 여성명사 분류를 함께 검토했다. 두 언어에서 같은 편지 어휘라는 공통 바탕은 표현하되, 남성→여성 전환이나 역사적 차용 방향을 확정하지 않는 무방향 관계를 택했다. 언어별 동계 대응을 root_shared로 기록하는 기존 프로젝트 관례와 일치한다.

정본16회/16절 전량과 HebGrkKo exact3행, 로컬 절 참고자료5종×16절=80건, LXX explicit13절을 확인했다. 원문·형태·전체 문맥과 번역 표현을 비교했으며 미분류·ambiguous·추천안을 뒤집는 occurrence 반례는0이다. LXX/local은 reference-only이며 자동 alignment·Strong 부여·canonical counting의 authority로 승격하지 않았다. 원본 Packet/Review/state와 연구 요약17파일은 변경하지 않았다.

보충 근거는 [Bodi의 공개 어원 논의 pp.15–21](https://api.pageplace.de/preview/DT0400.9783161615252_A46638824/preview-9783161615252_A46638824.pdf#page=30), [Cambridge Greek Lexicon의 해당 어휘](https://api.pageplace.de/preview/DT0400.9781108623315_A45554777/preview-9781108623315_A45554777.pdf#page=31), [국립국어원 편지 항목](https://krdict.korean.go.kr/eng/dicSearch/SearchView?ParaWordNo=24147)이다. Bodi 논문 전체를 확보했다고 주장하지 않으며, source 설명·학술 이견·한국어 풀이를 구분한다. 사전 본문·PDF 판면·새 코퍼스를 앱에 import하지 않았다.

## 채택하지 않은 주요 대안

| 대안 | 채택하지 않은 이유 / 보존 |
|---|---|
| H104 서신과 편지를 별도 sense로 분리 | 동의 표현이며 전체3회에서 lexical 구분이 불필요하다. 서신도 유효한 대안이지만 쉬운 대표어 편지를 선택했다. 변경 전 값은 byte 백업·history에 보존했다. |
| H104 공문·상소문, H107 칙령·조서 추가 | 특정 문서 기능·발신자에 한정되므로 일반 sense를 늘리지 않았다. 왕의 편지는 비고에 설명한다. |
| G29 징발하다(徵發하다) 대표어 유지 | 공적 강제 동원을 잘 표현하는 유효한 대안이다. 원문에 없는 국가 기관 제약을 더하지 않는 쉬운 풀이를 채택하고 징발하다는 비고에 남겼다. |
| G29 급사 노릇을 하다 / 십자가를 지우다 추가 | 각각 어원 배경과 특정 문맥의 행위다. 정본3회에 필요한 독립 sense로 확정하지 않았다. |
| H104 고대 페르시아어 직접 차용 단정 | Strong의 설명은 비고에 출처를 밝혀 보존하지만, 아카드어 관련성과 차용 경로에 관한 다른 분석이 있다. |
| H104→H107 확정 형태 파생·차용 방향 | 같은 lexical 바탕과 직접 역사적 방향은 다른 판단이다. 무방향 공통어원 대응만 기록했다. |
| G29–H104 확정 어원 관계 | canonical wording은 compare다. 기존 inferred/unknown 관계를 보존하고 승격하지 않았다. |

## 남은 불확실성 및 재검토 조건

H104의 궁극 어원·직접 차용 경로, H107과의 상세 전승 방향, G29의 외래 명사 원천형과 H104 직접 연결은 미확정이다. 세 단어의 식별과 정본 전체 의미 설명을 막는 불확실성이 아니므로 word hold로 처리하지 않았다.

HebGrkKo H104의 스4:1,8;5:6 목록은 정본4:8·4:11·5:6과 다르며 참고 사전 내부 오류로 기록한다. 이를 canonical occurrence에 가산하거나 정본 출현을 제외하지 않는다. LXX는 provenance·license 미검증, 번역 source의 unverified reference profile은 그대로다. H107의 기존 발음 안내도 이번 의미 승인에서 변경하지 않는다.

직접 차용 경로를 입증하는 새 언어학적 evidence, 현재 sense로 설명되지 않는 검증된 정본 용례, 실제 identity/source-mapping 충돌이 확인될 때 재검토한다. 단순 번역어 차이·번호 인접성·한자 marker만으로 자동 재검토하지 않는다.

### 적용과 검증

공식 v5 applicator로 meaning replacement3·word note replacement3·relation create1, 총7 write를 적용했다. Dry-run 사본 적용·실제 undo·원본 불변과 live apply가 성공했다. History group 1792206265189026, ID6170–6176은 word update6·relation create1, active7행·undone0이다.

독립 SQL 51조회·60검증에서 전체13테이블·DDL·byte 백업·공식 snapshot을 대조했다. 승인 대상 외 데이터, 기존 expression·관계·history는 그대로이며 허용된 meaning·note·관계·history와 해당 sequence 외 변화가 없다. Work·seed·byte 백업·snapshot integrity ok·FK0·sidecar0, 보호 입력98개 불변, 기존 applicator 테스트31건 통과다. word_meaning_set은 AUTOINCREMENT가 아니므로 sqlite_sequence 변경을 요구하지 않고 실제 schema에 맞춰 확인했다.

Work SHA 0955d232eade5cef0b8afd765e353a35436e6ca1035bbd08306f00adbb9bdde7 → 4a4a48939b2985de98773cc355d7c66548e1a7b3a2be73bd04f3e6092d26ebf6. Seed SHA a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1는 불변이다. 승인 원문 SHA a9368279753762d35132b5d11e823e5cda707da14d43d2c74e2a20ee8a3d6c6b, manifest SHA 9be32fd285a5083e6ffca943778efae364afa34a9324ca7b1ea113935c96f7ba이며 새 manifest는 UTF-8 LF로 기록했다.

표준 semantic_progress JSON·CSV·Markdown을 공식 CLI로 갱신하고28검증을 통과했다. 전체14,298행 중 이번3개만 unapproved→explicit_approved이며 승인319→322·미승인13,973→13,970·hold6·anomaly113이다. 비대상 row·canonical relation index·원천 fingerprint는 그대로이고 CSV/Markdown은 공식 render와 byte 일치한다. Snapshot identity는 52595bad105e105bfb0c9bed0f815a22fd2749f9a5d374a272ba97d726b4c416이다.

정상 CORE3 closure·frontier0을 유지한다. 실제 적용 결과는 외부00_applied_content.md/json에 별도로 보존한다. Work DB는 Git 미추적 로컬 자산이며 seed·설치 DB 교체나 앱 배포는 수행하지 않았다. 앱/UI·UX·schema·의존성·원천 도구 변경이 없어 UI 수동 테스트와 전체 앱 빌드는 N/A다.
