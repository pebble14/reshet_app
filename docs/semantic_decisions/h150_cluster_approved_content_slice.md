# H150·H1871 화폐 단위 의미와 불확실성 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-21 (Asia/Seoul)
- 대상: H0150 (`H0150_0000`), H1871 (`H1871_0000`)
- 승인 manifest: [h150_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h150_cluster_approved_content_slice.json)
- 관련 hold ledger: 변경 없음; 신규 hold 없음, 기존 hold6 유지
- 로컬 연구 산출물: `reshet_research_output/H150_cluster_20261021_c7f4d41c_full/`
- 초기 자동 탐색 보존: `reshet_research_output/H150_cluster_20261021_c7f4d41c/`
- 최종 승인·byte 백업·검증: `data/backups/approved_content_batch/h150_approval_20261021/`
- 공식 snapshot·result·manifest 사본: `data/backups/approved_content_batch/20261021T015000041004Z/`
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)

## 최종 결정

사용자는 H150의 다릭 추천을 유지하고, H1871은 확실한 화폐 단위 범주와 드라크마·다릭의 경쟁 해석을 구분하는 최종안을 채택했다. 이어 DB·문서·필요 파일과 검증 후 Git·이번 작업 branch 정리까지 승인했다. Meaning replacement2·word note replacement2를 반영했으며 각 단어는 seq1 한 의미다.

| Strong | 변경 전 meaning | 최종 meaning | sense | canonical 출현 |
|---|---|---|---:|---:|
| H0150 | 다릭[페르시아 화폐] | 다릭[페르시아 금화(金貨)] | 1 | 2 |
| H1871 | 다릭 금화 | 화폐(貨幣) 단위(單位) | 1 | 4 |

### 승인 비고 전문

H150:

> 스 8:27에서는 금잔의 중량·가치를 다릭 단위로 나타내는 용법으로 이해된다. 이 화폐의 고대 페르시아어 명칭과 정확한 발음은 미확정이다.

H1871:

> Strong은 페르시아계 어휘로 설명하면서 ‘드라크마 또는 주화’로 풀이한다. 성경에서는 금의 양을 나타내는 화폐 단위로 쓰인다. 그리스계 드라크마로 보는 해석과 페르시아 금화 다릭으로 보는 해석이 있으며, 정확한 화폐의 동일시와 차용 경로는 불확실하다.

드라크마와 다릭은 H1871의 같은 용례들에 대한 경쟁 해석으로 취급한다. 별도 meaning 두 개로 나누거나 같은 화폐의 단순 표기 변형으로 확정하지 않는다.

### 관계와 hold

두 단어가 같은 화폐를 가리킨다는 관계나 공통 어원·형태 변이·차용 방향을 확정하지 않았다. Relation create/replacement/delete 모두0이고, 두 단어 관련 기존 WORD_RELATION 행도0이다. 생성할 relation의 category_code·relation_type·status_code·direction_code는 N/A다. 단어의 일반 의미는 승인할 수 있어 신규 hold를 만들지 않았으며 기존 ledger는 유지한다.

의미·비고 외 원어·아다르콘/다르케몬 음역·발음·언어·graph 설정·schema·seed·앱 코드와 비대상 데이터를 보존했다. 화폐명 의미와 히브리어 표제어를 읽는 음역은 별개 정보다.

## 핵심 판단 근거

Canonical Strong은 두 단어를 히브리어 남성 명사로 제시한다. H150은 페르시아계 어휘와 다릭 또는 페르시아 주화로, H1871은 페르시아계 어휘와 드라크마 또는 주화로 설명한다. 이 풀이를 보존하되 사전의 대표 번역을 실제 화폐 동일시의 최종 증명으로 취급하지 않는다.

OSHB의 H150 두 용례는 대상29:7의 금 헌물과 스8:27의 금잔에 연결된다. 다릭이라는 화폐명과 금잔의 중량·가치를 계산하는 용법을 한 의미와 비고로 처리한다. 고대 페르시아어 화폐명의 재구형을 당대에 직접 확인된 이름·발음으로 취급하지 않는다.

H1871의 스2:69와 OSHB 느7:69–71 네 용례는 모두 금의 양을 나타내는 단위다. 개역개정은 스2:69에서 다릭, 한국어 절 번호 느7:70–72에서 드라크마로 옮기며, 개역한글·새번역은 다릭을 사용한다. Strong·HebGrkKo·번역본·NET 번역자 주석을 비교하면 대표 화폐의 정확한 식별에는 논쟁이 남는다. 따라서 확실한 범주인 화폐 단위를 meaning으로 채택하고, Strong의 풀이와 두 해석을 비고에 함께 보존했다.

두 CORE의 canonical occurrence6/6회를 전부 검토했다. 느헤미야의 OSHB/KJV 절 번호 차이로 자동 lookup이 생략된 한국어 참고자료는 실제 본문과 헌물 수치를 사람이 대조했다. Machine Review의 manual_review_required를 덮어쓰지 않고 수동 증거를 별도로 보존했다. Local6자료와 LXX는 reference-only이며 canonical source로 승격하지 않는다.

초기 cluster summary의 H1871 드라크마 우선 추천은 연구 단계의 제안이었다. 이후 사용자는 그보다 넓고 확실한 화폐 단위 meaning을 선택했다. 초기 연구 artifact는 보존하고 최종 승인·적용 결과를 별도로 기록한다. 기존 active 의미 결정을 변경한 것은 아니므로 supersedes는 비어 있다. 사용자가 말하지 않은 개인적 선택 이유를 추정해 추가하지 않는다.

참고 출처:

- [Canonical Strong 고정 XML](https://raw.githubusercontent.com/openscriptures/HebrewLexicon/21c9add13bc727d3a951361778e97e3ff7afd1ce/HebrewStrong.xml): Open Scriptures Hebrew Bible Project, CC BY4.0. 현행 manifest hash와 일치하는 원문을 확인했다.
- [NET 에스라 본문·번역자 주석](https://bible.org/download/netbible/ondemand/bybook/ezr.pdf#page=4): 스2:69의 드라크마·다릭 경쟁 해석과 불확실성. 이 문서가 인용하는 모든 사전·문헌 원전을 별도로 전량 읽은 것은 아니다.
- [Williamson, Eschatology in Chronicles (1977),124쪽](https://tyndalebulletin.org/article/30618-eschatology-in-chronicles.pdf#page=10): 고대 페르시아어 화폐명 재구와 직접 입증의 구별.
- [Iranica, Daric](https://www.iranicaonline.org/articles/daric/): 그리스어 전승 명칭과 논쟁적인 어원 설명. 고대 페르시아어 재구형과 실제 그리스어 기록을 구별한다.

## 채택하지 않은 주요 대안

- H1871 `드라크마[화폐(貨幣)]`: canonical Strong의 풀이를 충실히 보존하는 유효한 후보이나, 대표 meaning으로 특정 화폐를 우선 확정하지 않기로 했다. 풀이 자체는 승인 비고에 보존한다.
- H1871 기존 `다릭 금화` 또는 `다릭[페르시아 금화(金貨)]`: 금 문맥과 한국어 번역 전통이 지지하는 유효한 해석이다. 다만 금이라는 문맥만으로 그 단위를 특정 페르시아 금화에 확정 대응하지 않는다. 다릭 해석은 비고에 보존한다.
- H1871 `드라크마·다릭` 병기: 동일 대상의 표기 변형처럼 보일 수 있으므로 채택하지 않는다. 두 이름은 경쟁 식별 해석이다.
- H1871 금화·은화 또는 드라크마·다릭의 별도2 sense: 실제 네 용례를 서로 다른 의미로 배분할 근거가 부족하다. 단일 범주와 불확실성 note로 처리한다.
- H150 기존 `다릭[페르시아 화폐]`: 기본 의미는 적절하지만 사용자가 금화 식별을 보완하는 최종안을 선택했다. 별도 중량 단위 sense는 추가하지 않는다.
- 확정 어원·동의·형태 변이 relation: 직접 입증이 부족하여 생성하지 않는다. 두 단어를 동일한 실물 화폐로 처리하는 관계도 승인하지 않았다.

## 남은 불확실성 및 재검토 조건

H150이 가리키는 화폐의 정확한 고대 페르시아어 명칭·당대 발음과 스8:27의 중량·가치 표현 차이, 정확한 환산값은 남아 있다. H1871의 그리스계/페르시아계 차용 경로·실제 화폐·H150과의 형태적 동일성도 확정하지 않는다. -몬을 독립된 히브리어 의미 접미사로 확정하지 않으며, 차용어 형태 분석을 추가 관계로 승격하지 않는다.

한국어 local reference 전체 versification profile과 LXX upstream provenance/license는 미검증 경계를 유지한다. LXX 확보 본문의 수치·표현 차이는 상세 연구에 보존했다. 특정 구절의 수동 대조를 source 전체의 자동 mapping 승인으로 확대하지 않는다.

원천어의 직접 입증 자료, 화폐 동일시를 실질적으로 해소하는 근거, 새로운 검증된 성경 용례·source identity 충돌이 제시되거나 사용자가 대표 의미를 변경할 때 재검토한다. 단순 발음 유사성·번역본의 이름 차이·같은 금 문맥만으로 자동 재검토하거나 관계를 생성하지 않는다.

### 적용 검증

공식 dry-run에서 사본 적용·실제 undo·원본 불변을 검증하고 기존 applicator 테스트31건을 통과한 뒤 live apply했다. History group1792547401280407, ID6442–6445는 word update4·undone0이다. 각 단어의 의미 교체 뒤 비고 추가 이력의 before/after 연쇄가 일치한다.

독립 SQL75조회·76검증에서 전체13테이블·DDL·공식 snapshot·byte 백업을 대조했다. 승인 의미2·비고2·history4와 history sequence 외 변경이 없다. Work·seed·백업·snapshot integrity ok·FK0·sidecar0, 보호 입력148파일·원본 연구24파일 불변이다.

Work SHA `c7f4d41c93067d16229bc56f438f43a938724654e9c8c81c321ddff924c87b01` → `ab1d645fa6a8d16a23092b7356c2a42e002c913a1f24ad3d9d1fadede84fc7f5`. Seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1` 불변. 승인 원문 SHA `a31bd733ccedb58402e2735a962e12979f850bea72c7e5f44444eada425ec091`, manifest SHA `700a7003993bfd73b00a9b3cdc03614ec80c7b58ce8fb79ec5588fda47c5cb34`다. 신규 manifest 경로만 -text로 지정하여 공식 적용 당시 bytes와 staged/committed blob을 일치시킨다.

표준 progress JSON·CSV·Markdown 공식 재생성, renderer byte 대조와26검증을 통과했다. 두 대상만 승인되어 explicit_approved422→424·unapproved13,870→13,868·hold6·anomaly113·전체14,298이며 나머지 row·canonical relation index·anomaly 목록은 불변이다. Snapshot identity `9bdc041c709e276087019d55753ed24d062872b2f395bd60b386acdb0588b008`.

DB는 Git 미추적 로컬 자산이다. 이번 Git 반영은 승인 manifest·결정 기록·provenance·색인·필요 metadata다. seed 교체·앱 배포·UI 변경은 없으며 UI 테스트·전체 앱 빌드는 N/A다.
