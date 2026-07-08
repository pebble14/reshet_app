# Graph Layout / Viewport 계약

> 상태: Active graph layout/viewport authority

## 1. 목적과 범위

이 문서는 graph layout coordinate와 실제 viewport/camera의 책임 경계를 정의한다.
Graph traversal, relation 의미, expansion 정책, responsive pane 구성은 각각의 별도 authority를 따른다.

## 2. Layout coordinate 계약

- Layout coordinate는 실제 화면 또는 pane의 viewport 크기와 독립적이어야 한다.
- 같은 graph data, layout mode, layout seed, seed positions, layout options는 같은 layout result를 가져야 한다.
- `seedPositions`는 layout space 좌표이며 zoom, pan, fit, reset 또는 viewport resize로 변경하지 않는다.
- Force와 radial 전략은 동일한 canonical layout space 계약을 사용한다.

현재 첫 분리 단계에서는 고정 canonical layout space를 사용한다. 실제 viewport constraints는 layout 전략 입력으로 전달하지 않는다.

## 3. Cache identity 계약

Layout cache identity에는 다음 항목만 포함한다.

- graph data signature
- layout mode
- layout seed
- seed positions
- canonical layout options

실제 viewport width/height 변경만으로 layout cache를 무효화하지 않는다.

## 4. Camera / viewport 계약

- 실제 viewport 크기는 scene 표시와 camera transform 계산에만 사용한다.
- Fit은 graph content bounds를 실제 viewport에 맞추는 scale/translation을 계산한다.
- Reset은 scale을 초기화하고 canonical layout의 중심을 실제 viewport 중심에 배치한다.
- 선택 노드 포커스는 현재 scale을 유지하고 선택 node의 layout coordinate가 실제 viewport 중심에 오도록 translation만 조정한다.
- Zoom과 pan은 layout result를 변경하지 않는다.
- Viewport resize는 layout을 다시 정의하지 않고 기존 camera 중심을 새 viewport 중심에 맞춘다.
- Edge stroke와 dash/dot/arrowhead 같은 edge rendering metric은 screen-space 기준값을 유지하도록 rendering 단계에서 camera scale의 역수로 보정한다. 이 보정은 layout result, cache identity, graph data, camera transform을 변경하지 않는다.
- Graph node border와 peripheral selected node outer ring 두께는 해당 node 정책의 실효 화면 scale을 기준으로 역보정해 screen-space 기준값을 유지한다.
- Peripheral node label은 raw camera scale 기반 LOD로 정보량을 바꾸며, node 시각 확대 상한과 독립된 책임을 가진다.
- 실제 peripheral word node의 spelling font는 `E_peripheral` 역보정값을 기본 font size의 75%~135% 범위로 제한한다. Strong·language·transliteration·primary meaning line은 기본 font size의 80%~125% 범위로 제한한다.

### 4.1 Node 시각 확대 상한

- Camera scale `S`와 node-local visual scale `V`의 책임을 분리한다. 안전한 camera scale은 0 이하 또는 비정상 값을 `1.0`으로 정규화한다.
- Center와 `+more` 등 placeholder node는 common visual-cap `V_common = min(1.0, 1.6 / S)`, `E_common = S × V_common`을 유지한다.
- 실제 peripheral word node는 `E_peripheral = min(S^1.15, 1.80)`, `V_peripheral = E_peripheral / S`를 사용한다. `S = 1`에서는 baseline을 유지하고 충분한 고배율에서 실효 화면 scale을 `1.80`으로 제한한다.
- 실제 peripheral word node의 본체, label, border, selected ring, expansion-source ring, shadow 및 사각 hit area는 node 중심을 기준으로 `V_peripheral`을 함께 적용한다. Placeholder는 `V_common`을 유지한다.
- Node center의 layout coordinate, node center 간 거리, edge 길이와 scene의 pan/zoom 위치 관계는 raw camera scale `S`를 계속 따른다.
- 실제 peripheral word node의 font, border와 selected outer ring 두께 보정은 raw `S`가 아니라 `E_peripheral`을 기준으로 한다.
- Edge stroke, dash/dot metric과 arrowhead 자체는 raw `S` 기준 보정을 유지한다. Arrow tip의 node 경계 참조는 실제 peripheral word node에서 `base node half × V_peripheral`, center와 placeholder에서 `base node half × V_common`을 사용하며 기존 scene-space `edgeInset`은 유지한다.
- 시각 확대 상한은 node 크기와 screen-space metric을 제한하고, peripheral LOD는 label 정보량을 결정한다. LOD는 계속 raw `S`와 4.2절의 기존 threshold/hysteresis를 사용하며 visual curve가 이를 대체하지 않는다.
- Center semantic anchor는 common visual-cap, border의 `E_common` 기준 보정, label 역보정 비적용 책임을 유지한다.

### 4.2 Peripheral node label LOD

- LOD 1은 Strong 1줄을 표시하고, Strong이 없을 때만 representative spelling 1줄을 표시한다.
- LOD 2는 `language → Strong → representative spelling` 순서로 표시한다. Strong이 없으면 `language → spelling` 순서다.
- LOD 3은 `language → Strong → representative spelling → representative transliteration → primary meaning` 순서로 표시한다.
- 초기 진입은 `S < 1.15`에서 LOD 1, `1.15 <= S < 1.80`에서 LOD 2, `S >= 1.80`에서 LOD 3을 선택한다.
- 전환 hysteresis는 LOD 1→2에서 `S >= 1.20`, LOD 2→1에서 `S < 1.10`, LOD 2→3에서 `S >= 1.85`, LOD 3→2에서 `S < 1.75`를 적용한다. 한 번의 큰 scale 변화는 중간 상태를 event별로 지연하지 않고 최종 적합 LOD로 직접 전환한다.
- Language는 `GraphNode.languageCode`가 아니라 graph label batch query가 제공하는 실제 `WORD_TABLE.언어` 표시값이다.
- 빈 값은 placeholder나 빈 줄 없이 생략한다. Representative spelling이 비어 있으면 기존 `wordId` fallback을 사용한다.
- 모든 label line은 한 줄 ellipsis를 적용하며 LOD 전환 전용 animation은 도입하지 않는다.

## 5. 현재 구현 범위와 비범위

현재 구현 범위는 canonical layout options, force/radial layout 입력, layout cache identity, `WordGraphScreen`의 scene/camera 분리다. 기존 selection, center 변경, expansion, relation action, delete/edit result 계약은 유지한다.

다음 항목은 아직 이 계약의 구현 범위가 아니다.

- node drag와 pin/fixed position
- 지속 physics simulation
- physics option UI
- PyVis, vis.js, WebView 또는 새 dependency 도입
- graph route 또는 Explorer responsive boundary 변경
- DB schema와 repository read/write 경로 변경

PyVis-like interaction은 이 layout/viewport 경계 위에서 별도 단계로 추가한다.

## 6. Graph 정보 계층과 detail 접근 계약

### 6.1 현재 구현 상태

- Peripheral node는 raw camera scale에 따라 3단계 label LOD를 적용한다. 각 단계의 line 순서와 전환 기준은 4.2절을 따른다.
- Center node는 zoom과 무관한 고정 semantic anchor다. `language · Strong → spelling → representative transliteration → primary meaning` 순서로 표시하고, spelling이 없으면 `wordId`를 사용한다.
- 관계 chip은 `S >= 1.15`의 visible zoom 구간에서 parallel offset이 적용된 실제 visible edge segment 위에 배치한다.
- 관계 chip은 relation detail popup을 여는 clickable control이며, 기존 popup 진입 경로를 유지한다.
- `S < 1.15`에서 관계 chip을 숨기는 zoom-out visibility 정책은 유지한다.
- 방향 edge는 기존 arrowhead로 표현하며, 관계 chip에 별도 방향 배지를 추가하지 않는다.
- 관계 chip의 상태 배지는 화살표가 없는 edge 상태를 구분하기 위한 보조 표시다. `미정`은 direction이 확인되지 않았거나 unknown인 관계, `무향`은 방향 없는 관계, `혼합`은 여러 relation direction이 하나의 visual edge에 섞인 상태를 뜻한다. 이 표시는 relation 데이터 재해석이나 status/provenance 변경이 아니다.
- 현재 선택 노드에 표시 가능한 관계가 하나 이상 있으면 graph 우하단에 compact한 “관계 보기” launcher가 표시된다. 관계가 1건이면 바로 해당 관계로 진입하고, 복수이면 popup menu에서 관계를 선택한다. 표시 가능한 관계가 없으면 launcher를 표시하지 않는다.
- Mobile selected-node preview와 기존 full-detail route 연결은 구현되어 있다.

### 6.2 Graph와 detail의 역할 경계

- Graph는 단어 간 관계 탐색과 핵심 식별을 위한 surface다.
- Detail surface는 발음, 추가 meaning, 설명을 확인하는 surface다.
- Graph node와 detail surface가 같은 상세 정보를 모두 중복해 담을 필요는 없다.

### 6.3 기본 graph node 정보 계층

- Strong 번호와 spelling은 graph node의 core identity pair다. Peripheral node의 표시 순서는 현재 LOD에 따라 달라지고 center node는 고정 semantic-anchor 정보 계층을 유지한다.
- 실제 Strong 값이 있으면 항상 표시한다. 값이 없으면 임의 값을 만들지 않고 Strong 줄을 생략한다.
- spelling이 없으면 기존 `wordId` fallback을 유지한다.
- Center metadata는 trim된 language와 Strong을 가운데점으로 결합한다. 둘 중 하나만 있으면 해당 값만 표시하고, 둘 다 없으면 metadata 줄 전체를 생략한다.
- Center는 metadata 다음에 spelling 또는 `wordId` fallback, representative transliteration, primary meaning을 순서대로 표시한다. 빈 transliteration과 meaning은 placeholder나 빈 간격 없이 해당 줄 전체를 생략한다.
- Center의 모든 정보 줄은 중앙 정렬한 한 줄 ellipsis다. Pronunciation은 표시하지 않고 detail surface 책임으로 유지한다.
- Center와 peripheral은 동일한 정보량일 필요가 없다. Center는 peripheral 3단계 LOD와 독립된 고정 정보량을 유지하며 zoom별 정보량 전환을 하지 않는다.
- Center node의 중요성은 더 큰 크기, 중심 위치, 강조색, 선택·중심 affordance로 유지한다.
- Peripheral LOD 2·3의 language는 실제 DB 표시값을 최상단에 두며, LOD 3은 representative transliteration과 primary meaning을 추가한다.
- Center node와 mobile selected-node preview의 정보량은 peripheral LOD에 연동하지 않는다.
- Center 전체의 visual cap `V` 적용, border의 실효 화면 scale `E` 기준 보정, center label 역보정 비적용 책임은 4.1절을 그대로 따른다.

### 6.4 Desktop detail 표현

- Large-screen에서는 선택된 node의 상세 정보를 detail panel에 표시한다.
- Graph node는 detail panel을 대체하지 않는다.

### 6.5 Mobile detail 접근 정책

다음은 현재 구현된 mobile detail 접근 정책이다.

- Mobile graph에서는 선택된 node가 있을 때만 compact selected-node preview surface를 표시한다.
- 선택된 node가 없으면 preview를 표시하지 않는다. Center word가 존재한다는 이유만으로 자동 표시하지 않는다.
- 전체 창 폭이 900px 미만일 때만 preview를 표시하며, 900px 이상 large-screen에서는 preview를 표시하지 않고 기존 detail panel 역할을 유지한다.
- Center node도 사용자가 명시적으로 탭해 선택할 수 있으며, 선택되면 같은 preview 규칙을 적용한다.
- Preview는 현재 mobile “관계 보기”와 같은 compact secondary surface 계열의 표현과 상호작용 리듬을 따른다. 같은 widget이나 구현을 재사용한다는 의미는 아니다.
- Preview와 “관계 보기” launcher가 함께 표시되면 preview를 launcher 위에 배치해 tap 영역이 겹치지 않게 한다.
- Preview에는 실제 값이 있는 범위에서 Strong, spelling, transliteration, meaning 1까지만 이 순서로 표시한다.
- Transliteration 또는 meaning 1이 없으면 placeholder를 만들지 않고 해당 항목을 생략한다.
- Node 탭은 선택, preview 탭은 해당 선택 node의 기존 full detail route 진입 역할을 맡는다.
- Preview는 full detail을 대체하지 않는다. 추가 관계 목록, 스크롤형 상세, 복수 action을 preview 내부에 넣지 않는다.

### 6.6 구현 분리 원칙

- Center semantic anchor와 mobile selected-node preview/detail route는 설계상 연결되지만 별도의 small production slice로 구현되었다.
- Center semantic anchor는 graph label renderer 범위로 구현되었다.
- Phase 24-K에서 mobile preview 구현 전 route와 selection seam의 read-only audit을 완료했다.
- Mobile preview/detail 접근은 별도 구현으로 mobile selection state, compact surface, 기존 detail route 연결 범위에 한정했다.

### 6.7 비범위

이 계약은 center node 또는 mobile selected-node preview의 LOD, edge label·metric, relation visual style mapping, DB schema·migration, graph layout·physics·drag·pin, 새 graph dependency, 다크모드 변경을 포함하지 않는다.
