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
- Graph node border와 peripheral selected node outer ring 두께도 screen-space 기준값을 유지하도록 rendering 단계에서 camera scale의 역수로 보정한다.
- Peripheral node의 기본 identity pair는 상단 Strong 번호와 하단 spelling이다. 실제 Strong 값은 transliteration 유무와 관계없이 표시하며, spelling/primary 값이 없으면 기존 word ID fallback을 유지한다.
- Peripheral spelling/primary label font는 zoom에 따른 screen-space 가독성 변동을 완화하기 위해 camera scale 역보정값을 기본 font size의 85%~125% 범위로 제한한다. Strong identity line도 같은 목적의 역보정을 적용하되 두 줄 구성의 overflow를 제한하도록 기본 font size의 90%~115% 범위로 제한한다. 이 보정은 center label, language label 또는 transliteration LOD 정책으로 확장되지 않는다.

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

- Peripheral node는 Strong 값이 있으면 상단에 표시하고, 하단에는 spelling을 표시한다. spelling이 없으면 `wordId`를 사용한다.
- Center node는 Strong 값이 있으면 상단에 표시하고, 하단에는 spelling을 표시한다. Strong 값이 없으면 해당 줄을 생략하고, spelling이 없으면 `wordId`를 사용한다.
- 현재 선택 노드에 표시 가능한 관계가 하나 이상 있으면 graph 우하단에 compact한 “관계 보기” launcher가 표시된다. 관계가 1건이면 바로 해당 관계로 진입하고, 복수이면 popup menu에서 관계를 선택한다. 표시 가능한 관계가 없으면 launcher를 표시하지 않는다.
- Mobile selected-node preview와 기존 full-detail route 연결은 구현되어 있다.

### 6.2 Graph와 detail의 역할 경계

- Graph는 단어 간 관계 탐색과 핵심 식별을 위한 surface다.
- Detail surface는 의미, 발음, 음역, 추가 설명을 확인하는 surface다.
- Graph node와 detail surface가 같은 상세 정보를 모두 중복해 담을 필요는 없다.

### 6.3 기본 graph node 정보 계층

- Strong 번호와 spelling은 graph node의 core identity pair이며 기본 순서는 `Strong → spelling`이다.
- 실제 Strong 값이 있으면 항상 표시한다. 값이 없으면 임의 값을 만들지 않고 Strong 줄을 생략한다.
- spelling이 없으면 기존 `wordId` fallback을 유지한다.
- Center와 peripheral은 동일한 정보량일 필요가 없다. 현재 center와 peripheral 모두 Strong과 spelling 중심의 compact structure를 따른다.
- Center node의 중요성은 더 큰 크기, 중심 위치, 강조색, 선택·중심 affordance로 유지한다.
- 기본 node label에는 language, transliteration, pronunciation, meaning을 넣지 않는다.
- 향후 language를 실제 텍스트로 표시하는 정책이 생기면 label 최상단에 둔다.
- 현재는 language label, transliteration LOD, zoom별 정보량 전환을 도입하지 않는다.

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

- Center compact와 mobile selected-node preview/detail route는 설계상 연결되지만 별도의 small production slice로 구현되었다.
- Center compact는 graph label renderer 범위로 구현되었다.
- Phase 24-K에서 mobile preview 구현 전 route와 selection seam의 read-only audit을 완료했다.
- Mobile preview/detail 접근은 별도 구현으로 mobile selection state, compact surface, 기존 detail route 연결 범위에 한정했다.

### 6.7 비범위

이 계약은 full LOD, edge label·metric·border·ring, relation visual style mapping, DB schema·migration·repository·SQL, graph layout·physics·drag·pin, 새 graph dependency, 다크모드 변경을 포함하지 않는다.
