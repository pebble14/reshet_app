# H260 습지 풀 의미·비고 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-29
- 대상: H0260_0000
- 승인 manifest: [h260_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h260_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 기존 6건 유지
- 로컬 연구 산출물: `reshet_research_output/H260_cluster_20261029_2390663a/`, R1
- 승인·백업·독립 검증: `data/backups/approved_content_batch/h260_approval_20261029/`

## 최종 결정

사용자는 R1 추천안과 DB·문서·기타 파일 반영, 검증, Git 및 이번 작업 브랜치 정리까지 승인했다.

- ordered meaning: seq1 **습지(濕地) 풀**, 1의미. 기존 ‘갈대, 골풀’에서 교체.
- 비고: 아래 승인문으로 NULL에서 교체.
- 관계 신규·교체·삭제 없음. Word-level hold 없음.
- H98·H100·H251 등 관련어의 기존 승인 유지. 원문·음역·발음·schema·seed 변경 없음.

> 갈대·골풀처럼 물가나 습지에 자라는 풀을 집합적으로 가리키며, 특정 식물 종으로 한정하지 않는다. 창 41:2·18에서는 나일강가에서 풀이 자란 곳을 가리켜 ‘갈밭’으로 옮길 수 있고, 욥 8:11에서는 물 없이는 자라지 못하는 풀로 나온다. BDB와 이집트어 사전은 이집트어와의 관련을 제시하지만, Strong은 어원을 불확실하며 아마 이집트어에서 왔을 것으로 설명한다.

## 핵심 판단 근거

Canonical Strong의 any marshy grass 정의와 OSHB의 전체3용례는 습지 풀의 집합 의미로 설명된다. 창41:2·18은 같은 꿈과 그 재진술에서 풀이 자라는 장소를 나타내고 욥8:11은 물 없이는 자라지 못하는 식물을 가리킨다. 장소적 ‘갈밭’을 별도 sense로 늘리지 않았다.

HebGrkKo exact1행, KJV·개역개정·개역한글·새번역·원전분해 15절 reference를 전량 대조했다. LXX 명시적3절을 수동 비교했으며 human-reference 경계와 provenance/license 미검증을 보존한다. BDB와 Chicago Demotic Dictionary의 관련 entry는 이집트어 관련설을 지지하지만 Strong의 불확실성 표현과 구별한다. 추가 논문은 초록·검색 발췌만 확인했고 전문 미열람이다.

H100의 갈대·골풀과 의미 겹침 및 종 미확정 원칙을 보존한다. 더 넓은 습지 식생을 대표하기 위해 이번 뜻풀이를 선택했으며 두 어휘를 배타적으로 구분하지 않는다. 한국어 표기 정책에 따라 습지에 濕地를 병기하고 고유어 풀에는 한자를 붙이지 않았다. 사용자가 근거를 갖춘 추천안을 채택한 결정이며 개인적인 선택 동기를 추정하지 않는다.

## 채택하지 않은 주요 대안

- 갈대·골풀: 유효한 대안이나 특정 식물 두 종류로 범위가 제한되는 인상을 줄 수 있다. 비고에 보존한다.
- 갈밭 또는 식물/장소2의미: 창세기 장소 구문은 자연스럽게 설명하지만 욥기의 식물 의미를 단일 갈밭으로 좁히거나 불필요하게 sense를 늘린다.
- 물풀: 짧지만 물속·수면 식물 전반으로 넓어질 수 있어 습지 풀을 우선했다.
- 추정 차용·유의어·LXX·호13:15 관계: 직접 Strong endpoint·방향·독립된 lexical assertion을 충분히 입증하지 않아 생성하지 않는다.

## 남은 불확실성 및 재검토 조건

전체3·검토3·미검토0, sense1 배정3·ambiguous0·의미 미해결0·반례0이다. 정확한 식물 종과 역사적 차용 시점·경로·발음은 미확정이다. 일반 의미를 막지 않으므로 word-level hold를 두지 않았다.

호13:15의 갈대 독법은 BDB의 대안 읽기이며 현 OSHB는 H251이다. H260의 네 번째 canonical occurrence로 합산하거나 기존 H251 승인을 바꾸지 않는다. 직접 본문비평·역사언어학·식물학 근거가 현재 판단을 실질적으로 바꿀 때 재검토하며 번역 표현의 반복·번호 인접성만으로 자동 변경하지 않는다.

### 적용·검증

공식 dry-run의2건 적용·undo·원본 byte 불변, 기존 applicator 테스트31개 통과 후 live apply1회를 수행했다. 전체13테이블과 DDL을 적용 전 byte 백업과 독립 대조하여 승인 meaning·note·history2행 및 history sequence 외 변화가 없음을 확인했다. History group `1793261701308814`, IDs7344–7345, undone 없음.

Work SHA `2390663a17ad0bd16fb767fc8f34449d1ffa68d726d19bda90f547c50534e2b0` → `28c0cb8f710904154ce30c77e730aeaf2d56a649660aa17ab0038a1a926126ba`. Seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1` 불변. Integrity ok·FK0·sidecar 없음.

공식 receipt: `data/backups/approved_content_batch/20261029T081459899413Z/result.json`. 표준 progress 승인762→763·미승인13530→13529, hold6·anomaly113 유지. 비대상14297개 progress 행과 anomaly 목록 불변이다. 앱/UI 코드 변경이 없어 사용자 UI 테스트·전체 앱 빌드는 N/A다.
