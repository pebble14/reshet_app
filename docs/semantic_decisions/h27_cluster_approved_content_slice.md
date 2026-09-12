# H27 클러스터 결정

- 상태: `active`
- 기록 성격: 승인 시점 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-09-12
- 대상: H0027에서 출발한 CORE 27개; 의미 승인 25개, H1777·H4092 hold
- 승인 manifest: [h27_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h27_cluster_approved_content_slice.json)
- hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json)
- 로컬 연구 산출물: `H27_cluster_20260911_427a6c2f`
- 승인 보완 산출물: `H27_cluster_20260911_427a6c2f/00_approved_refinement.md`
- DB 적용: 2026-09-12, history group `1789142925366297`

## 마감 검증

- semantic progress: canonical 14,298건, `explicit_approved` 93건, `hold` 3건, `unapproved` 14,202건, anomaly 113건
- snapshot identity: `a6232d92ffcf18c37ffac44e0f4c66d03379e3de45374da40a8a506f6a6dbe63`
- 산출물 SHA-256: JSON `6f32523c1c49a8886404d1910fb36493aa90e28ac2b0e13520273bf5a7c19cfc`, CSV `a1f63c8c8daeca1a5e8a0cd1f8f7953e62c7f3ee5062fb9a915278cbe4a91a69`, Markdown `3b1332d3a18922585231d843476d1d75b2715e107f13f2ca67e9063e34b7e96c`
- manifest SHA-256: `4839777d47bf5788eab2e7f6346f1f6f07cdcd75f4fb5756054120819004ffa0`
- DB SHA-256: work `5b04be523501015aa6bafbec6893f8d4b6de1abccb4d22cac010ade6049cfe21`, seed `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`
- 적용량: meaning replacement 24건, current meaning approval 1건, word note replacement 14건, relation create 20건, relation replacement 7건
- live history: word update 38행, relation create 20행, relation update 7행, 합계 65행; 모두 active이며 자동 restore 없음

## 최종 결정

다음 25개 Strong의 ordered meaning projection과 manifest에 명시한 비고를 승인했다.

| Strong | 최종 meaning |
| --- | --- |
| H0027 | `아비단·아비-단 (인)` |
| H1778 | `재판하다(裁判하다)` |
| H1779 | `심판(審判)` / `송사(訟事)` / `다툼` |
| H1780 | `심판(審判)` / `공의(公義)` |
| H1781 | `재판관(裁判官)` |
| H1782 | `재판관(裁判官)` |
| H1783 | `디나 (인)` |
| H1835 | `단` |
| H1839 | `단 자손(子孫)` |
| H1840 | `다니엘·다니-엘 (인)` |
| H1841 | `다니엘 (인)` |
| G1158 | `다니엘 (인)` |
| H1842 | `다냐안·단-야안 (지)` |
| H2806 | `하스밧다나·하쉬밧다나 (인)` |
| H4066 | `다툼` |
| H4079 | `다툼` |
| H4080 | `미디안·미드얀` |
| H4081 | `밋딘 (지)` |
| H4082 | `지방(地方)` |
| H4083 | `지방(地方)` |
| H4084 | `미디안 사람` |
| H4090 | `다툼` |
| H4091 | `므단·메단 (인)` |
| G3099 | `미디안` |
| H4265 | `마하네단·마하네-단 (지)` |

고유명사의 가운데점은 하나의 lexical sense 안에서 한국어 성경의 관용 표기와 원문 또는 구성 분석에 가까운 표기를 함께 보존한다. H0027·H1840·H1842의 하이픈은 분석적 구성 경계이고 실제 히브리어 마케프를 뜻하지 않는다. H4265의 하이픈은 본문의 실제 마케프와 H4264·H1835의 구성 경계를 함께 반영한다. H2806은 어원과 내부 경계가 불확실하므로 하이픈을 두지 않았다.

한자 병기는 한자어 전체에 붙이는 기존 형식을 적용했다. 히브리어 고유명사에는 한자를 만들지 않았고, 고유명사에서 파생된 사람 표기는 필요한 한자만 `자손(子孫)`에 병기했다.

다음 27개 relation을 승인했다.

- `compound / asserted`: H0001→H0027, H1777→H0027, H1835→H1840, H1835→H1842, H1835→H4265, H0410→H1840, H4264→H4265
- `derived / asserted`: H1777→H1779, H1777→H1781, H1777→H1835, H1777→H4066, H1777→H4082, H1779→H1783, H1835→H1839, H4080→H4084
- `root_shared / asserted`: H1777↔H1778, H1779↔H1780, H1781↔H1782, H4082↔H4083, H1840↔H1841
- `variant / asserted`: H4066↔H4079, H4066↔H4090
- `borrowed_from / asserted`: H1840→G1158, H4080→G3099
- `derived / hypothesized`: H4079→H4080, H4090→H4091
- `variant / hypothesized`: H4080↔H4081

H1777과 H4092는 meaning·note를 변경하지 않고 hold로 기록했다. H1777의 최종 후보는 `심판하다(審判하다) / 변호하다(辯護하다) / 다투다 / 다스리다`이지만 창세기 6:3의 יָדוֹן 분석을 확정하지 않았다. H4092는 유일한 형태가 므단 계열로 보이는 반면 canonical 사전과 번역 전통은 미디안 사람으로 해석하므로 대표 표기와 집단 식별을 보류했다.

## 핵심 판단 근거

H1777은 불리한 판결을 내리는 행위에 한정되지 않는다. 창 30:6, 시 54:3과 같은 문맥에서는 정당함을 인정하거나 권리를 회복하는 심판 기능이 드러나며, 렘 30:13과 같은 송사 문맥에서는 당사자의 사정을 맡아 옹호하는 기능이 나타난다. 따라서 최종 후보에서 `심판하다`와 `변호하다`를 구분했다. 다만 창 6:3의 유일한 형태는 히브리어 분석과 고대 번역이 하나로 수렴하지 않아 단어 전체를 승인하기보다 hold가 정확하다.

H4080 מִדְיָן의 가운데 슈와는 독립된 `에` 모음이 아니므로 원문 근사 표기로 `미드얀`을 선택했다. H4091 מְדָן의 어두 모음성 슈와는 고대 발음과 한국어 대응이 하나로 고정되지 않으므로 관용 표기 `므단`과 Strong식 일반 발음에 가까운 `메단`을 함께 보존했다.

H2806은 Strong이 H2803과 H1777의 합성으로 풀이하지만 BDB는 어원을 불확실하게 본다. 따라서 인명 식별과 두 한국어 표기는 승인하면서 두 구성 relation과 강제 하이픈은 제외했다. H1842의 첫 `단` 요소와 H4265의 `마하네-단` 구성은 본문 형태와 canonical 분석이 충분히 뒷받침하므로 asserted compound로 승인했다.

관계 저장은 canonical pair 순서와 semantic 방향을 구분했다. 역방향 저장이 필요한 H1777→H0027, H1840→G1158, H4080→G3099는 canonical pair에 `w2_to_w1`을 사용했다. 양방향 관계는 `undirected`로 저장했다. Strong의 `the same as`, `a variation for`만으로 역사적 어원을 확정하기 어려운 세 관계는 관계 자체를 버리지 않고 `hypothesized`로 보존했다.

## 채택하지 않은 주요 대안

- H1777의 `억울함을 풀어주다`를 독립 meaning으로 추가: 이는 유리한 심판이나 변호의 문맥적 결과이므로 별도 lexical sense로 늘리지 않았다.
- H1777의 현행 `변론하다`를 그대로 승인: 옹호와 법적 권리 보호 기능을 더 분명히 나타내는 후보 `변호하다(辯護하다)`로 보완했지만 창 6:3 때문에 최종 적용하지 않았다.
- H4080 `미데얀`: 가운데 슈와를 독립 모음으로 읽는 인상을 주므로 채택하지 않았다.
- H4091에서 `므단` 또는 `메단` 하나만 사용: 서로 다른 한국어 전통과 슈와의 불확실성을 과도하게 단일화하므로 병기했다.
- H2806을 `하쉬밧-다나` 등으로 분절: 내부 구성 경계가 확실하지 않아 채택하지 않았다.
- H1777→H2806과 H2803→H2806: BDB의 어원 불확실성 때문에 생성하지 않았다.
- H3282→H1842: source의 `apparently` 한정을 넘어 asserted compound로 만들지 않았다.
- H4084↔H4092: H4092의 집단 식별 문제가 해결되지 않아 생성하지 않았다.
- 기존 legacy H1777–H1840(id 3647), H4066–H4080(id 4390): 직접 관계로 구체화할 근거가 부족해 현행 상태를 유지했다.

## 남은 불확실성 및 재검토 조건

H1777은 창세기 6:3의 형태·문맥·고대 번역을 함께 설명하는 새로운 원자료 근거가 확보되거나, 사용자가 불확실성을 비고에 남긴 채 네 의미 후보를 승인할 때 재검토한다. H4092는 므단과 미디안 집단의 관계를 판별할 본문비평·역사언어학 근거가 확보되거나 대표 표기 정책이 확정될 때 재검토한다.

`hypothesized` 관계 H4079→H4080, H4090→H4091, H4080↔H4081은 새로운 어원 자료가 나오면 status나 relation type을 재검토할 수 있다. H2806의 두 생성 보류 관계도 신뢰할 만한 어원 연구가 Strong의 합성 풀이를 지지할 때 다시 검토한다. H0001과 H0410은 생산적인 이름 요소이므로 이번 결정은 H27 CORE에 직접 필요한 관계만 승인하며 두 허브 전체의 semantic closure를 주장하지 않는다.
