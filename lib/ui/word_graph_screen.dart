import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../data/models/word.dart';
import '../data/repositories/word_repository.dart';

/// CreateRelationPayload
/// - "관계 추가" 다이얼로그에서 사용자가 입력한 값을 담는 DTO(전달용 객체)
/// - WordGraphScreen 내부 로직에서만 쓰지만, Dart의 스코프 제약 때문에
///   파일 최상단에 둔다(타입 인식 안정성 확보).
class CreateRelationPayload {
  final String? categoryCode;
  final String? relationType;
  final String? note;
  final String? source;

  CreateRelationPayload({
    required this.categoryCode,
    required this.relationType,
    required this.note,
    required this.source,
  });
}

/// WordGraphScreen
/// - 중심 단어(선택된 단어)를 기준으로
/// - WORD_RELATION을 통해 연결된 단어들을 원형으로 배치하고
/// - 중심↔연결 단어 간 엣지(선)를 그리는 화면
class WordGraphScreen extends StatefulWidget {
  /// 그래프의 중심이 되는 단어(모델)
  final Word centerWord;

  /// 스플릿뷰 등에서 노드 클릭 시 화면 push 대신
  /// 선택 이벤트만 전달하고 싶을 때 사용한다.
  final ValueChanged<Word>? onSelectWord;

  const WordGraphScreen({
    super.key,
    required this.centerWord,
    this.onSelectWord,
  });

  @override
  State<WordGraphScreen> createState() => _WordGraphScreenState();
}

class _WordGraphScreenState extends State<WordGraphScreen> {
  final WordRepository _repository = WordRepository();

  /// 그래프 줌/팬 상태를 관리하는 컨트롤러
  final TransformationController _transformController =
      TransformationController();

  /// 현재 줌 배율(태그 표시/숨김 등에 사용)
  double _currentScale = 1.0;

  /// 이 배율보다 작아지면 엣지 태그를 숨긴다(가독성/겹침 감소)
  static const double _labelVisibleScaleThreshold = 1.15;

  late final Word _centerWord;

  bool _isLoading = true;
  String? _errorMessage;

  /// 중심 단어와 연결된 단어 목록
  List<Word> _connectedWords = [];

  /// 사용자가 클릭(선택)한 주변 노드 id
  /// - 같은 노드를 다시 클릭하면 이동(push)하는 트리거로 사용
  String? _selectedWordId;

  /// 상대 단어 id 기준으로 관계(엣지) 메타를 보관한다.
  /// - 여러 관계가 있을 수 있으나, 현재는 “표시용 1개”만 선택(마지막으로 덮어씀)
  final Map<String, WordRelationEdgeInfo> _edgeInfoByOtherId = {};

  @override
  void initState() {
    super.initState();
    _centerWord = widget.centerWord;
    _loadConnectedWords();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _loadConnectedWords() async {
    try {
      final words = await _repository.getConnectedWords(_centerWord.id);
      final edges = await _repository.getRelationEdges(_centerWord.id);

      if (!mounted) return;
      setState(() {
        _connectedWords = words;

        _edgeInfoByOtherId.clear();
        for (final e in edges) {
          _edgeInfoByOtherId[e.otherWordId] = e;
        }

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '연결 단어 로딩 실패: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로딩
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Word Graph')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 에러
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Word Graph')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final centerX = constraints.maxWidth / 2;
        final centerY = constraints.maxHeight / 2;

        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        final nodes = _connectedWords;

        // 노드 배치 순서와 동일한 순서로 엣지 색상/라벨 생성
        final edgeColors = nodes.map((w) {
          final info = _edgeInfoByOtherId[w.id];
          return _colorForCategory(info?.categoryCode);
        }).toList();
        final edgeLabels = nodes.map((w) {
          final info = _edgeInfoByOtherId[w.id];
          return _labelForEdge(info);
        }).toList();

        // 선택된 노드가 연결 노드 목록에서 몇 번째인지(없으면 null)
        final int selectedIndexRaw = nodes.indexWhere(
          (w) => w.id == _selectedWordId,
        );
        final int? selectedIndex = (selectedIndexRaw >= 0)
            ? selectedIndexRaw
            : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Word Graph'),
            actions: [
              IconButton(
                tooltip: '전체보기',
                icon: const Icon(Icons.fit_screen),
                onPressed: () =>
                    _fitToView(canvasSize, centerX, centerY, nodes),
              ),
              IconButton(
                tooltip: '보기 초기화',
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  _transformController.value = Matrix4.identity();
                  setState(() => _currentScale = 1.0);
                },
              ),
              IconButton(
                tooltip: '관계 추가',
                icon: const Icon(Icons.add_link),
                onPressed: _showAddRelationFlow,
              ),
            ],
          ),
          body: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                _handlePointerScroll(event);
              }
            },
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.6,
              maxScale: 3.5,
              boundaryMargin: const EdgeInsets.all(2000),
              panEnabled: true,
              scaleEnabled: true,
              onInteractionUpdate: (_) {
                final newScale = _transformController.value.getMaxScaleOnAxis();
                if (newScale != _currentScale) {
                  setState(() => _currentScale = newScale);
                }
              },
              child: SizedBox(
                width: canvasSize.width,
                height: canvasSize.height,
                child: Stack(
                  children: [
                    if (nodes.isNotEmpty)
                      CustomPaint(
                        size: canvasSize,
                        painter: GraphLinePainter(
                          centerX,
                          centerY,
                          edgeColors,
                          edgeLabels,
                          showLabels: false,
                          sceneScale: _currentScale,
                          selectedIndex: selectedIndex,
                        ),
                      ),
                    Positioned(
                      left: centerX - 90,
                      top: centerY - 90,
                      child: _buildCenterNode(_centerWord),
                    ),
                    ..._buildEdgeLabelWidgets(
                      centerX,
                      centerY,
                      nodes,
                      edgeLabels,
                      edgeColors,
                    ),

                    ..._buildWordNodes(centerX, centerY, nodes),
                    if (nodes.isEmpty)
                      Center(
                        child: Text(
                          '연결된 단어가 없습니다.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 중앙(선택) 단어 노드
  Widget _buildCenterNode(Word word) {
    return Container(
      width: 180,
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.shade100,
        border: Border.all(color: Colors.blue, width: 3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(word.language ?? '', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text(word.strongNumber ?? '', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            word.spelling1 ?? '',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(word.pronunciation1 ?? '', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            word.meaning1 ?? '',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// 연결 단어 노드(원형)
  Widget _buildWordNode(Word word, Color borderColor) {
    final label = (word.spelling1 != null && word.spelling1!.trim().isNotEmpty)
        ? word.spelling1!
        : word.id;

    final bool isSelected = (_selectedWordId == word.id);

    return GestureDetector(
      onTap: () {
        // 1) 먼저 선택 상태를 갱신한다(강조 표시용).
        //    - 이미 선택된 노드를 다시 클릭한 경우에만 "이동"을 허용한다.
        final bool isSameTap = (_selectedWordId == word.id);

        if (!isSameTap) {
          setState(() => _selectedWordId = word.id);
        }

        // 2) 스플릿뷰 모드: 선택 이벤트 전달(화면 push는 하지 않음)
        if (widget.onSelectWord != null) {
          widget.onSelectWord!(word);
          return;
        }

        // 3) 단독 화면 모드: 같은 노드를 2번 눌렀을 때만 그래프 이동
        if (isSameTap) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WordGraphScreen(centerWord: word),
            ),
          );
        }
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: isSelected ? 4 : 2),
          color: isSelected ? Colors.grey.shade100 : Colors.white,
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }

  /// 연결 단어들을 원형으로 자동 배치
  List<Widget> _buildWordNodes(
    double centerX,
    double centerY,
    List<Word> words,
  ) {
    if (words.isEmpty) return [];

    const double radius = 160;
    const double nodeRadius = 40;

    final List<Widget> widgets = [];

    for (int i = 0; i < words.length; i++) {
      final angle = (2 * pi / words.length) * i;

      final dx = centerX + radius * cos(angle);
      final dy = centerY + radius * sin(angle);

      widgets.add(
        Positioned(
          left: dx - nodeRadius,
          top: dy - nodeRadius,
          child: _buildWordNode(
            words[i],
            _colorForCategory(_edgeInfoByOtherId[words[i].id]?.categoryCode),
          ),
        ),
      );
    }

    return widgets;
  }

  /// 엣지 태그(라벨)를 "클릭 가능한 위젯"으로 렌더링한다.
  /// - Painter는 선만 그리고, 태그는 위젯으로 올려서 클릭 이벤트를 처리한다.
  List<Widget> _buildEdgeLabelWidgets(
    double centerX,
    double centerY,
    List<Word> nodes,
    List<String> edgeLabels,
    List<Color> edgeColors,
  ) {
    // 줌이 작으면 태그 숨김(기존 정책 유지)
    if (_currentScale < _labelVisibleScaleThreshold) return [];
    if (nodes.isEmpty) return [];

    const double radius = 160.0;

    // 태그가 선 위에 겹치지 않도록 약간 수직 방향 오프셋(줌 역보정)
    final double offset = (12.0 / (_currentScale <= 0 ? 1.0 : _currentScale))
        .clamp(6.0, 14.0);

    final List<Widget> widgets = [];

    for (int i = 0; i < nodes.length; i++) {
      final label = edgeLabels[i].trim();
      if (label.isEmpty) continue;

      final angle = (2 * pi / nodes.length) * i;

      final dx = centerX + radius * cos(angle);
      final dy = centerY + radius * sin(angle);

      // 중심 -> 주변 방향 벡터
      final vx = dx - centerX;
      final vy = dy - centerY;

      // 태그는 중심에서 멀어지게(주변 노드 쪽)
      const t = 0.68;
      final anchor = Offset(centerX + vx * t, centerY + vy * t);

      // 수직 단위벡터
      final len = sqrt(vx * vx + vy * vy);
      final nx = (len == 0) ? 0.0 : -vy / len;
      final ny = (len == 0) ? 0.0 : vx / len;

      final pos = Offset(anchor.dx + nx * offset, anchor.dy + ny * offset);

      final otherWord = nodes[i];
      final edgeInfo = _edgeInfoByOtherId[otherWord.id];

      widgets.add(
        Positioned(
          left: pos.dx,
          top: pos.dy,
          child: FractionalTranslation(
            translation: const Offset(-0.5, -0.5),
            child: GestureDetector(
              onTap: () {
                if (edgeInfo == null) return;
                _showEdgeDetailDialog(otherWord, edgeInfo);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: edgeColors[i].withOpacity(0.9),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  /// 엣지(관계) 상세/편집 팝업
  /// - 기본은 읽기 전용
  /// - [편집] 버튼을 눌러야 입력 컨트롤이 활성화된다(실수 방지)
  void _showEdgeDetailDialog(Word otherWord, WordRelationEdgeInfo info) {
    showDialog(
      context: context,
      builder: (context) {
        bool isEditing = false;
        bool isSaving = false;

        // 초기값(읽기용)
        String? selectedCategoryCode = info.categoryCode;
        String? selectedRelationType = info.relationType;
        // 'unspecified' 같은 표시용 값이 들어오면 드롭다운 value 규칙 위반이므로 null 처리
        if ((selectedCategoryCode ?? '').toLowerCase() == 'unspecified')
          selectedCategoryCode = null;
        if ((selectedRelationType ?? '').toLowerCase() == 'unspecified')
          selectedRelationType = null;

        final noteController = TextEditingController(text: info.note ?? '');
        final sourceController = TextEditingController(text: info.source ?? '');

        // 드롭다운 옵션(편집 눌렀을 때 로딩)
        List<Map<String, dynamic>> categories = [];
        List<Map<String, dynamic>> types = [];
        bool isOptionsLoading = false;

        bool hasChanges() {
          final note = noteController.text.trim();
          final src = sourceController.text.trim();

          final originalNote = (info.note ?? '').trim();
          final originalSrc = (info.source ?? '').trim();

          return selectedCategoryCode != info.categoryCode ||
              selectedRelationType != info.relationType ||
              note != originalNote ||
              src != originalSrc;
        }

        Future<void> loadOptionsIfNeeded(StateSetter setState) async {
          if (categories.isNotEmpty && types.isNotEmpty) return;

          setState(() => isOptionsLoading = true);
          try {
            final c = await _repository.getRelationCategories();
            final t = await _repository.getRelationTypes();
            setState(() {
              categories = c;
              types = t;
              isOptionsLoading = false;

              // 현재 선택값이 실제 items에 없으면 null로 보정(드롭다운 assert 방지)
              final categoryCodes = categories
                  .map((m) => (m['code'] as String?) ?? '')
                  .where((s) => s.isNotEmpty)
                  .toSet();
              final typeCodes = types
                  .map((m) => (m['code'] as String?) ?? '')
                  .where((s) => s.isNotEmpty)
                  .toSet();

              if (selectedCategoryCode != null &&
                  !categoryCodes.contains(selectedCategoryCode)) {
                selectedCategoryCode = null;
              }
              if (selectedRelationType != null &&
                  !typeCodes.contains(selectedRelationType)) {
                selectedRelationType = null;
              }
            });
          } catch (e) {
            setState(() => isOptionsLoading = false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('코드표 로딩 실패: $e')));
          }
        }

        Future<void> save(StateSetter setState) async {
          if (!hasChanges()) return;

          setState(() => isSaving = true);
          try {
            await _repository.updateRelation(
              relationId: info.relationId,
              categoryCode: selectedCategoryCode,
              relationType: selectedRelationType,
              note: noteController.text.trim(),
              source: sourceController.text.trim(),
            );

            // 그래프 갱신(색/라벨/팝업 내용 반영)
            await _loadConnectedWords();

            if (!mounted) return;
            Navigator.pop(context);

            ScaffoldMessenger.of(
              this.context,
            ).showSnackBar(const SnackBar(content: Text('관계가 저장되었습니다.')));
          } catch (e) {
            setState(() => isSaving = false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
          }
        }

        Future<void> deleteEdge(StateSetter setState) async {
          setState(() => isSaving = true);

          try {
            await _repository.deleteRelation(info.relationId);

            // 그래프 갱신(엣지/라벨/색 반영)
            await _loadConnectedWords();

            if (!mounted) return;
            Navigator.pop(context);

            ScaffoldMessenger.of(
              this.context,
            ).showSnackBar(const SnackBar(content: Text('관계가 삭제되었습니다.')));
          } catch (e) {
            setState(() => isSaving = false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
          }
        }

        return StatefulBuilder(
          builder: (context, setState) {
            final categoryText =
                (info.categoryLabel?.trim().isNotEmpty ?? false)
                ? info.categoryLabel!.trim()
                : (info.categoryCode?.trim().isNotEmpty ?? false)
                ? info.categoryCode!.trim()
                : 'unspecified';

            final typeText =
                (info.relationTypeLabel?.trim().isNotEmpty ?? false)
                ? info.relationTypeLabel!.trim()
                : (info.relationType?.trim().isNotEmpty ?? false)
                ? info.relationType!.trim()
                : 'unspecified';

            final canSave = isEditing && !isSaving && hasChanges();

            return AlertDialog(
              title: Text('관계: ${otherWord.spelling1 ?? otherWord.id}'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 카테고리 ---
                      const Text(
                        '카테고리',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      if (!isEditing)
                        Text(categoryText)
                      else if (isOptionsLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: LinearProgressIndicator(),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: selectedCategoryCode,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('(없음)'),
                            ),
                            ...categories.map((m) {
                              final code = (m['code'] as String?) ?? '';
                              final label = (m['label'] as String?) ?? '';
                              final text = label.isNotEmpty
                                  ? '$label ($code)'
                                  : code;
                              return DropdownMenuItem<String>(
                                value: code,
                                child: Text(text),
                              );
                            }).toList(),
                          ],
                          onChanged: (v) =>
                              setState(() => selectedCategoryCode = v),
                        ),

                      const SizedBox(height: 14),

                      // --- 타입 ---
                      const Text(
                        '타입',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      if (!isEditing)
                        Text(typeText)
                      else if (isOptionsLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: LinearProgressIndicator(),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: selectedRelationType,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('(없음)'),
                            ),
                            ...types.map((m) {
                              final code = (m['code'] as String?) ?? '';
                              final label = (m['label'] as String?) ?? '';
                              final text = label.isNotEmpty
                                  ? '$label ($code)'
                                  : code;
                              return DropdownMenuItem<String>(
                                value: code,
                                child: Text(text),
                              );
                            }).toList(),
                          ],
                          onChanged: (v) =>
                              setState(() => selectedRelationType = v),
                        ),

                      const SizedBox(height: 14),

                      // --- 노트 ---
                      const Text(
                        '노트',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: noteController,
                        enabled: isEditing && !isSaving,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '(없음)',
                        ),
                      ),

                      const SizedBox(height: 14),

                      // --- 소스 ---
                      const Text(
                        '소스',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: sourceController,
                        enabled: isEditing && !isSaving,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '(없음)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('닫기'),
                ),
                if (!isEditing)
                  TextButton(
                    onPressed: () async {
                      setState(() => isEditing = true);
                      await loadOptionsIfNeeded(setState);
                    },
                    child: const Text('편집'),
                  )
                else ...[
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            setState(() {
                              isEditing = false;
                              // 편집 취소 시 값을 원래대로 되돌리기
                              selectedCategoryCode = info.categoryCode;
                              selectedRelationType = info.relationType;
                              noteController.text = info.note ?? '';
                              sourceController.text = info.source ?? '';
                            });
                          },
                    child: const Text('취소'),
                  ),

                  // ✅ 삭제(편집 모드에서만, 확인 후 실행)
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('관계 삭제'),
                                content: const Text(
                                  '이 관계를 삭제할까요?\n이 작업은 되돌리기 어렵습니다.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('삭제'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              await deleteEdge(setState);
                            }
                          },
                    child: const Text('삭제'),
                  ),

                  ElevatedButton(
                    onPressed: canSave ? () => save(setState) : null,
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('저장'),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  /// 관계 카테고리 코드에 따른 색상 매핑
  /// - RELATION_CATEGORY.code 값 기준
  /// - WORD_RELATION에 code 테이블에 없는 값(예: unspecified)이 있을 수 있으므로 기본값을 둔다.
  Color _colorForCategory(String? categoryCode) {
    switch (categoryCode) {
      case 'semantic':
        return Colors.green;
      case 'lexical':
        return Colors.blue;
      case 'morphological':
        return Colors.orange;
      case 'etymological':
        return Colors.purple;
      case 'phonological':
        return Colors.teal;
      case 'transliteration':
        return Colors.brown;
      case 'translation':
        return Colors.indigo;

      // DB에 'unspecified'가 존재하지만 RELATION_CATEGORY엔 없어서 fallback 필요
      case 'unspecified':
        return Colors.grey;

      default:
        return Colors.grey;
    }
  }

  /// 엣지(관계) 라벨 텍스트 생성
  /// - 우선순위: relationTypeLabel(코드 테이블 라벨) > relationType(코드) > 빈 문자열
  /// - 내부적으로 코드/영문 라벨을 사람이 읽기 좋은 짧은 라벨로 정리한다.
  String _labelForEdge(WordRelationEdgeInfo? info) {
    final raw = (info?.relationTypeLabel?.trim().isNotEmpty ?? false)
        ? info!.relationTypeLabel!.trim()
        : (info?.relationType ?? '').trim();

    if (raw.isEmpty) return '';

    final normalized = _normalizeRelationLabel(raw);

    // 너무 길면 잘라서 표시(가독성)
    const maxLen = 10; // 태그가 잘린다고 했으니 여기서 조금 더 짧게
    if (normalized.length <= maxLen) return normalized;
    return '${normalized.substring(0, maxLen)}…';
  }

  /// 관계 라벨 정리
  /// - DB에 코드 테이블에 없는 값이 들어올 수 있어(예: unspecified, related, root-related)
  /// - 그래프 태그는 짧고 명확해야 하므로 사용자 친화 라벨로 바꾼다.
  String _normalizeRelationLabel(String raw) {
    final v = raw.trim();

    // 이미 한글이면 그대로 사용(불필요 변환 방지)
    final hasKorean = RegExp(r'[가-힣]').hasMatch(v);
    if (hasKorean) return v;

    switch (v) {
      case 'unspecified':
        return '미분류';
      case 'related':
        return '관련';
      case 'root-related':
        return '어근관련';
      case 'synonym':
        return '동의어';
      case 'antonym':
        return '반의어';
      default:
        // 기타 영문 라벨/코드는 보기 좋게 정리
        return v.replaceAll('-', ' ');
    }
  }

  /// 마우스 휠(스크롤)로 마우스 위치를 기준으로 확대/축소한다.
  /// - Windows 데스크탑에서 "마우스 중심 줌"을 구현하기 위함.
  void _handlePointerScroll(PointerScrollEvent event) {
    // 휠 아래로: 확대, 위로: 축소(감각은 취향이지만 이게 일반적)
    final scrollDelta = event.scrollDelta.dy;

    // 스케일 변화량(너무 크지 않게)
    final scaleFactor = (scrollDelta > 0) ? 0.92 : 1.08;

    final matrix = _transformController.value;

    // 현재 스케일
    final currentScale = matrix.getMaxScaleOnAxis();
    final nextScale = (currentScale * scaleFactor).clamp(0.6, 3.5);

    // 실제 적용될 비율
    final effective = nextScale / currentScale;

    // 마우스 위치(로컬 좌표) 기준으로 줌
    final focalPoint = event.localPosition;

    final next = Matrix4.identity()
      ..translate(focalPoint.dx, focalPoint.dy)
      ..scale(effective)
      ..translate(-focalPoint.dx, -focalPoint.dy)
      ..multiply(matrix);

    _transformController.value = next;

    // 줌 값 갱신(태그 표시/숨김을 위해)
    if (nextScale != _currentScale) {
      setState(() => _currentScale = nextScale);
    }
  }

  /// 현재 그래프(중심 노드 + 연결 노드들)가 화면에 잘 들어오도록 자동으로 줌/팬을 맞춘다.
  void _fitToView(
    Size canvasSize,
    double centerX,
    double centerY,
    List<Word> nodes,
  ) {
    // 노드 배치 반지름(현재 GraphLinePainter와 _buildWordNodes에서 쓰는 값과 맞춰야 함)
    const radius = 160.0;

    // 중심 노드/주변 노드 크기(현재 위젯 크기와 맞춰야 함)
    const centerHalf = 90.0; // 180 / 2
    const nodeHalf = 40.0; // 80 / 2

    double minX = centerX - centerHalf;
    double maxX = centerX + centerHalf;
    double minY = centerY - centerHalf;
    double maxY = centerY + centerHalf;

    final n = nodes.length;
    if (n > 0) {
      for (int i = 0; i < n; i++) {
        final angle = (2 * pi / n) * i;
        final x = centerX + radius * cos(angle);
        final y = centerY + radius * sin(angle);

        minX = min(minX, x - nodeHalf);
        maxX = max(maxX, x + nodeHalf);
        minY = min(minY, y - nodeHalf);
        maxY = max(maxY, y + nodeHalf);
      }
    }

    // 여백(태그/선 고려)
    const margin = 60.0;
    final bboxW = (maxX - minX) + margin * 2;
    final bboxH = (maxY - minY) + margin * 2;

    // 스케일 계산
    final sx = canvasSize.width / bboxW;
    final sy = canvasSize.height / bboxH;
    final scale = min(sx, sy).clamp(0.6, 3.5);

    // 바운딩 박스 중심
    final bboxCenterX = (minX + maxX) / 2;
    final bboxCenterY = (minY + maxY) / 2;

    // bbox 중심이 화면 중앙에 오도록 변환 설정
    final m = Matrix4.identity()
      ..translate(canvasSize.width / 2, canvasSize.height / 2)
      ..scale(scale)
      ..translate(-bboxCenterX, -bboxCenterY);

    _transformController.value = m;
    setState(() => _currentScale = scale);
  }

  /// [관계 추가] 전체 흐름
  /// 1) 상대 단어 검색/선택
  /// 2) 관계 정보(카테고리/타입/노트/소스) 입력
  /// 3) 중복 관계 검사 후 INSERT
  /// 4) 그래프 갱신
  Future<void> _showAddRelationFlow() async {
    // 1) 상대 단어 선택
    final other = await _showSelectWordDialog();
    if (other == null) return;

    // 자기 자신 선택 방지
    if (other.id == _centerWord.id) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('자기 자신과의 관계는 추가할 수 없습니다.')));
      return;
    }

    // 2) 관계 입력
    final payload = await _showCreateRelationDialog(other);
    if (payload == null) return;

    // 3) 중복 검사
    final existingId = await _repository.findExistingRelationId(
      _centerWord.id,
      other.id,
    );

    if (existingId != null) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('이미 존재하는 관계'),
          content: const Text('이 두 단어 사이의 관계가 이미 DB에 존재합니다.\n중복 생성은 막았습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }

    // 4) INSERT
    await _repository.createRelation(
      wordId1: _centerWord.id,
      wordId2: other.id,
      categoryCode: payload.categoryCode,
      relationType: payload.relationType,
      note: payload.note,
      source: payload.source,
    );

    // 5) 갱신
    await _loadConnectedWords();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('관계를 추가했습니다.')));
  }

  /// 상대 단어를 검색해서 고르는 다이얼로그
  Future<Word?> _showSelectWordDialog() async {
    final controller = TextEditingController();
    List<Word> results = [];

    return showDialog<Word?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> doSearch(String q) async {
              final r = await _repository.searchWords(q, limit: 200);
              // 중심 단어는 결과에서 제외(혼동 방지)
              final filtered = r.where((w) => w.id != _centerWord.id).toList();
              setState(() => results = filtered);
            }

            return AlertDialog(
              title: const Text('관계 추가: 상대 단어 선택'),
              content: SizedBox(
                width: 520,
                height: 520,
                child: Column(
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: '검색 (표기/의미/스트롱넘버)',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) {
                        // 너무 잦은 쿼리를 피하려면 debounce가 좋지만,
                        // 지금은 단순 onChanged로 시작(안정 우선)
                        if (v.trim().length >= 2) {
                          doSearch(v);
                        } else {
                          setState(() => results = []);
                        }
                      },
                      onSubmitted: (v) => doSearch(v),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: results.isEmpty
                          ? const Center(child: Text('검색어를 입력하세요.'))
                          : ListView.separated(
                              itemCount: results.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final w = results[i];
                                return ListTile(
                                  title: Text(w.spelling1 ?? w.id),
                                  subtitle: Text(
                                    [
                                      if ((w.meaning1 ?? '').trim().isNotEmpty)
                                        w.meaning1!,
                                      if ((w.strongNumber ?? '')
                                          .trim()
                                          .isNotEmpty)
                                        '스트롱: ${w.strongNumber}',
                                    ].join(' / '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => Navigator.pop(context, w),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 관계 정보를 입력받는 다이얼로그
  Future<CreateRelationPayload?> _showCreateRelationDialog(Word other) async {
    // 드롭다운 옵션 로딩
    final categories = await _repository.getRelationCategories();
    final types = await _repository.getRelationTypes();

    String? selectedCategoryCode;
    String? selectedRelationType;

    final noteController = TextEditingController();
    final sourceController = TextEditingController();

    return showDialog<CreateRelationPayload?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('관계 추가: ${other.spelling1 ?? other.id}'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCategoryCode,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: '카테고리'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('없음'),
                        ),
                        ...categories.map((c) {
                          final code = c['code'] as String;
                          final label = c['label'] as String? ?? code;
                          return DropdownMenuItem<String>(
                            value: code,
                            child: Text('$label ($code)'),
                          );
                        }),
                      ],
                      onChanged: (v) =>
                          setState(() => selectedCategoryCode = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedRelationType,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: '타입'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('없음'),
                        ),
                        ...types.map((t) {
                          final code = t['code'] as String;
                          final label = t['label'] as String? ?? code;
                          return DropdownMenuItem<String>(
                            value: code,
                            child: Text('$label ($code)'),
                          );
                        }),
                      ],
                      onChanged: (v) =>
                          setState(() => selectedRelationType = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(labelText: '노트'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: sourceController,
                      decoration: const InputDecoration(labelText: '소스'),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      CreateRelationPayload(
                        categoryCode: selectedCategoryCode,
                        relationType: selectedRelationType,
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                        source: sourceController.text.trim().isEmpty
                            ? null
                            : sourceController.text.trim(),
                      ),
                    );
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// 연결선(엣지) 렌더러
class GraphLinePainter extends CustomPainter {
  final double centerX;
  final double centerY;

  final List<Color> edgeColors;
  final List<String> edgeLabels;

  /// 줌 레벨에 따라 라벨 표시/숨김
  final bool showLabels;

  /// 현재 씬(그래프) 줌 배율
  /// - 태그 텍스트/패딩을 1/scale로 보정하여 “거의 고정 크기”처럼 보이게 한다.
  final double sceneScale;

  /// 선택된 연결 노드 인덱스(없으면 null)
  final int? selectedIndex;

  GraphLinePainter(
    this.centerX,
    this.centerY,
    this.edgeColors,
    this.edgeLabels, {
    required this.showLabels,
    required this.sceneScale,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double radius = 160;
    final center = Offset(centerX, centerY);

    final nodeCount = edgeColors.length;
    if (nodeCount == 0) return;

    for (int i = 0; i < nodeCount; i++) {
      final angle = (2 * pi / nodeCount) * i;

      final dx = centerX + radius * cos(angle);
      final dy = centerY + radius * sin(angle);

      final bool hasSelection = (selectedIndex != null);
      final bool isSelectedEdge = (selectedIndex == i);

      final paint = Paint()
        ..color = hasSelection && !isSelectedEdge
            ? edgeColors[i].withOpacity(0.35)
            : edgeColors[i]
        ..strokeWidth = isSelectedEdge ? 4.0 : 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(center, Offset(dx, dy), paint);

      // 라벨(관계 타입) 태그 표시: 선 중간 근처(약간 중심 쪽)
      final label = (i < edgeLabels.length) ? edgeLabels[i] : '';
      if (showLabels && label.isNotEmpty) {
        // 중심 -> 주변 노드 방향 벡터
        final vx = dx - center.dx;
        final vy = dy - center.dy;

        // 태그는 선의 "중간"이 아니라, 중심에서 더 멀리(주변 노드 쪽) 배치한다.
        // t가 클수록 주변 노드에 가까워진다. (0.5 = 중간)
        const t = 0.68;

        // 태그 기준점(중앙에서 멀어진 지점)
        final anchor = Offset(center.dx + vx * t, center.dy + vy * t);

        // 선 벡터의 수직 방향으로 약간 이동(선/태그 겹침 완화)
        final len = sqrt(vx * vx + vy * vy);
        final nx = (len == 0) ? 0.0 : -vy / len; // 수직 단위벡터 x
        final ny = (len == 0) ? 0.0 : vx / len; // 수직 단위벡터 y

        final scale = sceneScale <= 0 ? 1.0 : sceneScale;
        // 줌과 관계없이 적당한 오프셋(역스케일) 유지
        final offset = (12.0 / scale).clamp(6.0, 14.0);

        final shifted = Offset(
          anchor.dx + nx * offset,
          anchor.dy + ny * offset,
        );

        _drawEdgeLabel(canvas, shifted, label, edgeColors[i]);
      }
    }
  }

  void _drawEdgeLabel(Canvas canvas, Offset pos, String text, Color edgeColor) {
    final scale = sceneScale <= 0 ? 1.0 : sceneScale;
    final fontSize = (11.0 / scale).clamp(9.0, 12.0);
    final padX = (6.0 / scale).clamp(4.0, 7.0);
    final padY = (3.0 / scale).clamp(2.0, 4.0);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout();

    final rect = Rect.fromCenter(
      center: pos,
      width: textPainter.width + padX * 2,
      height: textPainter.height + padY * 2,
    );

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));

    final bgPaint = Paint()..color = Colors.white.withOpacity(0.92);
    final borderPaint = Paint()
      ..color = edgeColor.withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    // 텍스트는 중앙 배치
    final textOffset = Offset(rect.left + padX, rect.top + padY);
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant GraphLinePainter oldDelegate) {
    // node 수나 색상이 변하면 다시 그리기
    return oldDelegate.edgeColors.length != edgeColors.length ||
        oldDelegate.edgeColors != edgeColors ||
        oldDelegate.edgeLabels.length != edgeLabels.length ||
        oldDelegate.edgeLabels != edgeLabels ||
        oldDelegate.showLabels != showLabels ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
