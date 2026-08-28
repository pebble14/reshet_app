# 세 번째 semantic 배치 결정

- 상태: `active`
- 기록 성격: 2026-08-28 소급 작성
- 판단 근거 복원 수준: 중간
- 대상: H1563, H1652, H5228, H5229, H6770, H6772, H2645와 관련 관계
- 의미 manifest: [third_semantic_batch_approved_content_slice.json](../../tool/data_provenance/manifests/third_semantic_batch_approved_content_slice.json)
- 관계 manifest: [third_semantic_batch_relations_approved_content_slice.json](../../tool/data_provenance/manifests/third_semantic_batch_relations_approved_content_slice.json)
- 적용 커밋: `c830ae0426d261491bc6cef65e8f32f4c4cc9fd9`, `afb10b7f0e30134223cd525e3e822aed4e95b2ea`
- 로컬 연구 산출물: `third_semantic_batch_20260814_7fe497b8`

## 최종 결정

| Strong | 승인 의미 |
|---|---|
| H1563 | 말다 |
| H1652 | 비를 내리다 |
| H5228 | 올바른 |
| H5229 | 올바름 |
| H6770 | 목마르다 |
| H6772 | 목마름 |
| H2645 | 덮다 |

H5229의 기존 `올곧음`과 H6772의 기존 `갈증`은 이 배치가 명시적으로 대체했다.

관계 결정은 다음과 같다.

- 신규 asserted: `H1563 → H1545` derived, `H6770 → H6771` derived, `H2645 → H2646` derived, `H2644 → H2645` variant
- 기존 관계 교체: `H1652 → H1653`, `H1652 → H1656`을 `root_shared / undirected`에서 `derived / w1_to_w2`로 구체화

## 핵심 판단 근거

이 배치는 관련 어근·품사 쌍이 한국어에서도 보이도록 대표어를 정리했다. `올바른`/`올바름`, `목마르다`/`목마름`, `비를 내리다`/`비`, `덮다`/`덮개·방`처럼 동사·형용사와 파생 명사의 관계를 직접 드러냈다. H1652와 H1653·H1656은 단순한 의미 유사성이 아니라 방향이 있는 파생 관계이므로 기존 root-shared 분류를 교체했다. H2644는 H2645의 variant로, 나머지 직접 source 관계는 derived로 확정했다.

## 채택하지 않은 주요 대안

- H5229의 `올곧음`은 의미상 가능하지만 H5228 `올바른`과의 표현 대응을 위해 `올바름`으로 대체했다.
- H6772의 `갈증`도 같은 개념이지만 H6770 `목마르다`와의 파생쌍을 드러내는 `목마름`으로 대체했다.
- H1652와 파생 명사의 관계를 무방향 `root_shared`로 남기지 않았다.
- H5228/H5226의 same-source, H1656/H1653 equivalent, H1565 probable, compare 및 depth-2-only 관계는 direct asserted relation으로 만들지 않았다.

## 남은 불확실성 및 재검토 조건

당시 사용자 대안 토론 전체는 남아 있지 않으므로 표현 통일 외의 세부 선택 이유는 확대해석하지 않는다. `probable`, `compare`, `same-source` 수준의 보류 관계는 새 근거 없이 asserted로 승격하지 않는다.
