# H165 장소 의문 클러스터 의미·비고·관계 승인 결정

- 상태 `partially_superseded`
- 2026-11-08 [H369 후속 결정](h369_cluster_approved_content_slice.md)에서 H0371의 비고를 보완했다. H0371의 뜻 승인과 이 기록의 다른 결정은 계속 유효하다.
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-22 (Asia/Seoul)
- 대상: H0165·H0335·H0346·H0349·H0351·H0370·H0371·H0375·H0575·H0645·H1963 (CORE11)
- 승인 manifest: [h165_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h165_cluster_approved_content_slice.json)
- 관련 hold authority: [현행 ledger](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음
- 연구 산출물: 로컬 `reshet_research_output/H0165_cluster_20261021_81afd7d3/`; 최신안은 `01_followup_semantic_review.md`와 `01_followup_semantic_assessment.json`
- 승인 원문·byte 백업·SQL·독립 검증: `data/backups/approved_content_batch/h165_approval_20261022/`
- 공식 snapshot·result·manifest 사본: `data/backups/approved_content_batch/20261022T001356357962Z/`
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)

## 최종 결정과 근거

사용자는 후속 검토의 최신안을 승인하고 DB·문서·필요 파일 반영, 검증을 거친 커밋·push·fast-forward 병합과 이번 로컬·원격 작업 브랜치 정리까지 승인했다. 아래 의미의 순서를 보존한다. 비고의 정확한 최종 문안과 적용 전 값은 manifest를 따른다.

| Strong | 승인 meaning 순서 | sense 수 | canonical 출현 |
|---|---|--:|--:|
| H0165 | 어디에 | 1 | 3 |
| H0335 | 어디에 | 1 | 38 |
| H0346 | 어디에 | 1 | 47 |
| H0349 | 어떻게 / 어디에 | 2 | 82 |
| H0351 | 어디에 | 1 | 1 |
| H0370 | 어디서 | 1 | 16 |
| H0371 | 아니 | 1 | 1 |
| H0375 | 어디 | 1 | 10 |
| H0575 | 어디에·어디로 | 1 | 43 |
| H0645 | 그러면 | 1 | 15 |
| H1963 | 어떻게? | 1 | 2 |

1. H0165는 호 13:10·14의 장소 의문으로 유지한다. KJV의 H1961 동사 독법과 13:10 난외 대안, H0346 철자 변이의 추정은 비고에 보존한다. 13:14의 수사적 의도와 어휘 의미는 구별한다.
2. H0335는 기본 장소 의문 하나를 두며 선택·출처·근거를 묻는 구성은 비고에 설명한다. 렘 5:7의 אֵי לָזֹאת와 Strong의 how 설명을 번역상 임의 첨가로 부정하지 않는다. 다만 이 구성에서 일반 방법 의문 전체로 확대하지 않는다. 잠 31:4의 Ketiv/Qere도 구별한다.
3. H0346의 47개 소재·존재 의문은 단일 의미로 충분하다. H0349는 어떻게와 어찌를 별도 sense로 나누거나 중복 병기하지 않고 어떻게를 대표로 둔다. 아 1:7의 두 장소 용례 때문에 어디에는 유지하며 탄식·반문·놀람은 비고에 둔다.
4. H0351의 유일한 왕하 6:13 간접 장소 의문에 맞추어 어디에로 정리한다. Strong의 H0349와의 probably 관계는 확정하지 않는다. H0370의 מִן 결합 16개 출처 의문은 어디서로 유지하고 부정어 H0369와의 추정 동일성을 구별한다.
5. H0371은 삼상 21:8(히브리어 21:9)의 부정의문에 근거해 아니를 유지한다. Strong의 is it not 설명과 OSHB 부정어 태그, local 사전 출현 집계 차이를 canonical 의미 통합 근거로 오용하지 않는다.
6. H0375는 사용자가 어디 하나와 비고를 선택했다. 삿 8:18의 인물 모습에 관한 대답과 한국어·KJV의 질적 해석, 확보된 LXX의 장소 의문 독법은 경쟁 해석으로 보존한다. 어떠한·when·how를 독립 meaning으로 추가하지 않는다.
7. H0575는 어디에·어디로 하나를 둔다. 시간 용례 14회/11절 모두 עַד־אָנָה 또는 עַד־אָן 구성이며 언제까지·얼마나 오래라는 실제 시간 용법은 인정한다. 단독 언제의 독립 meaning을 필수로 분리한 최초 추천은 채택하지 않는다. 공간적 원뜻만을 이유로 시간 문맥을 장소 질문으로 환원하지 않는다.
8. H0645는 그러면 하나를 대표로 둔다. 15개 용례의 질문 8·명령/소망 4·조건절 뒤 연결 3은 담화 기능으로 설명할 수 있다. 번역의 이제·지금을 별도 현재 시간 sense로 단정하지 않으며, 모든 용례를 조건문의 논리적 귀결로 제한하지 않는다. Strong의 here·now·then 및 KJV 출 33:16 독법은 비고에 보존한다.
9. H1963은 두 용례의 어떻게?를 유지한다. 별도 비고는 필요하지 않아 H0346과 함께 NULL을 보존한다.

## 관계 결정과 승인 범위

7개 모두 `category_code=morphological`, `status_code=asserted`다. Stored pair는 lexical canonical 순서이며 의미 방향은 direction_code로 표현한다. 기존 관계 교체·삭제는 없다.

| word_id_1의 Strong | word_id_2의 Strong | relation_type | direction_code |
|---|---|---|---|
| H0335 | H0346 | derived | w1_to_w2 |
| H0335 | H0349 | derived | w1_to_w2 |
| H0335 | H0375 | compound | w1_to_w2 |
| H0375 | H6311 | compound | w2_to_w1 |
| H0370 | H0575 | derived | w1_to_w2 |
| H0645 | H6311 | derived | w2_to_w1 |
| H0349 | H1963 | variant | undirected |

H0335→H0346/H0349의 확장, H0335·H6311→H0375의 합성 구성, H0370→H0575의 축약, H6311→H0645의 확장, H0349–H1963의 다른 형태라는 명시 설명을 각각 검토했다. H1963 변이는 역사적 선후를 단정하지 않는다. H0165–H0346의 apparently, H0335–H0370의 perhaps, H0349–H0351의 probably, H0370–H0369의 추정은 확정 관계로 만들지 않는다. H0165–H1961은 동일 형태의 대안 독법에 대한 usage 참조이며 파생 관계로 생성하지 않는다.

신규 hold 없음, 기존 ledger 6건 유지다. CORE11 외 CONTEXT4와 HUB-EXCLUDED52의 의미는 승인 대상이 아니다. H6311은 두 승인 관계의 구성 요소로만 참여하며 기존 어휘 값은 유지한다. 기존 active 결정을 대체하는 작업이 아니므로 supersession은 없다.

## 자료·범위·남은 불확실성

Canonical lexical source는 Open Scriptures HebrewStrong.xml commit `21c9add13bc727d3a951361778e97e3ff7afd1ce`, 용례는 OSHB다. CORE11의 258 canonical token을 전량 분류해 미분류 0이며, 후속 검토는 쟁점 5개 어휘 188 token의 기존 증거를 바탕으로 구문을 재대조했다. 로컬 사전·KJV·한국어 번역·LXX는 참고 자료로 유지하고 lemma 대응이나 어원을 자동 승인하지 않는다. LXX 45조회 중 오류·내용 불일치를 제외한 38개 문맥, 번역본 60건의 단건 절번호 대조는 전역 alignment나 versification 검증이 아니다. 참고 자료의 upstream provenance·license 미확인 경계를 보존하며 원문 자료를 앱에 새로 편입하지 않는다.

원 batch는 max_nodes 8에서 frontier 49로 멈춘 capped 결과다. 보충 discovery와 합친 67 nodes/73 edge groups를 CORE11·CONTEXT4·HUB-EXCLUDED52로 분류했고, H1961–H3068 신명·인명 허브 확장을 이번 단위에서 제외했다. CORE 검토와 승인 단위는 완료했지만 전체 재귀 closure 완료라고 선언하지 않는다. 원 state·queue·Review·Packet은 그대로 보존한다.

표기 검토에서는 고유명사·한자 병기·음가 재구·합성 경계·붙임표가 새 meaning에 필요한지 확인했다. 이번 뜻은 한국어 의문·부정·연결 표현으로 불필요한 한자나 발음 변형을 추가하지 않는다. H0575의 가운데점은 동일 의미 범위의 장소/방향 표현을 묶으며 두 독립 sense를 뜻하지 않는다. 원어·음역·발음·언어 필드는 유지한다.

구문 결합의 확장 용법과 독립 meaning 수는 구별한다. 특정 구성에 한정된다는 이유만으로 lexical 의미가 아니라고 일반화하지 않는다. 새 canonical 용례·본문비평 근거가 현재 설명을 벗어나거나 확정적 형태 관계의 반증이 나올 때, 또는 사용자가 표시 단위를 다시 선택할 때 재검토한다. 번역의 표현 수·번호 인접성·추정 참조만으로 자동 재개하지 않는다.

## 적용 검증

공식 dry-run의 사본 적용·undo·원본 DB 불변과 기존 applicator 테스트 31건이 통과했다. Live apply는 meaning replacement 5·기존 meaning approval 6·word note replacement 9·relation create 7이며 history group `1792628037634095`, history ID 6542–6562 총 21건(word update 14·relation create 7·undone 0), relation ID 7989–7995다.

독립 SQL 55조회·335검증에서 전체 13테이블·DDL·byte 백업·공식 snapshot을 대조했다. 승인된 값·이력·관련 sequence 외 변경 없음, integrity ok·FK 위반 0·sidecar 없음, 보호 입력 199파일과 원본 연구 불변이다. Snapshot schema cookie 1368→1369는 기존 VACUUM INTO 계약이며 실제 DDL과 적용 전 전체 데이터가 일치한다.

Work SHA `81afd7d3da5b5450f03b11c76de939e0af768150110f4af64878a0f0a166606a` → `8e796fbb40bd35d6e05a8bffa584a0390f3881c3d36957cfda588208d4371d65`. Seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1` 불변. Manifest SHA `9df5638c9e12850115a830e1c2d9b238783b4b33befac996383c165b9ee9e680`, 승인 원문 SHA `fa4401b551fb9a13227fd0346dadbf8010df5b7206f1391f96a46388a8c7bee8`다. Manifest의 LF 속성을 지정하여 적용 사본과 Git blob bytes를 보존한다.

표준 progress JSON·CSV·Markdown 생성과 69검증·공식 renderer byte 대조가 통과했다. CORE11만 신규 승인되어 explicit_approved 466→477·unapproved 13,826→13,815·hold 6·anomaly 113·전체 14,298이다. 비대상 14,287행·anomaly·canonical lexical index는 exact 불변이다. Snapshot identity `61ae171da11a55562ccaa66f0452fd23d5a95d7b48718e997ee8f7b88717800e`.

작업 DB는 Git 미추적 로컬 자산이며 manifest·결정·provenance·색인을 Git으로 보존한다. Seed 교체·앱 배포·schema·UI 변경은 없어 전체 빌드와 수동 UI 테스트는 N/A다. 최초 연구·후속 추천을 덮어쓰지 않고 별도 로컬 `00_applied_content.json`·Markdown에 적용 결과를 남긴다.
