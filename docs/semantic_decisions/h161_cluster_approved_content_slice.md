# H161 클러스터 의미·비고·가설 공통 어근 관계 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-21
- 대상: H0161, H0164
- 승인 manifest: [h161_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h161_cluster_approved_content_slice.json)
- 관련 hold ledger: 새 hold 없음. 기존 [hold ledger](../../tool/data_provenance/manifests/semantic_research_dispositions.json) 6개는 변경하지 않음.
- 로컬 연구 산출물: `reshet_research_output/H0161_cluster_20261021_f701e3cb/`의 `00_cluster_summary.md`, Strong별 Review, `00_semantic_recommendations.json`
- 적용·검증: `data/backups/approved_content_batch/h161_approval_20261021/`, 공식 receipt `data/backups/approved_content_batch/20261021T115959984295Z/result.json`

## 최종 결정

사용자는 연구 추천안대로 DB·문서·필요 파일을 반영하고, 각 단계의 정상 완료를 확인한 뒤 Git 작업과 작업 브랜치 정리까지 진행하도록 승인했다.

| Strong | 최종 meaning | sense 수 |
|---|---|---:|
| H0161 | 오핫·오하드 (인) | 1 |
| H0164 | 에훗·에후드 (인) | 1 |

### 승인 비고 전문

**H0161**

> 시므온의 아들 이름(창 46:10; 출 6:15). ‘오핫’은 한국어 성경 관용 표기, ‘오하드’는 원문 אֹהַד의 교재식 읽기에 따른 한글 근사다. Strong은 ‘하나가 되다’를 뜻하는 미사용 어근에서 온 이름으로 풀이하며, ‘하나 됨’은 이 이름의 어원 풀이이다.

**H0164**

> ‘에훗’은 한국어 성경 관용 표기, ‘에후드’는 원문 אֵהוּד의 교재식 읽기에 따른 한글 근사다. 사사기에서는 게라의 아들인 사사(士師), 대상 7:10에서는 빌한의 아들 이름이다. Strong은 H161과 같은 어원에서 나온 이름으로 ‘연합된’이라고 풀이하지만, 로컬 참고 사전은 ‘나는 감사(찬양)하리라’라는 다른 풀이를 제시한다. 이름의 정확한 어원은 확정하지 않는다.

### 승인 관계

관계 id7977을 새로 생성했다. 저장 pair는 `H0161_0000` < `H0164_0000`, semantic direction은 H0161 ↔ H0164다.

| category_code | relation_type | status_code | direction_code |
|---|---|---|---|
| etymological | root_shared | hypothesized | undirected |

관계 비고: Strong은 H164를 H161에 제시된 어원과 연결한다. H161의 미사용 어근을 공유한다는 분석이며, H161 인명에서 H164 인명으로 직접 파생되었다는 뜻은 아니다. 로컬 참고 사전의 H164 어원 풀이가 달라 공통 어근 관계는 가설로 둔다.

근거는 Open Scriptures HebrewLexicon의 고정 HebrewStrong.xml(commit `21c9add13bc727d3a951361778e97e3ff7afd1ce`) H161/H164 source다. Source-reference H164 → H161을 semantic 파생 방향으로 복사하지 않는다. H161 인명에서 H164 인명으로 직접 파생되었다거나 같은 인물·동의어라는 관계를 승인하지 않았다.

두 단어의 hold는 없다. Expression·음역·발음·언어·기존 관계·schema·seed·앱 코드와 비대상 단어는 변경하지 않는다.

## 핵심 판단 근거

Recursive discovery는 H161·H164 두 node와 source edge1건에서 closure를 완료했다. Frontier0·resume0이며 hub 예외 없이 둘 다 CORE로 분석했다. Canonical Strong entry2개와 OSHB/WLC11 token·10절을 전량 검토했다.

- H161의 창46:10·출6:15는 모두 시므온의 아들 명단이다. 오핫은 한국어 성경 관용 표기, 오하드는 원문 אֹהַד와 기존 교재식 읽기 안내에 따른 한글 근사다.
- H164의 사사기8 token은 게라의 아들인 사사, 대상7:10의1 token은 빌한의 아들 이름이다. 다른 인물이 같은 이름을 쓴다는 이유로 lexical sense를 나누지 않는다.
- 관용명과 원문 근사 표기의 식별 가치를 함께 보존한다. 이 표기는 고대 발음 재구가 아니며 새 expression 교정도 아니다. 충분한 합성 경계 근거가 없어 붙임표는 넣지 않았다.
- Strong은 H161의 미사용 어근과 H164를 연결한다. HebGrkKo의 H164 ‘나는 감사(찬양)하리라’와 달라, 정확한 어원은 비고에서 미확정으로 남기고 공통 어근 관계를 가설로 승인했다. Strong 원문에 probably/perhaps가 있다는 뜻은 아니다.

5개 구절 참고자료를 occurrence 기준55건·고유 구절/자료 조합50건 비교하고 HebGrkKo exact row2개를 전량 확인했다. 로컬 자료는 reference-only다. LXX는 대상10절과 추가 문맥1절을 명시 조회했고 사사기 αωδ·대상7:10 αωθ를 수동 관찰했다. 자동 alignment·lemma 추정·canonical 집계로 사용하지 않았으며 upstream provenance·license 미검증 경계를 유지한다.

사용자는 위 evidence-backed 추천안의 의미·비고·관계를 최종 채택했다. 사용자에게 별도의 개인적 선택 이유를 귀속하지 않는다.

## 채택하지 않은 주요 대안

- 기존 `오핫 (인)`·`에훗 (인)`만 유지: 용례를 설명하는 유효한 대안이지만, 이번에는 원문 근사 표기도 같은 meaning에 두기로 승인했다.
- 원문 근사 표기만 사용: 한국어 성경 관용명으로 식별하는 가치를 보존하기 위해 채택하지 않았다.
- 하나 됨·연합된 자·나는 감사하리라를 별도 meaning으로 추가: 이름의 어원 풀이를 일반 명사·동사 sense로 승격하므로 채택하지 않았다. 필요한 내용은 비고에 보존했다.
- H164의 두 인물 문맥을 별도 sense로 분리: 인물 구별과 lexical sense 구별을 혼동하므로 채택하지 않았다.
- asserted 공통 어근·방향 있는 derived 또는 relation 비생성: Strong의 설명과 competing 참고 풀이를 함께 남기기 위해 무방향 hypothesized 관계를 선택했다. Relation 없이 note만 두는 방식도 가능한 대안이다.

## 남은 불확실성 및 재검토 조건

H161 미사용 어근의 독립 corpus 용례나 H164의 정확한 어원을 확정하지 않았다. Strong의 ‘두세 이스라엘 사람’이라는 설명을 OSHB의 두 인물 문맥과 강제로 맞추지 않는다. Source 언어 코드 x-pn/unresolved도 자동 보정하지 않는다.

로컬 LXX 삿4:1에는 에훗 이름과 죽음 절구가 없으며 추가로 확인한4:2에도 없다. 해당 human-reference의 차이를 전체 LXX 판본의 본문비평 결론으로 일반화하지 않는다. Canonical H164 삿4:1 출현은 그대로 보존한다.

전문 어원·본문비평 source가 상충하는 분석을 실질적으로 해결하거나 새로운 canonical 반례·인물/어휘 식별 문제가 발견되면 재검토한다. 같은 이름의 표기 변형이나 reference 번역어 차이만으로 승인값을 자동 변경하지 않는다.

## 적용 검증

공식 dry-run의 사본 적용·undo·원본 불변과 기존 applicator 테스트31건이 통과한 뒤 live apply했다. 의미2·비고2·관계1의5 operation이며 history group1792584001383765 / ID6500–6504는 word update4·relation create1·undone0이다.

독립 SQL54조회·84검증에서 전체13테이블·DDL·byte 백업·공식 snapshot을 비교했다. 승인 projection·새 history·관련 sequence 외 차이 없음, integrity ok·FK0·sidecar0이다. Snapshot schema cookie1369와 source1368의 차이는 기존 VACUUM INTO 계약이며 DDL·모든 table 데이터는 적용 전 백업과 일치한다. 보호 입력183파일·원본 연구17파일·applicator/test source는 불변이다.

Work SHA `f701e3cb874c8c3f0b56841513e75c3b7c101535a2ace3e307c96c11c55196ab` → `5a7421976c3e72d798daea06aacf36d7842a0759a59e506694595c16b4f587a7`. Seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1` 불변. Manifest SHA `e3c8357159718df57dc09a010925014e31f76ee5f7f3140b822217ff1c209a4e`, 승인 원문 SHA `46908a9d0d6fed62404dcb528540e0d9a23bbc8bc597faa3b371dc71bd9ec4ce`다. 신규 manifest의 text/eol=lf 속성으로 적용 bytes와 index가 일치한다.

표준 progress3종과 독립19검증·renderer byte 대조에서 H161·H164만 unapproved→explicit_approved로 바뀌었다. 승인446→448·미승인13,846→13,844·hold6·anomaly113·전체14,298이며 비대상14,296행은 exact 불변이다. Snapshot identity는 `18dc19a1682a868d17685ea04e898688b4a87ce3bbdaf636a7f04fed13029616`다.

DB는 Git 미추적 로컬 자산이다. 원본 연구 파일을 보존하고 후속 적용 receipt를 별도로 둔다. 앱 코드·UI·schema·의존성 변경이 없어 전체 빌드·UI 수동 테스트는 N/A다.
