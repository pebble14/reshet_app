# H0022·H1841·G1158 분석적 합성 표기 결정

- 상태: `active`
- 기록 성격: 승인 시점 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-09-13
- 대상: H0022, H1841, G1158 meaning 각 한 행
- 정책 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 승인 manifest: [h0022_h1841_g1158_analytic_name_notation_approved_content_slice.json](../../tool/data_provenance/manifests/h0022_h1841_g1158_analytic_name_notation_approved_content_slice.json)
- DB 적용: 2026-09-13, history group `1789265084936111`
- 적용 전 snapshot: `data/backups/approved_content_batch/20260913T020444075006Z/snapshot.db`
- 선행 결정: [H22 클러스터 결정](h22_cluster_approved_content_slice.md), [H27 클러스터 결정](h27_cluster_approved_content_slice.md)

## 최종 결정

| Strong | 변경 전 | 최종 meaning |
| --- | --- | --- |
| H0022 | `아비엘 (인)` | `아비엘·아비-엘 (인)` |
| H1841 | `다니엘 (인)` | `다니엘·다니-엘 (인)` |
| G1158 | `다니엘 (인)` | `다니엘·다니-엘 (인)` |

세 어휘의 word note, expression·transliteration, relation과 hold는 변경하지 않는다. 이 결정은 기존 인명 식별과 lexical sense를 바꾸지 않고, 한국어 성경 관용 표기 뒤에 원천 이름의 합성 경계를 보여 주는 분석 표기를 병기한다.

## 핵심 판단 근거

H0022는 선행 H22 결정에서 H0001과 H0410이 직접 구성 요소로 확인되었고, 두 관계가 `morphological / compound / asserted`로 승인되었다. 따라서 `아비-엘`은 충분한 형태 분석 근거가 있는 분석 표기이며, 관용 표기 `아비엘`과 같은 lexical sense 안에서 가운데점으로 병기한다.

H1841은 H1840과 같은 다니엘 이름의 언어별 형태다. H1840에는 H1835와 H0410의 합성 구조가 승인되어 있고 H1841과의 `root_shared / asserted` 관계도 승인되어 있으므로, 같은 원천 이름의 `다니-엘` 경계를 H1841의 분석 표기에 보존할 수 있다.

G1158 `Δανιήλ`은 H1840에서 전승된 이름의 헬라어 음역이며 두 항목의 관계는 `borrowed_from / asserted`로 승인되어 있다. G1158의 `다니-엘`은 헬라어 내부의 새 형태소 분석이 아니라 음역이 가리키는 히브리어·아람어 원천 이름의 합성 경계를 보여 준다. 이 구분은 [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)의 전승 고유명사 원칙을 따른다.

## 채택하지 않은 주요 대안

- 세 현행 meaning 유지: 인명 식별에는 충분하지만 이미 뒷받침된 원천 이름의 합성 구조를 meaning에서 확인할 수 없어 채택하지 않았다.
- 관용 표기를 분석 표기로 대체: 한국어 성경의 실제 이름을 그대로 식별하는 층위를 잃으므로 채택하지 않았다.
- H0022만 변경: 직접 compound relation의 유무만을 기계적 기준으로 삼으면 같은 원천 이름의 언어별 형태와 음역에 적용하는 정책을 일관되게 반영하지 못한다.
- G1158을 헬라어 형태소로 분석: `Δανιήλ`은 원천 이름의 음역이므로 그러한 주장을 하지 않는다.
- 이름 풀이를 별도 meaning으로 추가: 이번 범위는 동일 인명의 분석 표기이며 어원 설명을 독립 lexical sense로 만들지 않는다.

## 남은 불확실성 및 재검토 조건

H1841과 G1158의 분석 표기는 현재 표제어 언어에서 독립적으로 생산된 합성 구조를 주장하지 않는다. 원천 이름과의 동일성 또는 기존 `root_shared`·`borrowed_from` 관계를 실질적으로 바꾸는 provenance가 검증된 자료가 확보되면 해당 분석 표기와 관계를 함께 재검토할 수 있다.

## 적용 및 마감 검증

- Dry-run은 meaning replacement 3건을 임시 DB에 적용한 뒤 history 3행과 함께 실제 undo했고, 원본 work DB SHA-256 `71b348a889c5de2a2ddbeae5e235bdf38d28a7349de458a0d7f1cd0413fbc21f`을 전후 동일하게 유지했다.
- Live apply 뒤 work DB SHA-256은 `75a44ef1098742cca6cfd91194931cd1fc063c040f7219e82ed635855d711171`이며 seed DB SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다.
- 적용 전 snapshot SHA-256은 `64d2fbe6b3782db9a4b7248bd84deeaa5c3d10651a21dfb4356ae0221a2347b3`이다. Snapshot과 현재 DB의 12개 사용자 테이블을 양방향 `EXCEPT` 대조한 결과 승인된 `word_meaning_set` 교체 전후 각 3행과 `CHANGE_HISTORY`의 active 3행 외 차이는 없다.
- Work·snapshot integrity check는 `ok`, foreign key 위반은 0이고 work·seed SQLite sidecar는 없다. 적용 manifest와 backup manifest SHA-256은 모두 `e42778640c9252d46ff3ada57d2a6fa295196eb6b4874daeb66f73d48b91d7da`이다.
- 기존 표기정비 manifest를 명시적으로 포함한 semantic progress는 canonical Strong 14,298건, `explicit_approved=94`, `hold=2`, `unapproved=14,202`, anomaly 113건이다. 세 대상은 새 manifest를 유일한 active authority로 하는 `explicit_approved / approved`이며 현재 meaning과 exact 일치한다.
- `../reshet_research_output/semantic_progress` 산출물 SHA-256은 JSON `4979ff2a92f69064a3425aa689747c6fbb571bb7d7c79547b0c52248a1960e97`, CSV `3e108a63f15cbe72cbe86cc91941c2ec73144bbf12fd962e7031a5effbda4173`, Markdown `2f351916049c66c93fb4308ed7fbb57e5b5d0d3dc81dc06c344f927d97a6af55`이다.
- Production Dart·schema·seed·UI/UX는 변경하지 않았다. Applicator 구현과 테스트는 직전 승인 slice 이후 변경되지 않았고, 이번에는 exact manifest dry-run·live apply·snapshot diff로 변경 3건을 검증했으므로 applicator 테스트를 반복 실행하지 않았다. 사용자 UI 수동 테스트는 N/A다.
