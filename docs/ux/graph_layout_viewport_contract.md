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
- Peripheral selected node outer ring 두께도 screen-space 기준값을 유지하도록 rendering 단계에서 camera scale의 역수로 보정한다.

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
