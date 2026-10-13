# H56 클러스터 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-13
- 대상: CORE 5개 `H0056`, `H0057`, `H0060`, `H0061`, `H0179`
- 승인 manifest: [h56_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h56_cluster_approved_content_slice.json)
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 관련 hold ledger: [기존 semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음
- 로컬 연구 산출물: `C:\Users\kkiih\Documents\Workspace\FlutterWorkspace\reshet_research_output\H0056_cluster_20261013_65c25be5`의 cluster summary, Strong별 Packet·Review·관계 증거, 83토큰 coverage와 원문 문맥 자료
- 최종 승인 원문·정확한 값과 검증: `data/backups/approved_content_batch/h56_approval_20261013/`
- 실제 적용 DB: `data/reshet_work.db`
- DB history group: `1791849685896495`

## 최종 결정

사용자는 기존 애통 계열 meaning의 충분성과 H56의 ‘마르다’ 분석을 추가 검토한 최신 제안을 채택했다. 마지막으로 ‘애도’의 한자 병기를 요구했고, 이를 반영한 최신 문안에 대해 DB·문서·Git·이번 작업 브랜치 정리까지 승인했다. 초기 연구 summary의 ‘애통’ 통일 제안보다 아래 최종값을 우선한다.

| Strong | 최종 meaning과 seq | 결정 |
| --- | --- | --- |
| H0056 | 1. `슬퍼하다, 애도하다(哀悼하다)` | 기존 의미 범위 유지, 한자 병기 |
| H0057 | 1. `슬퍼하는, 애도하는(哀悼하는)` | 기존 의미 범위 유지, 한자 병기 |
| H0060 | 1. `슬퍼함, 애도(哀悼)` | 기존 의미 범위 유지, 한자 병기 |
| H0061 | 1. `참으로`, 2. `그러나` | 확언·역접 두 기능을 순서대로 분리 |
| H0179 | 1. `오빌 (인)` | 기존 meaning 그대로 승인 |

H0056·H0057·H0060은 각각 하나의 meaning 행 안에서 넓은 슬픔과 사별의 애도를 함께 표현한다. 쉼표 앞뒤를 별도 sense로 늘리지 않는다. 다음 비고를 각 단어에 추가한다.

**H0056 비고**

> 죽음뿐 아니라 재난·상실·죄 때문에 슬퍼하는 데도 쓰이며, 애도 행동을 나타내기도 한다. 사역형에서는 ‘슬퍼하게 하다’로 쓰인다. 땅·초장 등이 주어인 구절은 의인화로 읽을 수 있으나, 일부 사전은 ‘마르다’라는 별도 어근으로 분석한다(사 24:4·7; 욜 1:10; 암 1:2 등). 관련 용례의 어근·의미 분리에는 견해 차이가 있다.

**H0057 비고**

> 사별뿐 아니라 좌절이나 재난으로 슬퍼하는 상태에도 쓰인다. 명사적으로는 ‘슬퍼하는 사람’을 뜻하며, 애 1:4에서는 시온으로 가는 길을 의인화한다.

**H0060 비고**

> 죽음뿐 아니라 재난을 슬퍼하는 데도 쓰인다. 문맥에 따라 애도 기간·상복·초상집과 관련된 표현을 이룬다.

**H0061 비고**

> 창 17:19·왕상 1:43·단 10:21에서는 확언과 앞말을 바로잡거나 전환하는 기능이 겹칠 수 있다. ‘슬퍼하다’ 계열과의 어원 연결은 Strong이 추정으로 제시한다.

**H0179 비고**

> 다윗의 낙타를 맡은 이스마엘 사람(대상 27:30). 이름의 어원은 미확정이며, ‘낙타 모는 사람’이라는 설명도 제시된다.

관계는 아래 두 건만 생성한다. 저장 pair는 canonical 순서이며 semantic 방향은 H0056에서 파생어로 향한다.

| semantic 방향 | category_code | relation_type | status_code | direction_code |
| --- | --- | --- | --- | --- |
| H0056 → H0057 | morphological | derived | asserted | w1_to_w2 |
| H0056 → H0060 | morphological | derived | asserted | w1_to_w2 |

H0056 → H0061의 `apparently`와 H0056 → H0179의 `probably` 어원 관계는 생성하지 않는다. 이 결정은 word hold와 구별한다. 다섯 단어 모두 새 word hold가 없고 기존 hold 6건은 유지한다. H56의 ‘마르다’는 경쟁 어근 분석으로 비고에 보존하며 독립 meaning으로 확정하지 않는다. 원문 expression·한글 음역·발음·언어·품사·schema·seed·원천 자료와 다른 승인값은 유지한다.

공식 applicator로 meaning 교체 4건·비고 교체 5건·관계 생성 2건, 총 11개 operation과 H179 meaning 유지 승인 1건을 검증했다. Dry-run 사본 적용·undo 및 live apply가 성공했고, 독립 전체 13테이블·DDL 대조에서 승인된 변경과 history 11행·관련 sequence 증가만 확인했다. 표준 progress에서는 다섯 Strong만 `unapproved`에서 `explicit_approved`로 바뀌었다.

## 핵심 판단 근거

- Canonical Strong과 OSHB에 따른 closure 5개 전체를 검토했다. H56 39토큰/38절, H57 8/8, H60 24/22, H61 11/11, H179 1/1로 총 83토큰이며 서로 다른 78절이다. Frontier 0, discovery/research complete이며 hub 예외가 없다. 로컬 번역·어휘 자료와 LXX는 참고자료로만 사용했다.
- 기존 ‘슬퍼하다/슬퍼함’은 살아 있는 사울을 슬퍼함(삼상 15:35·16:1), 죄로 인한 슬픔(스 10:6), 하만의 좌절(에 6:12), 재난의 위협(에 4:3)도 포괄한다. ‘애도’를 함께 둔 기존 meaning은 이 넓은 범위를 좁히지 않는다. ‘애도’는 哀悼이므로 사용자의 마지막 지시에 따라 병기했다. [국립국어원 사전](https://krdict.korean.go.kr/kor/dicSearch/SearchView?ParaWordNo=25193)
- H56 자연물 주어의 구절에는 의인화한 슬픔과 물리적 마름이라는 경쟁 분석이 있다. BDB의 슬픔·의인화 분석과 NET 주석이 인용하는 HALOT의 별도 ‘마르다’ 어근 분석을 구별했다. HALOT 원전 자체를 직접 열람한 것은 아니다. 사 24:4·7, 33:9, 렘 12:4, 욜 1:10, 암 1:2의 병행 표현은 마름 분석을 지지할 수 있지만 어근 분리를 확정하지는 않는다. 일부 LXX의 애통 계열 대응은 오래된 의인화 읽기를 뒷받침하며 다른 분석을 배제하지 않는다. [BDB H56](https://biblehub.com/hebrew/56.htm), [NET 사 24:4 주석](https://classic.net.bible.org/passage.php?passage=Isa+24:4), [NET 암 1:2 주석](https://classic.net.bible.org/verse.php?book=Amo&chapter=1&tab=commentaries&verse=2)
- H57의 ‘슬퍼하는 사람’은 형용사의 명사적 쓰임이며 애 1:4의 길은 의인화다. H60의 애도 기간·상복·초상집은 문맥과 구문에서 생기는 표현이므로 별도 의미를 기계적으로 추가하지 않는다. [BDB H57](https://biblehub.com/hebrew/57.htm), [BDB H60](https://biblehub.com/hebrew/60.htm)
- H61의 대표 기능 배정은 참으로 4회·그러나 7회지만 창 17:19·왕상 1:43·단 10:21의 3회에는 두 기능이 겹친다. 기존 ‘확실히, 진실로’만으로는 역접을 충분히 담지 못한다. H179는 대상 27:30에서 인물 식별이 분명하며 이름 뜻과 직무를 구별한다.
- Strong은 H57·H60에 명시적인 `from H56`을 제시한다. H61·H179에는 추정 qualifier가 있어 확정 파생 관계 두 건과 구별한다. 인명·부사 의미의 충분성과 어원의 확실성은 서로 다른 판단이다.

## 채택하지 않은 주요 대안

- **‘애통하다(哀痛하다) / 애통하는(哀痛하는) / 애통(哀痛)’으로 통일**: 의미상 가능한 대안이지만 기존 ‘슬퍼하다/슬퍼함’과 ‘애도’ 조합도 실제 범위를 충분히 담는다. 기존 의미 범위를 유지하고 한자와 비고를 보완했다.
- **H56 ‘마르다’를 별도 meaning으로 확정**: 단순 번역 차이를 넘어 실제 경쟁 어근 분석이다. 자연물의 의인화, 물리적 결과와 병행 표현을 모두 고려하면 해당 구절들의 어근 분리에는 견해 차이가 남는다. 오답으로 폐기하지 않고 비고에 보존했다.
- **‘애도’만 사용하거나 ‘울다·장례·상복·초상집’을 독립 sense로 추가**: 사별로 범위를 좁히거나 구문·문맥의 뜻을 어휘 자체에 과잉 부여할 수 있어 채택하지 않았다.
- **H61 확언 의미만 유지, ‘아니/오직’을 각각 추가**: 확언만으로 역접 용례를 설명할 수 없고, 정정 응답과 단 10:21의 개별 번역을 별도 sense로 늘릴 필요는 없다.
- **H179를 ‘슬퍼하는 사람’ 또는 ‘낙타 모는 사람’으로 교체, 추정 어원 관계 생성**: 불확실한 이름 뜻을 인명 식별 대신 고정하지 않는다. 직무와 어원 불확실성은 비고에 보존하고 추정 관계는 생성하지 않는다.

## 남은 불확실성 및 재검토 조건

H56의 별도 마름 어근과 겔 31:15의 사역형·절 구성, H60 사 61:3의 애도 복장 해석, H61 세 구절의 기능 중첩, H179의 어원은 미확정이다. 기본 meaning 승인을 막는 word identity conflict로 확인되지 않아 신규 hold를 만들지 않았다. H179 원자료 언어 `x-pn`의 unresolved 상태도 인명 식별과 구별하여 유지한다.

삼하 OSHB 19:2·19:3과 KJV 19:1·19:2의 번호 차이, 시 35:14/LXX 34:14와 렘 31:13/LXX 38:13의 개별 비교를 전체 versification authority로 일반화하지 않는다. 다른 참고자료의 전체 profile은 unverified이며 LXX의 라이선스·정렬 provenance는 canonical authority로 승격하지 않는다.

전문 어휘·동족어·본문 연구가 H56의 어근 분리나 H61·H179의 파생을 실질적으로 판별할 때 재검토한다. 번역어·문체 선호, Strong 번호의 인접성이나 source-reference 방향만으로 자동 의미 변경·관계 생성·hold를 하지 않는다. 추정 관계를 `hypothesized`로 기록하려면 별도 사용자 결정이 필요하다.
