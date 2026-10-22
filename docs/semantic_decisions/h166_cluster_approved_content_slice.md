# H166 천막 클러스터 의미·비고·관계 승인 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-22 (Asia/Seoul)
- 대상: H0166–H0173 (CORE8); H0001·H1116은 관계 구성 요소만 포함
- 승인 manifest: [h166_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h166_cluster_approved_content_slice.json)
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 원본 연구: 로컬 `reshet_research_output/H166_cluster_20261022_8e796fbb/`
- 승인 원문·백업·SQL·검증: `data/backups/approved_content_batch/h166_approval_20261022/`
- 공식 snapshot·result·manifest 사본: `data/backups/approved_content_batch/20261022T031430304545Z/`

## 최종 결정

사용자는 최신 천막 대표어 제안과 나머지 추천을 승인하고 DB·문서 반영, 단계별 검증 후 커밋·push·fast-forward 병합 및 이번 로컬·원격 작업 브랜치 정리까지 승인했다. 각 어휘는 아래 단일 meaning을 둔다. 정확한 적용 전후 값과 비고 전문은 manifest를 따른다.

| Strong | 승인 meaning |
|---|---|
| H0166 | 빛나다 |
| H0167 | 천막(天幕)을 치고 살다 |
| H0168 | 천막(天幕) |
| H0169 | 오헬 (인) |
| H0170 | 오홀라 (인) |
| H0171 | 오홀리압·오홀리-아브 (인) |
| H0172 | 오홀리바 (인) |
| H0173 | 오홀리바마·오홀리-바마 (인) |

의미 교체4·기존 의미 명시 승인4·비고 교체6·관계 생성9를 적용한다. H0166·H0169의 비고 NULL을 유지한다. H0168은 일반 거주용·성소용 천막, 귀가 문맥과 비유·환유, 삿19:9의 실제 천막 가능성, 겔41:1의 해석 한계를 비고에 둔다. 전통 번역어 장막도 비고에서 연결한다. H0170–H0173의 이름 풀이와 인물·상징명 구별은 비고에 둔다.

관계9건은 모두 asserted이며 기존 관계 교체·삭제는 없다. Stored pair는 lexical canonical 순서이고 의미 방향은 direction_code로 표현한다.

| word_id_1 Strong | word_id_2 Strong | category/type | direction_code |
|---|---|---|---|
| H0166 | H0168 | morphological/derived | w1_to_w2 |
| H0167 | H0168 | morphological/derived | w2_to_w1 |
| H0168 | H0169 | etymological/root_shared | undirected |
| H0168 | H0170 | morphological/derived | w1_to_w2 |
| H0168 | H0171 | morphological/compound | w1_to_w2 |
| H0001 | H0171 | morphological/compound | w1_to_w2 |
| H0168 | H0172 | morphological/derived | w1_to_w2 |
| H0168 | H0173 | morphological/compound | w1_to_w2 |
| H0173 | H1116 | morphological/compound | w2_to_w1 |

H0001·H1116의 어휘 값은 변경하지 않는다. 신규 hold 없이 기존 ledger6건을 유지한다. 원어·음역·발음·언어·schema·seed·앱 코드는 변경하지 않는다.

## 핵심 판단 근거

H0168의 대표어는 현대 한국어의 접근성을 고려해 천막(天幕)으로 선택했다. 천막은 천으로만 만든 물건으로 제한할 필요가 없고 나무 골조·가죽 덮개를 포함하는 성소 구조도 표현할 수 있다. 천막의 천은 한자로 天이며, 재료가 혼합됐다는 사실만으로 장막을 유일한 번역어로 요구하지 않는다. 기존 성경의 장막과 연결은 비고로 보존한다.

삿19:9의 לְאֹהָלֶךָ는 네 천막으로라는 표현이다. 장인의 귀가 권유와 집이라는 번역만으로 실제 천막을 배제하거나 건축물 일반을 가리키는 별도 어휘 의미를 확정할 수 없다. 따라서 최초 추천의 거처 독립 meaning을 철회하고 천막 하나와 문맥 설명을 채택했다. 이 절이 실제 천막임을 확정한 것도 아니다.

H0167의 세 용례는 천막을 치고 거주하거나 옮겨 자리 잡는 활동으로 포괄한다. H0171·H0173은 한국어 성경 관용명과 확인된 구성 경계를 드러내는 분석 표기를 가운데점으로 병기한다. 붙임표는 특정 시대 발음이나 실제 원문 구두점의 재현이 아니다. 필수 표기 검토표에 따라 한자 天幕, 관용명/분석명, meaning/비고의 역할을 구분했으며 새 발음 체계 재구는 N/A다.

Canonical Strong 자료와 OSHB의 CORE8 출현377건(337절)을 검토했다. H0168의348건에는 Qere3건이 포함되며 Ketiv와 구분한다. 로컬 사전6항목·KJV·한국어 번역·LXX는 참고 자료다. LXX85조회 중 문맥 확인71건과 제외14건은 전역 alignment 검증이나 새 원천 편입을 뜻하지 않는다. 개별 참고 자료의 미확인 provenance·license 경계는 보존한다.

## 채택하지 않은 주요 대안

- H0168의 장막/거처 두 meaning: 귀가·환유 문맥을 별도 일반 주거 sense로 강하게 확정하지 않는다.
- 장막만 대표어로 유지: 의미상 가능하지만 사용자가 선호한 현대 한국어 접근성을 반영해 천막을 대표로 삼았다.
- 천막을 직물만으로 된 구조로 한정: 골조·덮개의 재료와 어휘 범위를 혼동하지 않는다.
- 이름 풀이를 별도 meaning으로 추가: 상징명·인명 식별과 사전의 어원 설명을 분리한다.
- H0170–H0172의 사전 상호 참조나 H0166–H0167의 철자 유사만으로 직접 관계 생성: 명시 근거가 있는9건만 승인한다.

## 남은 불확실성 및 재검토 조건

겔41:1 한 용례의 정확한 지시 대상·본문 해석은 확정하지 않는다. H0170의 그녀의 천막과 KJV 주석 His tent의 차이, H0173 족장 목록과 에서의 아내의 동일 인물 여부도 한정된 불확실성으로 보존한다. 이를 단어 전체 hold로 확대하지 않는다.

자동 discovery는52노드·53 edge groups, CORE8·CONTEXT2·HUB-EXCLUDED42이며 raw frontier42와 closure 미완료 상태를 보존한다. 안전 cap8과 resume2 결과는 전체 재귀 closure를 뜻하지 않는다. 원 state·queue·Packet·Review·최초 추천은 덮어쓰지 않으며 최신 승인은 이 기록과 manifest가 구분한다. 새 canonical 용례·본문비평 근거나 형태 분석이 현재 범위를 실질적으로 바꿀 때 재검토한다.

## 적용 검증

공식 dry-run의 사본 적용·undo·원본 불변과 기존 applicator 테스트31건이 통과했다. Live apply history group `1792638871577600`, ID6563–6581 총19건(word update10·relation create9·undone0), 관계 ID7996–8004다.

독립 SQL60조회·373검증으로 전체13테이블·DDL·byte 백업·공식 snapshot을 대조했다. 승인 값·이력·해당 sequence 외 변경 없음, integrity ok·FK 위반0·sidecar 없음, 보호 입력235파일 불변이다. Snapshot schema cookie1368→1369는 VACUUM INTO의 기존 계약이며 DDL·적용 전 데이터는 일치한다.

Work SHA `8e796fbb40bd35d6e05a8bffa584a0390f3881c3d36957cfda588208d4371d65` → `105089085700b0f7fa1489eb4c40f61bf41c971d3aee6c42479ced378e306050`. Seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1` 불변. Manifest SHA `737419bf108311bd222f5dd642f7487e5361d2a0c4b1e218432d9b300627daf6`, 승인 원문 SHA `f1ac65e8acbd56ef28f5dfb9455bcc5e35806a13aa498ce17a3c340aeb1cf02c`. Manifest LF 속성으로 적용 bytes를 보존한다.

표준 progress JSON·CSV·Markdown을 공식 도구로 함께 생성하고 공식 renderer bytes를 대조했다. CORE8만 신규 승인, 비대상14,290행·anomaly·canonical lexical index는 exact 불변이다. 승인477→485·미승인13,815→13,807·hold6·anomaly113·전체14,298이며 snapshot identity는 `a81fecb54ec264312e257bf54569c19c764bdeb58014beddd1be1dddfe740ffc`다.

작업 DB는 Git 미추적 로컬 자산이며 manifest·결정 기록·색인·provenance를 Git으로 보존한다. Seed 교체·앱 배포·schema·UI 변경이 없어 전체 빌드와 수동 UI 테스트는 N/A다.
