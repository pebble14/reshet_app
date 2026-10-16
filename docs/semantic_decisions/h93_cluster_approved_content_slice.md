# H93 호두 의미와 동산 문맥 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-16 (Asia/Seoul)
- 대상: H0093 (`H0093_0000`)
- 승인 manifest: [h93_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h93_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 신규 hold 없음·기존 6건 유지
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 로컬 연구 산출물: `C:/Users/kkiih/Documents/Workspace/FlutterWorkspace/reshet_research_output/H0093_cluster_20261016_1ba1c63b/`, 최신 판단은 `01_nut_walnut_followup.md`
- 승인 원문·byte 백업·독립 검증: `data/backups/approved_content_batch/h93_approval_20261016/`
- 공식 snapshot·result·manifest 사본: `data/backups/approved_content_batch/20261016T042716757685Z/`

## 최종 결정

사용자는 일반 견과인지 특정 호두인지 추가 확인한 뒤 최신 `호두` 추천을 채택하고 DB·문서·필요한 파일 반영, 이상 없는 경우 Git 작업과 이번 작업 브랜치 정리까지 승인했다. 초기 `견과(堅果)` 우선 추천은 최종 승인값이 아니다.

| seq | 최종 meaning |
| --- | --- |
| 1 | 호두 |

기존 한 행 `견과, 호도`를 위 한 행으로 교체하고, NULL 비고에 다음 전문을 적용했다.

> 아가 6:11에서는 단수형이 집합적으로 쓰여 호두나무들이 있는 동산을 나타낸다. 전문 연구에서는 보통 호두(Juglans regia)로 식별하지만 성경 용례가 한 번뿐이므로 수종 식별의 불확실성은 남는다. Strong의 페르시아어 기원 설명은 추정이다.

H0093 관련 relation은 기존 0건이며 생성·교체·삭제하지 않는다. Category/type/status/direction은 N/A다. 신규 word hold는 없고 기존 hold 6건은 유지한다. 원문 `אֱגוֹז`, 음역 `에고즈`, 발음·언어·Strong 번호·schema·seed·canonical source·local reference는 보존한다. 기존 active H93 semantic 승인과 충돌하지 않아 supersession은 없다.

## 핵심 판단 근거

- Canonical lexical source는 H93을 남성명사로 분류하고 영어 gloss `a nut`를 제시한다. OSHB의 유일한 canonical 용례 아가 6:11은 남성 단수 절대형이 동산의 연계 구문에 쓰인 사례다. 1 token·1절 전체를 검토했으며, 그 열매를 맺는 나무들이 있는 동산을 가리키는 집합적 사용으로 이해한다.
- 사용자는 영어 nut가 일반 견과의 범위를 실제로 입증하는지, 특정 호두를 가리키는지 구분할 필요를 제기했다. 추가로 직접 확인한 Lambert Isebaert의 BABELAO 10–11 (2022), 64–65쪽 연구는 표제어를 보통호두나무(Juglans regia)의 열매로 식별한다. 이 구체적인 어휘 식별을 반영해 추천을 견과에서 호두로 수정했고 사용자가 최신 추천을 채택했다.
- Strong·BDB의 영어 gloss가 넓다는 사실만으로 원어도 모든 견과를 포괄한다고 확정하지 않는다. 호두 식별에는 구체적인 전문 근거가 있지만, NET 주석의 추정 표현과 성경 1회 출현이라는 한계는 비고에 남겼다.
- LXX의 해당 표면형을 수동 비교한 LSJ καρύα 항목은 여러 종류의 견과나무에 쓰일 수 있다. 따라서 LXX를 수종 확정의 단독 근거로 사용하지 않으며, Greek 번역어의 범위를 Hebrew H93의 독립 sense로 자동 승격하지 않는다.
- 한국어는 표준 표기인 `호두`를 사용한다. 참고 번역 원문에 있는 `호도`는 raw evidence에서 보존하고, 표현·음역·발음을 별도 meaning으로 추가하지 않는다.

Canonical lexical authority는 [고정 HebrewStrong 원문](https://raw.githubusercontent.com/openscriptures/HebrewLexicon/21c9add13bc727d3a951361778e97e3ff7afd1ce/HebrewStrong.xml)과 현행 manifest다. [Isebaert 연구 원문](https://ojs.uclouvain.be/index.php/babelao/article/download/64843/61203/120373), [NET 아가 6:11 주석](https://bible.org/sites/bible.org/resources/download/netbible/ondemand/bybook/sos.pdf), [LSJ καρύα](https://logeion.uchicago.edu/καρύα)는 semantic 판단을 돕는 reference로 구분한다. 외부 연구 PDF를 canonical source로 도입하거나 재배포 데이터로 import하지 않았다.

## 채택하지 않은 주요 대안

- **`견과(堅果)` 단일 의미**: 초기 추천이었고 Strong gloss를 포괄하지만, 영어 풀이의 일반성만으로 원어의 의미 범위를 넓게 확정할 수 없다. 추가 전문 연구의 구체적인 호두 식별에 따라 대표 meaning은 호두로 선택했다. 일반 nut 풀이의 존재는 판단 근거와 비고의 수종 불확실성 설명으로 보존한다.
- **`호두나무`를 독립 meaning으로 추가**: 아가의 동산 문맥에 적절한 구체 표현이지만 열매 이름과 그 나무의 지시 관계를 한 용례에서 별도 sense로 늘릴 필요성이 부족하다. 동산의 나무 지시는 비고에 둔다.
- **`견과` / `호두` / `호두나무` 복수 sense 또는 현행 `견과, 호도` 유지**: 실제 독립 의미 차이보다 일반 영어 gloss·수종 식별·문맥상 지시·한국어 표기 차이를 중복 저장하게 된다. 최신 선택은 호두 한 행이다.
- **페르시아어 차용 relation 또는 word hold**: canonical source의 기원 설명은 추정이고 구체적인 source-language word_id가 없다. 전문 연구의 어원 분석을 자동 확정 관계로 만들지 않는다. 수종·어원 한계는 비고로 보존할 수 있어 어휘 전체 hold는 채택하지 않았다.

## 남은 불확실성 및 재검토 조건

성경 용례가 한 번뿐이므로 호두 수종 식별을 본문 자체만으로 절대적으로 확정하거나 모든 시대·방언에서 호두만을 뜻했다고 배타적으로 주장하지 않는다. NET은 수종을 추정으로 표현하며, LXX의 일반적인 견과나무 표현도 수종을 단독 확정하지 못한다. Strong의 페르시아어 기원 qualifier는 보존한다. 보충 논문이 인용하는 DCH·Noonan·Gindin 등 문헌을 각각 직접 열람한 것으로 보고하지 않는다.

검증된 전문 어휘·식물 식별 자료나 직접 관련 고대 용례가 다른 수종 또는 독립적인 일반 견과 의미를 실질적으로 입증할 때 사용자 판단으로 재검토한다. 같은 영어 nut gloss, 번역 다수결, 현대 용법만으로 의미를 자동 확대하거나 hold를 생성하지 않는다. LXX local 자료의 upstream provenance·license 미검증과 human-reference 경계를 유지한다.

공식 dry-run의 사본 적용·실제 undo·원본 불변과 live apply가 성공했다. 독립 SQL 58조회로 전체 13개 테이블·DDL·byte 백업·공식 snapshot을 대조했고 승인 의미·비고 및 history 6097–6098(group `1792124837912598`), 해당 history sequence 외 차이가 없다. Work·seed·snapshot·byte 백업 integrity ok·FK0·sidecar0이며 seed는 불변이다. 기존 applicator 테스트 31건이 통과했다. 표준 progress에서 H0093만 승인으로 전환돼 승인290→291·미승인14,002→14,001이며 hold6·anomaly113은 유지됐다. 원본 연구 14개 파일을 보존하고 실제 적용 결과를 외부 `00_applied_content.md/json`에 별도로 기록한다. 앱/UI 코드 변경이 없어 UI 수동 테스트·전체 앱 빌드는 N/A다.
