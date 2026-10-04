# H49 클러스터 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-04
- 대상: H0049, H7686, H4870, H7681, H7691, H7692; H0001은 승인 관계의 endpoint로만 포함
- 승인 manifest: [h49_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h49_cluster_approved_content_slice.json)
- 관련 hold ledger: 변경 없음, CORE word-level hold 없음
- 로컬 연구 산출물: `H0049_cluster_20261004_d58aa42d/00_cluster_summary.md`, 6개 Evidence Packet·Review, 31건 용례 평가 및 수동 시편 대조
- 최종 승인 원문과 값: `data/backups/approved_content_batch/h49_approval_20261004/00_approved_content.md`
- DB history group: `1791078986352574`

## 최종 결정

사용자는 H7686의 취함 용법 및 두 파생 명사의 범위를 확인한 뒤, H4870을 `잘못`으로 보완한 마지막 제안에 대해 “그래 지금 이대로 좋다고 본다. 이제 파일·DB·Git 작업까지 완료할 수 있겠다.”라고 승인했다. 나머지는 최초 추천안과 후속 설명을 반영한다. 아래는 승인된 추천의 근거이며 별도로 진술하지 않은 사용자의 개인적 판단 이유를 추정하지 않는다.

| Strong | 최종 meaning (순서) |
|---|---|
| H0049 | 1. 아비삭·아비-샤그 (인) |
| H7686 | 1. 빗나가다·잘못하다; 2. 취하다(醉하다)·마음을 빼앗기다 |
| H4870 | 1. 잘못 |
| H7681 | 1. 사게·샤게 (인) |
| H7691 | 1. 허물·잘못 |
| H7692 | 1. 식가욘 |

최종 비고:

- **H0049**: 수넴 출신으로 늙은 다윗을 돌보던 여성이다. ‘아비삭’은 한국어 성경 관용 표기이고 ‘아비-샤그’는 אֲבִישַׁג의 구성 요소를 드러낸 원문 기반 근사 표기다. H1과 H7686의 합성으로 설명되지만 이름 전체의 풀이를 하나로 확정하지 않는다. 왕상 1:4는 다윗이 그와 잠자리를 같이하지 않았다고 명시한다.
- **H7686**: 길이나 바른 판단·행동에서 벗어나는 것을 뜻하며, 일부 용례에서는 알지 못하고 잘못을 범하는 경우를 가리킨다. 히필형은 ‘빗나가게 하다·잘못 이끌다’의 사역 표현이다. 술에 취해 비틀거리는 용법과 비유적으로 사랑에 깊이 빠지는 용법이 있으며, 잠 5:19의 아내 사랑은 긍정적 용례다.
- **H4870**: 유일한 성경 용례인 창세기 43:12에서는, 돈이 되돌아온 일을 실수나 착오였을 가능성으로 설명한다.
- **H7681**: 하랄 사람 요나단의 아버지를 가리킨다. ‘사게’는 한국어 성경 관용 표기이고 ‘샤게’는 원문 기반 근사 표기다. Canonical 표제어 שָׁגֶא와 대상 11:34의 שָׁגֵה가 다르며, H7686에서 유래했다는 Strong의 설명은 추정이다.
- **H7691**: 시편 19편에서는 스스로 알아차리기 어려운 도덕적 잘못을 가리킨다. 유일한 용례의 히브리어 절 번호는 시 19:13이며, 한국어 성경과 KJV의 시 19:12에 해당한다.
- **H7692**: 시편 7편 표제와 합 3:1에 쓰인 문학·음악 용어로, 구체적인 형식이나 연주 방식은 분명하지 않다. 합 3:1의 ‘시기오놋’은 복수형이다. Strong은 H7686에서 유래한 격정적인 시로 설명하지만 이를 확정 번역이나 확정 어원으로 채택하지 않는다.

| Semantic 방향 | relation id | category / type / status | direction_code |
|---|---|---|---|
| H0001 → H0049 | 7716 | morphological / compound / asserted | w1_to_w2 |
| H7686 → H0049 | 7717 | morphological / compound / asserted | w2_to_w1 |
| H7686 → H4870 | 7718 | morphological / derived / asserted | w2_to_w1 |
| H7686 → H7691 | 7719 | morphological / derived / asserted | w1_to_w2 |
| H7686 → H7681 | 7720 | morphological / derived / hypothesized | w2_to_w1 |

H7686–H7692, H0001–H7686, H4870–H7691과 H7684 신규 관계는 생성하지 않는다. H0001의 기존 승인 meaning·비고, HUB-EXCLUDED와 기존 hold 2건은 유지한다. H7961은 후속 질문 문맥상 H7691을 가리킨 것으로 설명했으며 변경 대상이 아니다. Expression·언어·발음·POS·schema·seed·원천·앱 코드 변경 없음.

## 핵심 판단 근거

H0049은 실제 다윗을 돌본 여성의 이름으로, 관용 표기와 H0001·H7686 구성 경계를 보이는 근사 표기를 한 meaning에 병기한다. 이름 풀이를 별도 보통명사 meaning으로 만들지 않고 인물 식별과 어원 풀이를 구분한다. H7681도 관용 이름과 근사 표기를 병기하지만 Strong의 probably를 보존하여 파생 관계를 hypothesized로 저장한다. 표제어와 대상 11:34 surface 차이는 비고에 남기며 시대별 실제 발음을 확정하지 않는다.

H7686은 길·판단·행동에서 빗나가는 범위와 취함·매혹의 용법을 함께 가진다. 사 28:7의 취중 비틀거림과 잠 5:19의 아내 사랑에 빠지는 긍정적 용례가 모두 확인되므로 ‘마음을 빼앗기다’만으로 축소하지 않는다. 술이 등장한다는 이유만으로 의미를 추가한 것이 아니라 실제 용법과 BDB의 취중 비틀거림·취함 설명을 근거로 삼는다. 히필의 사역 표현은 별도 의미를 늘리지 않고 비고에 둔다.

H4870의 유일한 용례 창 43:12는 야곱이 반환된 돈을 실수·착오였을 가능성으로 설명하는 말이다. 창 42:25에서는 요셉이 의도적으로 돈을 돌려놓게 했으므로 사건의 실제 원인과 야곱의 추측을 구분한다. 이 용례에는 ‘실수’가 적합하지만 비의도성을 어휘 전체의 필수 조건으로 확정할 근거는 부족하다. 따라서 대표 meaning을 더 포괄적인 ‘잘못’으로 선택하고 확인된 문맥의 실수·착오 성격을 비고에 보존한다. 이는 고의적인 악행 용법까지 입증했다는 뜻이 아니다. 초기 ‘실수(失手)’, note NULL 추천은 이 최종 결정으로 대체한다.

H7691은 시편의 스스로 알아차리기 어려운 도덕적 잘못을 바탕으로 ‘허물·잘못’을 선택한다. H4870과 공유하는 잘못의 범위를 유지하며 의도적인 죄만 가리키는 단어로 대립시키지 않는다. 한국어·KJV 시 19:12와 히브리어 시 19:13을 명시적으로 대조했다. BDB가 제안한 H7684 복수형으로의 대안 독법은 확정 본문 교정이 아니므로 현행 canonical 형태·관계를 임의 교체하지 않는다.

H7692는 시편·하박국의 문학·음악 표제 term 식별은 가능하지만 구체적인 장르·연주 방식과 H7686 어원은 확정하기 어렵다. 음역 meaning으로 식별하고 한계를 비고에 남겨 word-level hold는 만들지 않는다. 어원 관계 미생성은 어원 반증을 뜻하지 않는다.

근거: pinned Strong 원문·OSHB·확보 로컬 참조·LXX 수동 대조는 로컬 연구 산출물에 보존한다. 후속 확인은 [BDB H7686](https://biblehub.com/bdb/7686.htm), [BDB H4870](https://biblehub.com/bdb/4870.htm), [BDB H7691](https://biblehub.com/bdb/7691.htm), [BDB H7684](https://biblehub.com/bdb/7684.htm), 창 42:25·43:12 및 시 19:12–13 원문을 사용했다. [한국어 표기 정책](../semantic_research/korean_lexical_notation_policy.md)의 meaning/비고·동일 표기 병기·붙임표·한자 검토를 적용했다.

## 채택하지 않은 주요 대안

- H4870을 ‘실수(失手)’로 고정: 유일한 용례에는 적합하지만 어휘 자체의 비의도성을 과도하게 고정할 수 있어 ‘잘못’과 문맥 비고를 선택한다. ‘착오(錯誤)’ 역시 가능한 문맥 번역으로 비고에 보존한다.
- H7686의 ‘취하다’를 삭제하거나 전체를 부정적인 잘못으로 통합: 취중 비틀거림과 아내 사랑의 긍정적 매혹 용례를 함께 설명하기 어렵다.
- H4870/H7691을 비의도적/의도적 잘못으로 대립하거나 완전 동의어 관계로 추가 연결: 현재 근거는 공유 의미와 용례 차이를 보여 줄 뿐 그러한 고정 관계를 입증하지 않는다.
- H7681의 어원을 asserted로 확정하거나 이름에 추정 합성 경계를 추가: canonical probably와 형태 한계를 보존한다.
- H7692를 격정적인 시·특정 연주 방식으로 확정 번역하거나 어원 관계 생성: 구체적 뜻·유래 확증이 부족하다.
- H0001의 생산적 인명 가지까지 새 승인: CORE와 구분된 CONTEXT/HUB-EXCLUDED 범위에 남긴다.

## 남은 불확실성 및 재검토 조건

H4870과 H7691은 각 1회 용례로 중심 의미를 선택할 근거는 충분하지만 가능한 모든 문맥·의도성 범위를 확정할 수 없다. H4870의 고의적 잘못 용법을 확인했다고 주장하지 않는다. 새로운 검증된 코퍼스·전문 어휘 자료가 의미 경계를 바꾸는 직접 근거를 제공하면 해당 의미와 비고만 재검토한다. 이름 전체의 풀이·시대별 발음, H7681 추정 어원, H7692 기술적 뜻·어원, 시편 대안 독법도 새로운 직접 근거가 있을 때 재검토한다.

Raw discovery 51 nodes/50 edges, frontier 43, max_nodes_reached, research_complete=false를 유지한다. CORE 6개의 canonical 31 token/29개 구별 절을 전량 검토했고 CONTEXT H0001과 HUB-EXCLUDED 44개를 구분한다. CORE의 승인 완료는 전체 그래프 closure 완료가 아니다. LXX는 human-reference이며 upstream/license unverified 상태와 자동 Strong/lemma/morph alignment 금지를 유지한다. H49/H7681 x-pn unresolved 및 H7691 자동 join 보류와 명시적 수동 보충을 구분한다.

## 적용 검증

- 공식 dry-run: meaning 교체 6·비고 교체 6·관계 생성 5, 총 17 operations; history 17행 및 사본 undo 성공. 원본 work SHA 불변. Live apply도 exit 0.
- Snapshot·result·manifest copy·독립 검증: `data/backups/approved_content_batch/20261004T015625523970Z/`. Snapshot SHA `87ad8d3f64855d715b31a3e2da7c76ebad199ef66b5993133213a1896baabb02`; integrity ok, FK 0. 기존 VACUUM INTO 계약의 schema cookie 차이는 DDL 변경이 아니다.
- 독립 전체 13테이블 대조: WORD_TABLE 승인 비고 6행, word_meaning_set 승인 대상 6개(최종 7행), WORD_RELATION 신규 5행(ID 7716–7720), CHANGE_HISTORY 신규 17행 및 관련 sequence 증가만 확인. 기존 관계와 승인 밖 데이터·DDL 동일.
- 실제 SQL: `SELECT seq,meaning FROM word_meaning_set WHERE word_id=? ORDER BY seq`에 CORE word_id 6개를 각각 전달하여 before/after·순서를 대조했다. `SELECT * FROM WORD_TABLE`의 비고 외 전체 column도 snapshot과 대조했다.
- 관계 SQL: `SELECT * FROM WORD_RELATION WHERE word_id_1=? AND word_id_2=?`에 manifest canonical pair 5개를 전달하여 pair·category·type·status·direction·note·source와 유일성을 확인했다. History SQL: `SELECT id,group_id,action_type,entity_type,entity_id,undone_at FROM CHANGE_HISTORY WHERE group_id=? ORDER BY id`에 `1791078986352574`를 전달하여 active 17행(word update 12/relation create 5)을 확인했다. SQL·parameters·결과는 independent_verification.json에 보존한다.
- Work SHA: `d58aa42d6b7a1ca798fcd4c096de42aed0a52a7fb4f530dbd0cc8b11bb354341` → `4c3b7ab814d1de7ae52fc19b823f4459ad0da378f2203630e476793b1d83bf13`.
- Seed SHA 불변: `e44bb989bebdc46a22bba2efac9defd06f3bdfd500577153de85adfa1bc148bb`; work/seed integrity ok, FK 0, sidecar 없음.
- Approval SHA: `35c1fd70b574f55ecaed994fbed781583ad740a297c5b01d3b48a418a41eabdd`; manifest SHA: `2ee9296f49f394a846f1cf3886ce2d31040c3b6f4ab5c0a366d828fc2d2e0f31` (working bytes·index blob·backup copy 일치, 새 manifest LF 고정).
- 공식 progress: CORE 6개 explicit_approved, 전체 승인 122→128, hold 2→2, 미승인 14,174→14,168, anomaly 113. JSON/CSV 각 14,298행 일치; 승인율 0.8533%→0.8952%. Snapshot identity `4b163d3c7b8f2a4f39861738064c7f2c818332bd5b3928be248a2d51d8fb0003`.
- `flutter test test/database/approved_content_batch_service_test.dart`: 29건 모두 통과.
- UI 테스트 N/A — 앱 코드·UX 변경 없음; 수동 UI 테스트는 수행하지 않았다.
