# H18 클러스터 결정

- 상태: `active`
- 기록 성격: 2026-08-28 소급 작성
- 판단 근거 복원 수준: 높음
- 대상: H0018, H0075, H3965
- 승인 manifest: [h18_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h18_cluster_approved_content_slice.json)
- 적용 커밋: `35367291c11cf136ec3c2e97dcfecce5df57a0f9`
- 로컬 연구 산출물: `H18_cluster_20260827_67ad253b`

## 최종 결정

- H0018: `구유`
- H0075: `살찌우다`
- H3965: `곡물 창고(穀物倉庫)`
- H0018 비고: 가축의 먹이통을 뜻하고 욥 39:9에서는 문맥상 `외양간`으로 번역되기도 함
- H0075 비고: 가축에게 먹이를 주어 살찌게 하며 확인된 두 용례가 모두 칼 수동분사임
- 관계: `H0075 → H0018`, `H0075 → H3965`, 모두 `morphological / derived / asserted`
- H0018–H3965 직접 관계: 생성하지 않음

## 핵심 판단 근거

H18의 canonical source는 `manger or stall`이고 세 용례는 가축의 먹이통과 먹이 자리를 가리킨다. 대표 lexical 대상은 `구유`이며, `외양간`은 욥 39:9의 stall 문맥을 설명하는 번역이므로 별도 meaning으로 병기하지 않고 비고에 보존했다. 말에 한정되는 `마굿간`은 소·나귀·들소 문맥 전체를 대표하기 어렵다.

H75는 먹이를 주어 가축이나 새를 살찌게 하는 동사다. 사용자는 `먹여 살찌우다`까지 meaning에 넣지 않아도 `살찌우다`로 충분하다고 판단했고, feeding mechanism과 수동분사 용례는 비고가 보완하도록 했다. H3965는 곡물 저장 장소가 명확하며 한국어 띄어쓰기와 한자 병기 원칙에 따라 `곡물 창고(穀物倉庫)`로 확정했다.

H18과 H3965가 모두 H75에서 파생되었다는 canonical source는 직접적이고 qualifier가 없으므로 두 관계를 asserted로 승인했다. 두 파생 명사 사이의 직접 관계는 source가 제시하지 않아 만들지 않았다.

## 채택하지 않은 주요 대안

- H18의 초기 후보 `구유·외양간`은 하나의 lexical core와 문맥 번역을 meaning에서 병렬하므로 `구유` + 비고로 정리했다.
- 기존 `마굿간, 구유`는 `마굿간`의 말 전용 뉘앙스 때문에 유지하지 않았다.
- H75의 초기 후보 `먹여 살찌우다`는 정확하지만 meaning으로는 `살찌우다`가 충분하여 원인 동작을 비고로 옮겼다.
- H3965의 붙여 쓴 `곡물창고`보다 일반 명사 결합의 띄어쓰기를 적용한 `곡물 창고`를 택했다.
- H18–H3965에 자동 `root_shared` 관계를 추가하지 않았다.

## 남은 불확실성 및 재검토 조건

H75 한 용례의 local Korean reference는 versification 차이 때문에 manual review 경계를 유지하지만 canonical occurrence는 확인되었다. H3965는 hapax이나 source와 문맥이 수렴한다. 새 lexical evidence가 H18의 먹이통과 stall을 독립 sense로 나누어야 함을 보일 때만 재검토한다.
