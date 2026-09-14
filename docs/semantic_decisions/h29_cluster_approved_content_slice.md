# H29 클러스터 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-09-14
- 대상: H0029·G0007; H0001·H3050은 구성 관계 문맥
- 승인 manifest: [h29_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h29_cluster_approved_content_slice.json)
- 로컬 연구 산출물: `H29_cluster_20260914_db8d6a6d`
- DB 적용: 2026-09-14, history group `1789343839802287`

## 최종 결정

- H0029 meaning: `아비야·아비-야 (인)` 한 행
- H0029 비고:

  > אֲבִיָּה와 연장형 אֲבִיָּהוּ는 여러 남녀 인물과 제사장 반열·가문 이름에 쓰인다. ‘아비야’는 한국어 성경의 관용 표기이고 ‘아비-야’는 H0001과 H3050의 구성 경계를 드러낸 분석 표기이며, 하이픈은 실제 히브리어 마케프를 뜻하지 않는다. Strong은 이름을 ‘야의 아버지 또는 예배자’ 방향으로, reference-only HebGrkKo는 ‘여호와는 아버지이시다’로 풀이하므로 어원 풀이를 별도 meaning으로 확정하지 않는다. 대하 29:1의 히스기야 어머니는 왕하 18:2의 아비(H0021)와 같은 인물이지만 직접 canonical lexical edge가 없어 별도 relation은 두지 않는다.

- G0007 meaning: `아비야·아비-야 (인)` 한 행
- G0007 비고:

  > Ἀβιά는 H0029 이름의 헬라어 음역이다. 마 1:7에서는 유다 왕 아비야, 눅 1:5에서는 아비야 제사장 반열을 가리킨다. ‘아비야’는 한국어 성경의 관용 표기이고 ‘아비-야’는 원천 히브리어 이름의 H0001·H3050 구성 경계를 보존한 분석 표기이며, 헬라어 합성어 분석을 뜻하지 않는다.

- relation: H0001→H0029, H3050→H0029 각각 `morphological / compound / asserted`
- relation: H0029→G0007 `transliteration / direct_transliteration / asserted`
- H0021–H0029 relation: 생성하지 않음
- expression·transliteration·pronunciation: 변경하지 않음
- hold: H0029·G0007 모두 없음
- 승인 범위 밖: H0001·H3050의 독립 meaning과 H0021의 기존 결정은 변경하지 않음

## 핵심 판단 근거

H0029의 OSHB canonical 25개 token은 여러 남녀 인물과 제사장 반열·가문을 가리키지만 모두 같은 고유명사다. `אֲבִיָּה` 23건과 연장형 `אֲבִיָּהוּ` 2건도 별도 lexical sense를 만들지 않으며, 한국어 참조 자료의 대응 용례는 모두 `아비야`를 사용한다. 따라서 인명 표지 `(인)`을 유지하고 관용 표기와 분석 표기를 한 meaning의 가운데점 병기로 승인했다.

Canonical Strong은 H0029을 H0001과 H3050의 구성으로 직접 분석한다. G0007의 canonical source도 H0029에서 온 헬라어 음역임을 직접 명시한다. 따라서 기존 inferred 관계 세 행을 같은 canonical pair와 semantic 방향을 보존한 asserted 관계로 교체했다. H3050→H0029과 H0029→G0007은 canonical pair 정렬 때문에 각각 `H0029_0000, H3050_0000 / w2_to_w1`, `G0007_0000, H0029_0000 / w2_to_w1`로 저장한다.

G0007의 TAGNT canonical 3개 token은 마태복음의 유다 왕과 누가복음의 제사장 반열을 가리킨다. 반열 용례는 인명에서 유래한 표지이므로 별도 sense로 분리하지 않았다. `아비-야`의 하이픈은 원천 히브리어 H0001·H3050 구성 경계를 보존하며 헬라어 내부 morphology를 주장하지 않는다.

## 채택하지 않은 주요 대안

- `아비야 (인)`만 유지: 한국어 관용 표기는 보존하지만 canonical source가 직접 뒷받침하는 H0001·H3050 구성 경계를 확인할 수 없어 채택하지 않았다.
- H0029 meaning에 `아비야후` 추가: 연장형 두 건은 같은 유다 왕을 가리키고 한국어 전 용례가 `아비야`를 사용하므로 expression 증거로만 유지했다.
- Strong 또는 HebGrkKo의 어원 풀이를 별도 meaning으로 추가: 두 자료의 풀이가 일치하지 않고 이름의 지시 대상과 어원 설명을 한 projection에 혼합하므로 채택하지 않았다. 차이는 H0029 비고에 보존했다.
- G0007 meaning에 `아비아` 추가: 현재 expression transliteration에 이미 보존되어 있고 한국어 성경 용례는 `아비야`이므로 중복 추가하지 않았다.
- H0021–H0029 relation 생성: 대하 29:1과 왕하 18:2가 같은 인물을 가리키지만 직접 canonical lexical edge가 없어 생성하지 않았다.
- hold: 전 용례 coverage와 직접 구성·음역 근거가 충분해 두지 않았다.

## 남은 불확실성 및 재검토 조건

H0029의 canonical source language는 `x-pn / source_language_unresolved` 상태이며 Strong과 reference-only HebGrkKo의 어원 풀이가 다르다. OSHB와 한국어·KJV 자료 사이에는 세 절의 versification 차이가 있었지만 수동 대조로 모두 해소했다. Human-reference LXX는 canonical 25개 절 중 23개만 대응했고 provenance와 license가 검증되지 않아 보조 자료로만 사용했다. 이 항목들은 현재 한 sense와 세 직접 관계 결정을 뒤집지 않는다.

원천 이름의 H0001·H3050 구성을 부정하는 신뢰할 만한 히브리어 onomastic 자료, G0007의 H0029 기원을 부정하는 canonical 자료, 또는 동형이의 lexical sense를 입증하는 corpus evidence가 확보되면 meaning·비고·relation을 함께 재검토할 수 있다. 번역본 하나의 표기 차이, 간접 hub node 추가 발견, provenance가 불명확한 LXX 표면형만으로는 자동 재검토하지 않는다.

## 적용 및 마감 검증

- Dry-run은 meaning 2건, word note 2건, relation replacement 3건을 임시 DB에 적용한 뒤 실제 undo했으며 원본 work DB SHA-256 `db8d6a6d28801b2aff9b6bf5a6b76a0d29d58bd2b57761cea8571d9561158c69`을 전후 동일하게 유지했다.
- Live apply 뒤 work DB SHA-256은 `d2aa4704444a529429174fbe36609b1ac490954cd8a33690f20c03e731f7bc5f`이며 seed DB SHA-256 `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`은 불변이다.
- 적용 전 snapshot은 `data/backups/approved_content_batch/20260913T235718895850Z/snapshot.db`, SHA-256 `6d9fe59da9acefec8783fc4e022dc4166071eb0346dbc69fd5820a3b30e3695b`이다. Snapshot과 현재 DB의 사용자 테이블을 양방향 대조해 승인된 meaning·note·relation 교체와 active history 7행 외 차이가 없음을 확인했다.
- Work·seed·snapshot integrity check는 `ok`, foreign key 위반과 SQLite sidecar는 0이다.
- 최종 semantic progress에서 H0029와 G0007은 `explicit_approved / approved`이며 전체 집계는 `explicit_approved=79`, `hold=2`, `unapproved=14,217`, anomaly 113건이다.
- Targeted approved-content applicator 테스트 29건이 모두 통과했다. Production Dart·schema·seed·UI/UX는 변경하지 않았고 사용자 UI 수동 테스트는 N/A다.
