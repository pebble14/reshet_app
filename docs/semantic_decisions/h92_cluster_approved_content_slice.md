# H92 묶음·결속·무리·건축 용법 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-16 (Asia/Seoul)
- 대상: H0092 (`H0092_0000`)
- 승인 manifest: [h92_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h92_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 새 hold 없음·기존 6건 유지
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 로컬 연구 산출물: `C:/Users/kkiih/Documents/Workspace/FlutterWorkspace/reshet_research_output/H0092_cluster_20261016_18bdd883/`
- 승인 원문·적용 전 byte 백업·검증: `data/backups/approved_content_batch/h92_approval_20261016/`
- 공식 snapshot·result·manifest 사본: `data/backups/approved_content_batch/20261016T025722639484Z/`

## 최종 결정

사용자는 네 meaning을 유지하고 아모스 용례의 불확실성을 비고에 명시하는 마지막 추천안을 채택했다. DB·문서·필요한 파일을 반영하고 검증 성공 후 Git 작업을 완료한 다음 이번 작업 브랜치까지 정리하도록 승인했다.

현재 한 행의 `띠, 무리, 묶음`을 다음 순서의 네 행으로 교체했다.

| seq | 최종 meaning |
| --- | --- |
| 1 | 묶음 |
| 2 | 묶는 줄 |
| 3 | 무리 |
| 4 | 둥근 천장(天障) |

word note는 NULL에서 다음 전문으로 교체했다. 앞선 연구 산출물에 있던 최초 제안 비고 대신, 사용자가 마지막으로 승인한 문장을 그대로 적용했다.

> 묶음과 무리는 ‘한데 묶이거나 모인 것’이라는 개념으로 연결되며, 묶는 줄은 그 결속을 이루는 수단이다. 사 58:6의 멍에 줄은 압제를 푸는 비유에 쓰인다. 암 9:6의 ‘둥근 천장’은 단단히 결합된 구조물을 하늘의 천장으로 이해하는 전통적 해석이다. 다만 이 구절의 정확한 지시 대상은 불확실하며, 기초를 받치는 구조라는 해석도 있다. KJV는 ‘무리’(난외: ‘묶음’), LXX는 ‘그의 약속’으로 옮긴다.

H0092 관련 relation은 기존 0건이며 생성·교체·삭제하지 않는다. 별도 category/type/status/direction은 N/A다. 새 hold를 만들지 않고 기존 hold 6건도 유지한다. 원문 `אֲגֻדָּה`, 음역 `아굳다`, 발음·언어·Strong 번호·schema·seed·canonical source·로컬 reference는 그대로다. 기존 active semantic 승인과 충돌하지 않아 supersession은 없다.

## 핵심 판단 근거

- 단일-node lexical cluster의 closure가 완료됐으며 frontier는 0이다. Canonical Strong entry와 OSHB 4회·4절 전량, HebGrkKo exact row 1행, 로컬 verse reference 5종 각각 4절, LXX 명시적 4절을 확인했다. 적용 전 상세 evidence와 machine state는 원본 연구 폴더에 보존한다.
- 출 12:22의 우슬초는 한데 묶은 물건, 사 58:6의 멍에 줄은 묶는 수단, 삼하 2:25는 함께 모인 사람들의 집단이다. 사용자는 묶음·묶는 줄·무리를 결속이라는 공통 개념으로 이해할 수 있다는 점을 중요하게 검토했다. 세 표현은 물건·수단·사람의 지시 대상 차이를 보존한다. 어느 의미가 역사적으로 먼저 생겼는지까지 결정한 것은 아니다.
- 아모스 9:6의 건축 용법은 Strong의 `arch` 및 한국어 번역 전통과 연결된다. 결합된 구조물을 하늘의 천장으로 이해하는 전통적 해석을 대표 meaning으로 채택하되, ‘둥근’이라는 구체적 모양과 정확한 지시 대상까지 단어 자체에서 확정됐다고 보지 않는다. 사용자와 이 연결의 근거 강도를 검토한 뒤 마지막 비고에 불확실성을 명시했다.
- Canonical Strong은 `feminine passive participle of an unused root (meaning to bind)`로 설명한다. 본문 품사는 여성명사이며 해당 미사용 어근에 별도 Strong 번호가 없어 관계 pair를 만들지 않는다. 번호 인접성이나 자동 LXX 대응으로 관계를 보충하지 않는다.
- 한자 표기는 `천장(天障)`에 적용했다. 기존 음역을 meaning으로 추가하거나 발음·표현을 다시 정비하지 않는다.

Canonical lexical authority는 [Open Scriptures 고정 Strong 원문](https://raw.githubusercontent.com/openscriptures/HebrewLexicon/21c9add13bc727d3a951361778e97e3ff7afd1ce/HebrewStrong.xml)과 현행 manifest다. [ISBE의 구조 결속 설명](https://www.biblestudytools.com/dictionary/earth-vault-of-the/)과 [NET 아모스 9:6 번역 주석](https://classic.net.bible.org/passage.php?passage=Amo+9%3A6)은 보충 reference로 사용했다. 이 참고자료를 canonical authority로 승격하지 않는다.

## 채택하지 않은 주요 대안

- **현재 `띠, 무리, 묶음` 유지**: 앞의 세 용법을 부분적으로 담지만 여러 뜻이 한 행에 섞여 있고 아모스의 건축 해석을 드러내지 못한다. `띠`는 멍에를 묶는 수단을 분명히 하는 `묶는 줄`로 정리했다.
- **`묶음` 한 의미로 통합**: 결속이라는 공통 개념은 설명에 유용하지만 묶인 물건·묶는 수단·사람의 집단·건축 구조를 한 한국어 뜻으로 자연스럽게 포괄하기 어렵다.
- **네 번째를 `궁창(穹蒼)` 또는 기초 지지 구조로 선택**: 궁창은 한국어 번역 전통의 유효한 표현이지만, 이번에는 전통적 건축 해석을 드러내는 `둥근 천장(天障)`을 채택했다. 기초를 받치는 구조는 여전히 가능한 대안으로 비고에 남겼다.
- **KJV의 무리·묶음 또는 LXX의 약속을 아모스의 확정 풀이로 채택**: 실제 번역 전승의 차이를 비고에 보존하되 그중 하나로 단정하거나 ‘약속’을 새 일반 meaning으로 추가하지 않았다.
- **별도 매듭·군대·압제 meaning 추가 또는 단어 전체 hold**: 현재 용례에서 추가 독립 sense의 필요성이 충분하지 않다. 앞의 세 뜻은 명확하므로 아모스 한 용례의 불확실성은 비고에 한정한다.

## 남은 불확실성 및 재검토 조건

아모스의 명사가 둥근 천장인지 기초를 받치는 구조인지, KJV와 LXX의 다른 풀이가 어떤 본문·어휘 이해에서 나왔는지는 확정하지 않았다. 네 번째 meaning은 불확실성을 포함한 대표 해석의 승인이다. Canonical 4건 모두 분석했지만 아모스 1건의 정확한 지시 대상까지 해결됐다는 뜻은 아니다. LXX의 upstream provenance·license 미검증 및 human-reference 경계도 유지한다.

검증된 전문 사전·본문비평 자료·관련 고대 용례가 지시 대상이나 전승 차이를 실질적으로 판별할 때 사용자 판단으로 재검토한다. 같은 번역본의 반복 비교, 번역 다수결, 결속이라는 공통 이미지만으로 의미를 일괄 통합하거나 자동으로 다시 hold하지 않는다.

공식 dry-run의 사본 적용·undo·원본 불변과 live apply가 성공했다. History group `1792119443828097`의 ID6095–6096은 active word update 2행이며 undone0이다. 독립 SQL 53조회·60검증으로 전체 13개 테이블·DDL·byte 백업·공식 snapshot을 대조했고, 승인한 meaning·비고와 history 2행 및 해당 sequence 외 차이가 없다. Work·seed·snapshot·byte 백업 integrity `ok`, FK 위반0, sidecar0이며 seed는 불변이다. 기존 applicator Flutter 테스트 31건이 통과했다.

공식 표준 progress JSON·CSV·Markdown을 함께 갱신했다. H0092만 explicit_approved로 전환되어 승인289→290·미승인14,003→14,002이며 hold6·anomaly113은 유지됐다. 전체 행·CSV·Markdown과 보호 입력의 교차검증 37건이 통과했다. 원본 연구 16개 파일을 보존하고 실제 승인·적용 결과는 외부 `00_applied_content.md/json`에 별도로 기록한다. 앱/UI 코드 변경이 없어 사용자 UI 수동 테스트·전체 앱 빌드는 N/A다.
