import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../data/models/relation_category_lookup.dart';
import '../data/models/relation_type_lookup.dart';
import '../data/models/word.dart';
import '../data/repositories/word_repository.dart';
import '../domain/graph/graph_build_options.dart';
import '../domain/graph/graph_builder.dart';
import '../domain/graph/graph_center_word_display_item.dart';
import '../domain/graph/graph_create_post_save_payload.dart';
import '../domain/graph/graph_edge.dart';
import '../domain/graph/graph_node.dart';
import '../domain/graph/graph_relation_add_search_result_item.dart';
import '../domain/graph/graph_view_data.dart';
import '../domain/graph/graph_visible_node.dart';
import '../domain/graph/graph_visible_word.dart';
import '../domain/graph/graph_word_label_display_item.dart';
import '../domain/graph/layout/graph_layout_options.dart';
import '../domain/graph/layout/graph_layout_strategy_resolver.dart';
import '../domain/relation/relation_formatter.dart';
import '../domain/word/duplicate_candidate_display_item.dart';
import '../domain/word/word_detail_like_display_item.dart';
import '../domain/word/word_edit_save_result.dart';
import '../domain/word/word_write_models.dart';
import '../domain/word/word_write_service.dart';
import 'responsive_layout.dart';
import 'mobile_word_search_screen.dart';
import 'word_detail_screen.dart';
import 'word_expression_set.dart';
import 'word_detail_route_result.dart';
import 'word_graph_cache.dart';
import 'word_edit_screen.dart';
import 'word_search_query.dart';

typedef WordGraphSelectedWordDeletedCallback =
    Future<void> Function(String wordId, {required bool wasCenterWord});

class _GraphAppBarCommand {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _GraphAppBarCommand({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  Widget buildIconButton() {
    return IconButton(tooltip: label, icon: Icon(icon), onPressed: onPressed);
  }
}

const double _centerNodeSize = 180.0;
const double _centerNodeHalf = _centerNodeSize / 2;
const double _connectedNodeSize = 80.0;
const double _connectedNodeHalf = _connectedNodeSize / 2;
const double _nodeVisualScaleCap = 1.6;
const double _peripheralNodeScaleExponent = 1.15;
const double _peripheralNodeEffectiveScaleCap = 1.80;
const double _depthOneNodeSize = 84.0;
const double _depthTwoNodeSize = 76.0;
const double _placeholderAnchorGap = 16.0;
const double _placeholderTangentOffset = 30.0;
const double _placeholderFallbackOutwardStep = 18.0;
const double _placeholderCollisionPadding = 10.0;
const double _labelAnchorFactor = 0.68;
const double _fitBoundsPadding = 72.0;
const double _baseLabelOffset = 12.0;
const int _labelPlacementMaxAttempts = 7;
const double _labelPlacementStep = 8.0;
const double _labelPlacementRadialStep = 6.0;
const double _labelMaxShiftDistance = 28.0;
const double _labelCollisionPadding = 4.0;
const double _edgeLabelFontSize = 11.0;
const double _edgeLabelHorizontalPadding = 8.0;
const double _edgeLabelVerticalPadding = 4.0;
const double _centerNodeBorderWidth = 4.6;
const double _centerNodeHaloBlur = 16.0;
const double _centerNodeHaloSpread = 1.8;
const double _centerNodeMainShadowBlur = 20.0;
const double _centerNodeMainShadowSpread = 1.1;
const double _centerNodeMainShadowOffsetY = 5.5;
const double _connectedNodeDefaultBorderWidth = 2.0;
const double _depthOneNodeBorderWidth = _connectedNodeDefaultBorderWidth + 0.2;
const double _depthTwoNodeBorderWidth = 1.8;
const double _connectedNodeSelectedBorderWidth = 4.0;
const double _connectedNodeMutedBorderWidth = 1.6;
const double _selectedNodeOuterRingInset = 5.0;
const double _selectedNodeOuterRingWidth = 2.4;
const double _expansionSourceRingInset = 3.0;
const double _expansionSourceRingWidth = 1.4;
const double _selectedEdgeStrokeWidth = 3.4;
const double _defaultEdgeStrokeWidth = 2.0;
const double _mutedEdgeStrokeWidth = 1.8;
const double _centerEdgeStrokeWidth = 2.2;
const double _expansionEdgeStrokeWidth = 1.8;
const double _connectedEdgeOpacity = 0.80;
const double _mutedEdgeOpacity = 0.40;
const double _centerEdgeOpacity = _connectedEdgeOpacity + 0.04;
const double _expansionEdgeOpacity = _connectedEdgeOpacity - 0.12;
const double _mutedCenterEdgeOpacity = _mutedEdgeOpacity + 0.10;
const double _mutedExpansionEdgeOpacity = _mutedEdgeOpacity;
const double _defaultEdgeLabelBorderWidth = 1.5;
const double _selectedEdgeLabelBorderWidth = 1.8;
const double _defaultEdgeLabelBorderOpacity = 0.9;
const double _mutedEdgeLabelBorderOpacity = 0.72;
const double _centerNodeLanguageTintFactor = 0.08;
const double _connectedNodeLanguageTintAlpha = 0.22;
const double _depthTwoNodeLanguageTintAlpha = 0.18;
const double _selectedNodeLanguageTintAlpha = 0.26;
const double _mutedNodeLanguageTintAlpha = 0.14;
const String _languageGroupHebrewAramaic = 'hebrew_aramaic';
const String _languageGroupGreek = 'greek';
const String _languageGroupLatin = 'latin';
const String _languageGroupEnglish = 'english';
const String _languageGroupOther = 'other';
const String _languageGroupFallback = 'fallback';
const Color _languageGroupHebrewAramaicColor = Color(0xFFFFD700);
const Color _languageGroupGreekColor = Color(0xFF4AC7D4);
const Color _languageGroupLatinColor = Color(0xFF9F0807);
const Color _languageGroupEnglishColor = Color(0xFF8B5FD3);
const Color _languageGroupOtherColor = Color(0xFF9CA3AF);
const Color _languageGroupFallbackColor = Color(0xFFC0C0C0);
const Duration _visualStateAnimationDuration = Duration(milliseconds: 150);
const Duration _backgroundTapSuppressDuration = Duration(milliseconds: 140);
const double _dimmedNodeOpacity = 0.54;
const double _dimmedNodeTextOpacity = 0.75;
const double _connectedCenterOpacity = 0.94;
const double _connectedEdgeLabelOpacity = 0.80;
const double _dimmedEdgeLabelOpacity = 0.40;
const double _centerEdgeLabelOpacity = _connectedEdgeLabelOpacity + 0.06;
const double _expansionEdgeLabelOpacity = _connectedEdgeLabelOpacity - 0.06;
const double _mutedCenterEdgeLabelOpacity = _dimmedEdgeLabelOpacity + 0.14;
const double _mutedExpansionEdgeLabelOpacity = _dimmedEdgeLabelOpacity + 0.04;
const double _selectedEdgeLabelTintAlpha = 0.18;
const double _connectedEdgeLabelTintAlpha = 0.06;
const double _dimmedEdgeLabelTintAlpha = 0.03;
const int _edgeLabelVisibleCountThreshold = 6;
const double _centerNodeAccentRingInset = 12.0;
const double _centerNodeSelectedAccentRingInset = 8.0;
const double _centerNodeAccentRingWidth = 1.8;
const double _centerNodeSelectedAccentRingWidth = 2.6;
const double _centerChangeFocusDistanceThreshold = 72.0;
const double _centerChangeFocusShiftFactor = 0.38;
const double _centerChangeFocusMaxShift = 112.0;
const double _selectedNodeRelationOverlayInset = 16.0;
const double _selectedNodeRelationOverlayMinHeight = 40.0;
const double _selectedNodePreviewMaxWidth = 320.0;
const double _selectedNodePreviewLauncherGap = 12.0;

double _safeCameraScale(double cameraScale) {
  return cameraScale.isFinite && cameraScale > 0 ? cameraScale : 1.0;
}

double _nodeLocalVisualScale(double cameraScale) {
  final safeCameraScale = _safeCameraScale(cameraScale);
  return min(1.0, _nodeVisualScaleCap / safeCameraScale);
}

double _effectiveNodeScreenScale(double cameraScale) {
  final safeCameraScale = _safeCameraScale(cameraScale);
  return safeCameraScale * _nodeLocalVisualScale(safeCameraScale);
}

double _effectiveNodeHalf(double baseNodeHalf, double cameraScale) {
  return baseNodeHalf * _nodeLocalVisualScale(cameraScale);
}

@visibleForTesting
double peripheralNodeEffectiveScreenScaleForTesting(double cameraScale) {
  final safeCameraScale = _safeCameraScale(cameraScale);
  return min(
    pow(safeCameraScale, _peripheralNodeScaleExponent).toDouble(),
    _peripheralNodeEffectiveScaleCap,
  );
}

double _peripheralNodeLocalVisualScale(double cameraScale) {
  final safeCameraScale = _safeCameraScale(cameraScale);
  return peripheralNodeEffectiveScreenScaleForTesting(safeCameraScale) /
      safeCameraScale;
}

double _peripheralNodeEffectiveHalf(double baseNodeHalf, double cameraScale) {
  return baseNodeHalf * _peripheralNodeLocalVisualScale(cameraScale);
}

@visibleForTesting
double peripheralNodeSpellingFontSizeForTesting({
  required double baseFontSize,
  required double cameraScale,
}) {
  final effectiveScreenScale = peripheralNodeEffectiveScreenScaleForTesting(
    cameraScale,
  );
  return (baseFontSize / effectiveScreenScale).clamp(
    baseFontSize * 0.75,
    baseFontSize * 1.35,
  );
}

@visibleForTesting
double peripheralNodeSecondaryFontSizeForTesting({
  required double baseFontSize,
  required double cameraScale,
}) {
  final effectiveScreenScale = peripheralNodeEffectiveScreenScaleForTesting(
    cameraScale,
  );
  return (baseFontSize / effectiveScreenScale).clamp(
    baseFontSize * 0.80,
    baseFontSize * 1.25,
  );
}

const double _dashedEdgeDashLength = 14.0;
const double _dashedEdgeGapLength = 9.0;
const double _dottedEdgeDotLength = 1.0;
const double _dottedEdgeGapLength = 7.0;
const int _centerDepthOneSoftLimit = 12;

enum _GraphVisualState { selected, connected, dimmed }

enum PeripheralNodeLodLevel { lod1, lod2, lod3 }

@visibleForTesting
PeripheralNodeLodLevel resolvePeripheralNodeLodForTesting({
  required double cameraScale,
  PeripheralNodeLodLevel? currentLod,
}) {
  final scale = _safeCameraScale(cameraScale);
  if (currentLod == null) {
    if (scale < 1.15) return PeripheralNodeLodLevel.lod1;
    if (scale < 1.80) return PeripheralNodeLodLevel.lod2;
    return PeripheralNodeLodLevel.lod3;
  }

  return switch (currentLod) {
    PeripheralNodeLodLevel.lod1 =>
      scale >= 1.85
          ? PeripheralNodeLodLevel.lod3
          : scale >= 1.20
          ? PeripheralNodeLodLevel.lod2
          : PeripheralNodeLodLevel.lod1,
    PeripheralNodeLodLevel.lod2 =>
      scale >= 1.85
          ? PeripheralNodeLodLevel.lod3
          : scale < 1.10
          ? PeripheralNodeLodLevel.lod1
          : PeripheralNodeLodLevel.lod2,
    PeripheralNodeLodLevel.lod3 =>
      scale < 1.10
          ? PeripheralNodeLodLevel.lod1
          : scale < 1.75
          ? PeripheralNodeLodLevel.lod2
          : PeripheralNodeLodLevel.lod3,
  };
}

enum _GraphEdgeSemanticStyle { solid, dashed, dotted }

enum _GraphEdgeVisualPriority { selected, center, expansion }

enum _GraphEdgeDirectionSummary {
  outgoing,
  incoming,
  undirected,
  unknown,
  mixed,
}

_GraphEdgeSemanticStyle _edgeSemanticStyleForRelationType(
  String? relationType,
) {
  final normalized = (relationType ?? '').trim().toLowerCase();

  switch (normalized) {
    case 'semantic':
      return _GraphEdgeSemanticStyle.dashed;
    case 'related':
    case 'root-related':
      return _GraphEdgeSemanticStyle.dotted;
    default:
      return _GraphEdgeSemanticStyle.solid;
  }
}

_GraphEdgeVisualPriority _edgeVisualPriorityFor({
  required bool isFocusedEdge,
  required bool touchesCenter,
}) {
  if (isFocusedEdge) {
    return _GraphEdgeVisualPriority.selected;
  }

  return touchesCenter
      ? _GraphEdgeVisualPriority.center
      : _GraphEdgeVisualPriority.expansion;
}

class _GraphNodeLayout {
  final String nodeId;
  final int index;
  final Offset center;
  final Rect nodeBounds;
  final Offset labelAnchor;
  final Offset labelNormal;
  final double radius;
  final double angle;
  final int ringIndex;
  final int depth;
  final double nodeSize;
  final bool isExpansionSource;

  const _GraphNodeLayout({
    required this.nodeId,
    required this.index,
    required this.center,
    required this.nodeBounds,
    required this.labelAnchor,
    required this.labelNormal,
    required this.radius,
    required this.angle,
    required this.ringIndex,
    required this.depth,
    required this.nodeSize,
    required this.isExpansionSource,
  });

  double get nodeHalf => nodeSize / 2;

  Offset labelCenter(double sceneScale) {
    final scale = sceneScale <= 0 ? 1.0 : sceneScale;
    final offset = (_baseLabelOffset / scale).clamp(6.0, 14.0);
    return Offset(
      labelAnchor.dx + labelNormal.dx * offset,
      labelAnchor.dy + labelNormal.dy * offset,
    );
  }
}

class _GraphEdgeLayout {
  final String edgeId;
  final String sourceId;
  final String targetId;
  final Offset start;
  final Offset end;
  final Offset midpoint;
  final Offset labelNormal;
  final Color color;
  final String? relationType;
  final _GraphEdgeDirectionSummary directionSummary;
  final bool touchesCenter;

  const _GraphEdgeLayout({
    required this.edgeId,
    required this.sourceId,
    required this.targetId,
    required this.start,
    required this.end,
    required this.midpoint,
    required this.labelNormal,
    required this.color,
    required this.relationType,
    required this.directionSummary,
    required this.touchesCenter,
  });

  Offset labelCenter(double sceneScale) {
    final scale = sceneScale <= 0 ? 1.0 : sceneScale;
    final offset = (_baseLabelOffset / scale).clamp(6.0, 14.0);
    return Offset(
      midpoint.dx + labelNormal.dx * offset,
      midpoint.dy + labelNormal.dy * offset,
    );
  }
}

class _GraphLayoutData {
  final Size viewportSize;
  final Size layoutSpaceSize;
  final String centerNodeId;
  final Offset center;
  final Rect centerBounds;
  final List<_GraphNodeLayout> nodeLayouts;
  final Map<String, _GraphNodeLayout> nodeLayoutById;
  final List<_GraphEdgeLayout> edgeLayouts;
  final Rect contentBounds;
  final Rect fitBounds;
  final List<double> ringRadii;

  const _GraphLayoutData({
    required this.viewportSize,
    required this.layoutSpaceSize,
    required this.centerNodeId,
    required this.center,
    required this.centerBounds,
    required this.nodeLayouts,
    required this.nodeLayoutById,
    required this.edgeLayouts,
    required this.contentBounds,
    required this.fitBounds,
    required this.ringRadii,
  });
}

class _SelectedNodeRelationEntry {
  final String edgeId;
  final String otherWordId;
  final List<WordRelationEdgeInfo> infos;

  const _SelectedNodeRelationEntry({
    required this.edgeId,
    required this.otherWordId,
    required this.infos,
  });
}

/// 신규 단어 생성 다이얼로그의 결과를 담는 DTO
class CreateWordPayload {
  final CanonicalWordWritePayload wordPayload;

  /// true면 단어 저장 후 현재 선택 단어와 관계 추가를 이어서 진행
  final bool createRelationAfterSave;

  CreateWordPayload({
    required this.wordPayload,
    required this.createRelationAfterSave,
  });
}

class _CreateWordDialog extends StatefulWidget {
  const _CreateWordDialog();

  @override
  State<_CreateWordDialog> createState() => _CreateWordDialogState();
}

class _CreateWordDialogState extends State<_CreateWordDialog> {
  static const List<String> _languageGroups = [
    '히브리어/아람어',
    '헬라어',
    '라틴어',
    '영어',
    '기타',
  ];

  final TextEditingController _strongController = TextEditingController();
  final TextEditingController _meaningController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _customLanguageController =
      TextEditingController();
  final List<WordExpressionSetControllerGroup> _expressionSetControllerGroups =
      createExpressionSetControllerGroups(const <String, dynamic>{});
  final Set<int> _blurredExpressionSetIndexes = <int>{};

  String _selectedLanguageGroup = '헬라어';
  bool _createRelationAfterSave = false;
  bool _didAttemptExpressionSetSave = false;
  bool _isClosing = false;
  bool _isChangingExpressionSetRepresentative = false;

  @override
  void dispose() {
    _strongController.dispose();
    _meaningController.dispose();
    _noteController.dispose();
    _customLanguageController.dispose();
    for (final controllerGroup in _expressionSetControllerGroups) {
      controllerGroup.dispose();
    }
    super.dispose();
  }

  WordExpressionSetValidationResult _buildExpressionSetValidationResult() {
    return validateExpressionSetDrafts(
      collectExpressionSetDrafts(_expressionSetControllerGroups),
    );
  }

  Set<int> _visibleExpressionSetIssueIndexes() {
    if (_didAttemptExpressionSetSave) {
      return {
        for (
          var index = 1;
          index <= _expressionSetControllerGroups.length;
          index++
        )
          index,
      };
    }

    return Set<int>.from(_blurredExpressionSetIndexes);
  }

  void _closeDialog([CreateWordPayload? payload]) {
    if (_isClosing) {
      return;
    }

    _isClosing = true;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context, payload);
  }

  void _addExpressionSet() {
    final controllerGroup = WordExpressionSetControllerGroup();

    setState(() {
      _blurredExpressionSetIndexes.clear();
      _expressionSetControllerGroups.add(controllerGroup);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _isClosing ||
          !_expressionSetControllerGroups.contains(controllerGroup)) {
        return;
      }
      controllerGroup.spellingFocusNode.requestFocus();
    });
  }

  void _removeExpressionSet(int index) {
    if (_expressionSetControllerGroups.length <= 1) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _blurredExpressionSetIndexes.clear();
      final controllerGroup = _expressionSetControllerGroups.removeAt(index);
      disposeExpressionSetControllerGroupAfterFrame(controllerGroup);
    });
  }

  void _makeExpressionSetRepresentative(int index) {
    if (index <= 0 || index >= _expressionSetControllerGroups.length) {
      return;
    }

    final controllerGroup = _expressionSetControllerGroups[index];
    if (controllerGroup.spellingController.text.trim().isEmpty) {
      return;
    }

    _isChangingExpressionSetRepresentative = true;
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _blurredExpressionSetIndexes.clear();
      final representativeGroup = _expressionSetControllerGroups[0];
      _expressionSetControllerGroups[0] = controllerGroup;
      _expressionSetControllerGroups[index] = representativeGroup;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isChangingExpressionSetRepresentative = false;
    });
  }

  void _handleExpressionSetChanged() {
    if (!mounted || _isClosing) {
      return;
    }

    setState(() {});
  }

  void _handleExpressionSetFocusLost(int setIndex) {
    if (!mounted ||
        _isClosing ||
        _isChangingExpressionSetRepresentative ||
        _didAttemptExpressionSetSave ||
        _blurredExpressionSetIndexes.contains(setIndex)) {
      return;
    }

    setState(() {
      _blurredExpressionSetIndexes.add(setIndex);
    });
  }

  Future<void> _save() async {
    final expressionSetDrafts = collectExpressionSetDrafts(
      _expressionSetControllerGroups,
    );
    final validationResult = validateExpressionSetDrafts(expressionSetDrafts);

    setState(() {
      _didAttemptExpressionSetSave = true;
    });

    if (validationResult.hasErrors) {
      return;
    }

    String resolvedLanguage;
    if (_selectedLanguageGroup == '히브리어/아람어' ||
        _selectedLanguageGroup == '기타') {
      resolvedLanguage = _customLanguageController.text.trim();
      if (resolvedLanguage.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('실제 언어명을 입력해주세요.')));
        return;
      }
    } else {
      resolvedLanguage = _selectedLanguageGroup;
    }

    final canonicalizationResult = canonicalizeExpressionSetDrafts(
      expressionSetDrafts,
    );
    final payload = CanonicalWordWritePayload(
      language: resolvedLanguage,
      strongNumber: _strongController.text.trim().isEmpty
          ? null
          : _strongController.text.trim().toUpperCase(),
      expressionSets: canonicalizationResult.expressionSets,
      meanings: _meaningController.text.trim().isEmpty
          ? const <String>[]
          : <String>[_meaningController.text.trim()],
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    if (canonicalizationResult.exclusionIssues.isNotEmpty) {
      final shouldContinue = await showWordWriteExclusionDialog(
        context,
        canonicalizationResult.exclusionIssues,
      );
      if (shouldContinue != true) {
        return;
      }
    }

    _closeDialog(
      CreateWordPayload(
        wordPayload: payload,
        createRelationAfterSave: _createRelationAfterSave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validationResult = _buildExpressionSetValidationResult();

    return WillPopScope(
      onWillPop: () async {
        _isClosing = true;
        FocusManager.instance.primaryFocus?.unfocus();
        return true;
      },
      child: AlertDialog(
        title: const Text('신규 단어 생성'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedLanguageGroup,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: '언어 그룹'),
                  items: _languageGroups
                      .map(
                        (lang) => DropdownMenuItem<String>(
                          value: lang,
                          child: Text(lang),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null || _isClosing) {
                      return;
                    }

                    setState(() {
                      _selectedLanguageGroup = value;
                      if (value != '히브리어/아람어' && value != '기타') {
                        _customLanguageController.clear();
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (_selectedLanguageGroup == '히브리어/아람어' ||
                    _selectedLanguageGroup == '기타') ...[
                  TextField(
                    controller: _customLanguageController,
                    decoration: InputDecoration(
                      labelText: _selectedLanguageGroup == '히브리어/아람어'
                          ? '실제 언어명 (예: 히브리어, 아람어)'
                          : '실제 언어명 입력',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _strongController,
                  decoration: const InputDecoration(
                    labelText: '스트롱 번호 (없으면 비워둠)',
                  ),
                ),
                const SizedBox(height: 12),
                WordExpressionSetSection(
                  controllerGroups: _expressionSetControllerGroups,
                  enabled: true,
                  validationResult: validationResult,
                  visibleIssueSetIndexes: _visibleExpressionSetIssueIndexes(),
                  onAddSet: _addExpressionSet,
                  onMakeRepresentative: _makeExpressionSetRepresentative,
                  onChanged: _handleExpressionSetChanged,
                  onSetFocusLost: _handleExpressionSetFocusLost,
                  onRemoveSet: _removeExpressionSet,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _meaningController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: '의미1'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: '비고'),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _createRelationAfterSave,
                  onChanged: (value) {
                    if (_isClosing) {
                      return;
                    }

                    setState(() {
                      _createRelationAfterSave = value ?? false;
                    });
                  },
                  title: const Text('저장 후 현재 선택 단어와 관계 추가'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: _closeDialog, child: const Text('취소')),
          ElevatedButton(onPressed: _save, child: const Text('저장')),
        ],
      ),
    );
  }
}

/// CreateRelationPayload
/// - "관계 추가" 다이얼로그에서 사용자가 입력한 값을 담는 DTO(전달용 객체)
/// - WordGraphScreen 내부 로직에서만 쓰지만, Dart의 스코프 제약 때문에
///   파일 최상단에 둔다(타입 인식 안정성 확보).
class CreateRelationPayload {
  final String? categoryCode;
  final String? relationType;
  final String directionCode;
  final String? description;
  final String? relationGroupId;
  final String? note;
  final String? source;

  CreateRelationPayload({
    required this.categoryCode,
    required this.relationType,
    required this.directionCode,
    required this.description,
    required this.relationGroupId,
    required this.note,
    required this.source,
  });
}

/// WordGraphScreen
/// - 중심 단어(선택된 단어)를 기준으로
/// - WORD_RELATION을 통해 연결된 단어들을 원형으로 배치하고
/// - 중심↔연결 단어 간 엣지(선)를 그리는 화면
class WordGraphScreen extends StatefulWidget {
  /// Graph public seed boundary. The graph rereads center display/data by id.
  final String centerWordId;

  /// Compatibility entrypoint for older callers. This returns an id-only seed
  /// object and does not preserve or trust display fields from the caller.
  @Deprecated('Use centerWordId instead.')
  Word get centerWord => Word(id: centerWordId);

  /// 스플릿뷰 등에서 노드 클릭 시 화면 push 대신
  /// 선택 이벤트만 전달하고 싶을 때 사용한다.
  final String? selectedWordId;
  final List<Widget> appBarActionPrefix;
  final ValueChanged<String>? onSelectWordId;

  /// Compatibility fallback for callers that still consume a Word payload.
  final ValueChanged<Word>? onSelectWord;
  final VoidCallback? onClearSelection;
  final WordGraphSelectedWordDeletedCallback? onDeletedSelectedWord;

  /// 스플릿뷰에서 이미 선택된 노드를 다시 클릭했을 때
  /// 부모가 중심 단어를 바꾸도록 알린다.
  final ValueChanged<String>? onChangeCenterWordId;
  final ValueChanged<Word>? onChangeCenterWord;
  final WordMutationImpactCollector? mutationImpactCollector;

  WordGraphScreen({
    super.key,
    String? centerWordId,
    @Deprecated('Use centerWordId instead.') Word? centerWord,
    this.selectedWordId,
    this.appBarActionPrefix = const [],
    this.onSelectWordId,
    this.onSelectWord,
    this.onClearSelection,
    this.onDeletedSelectedWord,
    this.onChangeCenterWordId,
    this.onChangeCenterWord,
    this.mutationImpactCollector,
  }) : centerWordId = _resolveCenterWordId(
         centerWordId: centerWordId,
         centerWord: centerWord,
       );

  static String _resolveCenterWordId({
    required String? centerWordId,
    required Word? centerWord,
  }) {
    final normalizedCenterWordId = centerWordId?.trim();
    if (normalizedCenterWordId != null && normalizedCenterWordId.isNotEmpty) {
      return normalizedCenterWordId;
    }

    final normalizedCompatibilityId = centerWord?.id.trim();
    if (normalizedCompatibilityId != null &&
        normalizedCompatibilityId.isNotEmpty) {
      return normalizedCompatibilityId;
    }

    throw ArgumentError('WordGraphScreen requires centerWordId.');
  }

  @override
  State<WordGraphScreen> createState() => _WordGraphScreenState();
}

class _WordGraphScreenState extends State<WordGraphScreen> {
  final WordRepository _repository = WordRepository();
  final WordWriteService _wordWriteService = WordWriteService();
  final GraphBuilder _graphBuilder = const GraphBuilder();
  static const GraphLayoutMode _graphLayoutMode = GraphLayoutMode.forceDirected;
  static const GraphLayoutOptions _graphLayoutOptions = GraphLayoutOptions();
  static const int _defaultGraphMaxNodes = 30;

  /// 그래프 줌/팬 상태를 관리하는 컨트롤러
  final TransformationController _transformController =
      TransformationController();

  /// 현재 줌 배율(태그 표시/숨김 등에 사용)
  double _currentScale = 1.0;
  PeripheralNodeLodLevel _peripheralNodeLod =
      resolvePeripheralNodeLodForTesting(cameraScale: 1.0);

  /// 이 배율보다 작아지면 엣지 태그를 숨긴다(가독성/겹침 감소)
  static const double _labelVisibleScaleThreshold = 1.15;

  /// The graph center authority is the normalized id only.
  late String _centerWordId;

  /// Compatibility/local fallback carrier for places that still require a Word
  /// object. This is not the authoritative center id state.
  late Word _centerWord;
  GraphCenterWordDisplayItem? _centerWordDisplayItem;

  bool _isLoading = true;
  String? _errorMessage;
  GraphViewData? _graphViewData;
  WordGraphBaseCacheData? _baseGraphData;

  /// 중심 단어와 연결된 visible node fallback 목록
  final Map<String, GraphVisibleNode> _graphWordsById = {};
  final Map<String, GraphWordLabelDisplayItem> _graphWordLabelsById = {};
  final Map<String, WordGraphExpansionCacheData> _expansionDataBySourceId = {};
  final Set<String> _expandedDepthOneWordIds = <String>{};
  final Set<String> _expansionRequestsInFlight = <String>{};
  final Set<String> _fullyRevealedExpansionSourceIds = <String>{};
  final Set<String> _dbWideCollisionWordIdsForVisibleGraph = <String>{};
  final Map<String, Offset> _seedNodePositions = <String, Offset>{};
  bool _isCenterDepthOneFullyRevealed = false;
  int _collisionWordIdsRefreshSerial = 0;

  /// 사용자가 클릭(선택)한 주변 노드 id
  /// - 같은 노드를 다시 클릭하면 이동(push)하는 트리거로 사용
  String? _selectedWordId;
  WordDetailLikeDisplayItem? _selectedWordPreviewItem;
  String? _selectedWordPreviewItemWordId;
  int _selectedWordPreviewRequestSerial = 0;

  /// 상대 단어 id 기준으로 관계(엣지) 메타를 보관한다.
  /// - 여러 관계가 있을 수 있으나, 현재는 “표시용 1개”만 선택(마지막으로 덮어씀)
  final Map<String, List<WordRelationEdgeInfo>> _edgeInfosByEdgeId = {};
  final Map<String, Set<String>> _adjacentNodeIdsByNodeId = {};
  bool _pendingCenterFocusAfterCenterChange = false;
  bool _didSchedulePendingCenterFocus = false;
  String? _pendingCenterFocusWordId;
  String? _pendingLocalRetargetCenterFocusWordId;
  bool _didSchedulePendingLocalRetargetCenterFocus = false;
  bool _suppressBackgroundTapClear = false;
  bool _isViewportInteracting = false;
  DateTime? _lastViewportInteractionAt;
  Size? _appliedViewportSize;
  Size? _pendingViewportSize;
  Offset? _pendingLayoutCenter;
  bool _isViewportCameraSyncScheduled = false;

  String? _nullIfBlank(String? value) {
    final trimmed = (value ?? '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _updateCurrentScale(double cameraScale) {
    final safeScale = _safeCameraScale(cameraScale);
    final nextLod = resolvePeripheralNodeLodForTesting(
      cameraScale: safeScale,
      currentLod: _peripheralNodeLod,
    );
    if (safeScale == _currentScale && nextLod == _peripheralNodeLod) {
      return;
    }

    setState(() {
      _currentScale = safeScale;
      _peripheralNodeLod = nextLod;
    });
  }

  /// Collapse the external graph seed to the only trusted bootstrap field.
  String _centerSeedIdOf(String centerWordId) => centerWordId.trim();

  Word _centerSeedWordFrom(String centerWordId) {
    return Word(id: _centerSeedIdOf(centerWordId));
  }

  Word _centerWordCompatibilityFallback() {
    final centerWord = _centerWord;
    return centerWord.id.trim() == _centerWordId
        ? centerWord
        : Word(id: _centerWordId);
  }

  Word _centerWordBuilderInput() {
    return Word(id: _centerWordId);
  }

  @override
  void initState() {
    super.initState();
    _centerWordId = _centerSeedIdOf(widget.centerWordId);
    _centerWord = _centerSeedWordFrom(_centerWordId);
    _selectedWordId = widget.selectedWordId;
    _loadConnectedWords();
  }

  @override
  void didUpdateWidget(covariant WordGraphScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextCenterSeedId = _centerSeedIdOf(widget.centerWordId);
    final oldCenterSeedId = _centerSeedIdOf(oldWidget.centerWordId);
    final didCenterWordChange = nextCenterSeedId != oldCenterSeedId;

    if (didCenterWordChange) {
      _retargetCenterLocally(
        nextCenterSeedId,
        selectedWordId: widget.selectedWordId,
      );
      return;
    }

    if (widget.selectedWordId != oldWidget.selectedWordId) {
      setState(() {
        final graphViewData = _graphViewData;
        _selectedWordId = graphViewData == null
            ? widget.selectedWordId
            : _normalizedSelectedWordIdForViewData(
                graphViewData,
                widget.selectedWordId,
              );
        _syncSelectedWordPreviewForCurrentSelection();
      });
    }
  }

  void _retargetCenterLocally(
    String centerWordId, {
    required String? selectedWordId,
    bool ensureCenterVisibleAfterRetarget = false,
  }) {
    final nextCenterWordId = _centerSeedIdOf(centerWordId);
    WordGraphDataCache.clearExpansionsForCenter(_centerWordId);
    _resetExpansionState(clearSeedPositions: true);
    setState(() {
      _centerWordId = nextCenterWordId;
      _centerWord = _centerSeedWordFrom(nextCenterWordId);
      _centerWordDisplayItem = null;
      _selectedWordId = selectedWordId;
      _resetSelectedWordPreviewState();
      _isLoading = true;
      _errorMessage = null;
      _graphViewData = null;
      _baseGraphData = null;
      _pendingCenterFocusAfterCenterChange = true;
      _pendingCenterFocusWordId = nextCenterWordId;
      _pendingLocalRetargetCenterFocusWordId = ensureCenterVisibleAfterRetarget
          ? nextCenterWordId
          : null;
      _didSchedulePendingLocalRetargetCenterFocus = false;
    });
    _loadConnectedWords();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _applyGraphData({
    required GraphViewData viewData,
    required List<Word> words,
    required List<GraphWordLabelDisplayItem> wordLabels,
    required List<WordRelationEdgeInfo> edges,
  }) {
    final visibleNodesById = <String, GraphVisibleNode>{
      _centerWordId: _visibleNodeForWord(_centerWordCompatibilityFallback()),
      for (final word in words)
        if (word.id.trim().isNotEmpty)
          word.id.trim(): _visibleNodeForWord(word),
    };
    final labelsById = <String, GraphWordLabelDisplayItem>{
      for (final labelDisplay in wordLabels)
        if (labelDisplay.wordId.trim().isNotEmpty)
          labelDisplay.wordId.trim(): labelDisplay,
    };

    _graphViewData = viewData;
    _graphWordsById
      ..clear()
      ..addAll(visibleNodesById);
    _graphWordLabelsById
      ..clear()
      ..addAll(labelsById);
    _selectedWordId = _resolvedSelectedWordIdForViewData(viewData);
    _syncSelectedWordPreviewForCurrentSelection();

    _edgeInfosByEdgeId.clear();
    _adjacentNodeIdsByNodeId.clear();
    for (final node in viewData.nodes) {
      _adjacentNodeIdsByNodeId.putIfAbsent(node.id, () => <String>{});
    }
    for (final edge in viewData.edges) {
      _adjacentNodeIdsByNodeId
          .putIfAbsent(edge.sourceId, () => <String>{})
          .add(edge.targetId);
      _adjacentNodeIdsByNodeId
          .putIfAbsent(edge.targetId, () => <String>{})
          .add(edge.sourceId);
    }
    for (final edgeInfo in edges) {
      final edgeId = _edgeIdForRelationInfo(edgeInfo);
      _edgeInfosByEdgeId
          .putIfAbsent(edgeId, () => <WordRelationEdgeInfo>[])
          .add(edgeInfo);
    }

    _errorMessage = null;
    _isLoading = false;
    _scheduleVisibleCollisionWordIdRefresh();
  }

  GraphVisibleNode _visibleNodeForWord(Word word) {
    return GraphVisibleNode(
      wordId: word.id.trim(),
      fallbackSpelling: (word.spelling1 ?? '').trim(),
      fallbackStrongNumber: (word.strongNumber ?? '').trim(),
      fallbackTransliteration: (word.transliteration1 ?? '').trim(),
    );
  }

  void _scheduleVisibleCollisionWordIdRefresh() {
    final viewData = _graphViewData;
    if (viewData == null) {
      _collisionWordIdsRefreshSerial++;
      _dbWideCollisionWordIdsForVisibleGraph.clear();
      return;
    }

    final visibleWordIds = viewData.nodes
        .map((node) => node.id.trim())
        .where(
          (nodeId) => nodeId.isNotEmpty && _graphWordsById.containsKey(nodeId),
        )
        .toSet()
        .toList(growable: false);
    final requestSerial = ++_collisionWordIdsRefreshSerial;

    if (visibleWordIds.isEmpty) {
      _dbWideCollisionWordIdsForVisibleGraph.clear();
      return;
    }

    unawaited(
      _refreshVisibleCollisionWordIds(
        expectedCenterWordId: _centerWordId,
        visibleWordIds: visibleWordIds,
        requestSerial: requestSerial,
      ),
    );
  }

  Future<void> _refreshVisibleCollisionWordIds({
    required String expectedCenterWordId,
    required List<String> visibleWordIds,
    required int requestSerial,
  }) async {
    final collisionWordIds = await _repository
        .findWordIdsInDbWideLanguageSpellingTransliterationCollisionGroups(
          visibleWordIds,
        );

    if (!mounted) return;
    if (_centerWordId != expectedCenterWordId) return;
    if (requestSerial != _collisionWordIdsRefreshSerial) return;
    if (_sameStringSets(
      _dbWideCollisionWordIdsForVisibleGraph,
      collisionWordIds,
    )) {
      return;
    }

    setState(() {
      _dbWideCollisionWordIdsForVisibleGraph
        ..clear()
        ..addAll(collisionWordIds);
    });
  }

  bool _sameStringSets(Set<String> left, Set<String> right) {
    if (identical(left, right)) {
      return true;
    }
    if (left.length != right.length) {
      return false;
    }
    return left.containsAll(right);
  }

  GraphWordLabelDisplayItem _labelDisplayForGraphNode(GraphNode graphNode) {
    final wordId = graphNode.wordId.trim();
    final labelDisplay = _graphWordLabelsById[wordId];
    if (labelDisplay != null) {
      return labelDisplay;
    }

    final visibleNode = _graphWordsById[wordId];
    final representativeSpelling = graphNode.label.trim().isNotEmpty
        ? graphNode.label
        : (visibleNode?.fallbackDisplayName ?? '');
    return GraphWordLabelDisplayItem(
      wordId: wordId,
      representativeSpelling: representativeSpelling,
      representativeTransliteration:
          visibleNode?.fallbackTransliteration.trim() ?? '',
      displayStrongNumber: visibleNode?.fallbackStrongNumber.trim() ?? '',
      language: '',
      primaryMeaning: '',
    );
  }

  String? _normalizedSelectedWordIdForViewData(
    GraphViewData viewData,
    String? candidateWordId,
  ) {
    final normalizedWordId = (candidateWordId ?? '').trim();
    if (normalizedWordId.isEmpty) {
      return null;
    }

    if (normalizedWordId == viewData.centerNodeId) {
      return viewData.centerNodeId;
    }

    return viewData.nodeById(normalizedWordId) == null
        ? null
        : normalizedWordId;
  }

  String? _resolvedSelectedWordIdForViewData(GraphViewData viewData) {
    final localSelectedWordId = _normalizedSelectedWordIdForViewData(
      viewData,
      _selectedWordId,
    );
    if (_selectedWordId == null || localSelectedWordId != null) {
      return localSelectedWordId;
    }

    return _normalizedSelectedWordIdForViewData(
      viewData,
      widget.selectedWordId,
    );
  }

  List<GraphNode> _peripheralNodesForViewData(GraphViewData viewData) {
    return viewData.nodes
        .where((node) => node.id != viewData.centerNodeId)
        .toList(growable: false);
  }

  bool _shouldUseCenterDepthOneMore() {
    final baseGraphData = _baseGraphData;
    if (baseGraphData == null) {
      return false;
    }

    return baseGraphData.connectedWords.length > _centerDepthOneSoftLimit;
  }

  int _effectiveGraphMaxNodes() {
    final shouldExpandMaxNodes =
        _isCenterDepthOneFullyRevealed ||
        _fullyRevealedExpansionSourceIds.isNotEmpty;
    if (!shouldExpandMaxNodes) {
      return _defaultGraphMaxNodes;
    }

    final potentialNodeIds = <String>{_centerWordId};
    final baseGraphData = _baseGraphData;
    if (baseGraphData != null) {
      for (final word in baseGraphData.connectedWords) {
        potentialNodeIds.add(word.wordId);
      }
    }

    var potentialPlaceholderCount = 0;
    if (!_isCenterDepthOneFullyRevealed && _shouldUseCenterDepthOneMore()) {
      potentialPlaceholderCount++;
    }
    for (final entry in _expansionDataBySourceId.entries) {
      final sourceWordId = entry.key.trim();
      if (sourceWordId.isEmpty) {
        continue;
      }

      for (final word in entry.value.connectedWords) {
        potentialNodeIds.add(word.wordId);
      }

      if (!_fullyRevealedExpansionSourceIds.contains(sourceWordId)) {
        potentialPlaceholderCount++;
      }
    }

    return max(
      _defaultGraphMaxNodes,
      potentialNodeIds.length + potentialPlaceholderCount,
    );
  }

  GraphBuildOptions _graphBuildOptions() {
    return GraphBuildOptions(
      centerWordId: _centerWordId,
      maxDepth: 2,
      maxNodes: _effectiveGraphMaxNodes(),
      layoutMode: _graphLayoutMode,
    );
  }

  GraphVisibleDataBuildResult _buildGraphData() {
    final baseGraphData = _baseGraphData;
    if (baseGraphData == null) {
      throw StateError('Base graph data is not loaded for $_centerWordId.');
    }

    return _graphBuilder.buildMergedVisibleGraphData(
      options: _graphBuildOptions(),
      centerWord: _centerWordBuilderInput(),
      baseWords: baseGraphData.connectedWords,
      wordLabels: baseGraphData.wordLabels,
      baseRelationEdges: baseGraphData.relationEdges,
      expansionDataBySourceId: _expansionDataBySourceId,
      fullyRevealedExpansionSourceIds: _fullyRevealedExpansionSourceIds,
      centerDepthOneSoftLimit: _centerDepthOneSoftLimit,
      fullyRevealCenterDepthOne: _isCenterDepthOneFullyRevealed,
    );
  }

  void _rebuildGraphData() {
    final buildResult = _buildGraphData();
    _applyGraphData(
      viewData: buildResult.viewData,
      words: buildResult.connectedWords,
      wordLabels: buildResult.wordLabels,
      edges: buildResult.relationEdges,
    );
  }

  void _resetExpansionState({bool clearSeedPositions = false}) {
    _expansionDataBySourceId.clear();
    _expandedDepthOneWordIds.clear();
    _expansionRequestsInFlight.clear();
    _fullyRevealedExpansionSourceIds.clear();
    _collisionWordIdsRefreshSerial++;
    _dbWideCollisionWordIdsForVisibleGraph.clear();
    _isCenterDepthOneFullyRevealed = false;
    if (clearSeedPositions) {
      _seedNodePositions.clear();
    }
  }

  Future<({Word word, GraphCenterWordDisplayItem displayItem})>
  _loadResolvedCenterPayload(String centerWordId) async {
    final centerWordMap = await _repository
        .getWordMapByIdForGraphCenterSingleWord(centerWordId);
    if (centerWordMap == null) {
      throw StateError('Graph center word not found: $centerWordId');
    }

    final centerDisplayItem = await _repository
        .getGraphCenterWordDisplayItemByIdForGraphCenterSingleWord(
          centerWordId,
        );
    if (centerDisplayItem == null) {
      throw StateError('Graph center display item not found: $centerWordId');
    }

    return (word: Word.fromMap(centerWordMap), displayItem: centerDisplayItem);
  }

  Future<void> _loadConnectedWords() async {
    final requestedCenterWordId = _centerWordId;
    _resetExpansionState(clearSeedPositions: true);

    final cachedBaseGraph = WordGraphDataCache.getBaseGraph(
      centerWordId: requestedCenterWordId,
    );

    try {
      final resolvedCenterPayload = await _loadResolvedCenterPayload(
        requestedCenterWordId,
      );
      final baseGraphData =
          cachedBaseGraph ??
          await (() async {
            final visibleGraphData = await _repository
                .getVisibleGraphDataForGraph(requestedCenterWordId);
            final words = visibleGraphData.connectedWords;
            final wordLabels = visibleGraphData.wordLabels;
            final edges = visibleGraphData.relationEdges;
            final loadedBaseGraphData = (
              connectedWords: List<GraphVisibleWord>.unmodifiable(words),
              wordLabels: List<GraphWordLabelDisplayItem>.unmodifiable(
                wordLabels,
              ),
              relationEdges: List<WordRelationEdgeInfo>.unmodifiable(edges),
            );
            WordGraphDataCache.putBaseGraph(
              centerWordId: requestedCenterWordId,
              connectedWords: words,
              wordLabels: wordLabels,
              relationEdges: edges,
            );
            return loadedBaseGraphData;
          })();

      if (!mounted) return;
      if (_centerWordId != requestedCenterWordId) {
        return;
      }
      setState(() {
        _centerWord = resolvedCenterPayload.word;
        _centerWordDisplayItem = resolvedCenterPayload.displayItem;
        _baseGraphData = baseGraphData;
        _rebuildGraphData();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '연결 단어 로딩 실패: $e';
        _isLoading = false;
        _graphViewData = null;
        _centerWordDisplayItem = null;
        _pendingCenterFocusAfterCenterChange = false;
        _pendingCenterFocusWordId = null;
        _pendingLocalRetargetCenterFocusWordId = null;
        _didSchedulePendingLocalRetargetCenterFocus = false;
      });
    }
  }

  Future<void> _refreshConnectedWordsPreservingState() async {
    final requestedCenterWordId = _centerWordId;
    final cameraTransform = Matrix4.copy(_transformController.value);
    final cameraScale = _currentScale;
    final selectedWordId = _selectedWordId;
    final expandedSourceIds = Set<String>.from(_expandedDepthOneWordIds);
    final fullyRevealedSourceIds = Set<String>.from(
      _fullyRevealedExpansionSourceIds,
    );
    final wasCenterDepthOneFullyRevealed = _isCenterDepthOneFullyRevealed;
    final seedNodePositions = Map<String, Offset>.from(_seedNodePositions);

    try {
      final resolvedCenterPayload = await _loadResolvedCenterPayload(
        requestedCenterWordId,
      );
      final visibleGraphData = await _repository.getVisibleGraphDataForGraph(
        requestedCenterWordId,
      );
      final baseGraphData = (
        connectedWords: List<GraphVisibleWord>.unmodifiable(
          visibleGraphData.connectedWords,
        ),
        wordLabels: List<GraphWordLabelDisplayItem>.unmodifiable(
          visibleGraphData.wordLabels,
        ),
        relationEdges: List<WordRelationEdgeInfo>.unmodifiable(
          visibleGraphData.relationEdges,
        ),
      );
      WordGraphDataCache.putBaseGraph(
        centerWordId: requestedCenterWordId,
        connectedWords: baseGraphData.connectedWords,
        wordLabels: baseGraphData.wordLabels,
        relationEdges: baseGraphData.relationEdges,
      );

      final currentDepthOneWordIds = baseGraphData.connectedWords
          .map((word) => word.wordId.trim())
          .where((wordId) => wordId.isNotEmpty)
          .toSet();
      final refreshedExpansionData = <String, WordGraphExpansionCacheData>{};
      for (final sourceWordId in expandedSourceIds.intersection(
        currentDepthOneWordIds,
      )) {
        final expansionGraphData = await _repository
            .getVisibleGraphDataForGraph(sourceWordId);
        final expansionData = (
          connectedWords: List<GraphVisibleWord>.unmodifiable(
            expansionGraphData.connectedWords,
          ),
          wordLabels: List<GraphWordLabelDisplayItem>.unmodifiable(
            expansionGraphData.wordLabels,
          ),
          relationEdges: List<WordRelationEdgeInfo>.unmodifiable(
            expansionGraphData.relationEdges,
          ),
        );
        refreshedExpansionData[sourceWordId] = expansionData;
        WordGraphDataCache.putExpansion(
          centerWordId: requestedCenterWordId,
          sourceWordId: sourceWordId,
          connectedWords: expansionData.connectedWords,
          wordLabels: expansionData.wordLabels,
          relationEdges: expansionData.relationEdges,
        );
      }

      if (!mounted || _centerWordId != requestedCenterWordId) {
        return;
      }

      setState(() {
        _centerWord = resolvedCenterPayload.word;
        _centerWordDisplayItem = resolvedCenterPayload.displayItem;
        _baseGraphData = baseGraphData;
        _selectedWordId = selectedWordId;
        _expansionDataBySourceId
          ..clear()
          ..addAll(refreshedExpansionData);
        _expandedDepthOneWordIds
          ..clear()
          ..addAll(refreshedExpansionData.keys);
        _expansionRequestsInFlight.clear();
        _fullyRevealedExpansionSourceIds
          ..clear()
          ..addAll(
            fullyRevealedSourceIds.intersection(
              refreshedExpansionData.keys.toSet(),
            ),
          );
        _isCenterDepthOneFullyRevealed = wasCenterDepthOneFullyRevealed;
        _seedNodePositions
          ..clear()
          ..addAll(seedNodePositions);
        _currentScale = cameraScale;
        _rebuildGraphData();
      });
      _transformController.value = cameraTransform;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('그래프 갱신 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로딩
    if (_isLoading) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 에러
    if (_errorMessage != null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        final viewData = _graphViewData;
        if (viewData == null) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: Center(
              child: Text(
                '?곌껐???⑥뼱媛 ?놁뒿?덈떎.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );
        }
        final centerDisplayItem = _centerWordDisplayItem;
        if (centerDisplayItem == null) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final peripheralNodes = _peripheralNodesForViewData(viewData);
        final layout = _computeGraphLayout(viewportSize, viewData);
        _scheduleViewportCameraSync(layout);
        _scheduleConditionalCenterFocus(layout);
        _scheduleLocalRetargetCenterFocus(layout);
        final selectedEdgeIds = _selectedEdgeIds(_selectedWordId);
        final selectedRelationEntries = _selectedNodeRelationEntries(
          layout,
          selectedEdgeIds: selectedEdgeIds,
          selectedWordId: _selectedWordId,
        );

        // 노드 배치 순서와 동일한 순서로 엣지 색상/라벨 생성

        // 선택된 노드가 연결 노드 목록에서 몇 번째인지(없으면 null)
        final centerVisualState = _centerVisualState();

        return Scaffold(
          appBar: _buildAppBar(
            title: const Text('단어 그래프'),
            commands: [
              _GraphAppBarCommand(
                label: '전체보기',
                icon: Icons.fit_screen,
                onPressed: () => _fitToView(layout),
              ),
              _GraphAppBarCommand(
                label: '보기 초기화',
                icon: Icons.refresh,
                onPressed: () => _resetView(layout),
              ),
              _GraphAppBarCommand(
                label: '선택 노드 중앙 맞춤',
                icon: Icons.center_focus_strong,
                onPressed: _selectedNodeLayoutCenter(layout) == null
                    ? null
                    : () => _focusSelectedNode(layout),
              ),
              _GraphAppBarCommand(
                label: '관계 추가',
                icon: Icons.add_link,
                onPressed: _showAddRelationFlow,
              ),
              _GraphAppBarCommand(
                label: '선택 단어 삭제',
                icon: Icons.delete_outline,
                onPressed: _confirmDeleteSelectedWord,
              ),
              _GraphAppBarCommand(
                label: '단어 추가',
                icon: Icons.note_add,
                onPressed: _showCreateWordFlow,
              ),
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    _markViewportInteraction();
                    _handlePointerScroll(event);
                  }
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _handleBackgroundTap,
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    constrained: false,
                    minScale: 0.6,
                    maxScale: 3.5,
                    boundaryMargin: const EdgeInsets.all(2000),
                    panEnabled: true,
                    scaleEnabled: true,
                    onInteractionStart: (_) {
                      _isViewportInteracting = true;
                      _markViewportInteraction();
                    },
                    onInteractionUpdate: (_) {
                      final newScale = _transformController.value
                          .getMaxScaleOnAxis();
                      _updateCurrentScale(newScale);
                    },
                    onInteractionEnd: (_) {
                      _isViewportInteracting = false;
                      _markViewportInteraction();
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _handleBackgroundTap,
                      child: SizedBox(
                        width: layout.layoutSpaceSize.width,
                        height: layout.layoutSpaceSize.height,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            if (peripheralNodes.isNotEmpty)
                              AnimatedSwitcher(
                                duration: _visualStateAnimationDuration,
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeOutCubic,
                                child: SizedBox(
                                  key: ValueKey<String>(
                                    '${_selectedWordId ?? ''}:${viewData.nodes.length}:${viewData.edges.length}',
                                  ),
                                  width: layout.layoutSpaceSize.width,
                                  height: layout.layoutSpaceSize.height,
                                  child: CustomPaint(
                                    size: layout.layoutSpaceSize,
                                    painter: _GraphLinePainter(
                                      layout: layout,
                                      selectedWordId: _selectedWordId,
                                      selectedEdgeIds: selectedEdgeIds,
                                      actualPeripheralWordNodeIds:
                                          _peripheralNodesForViewData(viewData)
                                              .where(
                                                (node) =>
                                                    !node.isPlaceholderMoreNode,
                                              )
                                              .map((node) => node.id)
                                              .toSet(),
                                      showLabels: false,
                                      sceneScale: _currentScale,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              left: layout.centerBounds.left,
                              top: layout.centerBounds.top,
                              child: Transform.scale(
                                key: const ValueKey<String>(
                                  'graph-center-node-visual-scale',
                                ),
                                scale: _nodeLocalVisualScale(_currentScale),
                                alignment: Alignment.center,
                                transformHitTests: true,
                                child: GestureDetector(
                                  onTap: _handleCenterNodeTap,
                                  child: _buildCenterNode(
                                    centerDisplayItem,
                                    visualState: centerVisualState,
                                  ),
                                ),
                              ),
                            ),
                            ..._buildEdgeLabelWidgets(
                              layout,
                              selectedEdgeIds: selectedEdgeIds,
                              selectedWordId: _selectedWordId,
                            ),
                            ..._buildWordNodes(
                              layout,
                              viewData,
                              selectedWordId: _selectedWordId,
                            ),
                            if (peripheralNodes.isEmpty)
                              _buildEmptyStateBanner(
                                context,
                                layout: layout,
                                layoutSpaceSize: layout.layoutSpaceSize,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _buildSelectedNodeBottomRightOverlayGroup(
                context,
                relationEntries: selectedRelationEntries,
              ),
            ],
          ),
        );
      },
    );
  }

  /// 중앙(선택) 단어 노드
  PreferredSizeWidget _buildAppBar({
    Widget? title,
    List<_GraphAppBarCommand>? commands,
  }) {
    final graphCommands = commands ?? const <_GraphAppBarCommand>[];
    final isMobile = !isExplorerLargeScreenWidth(
      MediaQuery.sizeOf(context).width,
    );
    final mergedActions = isMobile
        ? <Widget>[
            ...widget.appBarActionPrefix,
            IconButton(
              key: const Key('mobile-global-search-action'),
              tooltip: '검색',
              icon: const Icon(Icons.search),
              onPressed: _openMobileSearch,
            ),
            if (graphCommands.isNotEmpty)
              PopupMenuButton<int>(
                key: const Key('mobile-graph-command-overflow'),
                onSelected: (index) => graphCommands[index].onPressed?.call(),
                itemBuilder: (context) =>
                    List.generate(graphCommands.length, (index) {
                      final command = graphCommands[index];
                      return PopupMenuItem<int>(
                        value: index,
                        enabled: command.onPressed != null,
                        child: Row(
                          children: [
                            Icon(command.icon),
                            const SizedBox(width: 12),
                            Text(command.label),
                          ],
                        ),
                      );
                    }),
              ),
          ]
        : <Widget>[
            ...widget.appBarActionPrefix,
            ...graphCommands.map((command) => command.buildIconButton()),
          ];

    return AppBar(
      title: title ?? const Text('단어 그래프'),
      actions: mergedActions.isEmpty ? null : mergedActions,
    );
  }

  Future<void> _openMobileSearch() async {
    final selection = await Navigator.push<WordSearchSelection>(
      context,
      MaterialPageRoute(builder: (_) => const MobileWordSearchScreen()),
    );
    if (!mounted || selection == null) {
      return;
    }

    switch (selection.destination) {
      case WordSearchDestination.detail:
        await _openMobileSearchDetail(selection.wordId);
      case WordSearchDestination.graph:
        await _openMobileSearchGraph(selection.wordId);
    }
  }

  Future<void> _openMobileSearchDetail(String wordId) async {
    final detailWord = await _repository
        .getWordDetailLikeDisplayItemByIdForDetailScreen(wordId);
    if (!mounted) return;
    if (detailWord == null) {
      _showMobileSearchNavigationUnavailableSnackBar();
      return;
    }

    final collector =
        widget.mutationImpactCollector ?? WordMutationImpactCollector();
    final checkpoint = collector.checkpoint;
    final result = await Navigator.push<WordDetailRouteResult>(
      context,
      MaterialPageRoute(
        builder: (_) => WordDetailScreen(
          wordId: wordId,
          initialDisplayItem: detailWord,
          mutationImpactCollector: collector,
        ),
      ),
    );
    if (!mounted) return;
    await _handleMobileSearchTargetImpact(
      mutationImpactSince(
        collector: collector,
        checkpoint: checkpoint,
        routeResult: result,
      ),
    );
  }

  Future<void> _openMobileSearchGraph(String wordId) async {
    final centerWordExists = await _repository.wordExistsForGraphNavigation(
      wordId,
    );
    if (!mounted) return;
    if (!centerWordExists) {
      _showMobileSearchNavigationUnavailableSnackBar();
      return;
    }

    final collector =
        widget.mutationImpactCollector ?? WordMutationImpactCollector();
    final checkpoint = collector.checkpoint;
    final result = await Navigator.push<WordDetailRouteResult>(
      context,
      MaterialPageRoute(
        builder: (_) => WordGraphScreen(
          centerWordId: wordId,
          mutationImpactCollector: collector,
        ),
      ),
    );
    if (!mounted) return;
    await _handleMobileSearchTargetImpact(
      mutationImpactSince(
        collector: collector,
        checkpoint: checkpoint,
        routeResult: result,
      ),
    );
  }

  Future<void> _handleMobileSearchTargetImpact(
    WordMutationImpact impact,
  ) async {
    if (impact.isEmpty) {
      return;
    }

    final activeWordIds = _graphViewData?.nodes.map((node) => node.id).toSet();
    if (activeWordIds == null) {
      return;
    }
    final decision = resolveGraphMutationOriginDecision(
      impact: impact,
      centerWordId: _centerWordId,
      selectedWordId: _selectedWordId,
      activeWordIds: activeWordIds,
    );
    if (decision.shouldClose) {
      Navigator.pop(context, WordDetailDeletedResult(wordId: _centerWordId));
      return;
    }

    if (decision.shouldClearSelection) {
      _setSelectedWordId(null);
      widget.onClearSelection?.call();
    }

    if (!decision.shouldRefresh) {
      return;
    }

    WordGraphDataCache.clear();
    await _refreshConnectedWordsPreservingState();
  }

  void _showMobileSearchNavigationUnavailableSnackBar() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('단어 정보를 찾을 수 없습니다.')));
  }

  Widget _buildSelectedNodeBottomRightOverlayGroup(
    BuildContext context, {
    required List<_SelectedNodeRelationEntry> relationEntries,
  }) {
    final preview = _buildSelectedWordPreview(context);
    final relationLauncher = _buildSelectedNodeRelationLauncherOverlay(
      context,
      relationEntries: relationEntries,
    );
    if (preview == null && relationLauncher == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      minimum: const EdgeInsets.all(_selectedNodeRelationOverlayInset),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ?preview,
            if (preview != null && relationLauncher != null)
              const SizedBox(height: _selectedNodePreviewLauncherGap),
            ?relationLauncher,
          ],
        ),
      ),
    );
  }

  Widget? _buildSelectedNodeRelationLauncherOverlay(
    BuildContext context, {
    required List<_SelectedNodeRelationEntry> relationEntries,
  }) {
    if (relationEntries.isEmpty) {
      return null;
    }

    final launcher = relationEntries.length == 1
        ? Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () {
                unawaited(
                  _openSelectedNodeRelationEntry(relationEntries.first),
                );
              },
              child: _buildSelectedNodeRelationLauncher(
                context,
                relationCount: relationEntries.length,
                showMenuIndicator: false,
              ),
            ),
          )
        : PopupMenuButton<int>(
            tooltip: '관계 보기',
            onOpened: _temporarilySuppressBackgroundTapClear,
            onSelected: (index) {
              unawaited(_openSelectedNodeRelationEntry(relationEntries[index]));
            },
            itemBuilder: (context) {
              return List<PopupMenuEntry<int>>.generate(
                relationEntries.length,
                (index) {
                  final entry = relationEntries[index];
                  return PopupMenuItem<int>(
                    value: index,
                    child: SizedBox(
                      width: 240,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedNodeRelationEntryTitle(entry),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedNodeRelationEntrySubtitle(entry),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            child: _buildSelectedNodeRelationLauncher(
              context,
              relationCount: relationEntries.length,
              showMenuIndicator: true,
            ),
          );

    final edgeSignature = relationEntries
        .map((entry) => entry.edgeId)
        .join(':');

    return KeyedSubtree(
      key: const Key('selected-node-relation-launcher'),
      child: AnimatedSwitcher(
        duration: _visualStateAnimationDuration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        child: KeyedSubtree(
          key: ValueKey<String>(edgeSignature),
          child: launcher,
        ),
      ),
    );
  }

  Widget? _buildSelectedWordPreview(BuildContext context) {
    if (isExplorerLargeScreenWidth(MediaQuery.sizeOf(context).width)) {
      return null;
    }

    final selectedWordId = (_selectedWordId ?? '').trim();
    final previewItem = _selectedWordPreviewItem;
    if (selectedWordId.isEmpty ||
        previewItem == null ||
        _selectedWordPreviewItemWordId != selectedWordId) {
      return null;
    }

    final strong = _nullIfBlank(previewItem.displayStrongNumber);
    final spelling =
        _nullIfBlank(previewItem.representativeSpelling) ?? selectedWordId;
    final transliteration = _firstNonBlank(previewItem.transliterations);
    final meaning = _firstNonBlank(previewItem.meanings);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _selectedNodePreviewMaxWidth),
      child: Material(
        key: const Key('mobile-selected-node-preview'),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        elevation: 4,
        shadowColor: Theme.of(context).shadowColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            unawaited(_openSelectedWordPreviewDetail());
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (strong != null)
                  Text(strong, style: Theme.of(context).textTheme.labelMedium),
                Text(
                  spelling,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (transliteration != null)
                  Text(
                    transliteration,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                if (meaning != null)
                  Text(
                    meaning,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _firstNonBlank(Iterable<String> values) {
    for (final value in values) {
      final normalized = _nullIfBlank(value);
      if (normalized != null) {
        return normalized;
      }
    }
    return null;
  }

  void _resetSelectedWordPreviewState() {
    _selectedWordPreviewRequestSerial++;
    _selectedWordPreviewItem = null;
    _selectedWordPreviewItemWordId = null;
  }

  void _syncSelectedWordPreviewForCurrentSelection() {
    _resetSelectedWordPreviewState();
    final selectedWordId = (_selectedWordId ?? '').trim();
    if (selectedWordId.isEmpty) {
      return;
    }

    final requestSerial = _selectedWordPreviewRequestSerial;
    unawaited(
      _loadSelectedWordPreview(
        selectedWordId: selectedWordId,
        requestSerial: requestSerial,
      ),
    );
  }

  Future<void> _loadSelectedWordPreview({
    required String selectedWordId,
    required int requestSerial,
  }) async {
    WordDetailLikeDisplayItem? previewItem;
    try {
      previewItem = await _repository
          .getWordDetailLikeDisplayItemByIdForDetailScreen(selectedWordId);
    } catch (_) {
      previewItem = null;
    }

    if (!mounted ||
        requestSerial != _selectedWordPreviewRequestSerial ||
        selectedWordId != (_selectedWordId ?? '').trim()) {
      return;
    }

    setState(() {
      _selectedWordPreviewItem = previewItem;
      _selectedWordPreviewItemWordId = previewItem == null
          ? null
          : selectedWordId;
    });
  }

  void _setSelectedWordId(String? wordId) {
    final normalizedWordId = (wordId ?? '').trim();
    setState(() {
      _selectedWordId = normalizedWordId.isEmpty ? null : normalizedWordId;
      _syncSelectedWordPreviewForCurrentSelection();
    });
  }

  Future<void> _openSelectedWordPreviewDetail() async {
    _temporarilySuppressBackgroundTapClear();
    final selectedWordId = (_selectedWordId ?? '').trim();
    final previewItem = _selectedWordPreviewItem;
    if (selectedWordId.isEmpty ||
        previewItem == null ||
        _selectedWordPreviewItemWordId != selectedWordId) {
      return;
    }

    final collector = widget.mutationImpactCollector;
    final checkpoint = collector?.checkpoint;
    final detailResult = await Navigator.push<WordDetailRouteResult>(
      context,
      MaterialPageRoute(
        builder: (_) => WordDetailScreen(
          wordId: selectedWordId,
          initialDisplayItem: previewItem,
          mutationImpactCollector: widget.mutationImpactCollector,
        ),
      ),
    );
    if (!mounted) return;

    if (collector != null && checkpoint != null) {
      await _handleMobileSearchTargetImpact(
        mutationImpactSince(
          collector: collector,
          checkpoint: checkpoint,
          routeResult: detailResult,
        ),
      );
      return;
    }

    if (detailResult is WordDetailDeletedResult) {
      final deletedWordId = detailResult.wordId.trim();
      if (deletedWordId == _centerWordId) {
        Navigator.pop(context, detailResult);
        return;
      }
      if ((_selectedWordId ?? '').trim() == deletedWordId) {
        _setSelectedWordId(null);
        widget.onClearSelection?.call();
      }
    }

    WordGraphDataCache.clear();
    await _loadConnectedWords();
  }

  Widget _buildSelectedNodeRelationLauncher(
    BuildContext context, {
    required int relationCount,
    required bool showMenuIndicator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = relationCount > 1 ? '관계 보기 ($relationCount)' : '관계 보기';

    return Ink(
      decoration: ShapeDecoration(
        color: colorScheme.surfaceContainerHigh,
        shape: StadiumBorder(
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: _selectedNodeRelationOverlayMinHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_link, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (showMenuIndicator) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateBanner(
    BuildContext context, {
    required _GraphLayoutData layout,
    required Size layoutSpaceSize,
  }) {
    const double verticalInset = 20.0;
    const double horizontalInset = 16.0;
    const double gapFromCenterNode = 12.0;
    const double minBannerHeight = 44.0;

    final availableTopSpace =
        layout.centerBounds.top - verticalInset - gapFromCenterNode;
    final availableBottomSpace =
        layoutSpaceSize.height -
        layout.centerBounds.bottom -
        verticalInset -
        gapFromCenterNode;

    Alignment alignment;
    EdgeInsets padding;

    if (availableTopSpace >= minBannerHeight) {
      alignment = Alignment.topCenter;
      padding = const EdgeInsets.only(
        top: verticalInset,
        left: horizontalInset,
        right: horizontalInset,
      );
    } else if (availableBottomSpace >= minBannerHeight) {
      alignment = Alignment.bottomCenter;
      padding = const EdgeInsets.only(
        left: horizontalInset,
        right: horizontalInset,
        bottom: verticalInset,
      );
    } else {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: padding,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                '연결된 단어가 없습니다.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _blendColor(Color color, Color target, double amount) {
    return Color.lerp(color, target, amount) ?? color;
  }

  Color _surfaceTint(Color baseColor, double alpha) {
    return Color.alphaBlend(baseColor.withValues(alpha: alpha), Colors.white);
  }

  String _wordIdPrefix(String wordId) {
    final normalized = wordId.trim().toUpperCase();
    if (normalized.isEmpty) return '';
    return normalized.substring(0, 1);
  }

  String _languageGroupFromWordId(String wordId) {
    switch (_wordIdPrefix(wordId)) {
      case 'H':
        return _languageGroupHebrewAramaic;
      case 'G':
        return _languageGroupGreek;
      case 'L':
        return _languageGroupLatin;
      case 'E':
        return _languageGroupEnglish;
      case 'U':
        return _languageGroupOther;
      default:
        return _languageGroupFallback;
    }
  }

  Color _colorForLanguageGroup(String languageGroup) {
    switch (languageGroup) {
      case _languageGroupHebrewAramaic:
        return _languageGroupHebrewAramaicColor;
      case _languageGroupGreek:
        return _languageGroupGreekColor;
      case _languageGroupLatin:
        return _languageGroupLatinColor;
      case _languageGroupEnglish:
        return _languageGroupEnglishColor;
      case _languageGroupOther:
        return _languageGroupOtherColor;
      default:
        return _languageGroupFallbackColor;
    }
  }

  Color _colorForWordLanguageGroup(String wordId) {
    return _colorForLanguageGroup(_languageGroupFromWordId(wordId));
  }

  _GraphVisualState _centerVisualState() {
    return _visualStateForNodeId(_centerWordId);
  }

  bool _hasActivePeripheralSelection() {
    final selectedWordId = _selectedWordId;
    if (selectedWordId == null) {
      return false;
    }
    return selectedWordId != _centerWordId;
  }

  _GraphVisualState _visualStateForNodeId(String nodeId) {
    final selectedWordId = _selectedWordId;
    if (selectedWordId == null) {
      return _GraphVisualState.connected;
    }

    if (selectedWordId == nodeId) {
      return _GraphVisualState.selected;
    }

    final adjacentNodeIds = _adjacentNodeIdsByNodeId[selectedWordId];
    if (adjacentNodeIds != null && adjacentNodeIds.contains(nodeId)) {
      return _GraphVisualState.connected;
    }

    return _GraphVisualState.dimmed;
  }

  double _nodeOpacityForState(
    _GraphVisualState visualState, {
    required bool isCenter,
  }) {
    switch (visualState) {
      case _GraphVisualState.selected:
        return 1.0;
      case _GraphVisualState.connected:
        return isCenter ? _connectedCenterOpacity : 1.0;
      case _GraphVisualState.dimmed:
        return _dimmedNodeOpacity;
    }
  }

  double _nodeTextOpacityForState(_GraphVisualState visualState) {
    switch (visualState) {
      case _GraphVisualState.selected:
      case _GraphVisualState.connected:
        return 1.0;
      case _GraphVisualState.dimmed:
        return _dimmedNodeTextOpacity;
    }
  }

  double _nodeSizeForDepth(int depth) {
    return depth >= 2 ? _depthTwoNodeSize : _depthOneNodeSize;
  }

  double _fillTintAlphaForDepth(int depth) {
    return depth >= 2
        ? _depthTwoNodeLanguageTintAlpha
        : _connectedNodeLanguageTintAlpha;
  }

  bool get _hasSelectWordCallback =>
      widget.onSelectWordId != null || widget.onSelectWord != null;

  void _notifySelectedWord(Word word) {
    final selectedWordId = word.id.trim();
    final onSelectWordId = widget.onSelectWordId;
    if (onSelectWordId != null) {
      onSelectWordId(selectedWordId);
      return;
    }

    widget.onSelectWord?.call(word);
  }

  void _dispatchCenterChange(Word word) {
    final centerWordId = word.id.trim();
    final onChangeCenterWordId = widget.onChangeCenterWordId;
    if (onChangeCenterWordId != null) {
      widget.onChangeCenterWord?.call(word);
      onChangeCenterWordId(centerWordId);
      return;
    }

    widget.onChangeCenterWord?.call(word);
  }

  void _handleCenterNodeTap() {
    _temporarilySuppressBackgroundTapClear();
    if (_selectedWordId != _centerWordId) {
      _setSelectedWordId(_centerWordId);
    }

    _notifySelectedWord(_centerWordCompatibilityFallback());
  }

  Future<void> _handleConnectedWordTap(Word word) async {
    _temporarilySuppressBackgroundTapClear();
    final isSameTap = _selectedWordId == word.id;

    if (!isSameTap) {
      _setSelectedWordId(word.id);
      _notifySelectedWord(word);
      unawaited(_expandDepthTwoForSelection(word));
      return;
    }

    if (widget.onChangeCenterWordId != null ||
        widget.onChangeCenterWord != null) {
      _dispatchCenterChange(word);
      return;
    }

    if (_hasSelectWordCallback) {
      _notifySelectedWord(word);
      return;
    }

    final collector = widget.mutationImpactCollector;
    final checkpoint = collector?.checkpoint;
    final graphResult = await Navigator.push<WordDetailRouteResult>(
      context,
      MaterialPageRoute(
        builder: (_) => WordGraphScreen(
          centerWordId: word.id,
          mutationImpactCollector: widget.mutationImpactCollector,
        ),
      ),
    );
    if (!mounted) return;

    if (collector != null && checkpoint != null) {
      await _handleMobileSearchTargetImpact(
        mutationImpactSince(
          collector: collector,
          checkpoint: checkpoint,
          routeResult: graphResult,
        ),
      );
      return;
    }

    if (graphResult is WordDetailDeletedResult) {
      final deletedWordId = graphResult.wordId.trim();
      if (_selectedWordId == deletedWordId) {
        _setSelectedWordId(null);
        widget.onClearSelection?.call();
      }
      WordGraphDataCache.clear();
      await _loadConnectedWords();
    }
  }

  void _handlePlaceholderMoreNodeTap(GraphNode node) {
    _temporarilySuppressBackgroundTapClear();
    if (_isCenterDepthOnePlaceholderNode(node)) {
      if (_isCenterDepthOneFullyRevealed) {
        return;
      }

      setState(() {
        _isCenterDepthOneFullyRevealed = true;
        _rebuildGraphData();
      });
      return;
    }

    final sourceWordId = _placeholderSourceWordId(node);
    if (sourceWordId == null ||
        _fullyRevealedExpansionSourceIds.contains(sourceWordId)) {
      return;
    }

    setState(() {
      _fullyRevealedExpansionSourceIds.add(sourceWordId);
      _rebuildGraphData();
    });
  }

  Future<void> _expandDepthTwoForSelection(Word word) async {
    final viewData = _graphViewData;
    final selectedNode = viewData?.nodeById(word.id);
    if (selectedNode == null ||
        selectedNode.isCenter ||
        selectedNode.depth != 1) {
      return;
    }
    if (_expandedDepthOneWordIds.contains(word.id) ||
        _expansionRequestsInFlight.contains(word.id)) {
      return;
    }

    final requestedCenterWordId = _centerWordId;
    _expansionRequestsInFlight.add(word.id);

    try {
      final cachedExpansion = WordGraphDataCache.getExpansion(
        centerWordId: _centerWordId,
        sourceWordId: word.id,
      );
      final expansionData =
          cachedExpansion ??
          await (() async {
            final visibleGraphData = await _repository
                .getVisibleGraphDataForGraph(word.id);
            WordGraphDataCache.putExpansion(
              centerWordId: _centerWordId,
              sourceWordId: word.id,
              connectedWords: visibleGraphData.connectedWords,
              wordLabels: visibleGraphData.wordLabels,
              relationEdges: visibleGraphData.relationEdges,
            );
            return (
              connectedWords: List<GraphVisibleWord>.unmodifiable(
                visibleGraphData.connectedWords,
              ),
              wordLabels: List<GraphWordLabelDisplayItem>.unmodifiable(
                visibleGraphData.wordLabels,
              ),
              relationEdges: List<WordRelationEdgeInfo>.unmodifiable(
                visibleGraphData.relationEdges,
              ),
            );
          })();

      if (!mounted) return;
      if (_centerWordId != requestedCenterWordId) {
        return;
      }

      setState(() {
        _expansionDataBySourceId[word.id] = expansionData;
        _expandedDepthOneWordIds.add(word.id);
        _rebuildGraphData();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('depth 2 확장 로드 실패: $e')));
    } finally {
      _expansionRequestsInFlight.remove(word.id);
    }
  }

  Widget _buildCenterNode(
    GraphCenterWordDisplayItem displayItem, {
    required _GraphVisualState visualState,
  }) {
    final language = displayItem.language.trim();
    final strongNumber = displayItem.displayStrongNumber.trim();
    final metadata = [
      if (language.isNotEmpty) language,
      if (strongNumber.isNotEmpty) strongNumber,
    ].join(' · ');
    final representativeSpelling = displayItem.representativeSpelling.trim();
    final spelling = representativeSpelling.isNotEmpty
        ? representativeSpelling
        : displayItem.wordId.trim();
    final transliteration = displayItem.representativeTransliteration.trim();
    final meaning = displayItem.primaryMeaning.trim();
    final languageTintColor = _colorForWordLanguageGroup(displayItem.wordId);
    final centerInnerColor = _surfaceTint(
      languageTintColor,
      _centerNodeLanguageTintFactor * 0.8,
    );
    final centerMidColor = _surfaceTint(
      languageTintColor,
      _centerNodeLanguageTintFactor * 0.92,
    );
    final centerOuterColor = _surfaceTint(
      languageTintColor,
      _centerNodeLanguageTintFactor,
    );
    final children = <Widget>[];

    void addNodeText(Widget child, {double gap = 6}) {
      if (children.isNotEmpty) {
        children.add(SizedBox(height: gap));
      }
      children.add(child);
    }

    if (metadata.isNotEmpty) {
      addNodeText(
        Text(
          metadata,
          key: ValueKey<String>(
            'graph-center-node-line:${displayItem.wordId}:metadata',
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11),
        ),
        gap: 4,
      );
    }

    if (spelling.isNotEmpty) {
      addNodeText(
        Text(
          spelling,
          key: ValueKey<String>(
            'graph-center-node-line:${displayItem.wordId}:spelling',
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (transliteration.isNotEmpty) {
      addNodeText(
        Text(
          transliteration,
          key: ValueKey<String>(
            'graph-center-node-line:${displayItem.wordId}:transliteration',
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        gap: 5,
      );
    }

    if (meaning.isNotEmpty) {
      addNodeText(
        Text(
          meaning,
          key: ValueKey<String>(
            'graph-center-node-line:${displayItem.wordId}:meaning',
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11),
        ),
        gap: 4,
      );
    }

    final bool isSelected = visualState == _GraphVisualState.selected;
    final bool hasPeripheralSelection = _hasActivePeripheralSelection();
    final backgroundOpacity = _nodeOpacityForState(visualState, isCenter: true);
    final textOpacity = _nodeTextOpacityForState(visualState);
    final effectiveScreenScale = _effectiveNodeScreenScale(_currentScale);
    final centerNodeBorderWidth =
        (isSelected ? _centerNodeBorderWidth : _centerNodeBorderWidth - 0.8) /
        effectiveScreenScale;
    final centerAccentColor =
        _blendColor(
          languageTintColor,
          Colors.black,
          isSelected ? 0.12 : 0.24,
        ).withValues(
          alpha: isSelected
              ? 0.38
              : hasPeripheralSelection
              ? 0.20
              : 0.16,
        );
    final centerAccentInset = isSelected
        ? _centerNodeSelectedAccentRingInset
        : _centerNodeAccentRingInset;
    final centerAccentWidth = isSelected
        ? _centerNodeSelectedAccentRingWidth
        : _centerNodeAccentRingWidth;
    final List<BoxShadow> boxShadows = isSelected
        ? [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.27),
              blurRadius: _centerNodeHaloBlur,
              spreadRadius: _centerNodeHaloSpread,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: _centerNodeMainShadowBlur,
              spreadRadius: _centerNodeMainShadowSpread,
              offset: const Offset(0, _centerNodeMainShadowOffsetY),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 14,
              spreadRadius: 0.6,
              offset: const Offset(0, 4),
            ),
          ];

    return SizedBox(
      key: ValueKey<String>('graph-center-node:${displayItem.wordId}'),
      width: _centerNodeSize,
      height: _centerNodeSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            duration: _visualStateAnimationDuration,
            curve: Curves.easeOutCubic,
            opacity: backgroundOpacity,
            child: AnimatedContainer(
              duration: _visualStateAnimationDuration,
              curve: Curves.easeOutCubic,
              width: _centerNodeSize,
              height: _centerNodeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [centerInnerColor, centerMidColor, centerOuterColor],
                  stops: const [0.0, 0.72, 1.0],
                ),
                border: Border.all(
                  color: Colors.black.withValues(
                    alpha: isSelected ? 0.66 : 0.48,
                  ),
                  width: centerNodeBorderWidth,
                ),
                boxShadow: boxShadows,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: _visualStateAnimationDuration,
                curve: Curves.easeOutCubic,
                opacity: backgroundOpacity,
                child: Padding(
                  padding: EdgeInsets.all(centerAccentInset),
                  child: AnimatedContainer(
                    duration: _visualStateAnimationDuration,
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: centerAccentColor,
                        width: centerAccentWidth,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: AnimatedOpacity(
              duration: _visualStateAnimationDuration,
              curve: Curves.easeOutCubic,
              opacity: textOpacity,
              child: Column(
                key: ValueKey<String>(
                  'graph-center-node-semantic-anchor:${displayItem.wordId}',
                ),
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 연결 단어 노드(원형)
  Widget _buildWordNode(
    Word word,
    Color accentColor, {
    required GraphWordLabelDisplayItem labelDisplay,
    required _GraphNodeLayout nodeLayout,
    required _GraphVisualState visualState,
  }) {
    final spellingLabel = labelDisplay.peripheralTitleLabel;
    final strongIdentityLabel = labelDisplay.displayStrongNumber.trim();
    final languageLabel = labelDisplay.language.trim();
    final transliterationLabel = labelDisplay.representativeTransliteration
        .trim();
    final primaryMeaningLabel = labelDisplay.primaryMeaning.trim();
    final bool isDepthTwo = nodeLayout.depth >= 2;
    final bool isSelected = visualState == _GraphVisualState.selected;
    final bool isDimmed = visualState == _GraphVisualState.dimmed;
    final bool showExpansionSourceRing =
        nodeLayout.isExpansionSource && !isSelected;
    final languageColor = _colorForWordLanguageGroup(word.id);
    final Color effectiveAccentColor = isSelected
        ? _blendColor(accentColor, Colors.black, 0.18)
        : isDimmed
        ? _blendColor(accentColor, Colors.grey.shade500, 0.42)
        : accentColor;
    final double baseFillTintAlpha = _fillTintAlphaForDepth(nodeLayout.depth);
    final double fillTintAlpha = isSelected
        ? _selectedNodeLanguageTintAlpha
        : isDimmed
        ? _mutedNodeLanguageTintAlpha
        : baseFillTintAlpha;
    final Color fillColor = _surfaceTint(languageColor, fillTintAlpha);
    final Color innerFillColor = _surfaceTint(
      languageColor,
      (fillTintAlpha * 0.82).clamp(0.10, 0.22),
    );
    final Color midFillColor = _surfaceTint(
      languageColor,
      (fillTintAlpha * 0.92).clamp(0.12, 0.24),
    );
    final double borderWidth = isSelected
        ? _connectedNodeSelectedBorderWidth
        : isDimmed
        ? _connectedNodeMutedBorderWidth
        : isDepthTwo
        ? _depthTwoNodeBorderWidth
        : _depthOneNodeBorderWidth;
    final double backgroundOpacity =
        _nodeOpacityForState(visualState, isCenter: false) *
        (isDepthTwo ? 0.94 : 1.0);
    final double textOpacity = _nodeTextOpacityForState(visualState);
    final Color selectedRingColor = _blendColor(
      effectiveAccentColor,
      Colors.black,
      0.10,
    ).withValues(alpha: isDimmed ? 0.18 : 0.34);
    final Color expansionSourceRingColor = _blendColor(
      effectiveAccentColor,
      Colors.black,
      0.12,
    ).withValues(alpha: isDimmed ? 0.10 : 0.18);
    final List<BoxShadow> boxShadows = isSelected
        ? [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.22),
              blurRadius: 14,
              spreadRadius: 1.2,
            ),
            BoxShadow(
              color: accentColor.withValues(alpha: 0.16),
              blurRadius: 10,
              spreadRadius: 0.6,
              offset: const Offset(0, 3),
            ),
          ]
        : const [];
    final FontWeight labelFontWeight = isSelected
        ? FontWeight.w700
        : isDepthTwo
        ? FontWeight.w500
        : FontWeight.w600;
    final FontWeight secondaryLabelFontWeight = isDepthTwo
        ? FontWeight.w400
        : FontWeight.w500;
    final double labelFontSize = isDepthTwo ? 11.0 : 12.0;
    final double secondaryLabelFontSize = isDepthTwo ? 9.0 : 10.0;
    final double nodeSize = nodeLayout.nodeSize;
    final effectiveScreenScale = peripheralNodeEffectiveScreenScaleForTesting(
      _currentScale,
    );
    final boundedPrimaryLabelFontSize =
        peripheralNodeSpellingFontSizeForTesting(
          baseFontSize: labelFontSize,
          cameraScale: _currentScale,
        );
    final boundedStrongIdentityFontSize =
        peripheralNodeSecondaryFontSizeForTesting(
          baseFontSize: secondaryLabelFontSize,
          cameraScale: _currentScale,
        );
    final nodeBorderWidth = borderWidth / effectiveScreenScale;
    final selectedOuterRingWidth =
        _selectedNodeOuterRingWidth / effectiveScreenScale;
    final primaryLabelStyle = TextStyle(
      fontSize: boundedPrimaryLabelFontSize,
      fontWeight: labelFontWeight,
    );
    final secondaryLabelStyle = TextStyle(
      fontSize: boundedStrongIdentityFontSize,
      fontWeight: secondaryLabelFontWeight,
    );

    Widget buildLabelLine(String role, String value, TextStyle style) {
      return Text(
        value,
        key: ValueKey<String>(
          'graph-peripheral-node-lod-line:${word.id}:$role',
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    final labelLines = <Widget>[
      if (_peripheralNodeLod == PeripheralNodeLodLevel.lod1) ...[
        if (strongIdentityLabel.isNotEmpty)
          buildLabelLine('strong', strongIdentityLabel, secondaryLabelStyle)
        else if (spellingLabel.isNotEmpty)
          buildLabelLine('spelling', spellingLabel, primaryLabelStyle),
      ] else ...[
        if (languageLabel.isNotEmpty)
          buildLabelLine('language', languageLabel, secondaryLabelStyle),
        if (strongIdentityLabel.isNotEmpty)
          buildLabelLine('strong', strongIdentityLabel, secondaryLabelStyle),
        if (spellingLabel.isNotEmpty)
          buildLabelLine('spelling', spellingLabel, primaryLabelStyle),
        if (_peripheralNodeLod == PeripheralNodeLodLevel.lod3) ...[
          if (transliterationLabel.isNotEmpty)
            buildLabelLine(
              'transliteration',
              transliterationLabel,
              secondaryLabelStyle,
            ),
          if (primaryMeaningLabel.isNotEmpty)
            buildLabelLine('meaning', primaryMeaningLabel, secondaryLabelStyle),
        ],
      ],
    ];

    return GestureDetector(
      key: ValueKey<String>('graph-peripheral-node:${word.id}'),
      onTap: () => _handleConnectedWordTap(word),
      child: SizedBox(
        width: nodeSize,
        height: nodeSize,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (isSelected)
              Positioned(
                left: -_selectedNodeOuterRingInset,
                top: -_selectedNodeOuterRingInset,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: _visualStateAnimationDuration,
                    curve: Curves.easeOutCubic,
                    opacity: backgroundOpacity,
                    child: AnimatedContainer(
                      key: ValueKey<String>(
                        'graph-peripheral-node-selected-ring:${word.id}',
                      ),
                      duration: _visualStateAnimationDuration,
                      curve: Curves.easeOutCubic,
                      width: nodeSize + _selectedNodeOuterRingInset * 2,
                      height: nodeSize + _selectedNodeOuterRingInset * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedRingColor,
                          width: selectedOuterRingWidth,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (showExpansionSourceRing)
              Positioned(
                left: -_expansionSourceRingInset,
                top: -_expansionSourceRingInset,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: _visualStateAnimationDuration,
                    curve: Curves.easeOutCubic,
                    opacity: backgroundOpacity,
                    child: AnimatedContainer(
                      duration: _visualStateAnimationDuration,
                      curve: Curves.easeOutCubic,
                      width: nodeSize + _expansionSourceRingInset * 2,
                      height: nodeSize + _expansionSourceRingInset * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: expansionSourceRingColor,
                          width: _expansionSourceRingWidth,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            AnimatedOpacity(
              duration: _visualStateAnimationDuration,
              curve: Curves.easeOutCubic,
              opacity: backgroundOpacity,
              child: AnimatedContainer(
                key: ValueKey<String>('graph-peripheral-node-body:${word.id}'),
                duration: _visualStateAnimationDuration,
                curve: Curves.easeOutCubic,
                width: nodeSize,
                height: nodeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [innerFillColor, midFillColor, fillColor],
                    stops: const [0.0, 0.74, 1.0],
                  ),
                  border: Border.all(
                    color: effectiveAccentColor,
                    width: nodeBorderWidth,
                  ),
                  boxShadow: boxShadows,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AnimatedOpacity(
                duration: _visualStateAnimationDuration,
                curve: Curves.easeOutCubic,
                opacity: textOpacity,
                child: Column(
                  key: ValueKey<String>(
                    'graph-peripheral-node-lod:${word.id}:${_peripheralNodeLod.name}',
                  ),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: labelLines,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 연결 단어들을 원형으로 자동 배치
  String? _placeholderSourceWordId(GraphNode node) {
    final placeholderSourceWordId = (node.placeholderSourceWordId ?? '').trim();
    if (placeholderSourceWordId.isNotEmpty) {
      return placeholderSourceWordId;
    }

    final expansionSourceId = (node.expansionSourceId ?? '').trim();
    return expansionSourceId.isEmpty ? null : expansionSourceId;
  }

  bool _isCenterDepthOnePlaceholderNode(GraphNode node) {
    return node.isPlaceholderMoreNode &&
        node.depth <= 1 &&
        _placeholderSourceWordId(node) == _centerWordId;
  }

  Color _centerDepthOnePlaceholderAccentColor() {
    return _blendColor(
      _colorForWordLanguageGroup(_centerWordId),
      Colors.black,
      0.18,
    );
  }

  Color _placeholderAccentColor(GraphNode node) {
    final sourceWordId = _placeholderSourceWordId(node);
    if (sourceWordId == null) {
      return Colors.grey;
    }

    return _colorForCategory(
      _primaryEdgeInfoForNode(sourceWordId)?.categoryCode,
    );
  }

  String _placeholderLabelForNode(GraphNode node) {
    final hiddenCount = node.hiddenCount;
    if (hiddenCount > 0) {
      return '+$hiddenCount more';
    }

    final label = node.label.trim();
    return label.isEmpty ? '+more' : label;
  }

  Widget _buildCenterDepthOneMoreNode(
    GraphNode node,
    Color accentColor, {
    required _GraphNodeLayout nodeLayout,
    required _GraphVisualState visualState,
  }) {
    final isDimmed = visualState == _GraphVisualState.dimmed;
    final nodeSize = nodeLayout.nodeSize;
    final backgroundOpacity =
        _nodeOpacityForState(visualState, isCenter: false) * 0.97;
    final textOpacity = _nodeTextOpacityForState(visualState);
    final fillColor = Color.alphaBlend(
      accentColor.withValues(alpha: isDimmed ? 0.10 : 0.18),
      Colors.white,
    );
    final innerFillColor = Color.alphaBlend(
      accentColor.withValues(alpha: isDimmed ? 0.05 : 0.10),
      Colors.white,
    );
    final borderColor = isDimmed
        ? _blendColor(accentColor, Colors.grey.shade500, 0.36)
        : _blendColor(accentColor, Colors.black, 0.14);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _handlePlaceholderMoreNodeTap(node),
      child: SizedBox(
        width: nodeSize,
        height: nodeSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              duration: _visualStateAnimationDuration,
              curve: Curves.easeOutCubic,
              opacity: backgroundOpacity,
              child: AnimatedContainer(
                duration: _visualStateAnimationDuration,
                curve: Curves.easeOutCubic,
                width: nodeSize,
                height: nodeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [innerFillColor, fillColor],
                    stops: const [0.0, 1.0],
                  ),
                  border: Border.all(
                    color: borderColor,
                    width: _depthOneNodeBorderWidth,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AnimatedOpacity(
                duration: _visualStateAnimationDuration,
                curve: Curves.easeOutCubic,
                opacity: textOpacity,
                child: Text(
                  _placeholderLabelForNode(node),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderMoreNode(
    GraphNode node,
    Color accentColor, {
    required _GraphNodeLayout nodeLayout,
    required _GraphVisualState visualState,
  }) {
    final isDimmed = visualState == _GraphVisualState.dimmed;
    final nodeSize = nodeLayout.nodeSize;
    final backgroundOpacity =
        _nodeOpacityForState(visualState, isCenter: false) * 0.96;
    final textOpacity = _nodeTextOpacityForState(visualState);
    final fillColor = Color.alphaBlend(
      accentColor.withValues(alpha: isDimmed ? 0.08 : 0.15),
      Colors.white,
    );
    final innerFillColor = Color.alphaBlend(
      accentColor.withValues(alpha: isDimmed ? 0.04 : 0.08),
      Colors.white,
    );
    final borderColor = isDimmed
        ? _blendColor(accentColor, Colors.grey.shade500, 0.42)
        : _blendColor(accentColor, Colors.black, 0.10);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _handlePlaceholderMoreNodeTap(node),
      child: SizedBox(
        width: nodeSize,
        height: nodeSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              duration: _visualStateAnimationDuration,
              curve: Curves.easeOutCubic,
              opacity: backgroundOpacity,
              child: AnimatedContainer(
                duration: _visualStateAnimationDuration,
                curve: Curves.easeOutCubic,
                width: nodeSize,
                height: nodeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [innerFillColor, fillColor],
                    stops: const [0.0, 1.0],
                  ),
                  border: Border.all(
                    color: borderColor,
                    width: _depthTwoNodeBorderWidth,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AnimatedOpacity(
                duration: _visualStateAnimationDuration,
                curve: Curves.easeOutCubic,
                opacity: textOpacity,
                child: Text(
                  _placeholderLabelForNode(node),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearSelectedWord() {
    if (_selectedWordId == null) return;
    _setSelectedWordId(null);
    widget.onClearSelection?.call();
  }

  void _markViewportInteraction() {
    _lastViewportInteractionAt = DateTime.now();
  }

  void _temporarilySuppressBackgroundTapClear() {
    _suppressBackgroundTapClear = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _suppressBackgroundTapClear = false;
    });
  }

  bool _shouldIgnoreBackgroundTapClear() {
    if (_suppressBackgroundTapClear || _isViewportInteracting) {
      return true;
    }

    final lastViewportInteractionAt = _lastViewportInteractionAt;
    if (lastViewportInteractionAt == null) {
      return false;
    }

    return DateTime.now().difference(lastViewportInteractionAt) <
        _backgroundTapSuppressDuration;
  }

  void _handleBackgroundTap() {
    if (_shouldIgnoreBackgroundTapClear()) {
      return;
    }

    _clearSelectedWord();
  }

  void _scheduleConditionalCenterFocus(_GraphLayoutData layout) {
    if (!_pendingCenterFocusAfterCenterChange ||
        _pendingCenterFocusWordId != _centerWordId ||
        _didSchedulePendingCenterFocus) {
      return;
    }

    _didSchedulePendingCenterFocus = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _didSchedulePendingCenterFocus = false;
      if (!mounted) return;
      if (!_pendingCenterFocusAfterCenterChange ||
          _pendingCenterFocusWordId != _centerWordId) {
        return;
      }

      _applyConditionalCenterFocus(layout);
      _pendingCenterFocusAfterCenterChange = false;
      _pendingCenterFocusWordId = null;
    });
  }

  void _applyConditionalCenterFocus(_GraphLayoutData layout) {
    final matrix = Matrix4.copy(_transformController.value);
    final viewportCenter = Offset(
      layout.viewportSize.width / 2,
      layout.viewportSize.height / 2,
    );
    final currentCenter = MatrixUtils.transformPoint(matrix, layout.center);
    final delta = viewportCenter - currentCenter;
    if (delta.distance <= _centerChangeFocusDistanceThreshold) {
      return;
    }

    var shift = delta * _centerChangeFocusShiftFactor;
    final shiftDistance = shift.distance;
    if (shiftDistance > _centerChangeFocusMaxShift) {
      final clampFactor = _centerChangeFocusMaxShift / shiftDistance;
      shift = Offset(shift.dx * clampFactor, shift.dy * clampFactor);
    }

    final next = Matrix4.copy(matrix);
    next.storage[12] += shift.dx;
    next.storage[13] += shift.dy;
    _transformController.value = next;
  }

  void _scheduleLocalRetargetCenterFocus(_GraphLayoutData layout) {
    final pendingCenterWordId = _pendingLocalRetargetCenterFocusWordId;
    if (pendingCenterWordId == null ||
        pendingCenterWordId != _centerWordId ||
        pendingCenterWordId != layout.centerNodeId ||
        _didSchedulePendingLocalRetargetCenterFocus) {
      return;
    }

    _didSchedulePendingLocalRetargetCenterFocus = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _didSchedulePendingLocalRetargetCenterFocus = false;
      if (!mounted) return;
      if (_pendingLocalRetargetCenterFocusWordId != pendingCenterWordId ||
          _centerWordId != pendingCenterWordId ||
          layout.centerNodeId != pendingCenterWordId) {
        return;
      }

      _translateLayoutPointToViewportCenter(
        layoutPoint: layout.center,
        viewportSize: layout.viewportSize,
      );
      _pendingLocalRetargetCenterFocusWordId = null;
    });
  }

  void _scheduleViewportCameraSync(_GraphLayoutData layout) {
    if (_appliedViewportSize == layout.viewportSize &&
        _pendingViewportSize == null) {
      return;
    }

    _pendingViewportSize = layout.viewportSize;
    _pendingLayoutCenter = layout.center;
    if (_isViewportCameraSyncScheduled) {
      return;
    }

    _isViewportCameraSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isViewportCameraSyncScheduled = false;
      if (!mounted) return;

      final viewportSize = _pendingViewportSize;
      final layoutCenter = _pendingLayoutCenter;
      _pendingViewportSize = null;
      _pendingLayoutCenter = null;
      if (viewportSize == null || layoutCenter == null) {
        return;
      }

      final previousViewportSize = _appliedViewportSize;
      final matrix = Matrix4.copy(_transformController.value);
      final currentAnchor = previousViewportSize == null
          ? MatrixUtils.transformPoint(matrix, layoutCenter)
          : Offset(
              previousViewportSize.width / 2,
              previousViewportSize.height / 2,
            );
      final nextViewportCenter = Offset(
        viewportSize.width / 2,
        viewportSize.height / 2,
      );
      final shift = nextViewportCenter - currentAnchor;
      if (shift.distanceSquared > 0.0001) {
        matrix.storage[12] += shift.dx;
        matrix.storage[13] += shift.dy;
        _transformController.value = matrix;
      }
      _appliedViewportSize = viewportSize;
    });
  }

  void _resetView(_GraphLayoutData layout) {
    final viewportCenter = Offset(
      layout.viewportSize.width / 2,
      layout.viewportSize.height / 2,
    );
    final shift = viewportCenter - layout.center;
    final matrix = Matrix4.identity();
    matrix.storage[12] = shift.dx;
    matrix.storage[13] = shift.dy;
    _transformController.value = matrix;
    _updateCurrentScale(1.0);
  }

  Offset? _selectedNodeLayoutCenter(_GraphLayoutData layout) {
    final selectedWordId = (_selectedWordId ?? '').trim();
    if (selectedWordId.isEmpty) {
      return null;
    }
    if (selectedWordId == layout.centerNodeId) {
      return layout.center;
    }
    return layout.nodeLayoutById[selectedWordId]?.center;
  }

  void _focusSelectedNode(_GraphLayoutData layout) {
    final selectedNodeCenter = _selectedNodeLayoutCenter(layout);
    if (selectedNodeCenter == null) {
      return;
    }

    _translateLayoutPointToViewportCenter(
      layoutPoint: selectedNodeCenter,
      viewportSize: layout.viewportSize,
    );
  }

  void _translateLayoutPointToViewportCenter({
    required Offset layoutPoint,
    required Size viewportSize,
  }) {
    final matrix = Matrix4.copy(_transformController.value);
    final viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );
    final currentPoint = MatrixUtils.transformPoint(matrix, layoutPoint);
    final shift = viewportCenter - currentPoint;
    if (shift.distanceSquared <= 0.0001) {
      return;
    }

    matrix.storage[12] += shift.dx;
    matrix.storage[13] += shift.dy;
    _transformController.value = matrix;
  }

  _GraphLayoutData _computeGraphLayout(
    Size viewportSize,
    GraphViewData viewData,
  ) {
    final layoutResult = GraphLayoutStrategyResolver.layout(
      layoutMode: _graphLayoutMode,
      viewData: viewData,
      options: _graphLayoutOptions,
      layoutSeed: _graphLayoutSeed(viewData),
      seedPositions: _seedNodePositions,
    );
    final layoutSpaceSize = _graphLayoutOptions.layoutSpaceSize;
    final resolvedPositions = Map<String, Offset>.from(
      layoutResult.positionedNodes,
    );
    final peripheralNodes = _peripheralNodesForViewData(viewData);
    final center =
        resolvedPositions[viewData.centerNodeId] ??
        Offset(layoutSpaceSize.width / 2, layoutSpaceSize.height / 2);
    final centerBounds = Rect.fromCenter(
      center: center,
      width: _centerNodeSize,
      height: _centerNodeSize,
    );
    final occupiedBounds = <Rect>[centerBounds];
    for (final graphNode in peripheralNodes) {
      if (graphNode.isPlaceholderMoreNode) {
        continue;
      }

      final nodeCenter = resolvedPositions[graphNode.id];
      if (nodeCenter == null) {
        continue;
      }

      occupiedBounds.add(
        _nodeBoundsForCenter(
          center: nodeCenter,
          nodeSize: _nodeSizeForDepth(graphNode.depth),
        ),
      );
    }
    for (final placeholderNode in peripheralNodes.where(
      (node) => node.isPlaceholderMoreNode,
    )) {
      final sourceWordId = _placeholderSourceWordId(placeholderNode);
      if (sourceWordId == null) {
        continue;
      }

      final sourceCenter = resolvedPositions[sourceWordId];
      if (sourceCenter == null) {
        continue;
      }

      final placeholderNodeSize = _nodeSizeForDepth(placeholderNode.depth);
      final resolvedPlaceholderCenter =
          _isCenterDepthOnePlaceholderNode(placeholderNode)
          ? _resolveCenterDepthOnePlaceholderNodeCenter(
              placeholderNode: placeholderNode,
              centerPosition: center,
              placeholderRadius: placeholderNodeSize / 2,
              positionedNodes: resolvedPositions,
              occupiedBounds: occupiedBounds,
            )
          : () {
              final sourceNode = viewData.nodeById(sourceWordId);
              final sourceNodeSize = sourceNode == null
                  ? _depthOneNodeSize
                  : _nodeSizeForDepth(sourceNode.depth);
              return _resolvePlaceholderNodeCenter(
                placeholderNode: placeholderNode,
                sourceCenter: sourceCenter,
                centerPosition: center,
                sourceRadius: sourceNodeSize / 2,
                placeholderRadius: placeholderNodeSize / 2,
                positionedNodes: resolvedPositions,
                occupiedBounds: occupiedBounds,
              );
            }();
      resolvedPositions[placeholderNode.id] = resolvedPlaceholderCenter;
      occupiedBounds.add(
        _nodeBoundsForCenter(
          center: resolvedPlaceholderCenter,
          nodeSize: placeholderNodeSize,
        ),
      );
    }
    final expansionSourceIds = viewData.nodes
        .where((node) => node.depth >= 2 && node.expansionSourceId != null)
        .map((node) => node.expansionSourceId!)
        .toSet();
    _seedNodePositions
      ..clear()
      ..addAll(resolvedPositions);
    final ringRadii = <double>[];
    final nodeLayouts = <_GraphNodeLayout>[];

    for (var index = 0; index < peripheralNodes.length; index++) {
      final graphNode = peripheralNodes[index];
      final nodeCenter = resolvedPositions[graphNode.id];
      if (nodeCenter == null) {
        continue;
      }

      final radius = (nodeCenter - center).distance;
      var ringIndex = ringRadii.indexWhere(
        (ringRadius) => (ringRadius - radius).abs() < 0.5,
      );
      if (ringIndex == -1) {
        ringRadii.add(radius);
        ringRadii.sort();
        ringIndex = ringRadii.indexWhere(
          (ringRadius) => (ringRadius - radius).abs() < 0.5,
        );
      }

      nodeLayouts.add(
        _buildNodeLayout(
          nodeId: graphNode.id,
          index: index,
          center: center,
          nodeCenter: nodeCenter,
          ringIndex: max(ringIndex, 0),
          depth: graphNode.depth,
          nodeSize: _nodeSizeForDepth(graphNode.depth),
          isExpansionSource: expansionSourceIds.contains(graphNode.id),
        ),
      );
    }
    final nodeLayoutById = <String, _GraphNodeLayout>{
      for (final nodeLayout in nodeLayouts) nodeLayout.nodeId: nodeLayout,
    };
    final edgeLayouts = _buildEdgeLayouts(
      viewData: viewData,
      positionedNodes: resolvedPositions,
    );

    Rect contentBounds = centerBounds;
    for (final nodeLayout in nodeLayouts) {
      contentBounds = contentBounds.expandToInclude(nodeLayout.nodeBounds);
    }
    for (final edgeLayout in edgeLayouts) {
      contentBounds = contentBounds.expandToInclude(
        Rect.fromPoints(edgeLayout.start, edgeLayout.end),
      );
    }

    final resolvedBounds = _boundsForResolvedNodePositions(
      viewData: viewData,
      positionedNodes: resolvedPositions,
    );
    if (resolvedBounds != null && !resolvedBounds.isEmpty) {
      contentBounds = contentBounds.expandToInclude(resolvedBounds);
    }

    final fitPadding = _fitBoundsPadding + (ringRadii.length > 1 ? 12.0 : 0.0);

    return _GraphLayoutData(
      viewportSize: viewportSize,
      layoutSpaceSize: layoutSpaceSize,
      centerNodeId: viewData.centerNodeId,
      center: center,
      centerBounds: centerBounds,
      nodeLayouts: nodeLayouts,
      nodeLayoutById: Map<String, _GraphNodeLayout>.unmodifiable(
        nodeLayoutById,
      ),
      edgeLayouts: List<_GraphEdgeLayout>.unmodifiable(edgeLayouts),
      contentBounds: contentBounds,
      fitBounds: contentBounds.inflate(fitPadding),
      ringRadii: List<double>.unmodifiable(ringRadii),
    );
  }

  int _graphLayoutSeed(GraphViewData viewData) {
    var seed = 0x1f123bb5;

    void mix(String value) {
      for (final unit in value.codeUnits) {
        seed = 0x1fffffff & (seed + unit);
        seed = 0x1fffffff & (seed + ((0x0007ffff & seed) << 10));
        seed ^= (seed >> 6);
      }
    }

    mix(viewData.centerNodeId);
    for (final node in viewData.nodes) {
      mix(node.id);
      mix(node.label);
      mix(node.depth.toString());
    }
    for (final edge in viewData.edges) {
      mix(edge.id);
      mix(edge.sourceId);
      mix(edge.targetId);
    }

    seed = 0x1fffffff & (seed + ((0x03ffffff & seed) << 3));
    seed ^= (seed >> 11);
    seed = 0x1fffffff & (seed + ((0x00003fff & seed) << 15));

    return seed & 0x7fffffff;
  }

  _GraphNodeLayout _buildNodeLayout({
    required String nodeId,
    required int index,
    required Offset center,
    required Offset nodeCenter,
    required int ringIndex,
    required int depth,
    required double nodeSize,
    required bool isExpansionSource,
  }) {
    final vx = nodeCenter.dx - center.dx;
    final vy = nodeCenter.dy - center.dy;
    final radius = sqrt(vx * vx + vy * vy);
    final safeLength = radius <= 0.001 ? 1.0 : radius;

    return _GraphNodeLayout(
      nodeId: nodeId,
      index: index,
      center: nodeCenter,
      nodeBounds: Rect.fromCenter(
        center: nodeCenter,
        width: nodeSize,
        height: nodeSize,
      ),
      labelAnchor: Offset(
        center.dx + vx * _labelAnchorFactor,
        center.dy + vy * _labelAnchorFactor,
      ),
      labelNormal: Offset(-vy / safeLength, vx / safeLength),
      radius: radius,
      angle: atan2(vy, vx),
      ringIndex: ringIndex,
      depth: depth,
      nodeSize: nodeSize,
      isExpansionSource: isExpansionSource,
    );
  }

  Offset _resolvePlaceholderNodeCenter({
    required GraphNode placeholderNode,
    required Offset sourceCenter,
    required Offset centerPosition,
    required double sourceRadius,
    required double placeholderRadius,
    required Map<String, Offset> positionedNodes,
    required List<Rect> occupiedBounds,
  }) {
    final outward = _unitVector(sourceCenter - centerPosition);
    final tangent = Offset(-outward.dy, outward.dx);
    final baseDistance =
        sourceRadius + placeholderRadius + _placeholderAnchorGap;
    final tangentDistance = max(
      _placeholderTangentOffset,
      placeholderRadius * 0.78,
    );
    final desiredCenter = sourceCenter + outward * baseDistance;
    final sourceBounds = _nodeBoundsForCenter(
      center: sourceCenter,
      nodeSize: sourceRadius * 2,
    ).inflate(_placeholderCollisionPadding);

    Offset bestCenter = desiredCenter;
    double bestScore = double.infinity;

    for (final candidateCenter in _candidatePlaceholderCenters(
      placeholderNode: placeholderNode,
      sourceCenter: sourceCenter,
      desiredCenter: desiredCenter,
      outward: outward,
      tangent: tangent,
      baseDistance: baseDistance,
      tangentDistance: tangentDistance,
      positionedNodes: positionedNodes,
    )) {
      final candidateBounds = _nodeBoundsForCenter(
        center: candidateCenter,
        nodeSize: placeholderRadius * 2,
      ).inflate(_placeholderCollisionPadding);
      final collisionScore = _placeholderCollisionScore(
        candidateBounds: candidateBounds,
        occupiedBounds: occupiedBounds,
      );
      final score =
          collisionScore +
          _intersectionArea(candidateBounds, sourceBounds) * 8.0 +
          (candidateCenter - desiredCenter).distance * 0.35;
      if (score < bestScore) {
        bestScore = score;
        bestCenter = candidateCenter;
      }
      if (score <= 0.001) {
        break;
      }
    }

    return bestCenter;
  }

  Offset _resolveCenterDepthOnePlaceholderNodeCenter({
    required GraphNode placeholderNode,
    required Offset centerPosition,
    required double placeholderRadius,
    required Map<String, Offset> positionedNodes,
    required List<Rect> occupiedBounds,
  }) {
    return _resolvePlaceholderNodeCenter(
      placeholderNode: placeholderNode,
      sourceCenter: centerPosition,
      centerPosition: centerPosition,
      sourceRadius: _centerNodeHalf,
      placeholderRadius: placeholderRadius,
      positionedNodes: positionedNodes,
      occupiedBounds: occupiedBounds,
    );
  }

  Iterable<Offset> _candidatePlaceholderCenters({
    required GraphNode placeholderNode,
    required Offset sourceCenter,
    required Offset desiredCenter,
    required Offset outward,
    required Offset tangent,
    required double baseDistance,
    required double tangentDistance,
    required Map<String, Offset> positionedNodes,
  }) sync* {
    yield desiredCenter;
    yield desiredCenter + tangent * tangentDistance;
    yield desiredCenter - tangent * tangentDistance;

    final fartherCenter =
        sourceCenter +
        outward * (baseDistance + _placeholderFallbackOutwardStep);
    yield fartherCenter;
    yield fartherCenter + tangent * tangentDistance;
    yield fartherCenter - tangent * tangentDistance;

    final autoLayoutCenter = positionedNodes[placeholderNode.id];
    if (autoLayoutCenter != null) {
      yield autoLayoutCenter;
    }
  }

  double _placeholderCollisionScore({
    required Rect candidateBounds,
    required List<Rect> occupiedBounds,
  }) {
    double score = 0.0;
    for (final obstacleBounds in occupiedBounds) {
      score += _intersectionArea(
        candidateBounds,
        obstacleBounds.inflate(_placeholderCollisionPadding),
      );
    }
    return score;
  }

  Rect _nodeBoundsForCenter({
    required Offset center,
    required double nodeSize,
  }) {
    return Rect.fromCenter(center: center, width: nodeSize, height: nodeSize);
  }

  Rect? _boundsForResolvedNodePositions({
    required GraphViewData viewData,
    required Map<String, Offset> positionedNodes,
  }) {
    Rect? bounds;

    void includeNode(String nodeId, double nodeSize) {
      final nodeCenter = positionedNodes[nodeId];
      if (nodeCenter == null) {
        return;
      }

      final nodeBounds = _nodeBoundsForCenter(
        center: nodeCenter,
        nodeSize: nodeSize,
      );
      bounds = bounds == null
          ? nodeBounds
          : bounds!.expandToInclude(nodeBounds);
    }

    includeNode(viewData.centerNodeId, _centerNodeSize);
    for (final graphNode in viewData.nodes) {
      includeNode(graphNode.id, _nodeSizeForDepth(graphNode.depth));
    }

    return bounds;
  }

  List<_GraphEdgeLayout> _buildEdgeLayouts({
    required GraphViewData viewData,
    required Map<String, Offset> positionedNodes,
  }) {
    final groupedEdges = <String, List<GraphEdge>>{};
    for (final edge in viewData.edges) {
      groupedEdges
          .putIfAbsent(
            _edgePairKey(edge.sourceId, edge.targetId),
            () => <GraphEdge>[],
          )
          .add(edge);
    }

    final edgeLayouts = <_GraphEdgeLayout>[];
    for (final group in groupedEdges.values) {
      final orderedGroup = List<GraphEdge>.from(group)
        ..sort((left, right) => left.id.compareTo(right.id));
      final centerOffset = (orderedGroup.length - 1) / 2;

      for (var index = 0; index < orderedGroup.length; index++) {
        final edge = orderedGroup[index];
        final start = positionedNodes[edge.sourceId];
        final end = positionedNodes[edge.targetId];
        if (start == null || end == null) {
          continue;
        }
        final primaryEdgeInfo = _primaryEdgeInfoForEdge(edge.id);
        final directionSummary = _directionSummaryForEdges(
          _edgeInfosForEdge(edge.id),
        );
        final touchesCenter =
            edge.sourceId == viewData.centerNodeId ||
            edge.targetId == viewData.centerNodeId;

        final delta = end - start;
        final distance = max(delta.distance, 0.001);
        final direction = Offset(delta.dx / distance, delta.dy / distance);
        final normal = Offset(-direction.dy, direction.dx);
        final parallelOffset = (index - centerOffset) * 14.0;
        final shift = normal * parallelOffset;
        final shiftedStart = start + shift;
        final shiftedEnd = end + shift;
        final midpoint = Offset(
          (shiftedStart.dx + shiftedEnd.dx) / 2,
          (shiftedStart.dy + shiftedEnd.dy) / 2,
        );

        edgeLayouts.add(
          _GraphEdgeLayout(
            edgeId: edge.id,
            sourceId: edge.sourceId,
            targetId: edge.targetId,
            start: shiftedStart,
            end: shiftedEnd,
            midpoint: midpoint,
            labelNormal: normal,
            color: _colorForCategory(primaryEdgeInfo?.categoryCode),
            relationType: primaryEdgeInfo?.relationType ?? edge.relationType,
            directionSummary: directionSummary,
            touchesCenter: touchesCenter,
          ),
        );
      }
    }

    return edgeLayouts;
  }

  List<Widget> _buildWordNodes(
    _GraphLayoutData layout,
    GraphViewData viewData, {
    required String? selectedWordId,
  }) {
    if (layout.nodeLayouts.isEmpty) return [];

    final List<Widget> widgets = [];
    final regularNodes = <(_GraphNodeLayout, GraphNode)>[];
    final placeholderNodes = <(_GraphNodeLayout, GraphNode)>[];

    for (final nodeLayout in layout.nodeLayouts) {
      final graphNode = viewData.nodeById(nodeLayout.nodeId);
      if (graphNode == null) {
        continue;
      }

      if (graphNode.isPlaceholderMoreNode) {
        placeholderNodes.add((nodeLayout, graphNode));
      } else {
        regularNodes.add((nodeLayout, graphNode));
      }
    }

    for (final entry in [...regularNodes, ...placeholderNodes]) {
      final nodeLayout = entry.$1;
      final graphNode = entry.$2;
      final isActualPeripheralWordNode = !graphNode.isPlaceholderMoreNode;
      final isCenterDepthOnePlaceholder = _isCenterDepthOnePlaceholderNode(
        graphNode,
      );
      final visualState = selectedWordId == null
          ? _GraphVisualState.connected
          : _visualStateForNodeId(graphNode.id);
      final accentColor = isCenterDepthOnePlaceholder
          ? _centerDepthOnePlaceholderAccentColor()
          : graphNode.isPlaceholderMoreNode
          ? _placeholderAccentColor(graphNode)
          : _colorForCategory(
              _primaryEdgeInfoForNode(graphNode.id)?.categoryCode,
            );

      final child = isCenterDepthOnePlaceholder
          ? _buildCenterDepthOneMoreNode(
              graphNode,
              accentColor,
              nodeLayout: nodeLayout,
              visualState: visualState,
            )
          : graphNode.isPlaceholderMoreNode
          ? _buildPlaceholderMoreNode(
              graphNode,
              accentColor,
              nodeLayout: nodeLayout,
              visualState: visualState,
            )
          : () {
              final word = _wordForNodeId(graphNode.wordId);
              if (word == null) {
                return const SizedBox.shrink();
              }

              return _buildWordNode(
                word,
                accentColor,
                labelDisplay: _labelDisplayForGraphNode(graphNode),
                nodeLayout: nodeLayout,
                visualState: visualState,
              );
            }();
      widgets.add(
        Positioned(
          left: nodeLayout.nodeBounds.left,
          top: nodeLayout.nodeBounds.top,
          child: Transform.scale(
            key: ValueKey<String>('graph-node-visual-scale:${graphNode.id}'),
            scale: isActualPeripheralWordNode
                ? _peripheralNodeLocalVisualScale(_currentScale)
                : _nodeLocalVisualScale(_currentScale),
            alignment: Alignment.center,
            transformHitTests: true,
            child: child,
          ),
        ),
      );
    }

    return widgets;
  }

  /// 엣지 태그(라벨)를 "클릭 가능한 위젯"으로 렌더링한다.
  /// - Painter는 선만 그리고, 태그는 위젯으로 올려서 클릭 이벤트를 처리한다.
  List<Widget> _buildEdgeLabelWidgets(
    _GraphLayoutData layout, {
    required Set<String> selectedEdgeIds,
    required String? selectedWordId,
  }) {
    // 줌이 작으면 태그 숨김(기존 정책 유지)
    if (_currentScale < _labelVisibleScaleThreshold) return [];
    if (layout.edgeLayouts.isEmpty) return [];
    final visibleEdgeLabelIds = _visibleEdgeLabelIds(
      layout,
      selectedEdgeIds: selectedEdgeIds,
      selectedWordId: selectedWordId,
    );
    if (visibleEdgeLabelIds.isEmpty) return [];

    // 태그가 선 위에 겹치지 않도록 약간 수직 방향 오프셋(줌 역보정)

    final List<Widget> widgets = [];
    final placedLabelBounds = <Rect>[];
    final nodeObstacles = <Rect>[
      layout.centerBounds.inflate(_labelCollisionPadding),
      for (final nodeLayout in layout.nodeLayouts)
        nodeLayout.nodeBounds.inflate(_labelCollisionPadding),
    ];

    for (final edgeLayout in layout.edgeLayouts) {
      if (!visibleEdgeLabelIds.contains(edgeLayout.edgeId)) {
        continue;
      }
      final edgeInfos = _edgeInfosForEdge(edgeLayout.edgeId);
      final label = _labelForEdgeGroup(edgeInfos).trim();
      if (label.isEmpty) continue;

      // 중심 -> 주변 방향 벡터

      // 태그는 중심에서 멀어지게(주변 노드 쪽)

      // 수직 단위벡터

      final placement = _resolveEdgeLabelPlacement(
        layout: layout,
        edgeLayout: edgeLayout,
        label: label,
        nodeObstacles: nodeObstacles,
        placedLabelBounds: placedLabelBounds,
      );
      final pos = placement.center;
      placedLabelBounds.add(placement.bounds);

      final edgeColor = edgeLayout.color;
      final bool hasFocusedEdge = selectedEdgeIds.isNotEmpty;
      final bool isFocusedEdge = selectedEdgeIds.contains(edgeLayout.edgeId);
      final edgePriority = _edgeVisualPriorityFor(
        isFocusedEdge: isFocusedEdge,
        touchesCenter: edgeLayout.touchesCenter,
      );
      final Color labelBorderColor;
      final Color labelBackgroundColor;
      final double labelBorderWidth;
      final double labelOpacity;
      final FontWeight labelFontWeight;

      switch (edgePriority) {
        case _GraphEdgeVisualPriority.selected:
          labelBorderColor = _blendColor(edgeColor, Colors.black, 0.08);
          labelBackgroundColor = Color.alphaBlend(
            edgeColor.withValues(alpha: _selectedEdgeLabelTintAlpha),
            Colors.white,
          );
          labelBorderWidth = _selectedEdgeLabelBorderWidth;
          labelOpacity = 1.0;
          labelFontWeight = FontWeight.bold;
          break;
        case _GraphEdgeVisualPriority.center:
          labelBorderColor = edgeColor.withValues(
            alpha: hasFocusedEdge
                ? _mutedEdgeLabelBorderOpacity
                : _defaultEdgeLabelBorderOpacity,
          );
          labelBackgroundColor = Color.alphaBlend(
            edgeColor.withValues(
              alpha: hasFocusedEdge
                  ? _dimmedEdgeLabelTintAlpha + 0.01
                  : _connectedEdgeLabelTintAlpha + 0.01,
            ),
            Colors.white,
          );
          labelBorderWidth = _defaultEdgeLabelBorderWidth;
          labelOpacity = hasFocusedEdge
              ? _mutedCenterEdgeLabelOpacity
              : _centerEdgeLabelOpacity;
          labelFontWeight = FontWeight.w600;
          break;
        case _GraphEdgeVisualPriority.expansion:
          labelBorderColor = edgeColor.withValues(
            alpha: hasFocusedEdge
                ? _mutedEdgeLabelBorderOpacity - 0.06
                : _defaultEdgeLabelBorderOpacity - 0.10,
          );
          labelBackgroundColor = Color.alphaBlend(
            edgeColor.withValues(
              alpha: hasFocusedEdge
                  ? _dimmedEdgeLabelTintAlpha
                  : _connectedEdgeLabelTintAlpha - 0.01,
            ),
            Colors.white,
          );
          labelBorderWidth = _defaultEdgeLabelBorderWidth;
          labelOpacity = hasFocusedEdge
              ? _mutedExpansionEdgeLabelOpacity
              : _expansionEdgeLabelOpacity;
          labelFontWeight = FontWeight.w500;
          break;
      }

      widgets.add(
        Positioned(
          left: pos.dx,
          top: pos.dy,
          child: FractionalTranslation(
            translation: const Offset(-0.5, -0.5),
            child: GestureDetector(
              onTap: () {
                _temporarilySuppressBackgroundTapClear();
                if (edgeInfos.isEmpty) return;
                _showEdgeDetailDialog(edgeInfos);
              },
              child: AnimatedOpacity(
                duration: _visualStateAnimationDuration,
                curve: Curves.easeOutCubic,
                opacity: labelOpacity,
                child: AnimatedContainer(
                  duration: _visualStateAnimationDuration,
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: _edgeLabelHorizontalPadding,
                    vertical: _edgeLabelVerticalPadding,
                  ),
                  decoration: BoxDecoration(
                    color: labelBackgroundColor,
                    border: Border.all(
                      color: labelBorderColor,
                      width: labelBorderWidth,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: _edgeLabelFontSize,
                      fontWeight: labelFontWeight,
                    ),
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
  ({Offset center, Rect bounds}) _resolveEdgeLabelPlacement({
    required _GraphLayoutData layout,
    required _GraphEdgeLayout edgeLayout,
    required String label,
    required List<Rect> nodeObstacles,
    required List<Rect> placedLabelBounds,
  }) {
    final baseCenter = edgeLayout.labelCenter(_currentScale);
    final radial = _unitVector(
      Offset(
        edgeLayout.midpoint.dx - layout.center.dx,
        edgeLayout.midpoint.dy - layout.center.dy,
      ),
    );

    Offset bestCenter = baseCenter;
    Rect bestBounds = _measureEdgeLabelBounds(label: label, center: baseCenter);
    double bestScore = double.infinity;

    for (int attempt = 0; attempt < _labelPlacementMaxAttempts; attempt++) {
      final candidateCenter = _candidateEdgeLabelCenter(
        baseCenter: baseCenter,
        normal: edgeLayout.labelNormal,
        radial: radial,
        attempt: attempt,
      );
      final shiftDistance = (candidateCenter - baseCenter).distance;
      if (shiftDistance > _labelMaxShiftDistance) continue;

      final candidateBounds = _measureEdgeLabelBounds(
        label: label,
        center: candidateCenter,
      );
      final collisionScore = _edgeLabelCollisionScore(
        bounds: candidateBounds,
        nodeObstacles: nodeObstacles,
        placedLabelBounds: placedLabelBounds,
      );

      if (collisionScore < bestScore) {
        bestScore = collisionScore;
        bestCenter = candidateCenter;
        bestBounds = candidateBounds;
      }

      if (collisionScore == 0.0) {
        break;
      }
    }

    return (center: bestCenter, bounds: bestBounds);
  }

  Offset _candidateEdgeLabelCenter({
    required Offset baseCenter,
    required Offset normal,
    required Offset radial,
    required int attempt,
  }) {
    if (attempt == 0) return baseCenter;

    final tier = ((attempt + 1) / 2).ceil();
    final normalSign = attempt.isOdd ? 1.0 : -1.0;
    final lateralShift = min(
      _labelPlacementStep * tier,
      _labelMaxShiftDistance,
    );
    final radialShift = min(
      _labelPlacementRadialStep * max(0, tier - 1),
      _labelMaxShiftDistance,
    );

    return Offset(
      baseCenter.dx +
          normal.dx * lateralShift * normalSign +
          radial.dx * radialShift,
      baseCenter.dy +
          normal.dy * lateralShift * normalSign +
          radial.dy * radialShift,
    );
  }

  Rect _measureEdgeLabelBounds({
    required String label,
    required Offset center,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: _edgeLabelFontSize,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    return Rect.fromCenter(
      center: center,
      width: textPainter.width + _edgeLabelHorizontalPadding * 2,
      height: textPainter.height + _edgeLabelVerticalPadding * 2,
    );
  }

  double _edgeLabelCollisionScore({
    required Rect bounds,
    required List<Rect> nodeObstacles,
    required List<Rect> placedLabelBounds,
  }) {
    final paddedBounds = bounds.inflate(_labelCollisionPadding);
    double score = 0.0;

    for (final obstacle in nodeObstacles) {
      score += _intersectionArea(paddedBounds, obstacle);
    }

    for (final placedBounds in placedLabelBounds) {
      score += _intersectionArea(paddedBounds, placedBounds);
    }

    return score;
  }

  double _intersectionArea(Rect a, Rect b) {
    final overlap = a.intersect(b);
    if (overlap.isEmpty) return 0.0;
    return overlap.width * overlap.height;
  }

  Offset _unitVector(Offset vector) {
    final length = vector.distance;
    if (length <= 0.001) return const Offset(0, -1);
    return Offset(vector.dx / length, vector.dy / length);
  }

  String _edgeIdForRelationInfo(WordRelationEdgeInfo info) {
    if (info.relationId > 0) {
      return info.relationId.toString();
    }

    final minWordId = info.wordId1.compareTo(info.wordId2) <= 0
        ? info.wordId1
        : info.wordId2;
    final maxWordId = info.wordId1.compareTo(info.wordId2) <= 0
        ? info.wordId2
        : info.wordId1;
    final relationType = (info.relationType ?? '').trim();
    final categoryCode = (info.categoryCode ?? '').trim();
    return '$minWordId::$maxWordId::$relationType::$categoryCode';
  }

  String _edgePairKey(String leftNodeId, String rightNodeId) {
    return leftNodeId.compareTo(rightNodeId) <= 0
        ? '$leftNodeId::$rightNodeId'
        : '$rightNodeId::$leftNodeId';
  }

  List<WordRelationEdgeInfo> _edgeInfosForEdge(String edgeId) {
    return List<WordRelationEdgeInfo>.unmodifiable(
      _edgeInfosByEdgeId[edgeId] ?? const <WordRelationEdgeInfo>[],
    );
  }

  WordRelationEdgeInfo? _primaryEdgeInfoForEdge(String edgeId) {
    final edgeInfos = _edgeInfosByEdgeId[edgeId];
    if (edgeInfos == null || edgeInfos.isEmpty) {
      return null;
    }
    return edgeInfos.first;
  }

  WordRelationEdgeInfo? _primaryEdgeInfoForNode(String nodeId) {
    for (final edgeInfos in _edgeInfosByEdgeId.values) {
      if (edgeInfos.isEmpty) {
        continue;
      }
      final info = edgeInfos.first;
      if (info.wordId1 == nodeId || info.wordId2 == nodeId) {
        return info;
      }
    }

    return null;
  }

  Set<String> _selectedEdgeIds(String? selectedWordId) {
    final normalizedWordId = (selectedWordId ?? '').trim();
    if (normalizedWordId.isEmpty) {
      return const <String>{};
    }

    final edgeIds = <String>{};
    for (final entry in _edgeInfosByEdgeId.entries) {
      final edgeInfos = entry.value;
      if (edgeInfos.isEmpty) {
        continue;
      }

      if (edgeInfos.any(
        (info) =>
            info.wordId1 == normalizedWordId ||
            info.wordId2 == normalizedWordId,
      )) {
        edgeIds.add(entry.key);
      }
    }

    return edgeIds;
  }

  Set<String> _visibleEdgeLabelIds(
    _GraphLayoutData layout, {
    required Set<String> selectedEdgeIds,
    required String? selectedWordId,
  }) {
    final normalizedSelectedWordId = (selectedWordId ?? '').trim();
    final renderedEdgeIds = layout.edgeLayouts
        .map((edgeLayout) => edgeLayout.edgeId)
        .toSet();

    if (normalizedSelectedWordId.isNotEmpty) {
      return selectedEdgeIds
          .where((edgeId) => renderedEdgeIds.contains(edgeId))
          .toSet();
    }

    if (layout.edgeLayouts.length > _edgeLabelVisibleCountThreshold) {
      return const <String>{};
    }

    final edgeIds = <String>{};
    for (final edgeLayout in layout.edgeLayouts) {
      if (!edgeLayout.touchesCenter) {
        continue;
      }
      if (_edgeInfosForEdge(edgeLayout.edgeId).isEmpty) {
        continue;
      }
      edgeIds.add(edgeLayout.edgeId);
    }
    return edgeIds;
  }

  List<_SelectedNodeRelationEntry> _selectedNodeRelationEntries(
    _GraphLayoutData layout, {
    required Set<String> selectedEdgeIds,
    required String? selectedWordId,
  }) {
    final normalizedSelectedWordId = (selectedWordId ?? '').trim();
    if (normalizedSelectedWordId.isEmpty || selectedEdgeIds.isEmpty) {
      return const <_SelectedNodeRelationEntry>[];
    }

    final edgeLayoutsById = <String, _GraphEdgeLayout>{
      for (final edgeLayout in layout.edgeLayouts)
        edgeLayout.edgeId: edgeLayout,
    };
    final entries = <_SelectedNodeRelationEntry>[];

    for (final edgeId in selectedEdgeIds) {
      final edgeLayout = edgeLayoutsById[edgeId];
      if (edgeLayout == null) {
        continue;
      }

      final infos = _edgeInfosForEdge(edgeId);
      if (infos.isEmpty) {
        continue;
      }

      final otherWordId = edgeLayout.sourceId == normalizedSelectedWordId
          ? edgeLayout.targetId
          : edgeLayout.sourceId;
      entries.add(
        _SelectedNodeRelationEntry(
          edgeId: edgeId,
          otherWordId: otherWordId,
          infos: List<WordRelationEdgeInfo>.unmodifiable(infos),
        ),
      );
    }

    entries.sort((left, right) {
      final wordComparison = _wordDisplayName(
        left.otherWordId,
      ).compareTo(_wordDisplayName(right.otherWordId));
      if (wordComparison != 0) {
        return wordComparison;
      }
      return left.edgeId.compareTo(right.edgeId);
    });

    return List<_SelectedNodeRelationEntry>.unmodifiable(entries);
  }

  Word? _wordForNodeId(String nodeId) {
    final normalizedNodeId = nodeId.trim();
    if (normalizedNodeId == _centerWordId) {
      return _centerWordCompatibilityFallback();
    }

    final visibleNode = _graphWordsById[normalizedNodeId];
    if (visibleNode == null) {
      return null;
    }

    return _wordForVisibleNode(visibleNode);
  }

  Word _wordForVisibleNode(GraphVisibleNode visibleNode) {
    return Word(
      id: visibleNode.wordId,
      spelling1: _nullIfBlank(visibleNode.fallbackSpelling),
      strongNumber: _nullIfBlank(visibleNode.fallbackStrongNumber),
      transliteration1: _nullIfBlank(visibleNode.fallbackTransliteration),
    );
  }

  String _wordDisplayName(String nodeId) {
    final normalizedNodeId = nodeId.trim();
    final labelDisplay = _graphWordLabelsById[normalizedNodeId];
    final displayName = labelDisplay?.relationDisplayName.trim() ?? '';
    if (displayName.isNotEmpty) {
      return displayName;
    }

    final fallbackDisplayName =
        _graphWordsById[normalizedNodeId]?.fallbackDisplayName.trim() ?? '';
    if (fallbackDisplayName.isNotEmpty) {
      return fallbackDisplayName;
    }

    return normalizedNodeId;
  }

  String _edgeDisplayTitle(WordRelationEdgeInfo info) {
    return '${_wordDisplayName(info.wordId1)} ↔ ${_wordDisplayName(info.wordId2)}';
  }

  String _directionReferenceWordId(WordRelationEdgeInfo info) {
    if (info.wordId1 == _centerWordId || info.wordId2 == _centerWordId) {
      return _centerWordId;
    }

    return info.wordId1;
  }

  String _targetWordIdForRelationInfo(
    WordRelationEdgeInfo info, {
    String? centerWordId,
  }) {
    final referenceWordId = centerWordId ?? _directionReferenceWordId(info);
    return referenceWordId == info.wordId1 ? info.wordId2 : info.wordId1;
  }

  RelationText _relationTextForInfo(WordRelationEdgeInfo info) {
    final centerWordId = _directionReferenceWordId(info);
    final targetWordId = _targetWordIdForRelationInfo(
      info,
      centerWordId: centerWordId,
    );

    return RelationFormatter.formatForPair(
      relationType: info.relationType,
      directionCode: info.directionCode,
      wordId1: info.wordId1,
      wordId2: info.wordId2,
      centerWordId: centerWordId,
      centerWord: _wordDisplayName(centerWordId),
      targetWord: _wordDisplayName(targetWordId),
    );
  }

  _GraphEdgeDirectionSummary _directionSummaryForDirectionCode(
    String? directionCode,
  ) {
    switch ((directionCode ?? '').trim()) {
      case 'w1_to_w2':
        return _GraphEdgeDirectionSummary.outgoing;
      case 'w2_to_w1':
        return _GraphEdgeDirectionSummary.incoming;
      case 'undirected':
        return _GraphEdgeDirectionSummary.undirected;
      default:
        return _GraphEdgeDirectionSummary.unknown;
    }
  }

  _GraphEdgeDirectionSummary _directionSummaryForEdges(
    List<WordRelationEdgeInfo> infos,
  ) {
    if (infos.isEmpty) return _GraphEdgeDirectionSummary.unknown;

    final directions = infos
        .map((info) => _directionSummaryForDirectionCode(info.directionCode))
        .toSet();

    if (directions.length != 1) {
      return _GraphEdgeDirectionSummary.mixed;
    }

    return directions.first;
  }

  String _directionTagForSummary(_GraphEdgeDirectionSummary summary) {
    switch (summary) {
      case _GraphEdgeDirectionSummary.outgoing:
        return '->';
      case _GraphEdgeDirectionSummary.incoming:
        return '<-';
      case _GraphEdgeDirectionSummary.undirected:
        return 'UNDIR';
      case _GraphEdgeDirectionSummary.mixed:
        return 'MIX';
      case _GraphEdgeDirectionSummary.unknown:
        return 'UNK';
    }
  }

  String _relationPhraseForDetails(WordRelationEdgeInfo info) {
    return _relationTextForInfo(info).phrase;
  }

  String _selectedNodeRelationEntryTitle(_SelectedNodeRelationEntry entry) {
    return _wordDisplayName(entry.otherWordId);
  }

  String _selectedNodeRelationEntrySubtitle(_SelectedNodeRelationEntry entry) {
    final primaryInfo = entry.infos.first;
    final phrase = _relationPhraseForDetails(primaryInfo).trim();
    final fallbackLabel = _labelForEdgeGroup(entry.infos).trim();
    final baseText = phrase.isNotEmpty
        ? phrase
        : fallbackLabel.isNotEmpty
        ? fallbackLabel
        : '관계 상세 보기';

    if (entry.infos.length <= 1) {
      return baseText;
    }

    return '$baseText 외 ${entry.infos.length - 1}건';
  }

  Future<void> _openSelectedNodeRelationEntry(
    _SelectedNodeRelationEntry entry,
  ) async {
    _temporarilySuppressBackgroundTapClear();
    if (entry.infos.isEmpty) {
      return;
    }

    await _showEdgeDetailDialog(entry.infos);
  }

  String _labelForEdgeGroup(List<WordRelationEdgeInfo> infos) {
    if (infos.isEmpty) return '';

    final relationLabels = infos
        .map((info) => _relationTextForInfo(info).shortLabel.trim())
        .where((label) => label.isNotEmpty)
        .toSet();
    final countSuffix = infos.length > 1 ? ' x${infos.length}' : '';

    if (relationLabels.isEmpty) {
      return '';
    }

    if (relationLabels.length == 1) {
      return '${relationLabels.first}$countSuffix';
    }

    return '관계$countSuffix';
  }

  String _directionTextForRawCode({
    required String directionCode,
    required String centerWordId,
    required String wordId1,
    required String wordId2,
  }) {
    switch (directionCode.trim()) {
      case 'w1_to_w2':
        return centerWordId == wordId1 ? '중심 -> 상대' : '상대 -> 중심';
      case 'w2_to_w1':
        return centerWordId == wordId1 ? '상대 -> 중심' : '중심 -> 상대';
      case 'undirected':
        return '방향 없음';
      default:
        return '방향 미정';
    }
  }

  List<DropdownMenuItem<String>> _directionDropdownItems({
    required String centerWordId,
    required String wordId1,
    required String wordId2,
  }) {
    const directionCodes = <String>[
      'unknown',
      'w1_to_w2',
      'w2_to_w1',
      'undirected',
    ];

    return directionCodes
        .map(
          (code) => DropdownMenuItem<String>(
            value: code,
            child: Text(
              _directionTextForRawCode(
                directionCode: code,
                centerWordId: centerWordId,
                wordId1: wordId1,
                wordId2: wordId2,
              ),
            ),
          ),
        )
        .toList(growable: false);
  }

  List<T> _sanitizeLookupItemsByCode<T>(
    Iterable<T> items, {
    required String Function(T item) codeOf,
  }) {
    final sanitized = <T>[];
    final seenCodes = <String>{};

    for (final item in items) {
      final code = codeOf(item).trim();
      if (code.isEmpty || !seenCodes.add(code)) {
        continue;
      }
      sanitized.add(item);
    }

    return List<T>.unmodifiable(sanitized);
  }

  int _countMatchingLookupItemsByCode<T>({
    required String? rawValue,
    required Iterable<T> items,
    required String Function(T item) codeOf,
  }) {
    final value = (rawValue ?? '').trim();
    if (value.isEmpty) return 0;

    var count = 0;
    for (final item in items) {
      final code = codeOf(item).trim();
      if (code == value) {
        count++;
      }
    }
    return count;
  }

  String? _normalizeDropdownCodeForEditor<T>({
    required String? rawValue,
    required Iterable<T> items,
    required String Function(T item) codeOf,
  }) {
    final value = (rawValue ?? '').trim();
    if (value.isEmpty) return null;

    return _countMatchingLookupItemsByCode(
              rawValue: value,
              items: items,
              codeOf: codeOf,
            ) ==
            1
        ? value
        : null;
  }

  String? normalizeCategoryCodeForEditor({
    required String? rawValue,
    required Iterable<RelationCategoryLookup> categoryItems,
  }) {
    return _normalizeDropdownCodeForEditor(
      rawValue: rawValue,
      items: categoryItems,
      codeOf: (item) => item.code,
    );
  }

  List<RelationTypeLookup> _relationTypeItemsForEditor({
    required String? categoryCode,
    required List<RelationTypeLookup> allTypes,
  }) {
    final normalizedCategoryCode = (categoryCode ?? '').trim();
    if (normalizedCategoryCode.isEmpty) {
      return const [];
    }

    return allTypes
        .where((item) => item.belongsToCategory(normalizedCategoryCode))
        .toList(growable: false);
  }

  String? normalizeRelationTypeForEditor({
    required String? rawValue,
    required String? categoryCode,
    required List<RelationTypeLookup> allRelationTypeItems,
  }) {
    return _normalizeDropdownCodeForEditor(
      rawValue: rawValue,
      items: _relationTypeItemsForEditor(
        categoryCode: categoryCode,
        allTypes: allRelationTypeItems,
      ),
      codeOf: (item) => item.code,
    );
  }

  String _normalizeDropdownValueWithFallback({
    required String? rawValue,
    required Iterable<String> allowedValues,
    required String fallback,
  }) {
    final value = (rawValue ?? '').trim();
    if (value.isNotEmpty &&
        allowedValues.where((allowed) => allowed.trim() == value).length == 1) {
      return value;
    }

    return fallback;
  }

  String _normalizeDirectionCodeForEditor({
    required String? rawValue,
    required Iterable<DropdownMenuItem<String>> items,
  }) {
    return _normalizeDropdownValueWithFallback(
      rawValue: rawValue,
      allowedValues: items.map((item) => item.value).whereType<String>(),
      fallback: 'unknown',
    );
  }

  Future<void> _showEdgeDetailDialog(List<WordRelationEdgeInfo> infos) async {
    if (infos.isEmpty) return;
    if (infos.length == 1) {
      await _showSingleEdgeDetailDialog(infos.first);
      return;
    }

    final selectedInfo = await showDialog<WordRelationEdgeInfo>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('관계 목록 ${_edgeDisplayTitle(infos.first)}'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: infos
                    .map((info) {
                      final directionTag = _directionTagForSummary(
                        _directionSummaryForEdges([info]),
                      );
                      final relationLabel = _relationPhraseForDetails(info);
                      final metaParts = <String>[
                        directionTag,
                        if ((info.categoryLabel?.trim().isNotEmpty ?? false))
                          info.categoryLabel!.trim()
                        else if ((info.categoryCode?.trim().isNotEmpty ??
                            false))
                          info.categoryCode!.trim(),
                        'ID ${info.relationId}',
                      ];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => Navigator.pop(context, info),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  relationLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  metaParts.join(' | '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );

    if (!mounted || selectedInfo == null) return;
    await _showSingleEdgeDetailDialog(selectedInfo);
  }

  Future<void> _showSingleEdgeDetailDialog(WordRelationEdgeInfo info) async {
    await showDialog(
      context: context,
      builder: (context) {
        bool isEditing = false;
        bool isSaving = false;

        // 초기값(읽기용)
        final originalCategoryCode = info.categoryCode;
        final originalRelationType = info.relationType;
        final directionItems = _directionDropdownItems(
          centerWordId: _directionReferenceWordId(info),
          wordId1: info.wordId1,
          wordId2: info.wordId2,
        );

        String? selectedCategoryCode;
        String? selectedRelationType;
        String selectedDirectionCode = _normalizeDirectionCodeForEditor(
          rawValue: info.directionCode,
          items: directionItems,
        );
        // 'unspecified' 같은 표시용 값이 들어오면 드롭다운 value 규칙 위반이므로 null 처리
        final descriptionController = TextEditingController(
          text: info.description ?? '',
        );
        final relationGroupIdController = TextEditingController(
          text: info.relationGroupId ?? '',
        );
        final noteController = TextEditingController(text: info.note ?? '');
        final sourceController = TextEditingController(text: info.source ?? '');

        // 드롭다운 옵션(편집 눌렀을 때 로딩)
        List<RelationCategoryLookup> categories = [];
        List<RelationTypeLookup> types = [];
        bool isOptionsLoading = false;

        String? normalizedOriginalCategoryCode() {
          return normalizeCategoryCodeForEditor(
            rawValue: originalCategoryCode,
            categoryItems: categories,
          );
        }

        String? normalizedOriginalRelationType() {
          final originalCategoryCodeForEditor =
              normalizedOriginalCategoryCode();
          return normalizeRelationTypeForEditor(
            rawValue: originalRelationType,
            categoryCode: originalCategoryCodeForEditor,
            allRelationTypeItems: types,
          );
        }

        void normalizeCurrentEditorDropdownState() {
          selectedCategoryCode = normalizeCategoryCodeForEditor(
            rawValue: selectedCategoryCode,
            categoryItems: categories,
          );
          selectedRelationType = normalizeRelationTypeForEditor(
            rawValue: selectedRelationType,
            categoryCode: selectedCategoryCode,
            allRelationTypeItems: types,
          );
          selectedDirectionCode = _normalizeDirectionCodeForEditor(
            rawValue: selectedDirectionCode,
            items: directionItems,
          );
        }

        void restoreEditorDropdownStateFromOriginal() {
          selectedCategoryCode = normalizeCategoryCodeForEditor(
            rawValue: originalCategoryCode,
            categoryItems: categories,
          );
          selectedRelationType = normalizeRelationTypeForEditor(
            rawValue: originalRelationType,
            categoryCode: selectedCategoryCode,
            allRelationTypeItems: types,
          );
          selectedDirectionCode = _normalizeDirectionCodeForEditor(
            rawValue: info.directionCode,
            items: directionItems,
          );
        }

        bool hasChanges() {
          final description = descriptionController.text.trim();
          final relationGroupId = relationGroupIdController.text.trim();
          final note = noteController.text.trim();
          final src = sourceController.text.trim();

          final originalDescription = (info.description ?? '').trim();
          final originalRelationGroupId = (info.relationGroupId ?? '').trim();
          final originalNote = (info.note ?? '').trim();
          final originalSrc = (info.source ?? '').trim();

          return selectedCategoryCode != normalizedOriginalCategoryCode() ||
              selectedRelationType != normalizedOriginalRelationType() ||
              selectedDirectionCode !=
                  _normalizeDirectionCodeForEditor(
                    rawValue: info.directionCode,
                    items: directionItems,
                  ) ||
              description != originalDescription ||
              relationGroupId != originalRelationGroupId ||
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
              categories = _sanitizeLookupItemsByCode(
                c,
                codeOf: (item) => item.code,
              );
              types = _sanitizeLookupItemsByCode(
                t,
                codeOf: (item) => item.code,
              );
              isOptionsLoading = false;

              // 현재 선택값이 실제 items에 없으면 null로 보정(드롭다운 assert 방지)
              restoreEditorDropdownStateFromOriginal();
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
              directionCode: selectedDirectionCode,
              description: _nullIfBlank(descriptionController.text),
              relationGroupId: _nullIfBlank(relationGroupIdController.text),
              note: noteController.text.trim(),
              source: sourceController.text.trim(),
            );
            widget.mutationImpactCollector?.recordGraphAffectedWords([
              info.wordId1,
              info.wordId2,
            ]);

            // 그래프 갱신(색/라벨/팝업 내용 반영)
            WordGraphDataCache.invalidateMany([
              _centerWordId,
              info.wordId1,
              info.wordId2,
            ]);
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
            widget.mutationImpactCollector?.recordGraphAffectedWords([
              info.wordId1,
              info.wordId2,
            ]);

            // 그래프 갱신(엣지/라벨/색 반영)
            WordGraphDataCache.invalidateMany([
              _centerWordId,
              info.wordId1,
              info.wordId2,
            ]);
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
                : '(없음)';

            final typeText =
                (info.relationTypeLabel?.trim().isNotEmpty ?? false)
                ? info.relationTypeLabel!.trim()
                : (info.relationType?.trim().isNotEmpty ?? false)
                ? info.relationType!.trim()
                : '(없음)';
            final relationCenterWordId = _directionReferenceWordId(info);
            final relationTargetWordId = _targetWordIdForRelationInfo(
              info,
              centerWordId: relationCenterWordId,
            );
            final relationText = RelationFormatter.formatForPair(
              relationType: selectedRelationType ?? info.relationType,
              directionCode: selectedDirectionCode,
              wordId1: info.wordId1,
              wordId2: info.wordId2,
              centerWordId: relationCenterWordId,
              centerWord: _wordDisplayName(relationCenterWordId),
              targetWord: _wordDisplayName(relationTargetWordId),
            );
            final directionText = _directionTextForRawCode(
              directionCode: selectedDirectionCode,
              centerWordId: _directionReferenceWordId(info),
              wordId1: info.wordId1,
              wordId2: info.wordId2,
            );
            final descriptionText = _nullIfBlank(descriptionController.text);
            final relationGroupIdText = _nullIfBlank(
              relationGroupIdController.text,
            );
            final availableRelationTypes = _relationTypeItemsForEditor(
              categoryCode: selectedCategoryCode,
              allTypes: types,
            );

            final canSave = isEditing && !isSaving && hasChanges();

            return AlertDialog(
              title: Text('관계: ${_edgeDisplayTitle(info)}'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          relationText.sentence,
                          style: TextStyle(
                            color: Colors.grey.shade900,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
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
                              return DropdownMenuItem<String>(
                                value: m.code,
                                child: Text(m.displayLabel),
                              );
                            }),
                          ],
                          onChanged: (v) => setState(() {
                            selectedCategoryCode =
                                normalizeCategoryCodeForEditor(
                                  rawValue: v,
                                  categoryItems: categories,
                                );
                            normalizeCurrentEditorDropdownState();
                          }),
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
                            ...availableRelationTypes.map((m) {
                              return DropdownMenuItem<String>(
                                value: m.code,
                                child: Text(m.displayLabel),
                              );
                            }),
                          ],
                          onChanged: (v) => setState(() {
                            selectedRelationType =
                                normalizeRelationTypeForEditor(
                                  rawValue: v,
                                  categoryCode: selectedCategoryCode,
                                  allRelationTypeItems: types,
                                );
                          }),
                        ),
                      const SizedBox(height: 14),
                      const Text(
                        '방향',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      if (!isEditing)
                        Text(directionText)
                      else
                        DropdownButtonFormField<String>(
                          value: selectedDirectionCode,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: directionItems,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              selectedDirectionCode =
                                  _normalizeDirectionCodeForEditor(
                                    rawValue: value,
                                    items: directionItems,
                                  );
                            });
                          },
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
                        onChanged: (_) => setState(() {}),
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
                        onChanged: (_) => setState(() {}),
                        maxLines: 2,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '(없음)',
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '설명',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      if (!isEditing)
                        Text(descriptionText ?? '(없음)')
                      else
                        TextField(
                          controller: descriptionController,
                          enabled: !isSaving,
                          onChanged: (_) => setState(() {}),
                          maxLines: 3,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: '(없음)',
                          ),
                        ),
                      const SizedBox(height: 14),
                      const Text(
                        '관계 그룹 ID',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      if (!isEditing)
                        Text(relationGroupIdText ?? '(없음)')
                      else
                        TextField(
                          controller: relationGroupIdController,
                          enabled: !isSaving,
                          onChanged: (_) => setState(() {}),
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
                              restoreEditorDropdownStateFromOriginal();
                              descriptionController.text =
                                  info.description ?? '';
                              relationGroupIdController.text =
                                  info.relationGroupId ?? '';
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
  /// - 레거시/null 데이터가 남아 있을 수 있으므로 기본값을 둔다.
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
      case 'unspecified':
        return Colors.grey;

      default:
        return Colors.grey;
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
    _updateCurrentScale(nextScale);
  }

  /// [선택 단어 삭제] 전체 흐름
  /// 1) 선택 단어 확인
  /// 2) 연결 관계 수 확인
  /// 3) 삭제 확인
  /// 4) 단어 삭제 후 graph/selection/result 정리
  Future<void> _confirmDeleteSelectedWord() async {
    final selectedWordId = (_selectedWordId ?? '').trim();
    if (selectedWordId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('삭제할 단어를 그래프에서 먼저 선택하세요.')));
      return;
    }

    final wasCenterWord = selectedWordId == _centerWordId;
    final graphAffectedWordIds = <String>{
      selectedWordId,
      ...?_adjacentNodeIdsByNodeId[selectedWordId],
    };
    final relationCount = await _repository.countRelationsForWord(
      selectedWordId,
    );

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('단어 삭제'),
          content: Text(
            relationCount > 0
                ? '이 단어를 삭제하면 연결된 관계 $relationCount개도 함께 삭제됩니다.\n정말 삭제할까요?'
                : '이 단어를 정말 삭제할까요?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _wordWriteService.execute(
        DeleteWordCommand(wordId: selectedWordId),
      );
      WordGraphDataCache.clear();
      widget.mutationImpactCollector?.recordDeletedWord(
        selectedWordId,
        graphAffectedWordIds: graphAffectedWordIds,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('단어가 삭제되었습니다.')));

    final onDeletedSelectedWord = widget.onDeletedSelectedWord;
    if (onDeletedSelectedWord != null) {
      await onDeletedSelectedWord(selectedWordId, wasCenterWord: wasCenterWord);
      return;
    }

    if (wasCenterWord) {
      Navigator.pop(context, WordDetailDeletedResult(wordId: selectedWordId));
      return;
    }

    _setSelectedWordId(null);
    widget.onClearSelection?.call();
    await _loadConnectedWords();
  }

  /// [단어 추가] 전체 흐름
  /// 1) 단어 입력
  /// 2) 중복 후보 경고
  /// 3) 단어 저장
  /// 4) (옵션) 현재 선택 단어와 관계 추가
  /// 5) 그래프 갱신
  Future<void> _showCreateWordFlow() async {
    final relationSourceWordId = (_selectedWordId ?? '').trim();
    final payload = await _showCreateWordDialog();
    if (payload == null) return;

    final duplicates = await _repository.findDuplicateCandidates(
      language: payload.wordPayload.language,
      strongNumber: payload.wordPayload.strongNumber,
      spelling1: payload.wordPayload.representativeSpelling,
    );

    if (duplicates.isNotEmpty) {
      final shouldContinue = await _showDuplicateWarningDialog(
        language: payload.wordPayload.language,
        strongNumber: payload.wordPayload.strongNumber,
        spelling1: payload.wordPayload.representativeSpelling,
        candidates: duplicates,
      );

      if (shouldContinue != true) return;
    }

    final writeResult = await _wordWriteService.execute(
      CreateWordCommand(payload: payload.wordPayload),
    );
    final newId = writeResult.wordId;
    if (newId == null || newId.isEmpty) {
      throw Exception('신규 단어 ID를 생성하지 못했습니다.');
    }

    final editSeed = await _repository.getWordEditSeedForGraphCreateEdit(newId);
    if (!mounted) return;

    if (editSeed == null) {
      final didDiscardCreatedWord = await _repository
          .discardCreatedWordForGraphCreateFlow(newId);
      if (didDiscardCreatedWord) {
        WordGraphDataCache.invalidateMany([_centerWordId, newId]);
      }
      await _loadConnectedWords();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            didDiscardCreatedWord ? '단어 추가를 취소했습니다.' : '생성한 단어를 다시 불러오지 못했습니다.',
          ),
        ),
      );
      return;
    }

    GraphCreatePostSavePayload? createdWordPayload;
    final editResult = await Navigator.push<WordEditSaveResult>(
      context,
      MaterialPageRoute(
        builder: (_) => WordEditScreen.fromSeed(seed: editSeed),
      ),
    );

    if (!mounted) return;

    if (editResult != null) {
      createdWordPayload = await _repository
          .getGraphCreatePostSavePayloadAfterEdit(editResult.wordId);
    } else {
      final didDiscardCreatedWord = await _repository
          .discardCreatedWordForGraphCreateFlow(newId);
      if (didDiscardCreatedWord) {
        WordGraphDataCache.invalidateMany([_centerWordId, newId]);
        await _loadConnectedWords();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('단어 추가를 취소했습니다.')));
        return;
      }

      createdWordPayload = await _repository
          .getGraphCreatePostSavePayloadAfterEdit(newId);
    }

    bool didCreateRelation = false;

    // 저장 후 관계 추가 옵션
    if (payload.createRelationAfterSave) {
      if (relationSourceWordId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('관계를 추가할 단어를 그래프에서 먼저 선택하세요.')),
        );
      } else if (createdWordPayload != null) {
        final relationPayload = await _showCreateRelationDialog(
          sourceWordId: relationSourceWordId,
          otherWordId: createdWordPayload.wordId,
          otherWordDisplayLabel: _relationTargetDisplayLabel(
            wordId: createdWordPayload.wordId,
            representativeSpelling: createdWordPayload.representativeSpelling,
          ),
        );

        if (relationPayload != null) {
          final existing = await _repository.findExistingRelationIdBySignature(
            relationSourceWordId,
            createdWordPayload.wordId,
            relationType: relationPayload.relationType,
            directionCode: relationPayload.directionCode,
          );

          if (existing == null) {
            await _repository.createRelation(
              wordId1: relationSourceWordId,
              wordId2: createdWordPayload.wordId,
              categoryCode: relationPayload.categoryCode,
              relationType: relationPayload.relationType,
              directionCode: relationPayload.directionCode,
              description: relationPayload.description,
              relationGroupId: relationPayload.relationGroupId,
              note: relationPayload.note,
              source: relationPayload.source,
            );
            widget.mutationImpactCollector?.recordGraphAffectedWords([
              relationSourceWordId,
              createdWordPayload.wordId,
            ]);
            didCreateRelation = true;
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('이미 관계가 존재합니다.')));
          }
        }
      }

      if (didCreateRelation && createdWordPayload != null) {
        WordGraphDataCache.invalidateMany([
          _centerWordId,
          relationSourceWordId,
          createdWordPayload.wordId,
        ]);
      }

      await _loadConnectedWords();

      if (!mounted) return;
      _setSelectedWordId(newId);
      _notifySelectedWord(Word(id: newId));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('단어가 추가되었습니다: $newId')));
      return;
    }

    // 관계를 만들지 않은 경우:
    // 새로 만든 단어를 중심으로 하는 그래프 화면으로 즉시 전환
    if (!mounted) return;

    if (createdWordPayload != null) {
      final payload = createdWordPayload;
      final createdWord = Word(id: payload.wordId);
      if (widget.onChangeCenterWordId != null ||
          widget.onChangeCenterWord != null) {
        _dispatchCenterChange(createdWord);
        return;
      }

      if (widget.mutationImpactCollector != null) {
        _retargetCenterLocally(
          payload.wordId,
          selectedWordId: null,
          ensureCenterVisibleAfterRetarget: true,
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WordGraphScreen(
            centerWordId: payload.wordId,
            mutationImpactCollector: widget.mutationImpactCollector,
          ),
        ),
      );
      return;
    }

    // 혹시 단어 조회가 실패하면, 현재 화면만 갱신하고 알림
    await _loadConnectedWords();

    if (!mounted) return;
    _setSelectedWordId(newId);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('단어가 추가되었습니다: $newId')));
  }

  /// 신규 단어 생성 다이얼로그
  Future<CreateWordPayload?> _showCreateWordDialog() async {
    return await showDialog<CreateWordPayload?>(
      context: context,
      builder: (context) => const _CreateWordDialog(),
    );
  }

  /// 중복 후보 경고 다이얼로그
  Future<bool?> _showDuplicateWarningDialog({
    required String language,
    String? strongNumber,
    required String spelling1,
    required List<DuplicateCandidateDisplayItem> candidates,
  }) async {
    final isStrongCase = (strongNumber ?? '').trim().isNotEmpty;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('중복 가능성 경고'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isStrongCase
                        ? '같은 스트롱 번호를 가진 기존 단어가 있습니다.'
                        : '같은 언어/대표 표기를 가진 기존 단어가 있습니다.',
                  ),
                  const SizedBox(height: 12),
                  ...candidates.map((c) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ID: ${c.wordId}\n언어: ${c.language}\n스트롱 번호: ${c.strongNumber}\n대표 표기: ${c.representativeSpelling}\n의미1: ${c.primaryMeaning}',
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('계속 추가'),
            ),
          ],
        );
      },
    );
  }

  /// 기준 단어와 상대 단어 사이의 관계 생성 정보 입력
  Future<CreateRelationPayload?> _showCreateRelationDialog({
    required String sourceWordId,
    required String otherWordId,
    required String otherWordDisplayLabel,
  }) async {
    final categories = _sanitizeLookupItemsByCode(
      await _repository.getRelationCategories(),
      codeOf: (item) => item.code,
    );
    final types = _sanitizeLookupItemsByCode(
      await _repository.getRelationTypes(),
      codeOf: (item) => item.code,
    );
    if (!mounted) return null;

    String? selectedCategoryCode;
    String? selectedRelationType;
    final directionItems = _directionDropdownItems(
      centerWordId: sourceWordId,
      wordId1: sourceWordId,
      wordId2: otherWordId,
    );
    String selectedDirectionCode = _normalizeDirectionCodeForEditor(
      rawValue: 'unknown',
      items: directionItems,
    );
    final descriptionController = TextEditingController();
    final relationGroupIdController = TextEditingController();
    final noteController = TextEditingController();
    final sourceController = TextEditingController();

    return showDialog<CreateRelationPayload?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final availableRelationTypes = _relationTypeItemsForEditor(
              categoryCode: selectedCategoryCode,
              allTypes: types,
            );
            return AlertDialog(
              title: Text('관계 추가: $otherWordDisplayLabel'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
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
                            return DropdownMenuItem<String>(
                              value: c.code,
                              child: Text(c.displayLabel),
                            );
                          }),
                        ],
                        onChanged: (v) => setState(() {
                          selectedCategoryCode = normalizeCategoryCodeForEditor(
                            rawValue: v,
                            categoryItems: categories,
                          );
                          selectedRelationType = normalizeRelationTypeForEditor(
                            rawValue: selectedRelationType,
                            categoryCode: selectedCategoryCode,
                            allRelationTypeItems: types,
                          );
                        }),
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
                          ...availableRelationTypes.map((t) {
                            return DropdownMenuItem<String>(
                              value: t.code,
                              child: Text(t.displayLabel),
                            );
                          }),
                        ],
                        onChanged: (v) => setState(() {
                          selectedRelationType = normalizeRelationTypeForEditor(
                            rawValue: v,
                            categoryCode: selectedCategoryCode,
                            allRelationTypeItems: types,
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedDirectionCode,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: '방향'),
                        items: directionItems,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            selectedDirectionCode =
                                _normalizeDirectionCodeForEditor(
                                  rawValue: value,
                                  items: directionItems,
                                );
                          });
                        },
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
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: '설명'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: relationGroupIdController,
                        decoration: const InputDecoration(
                          labelText: '관계 그룹 ID',
                        ),
                      ),
                    ],
                  ),
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
                        directionCode: selectedDirectionCode,
                        description: _nullIfBlank(descriptionController.text),
                        relationGroupId: _nullIfBlank(
                          relationGroupIdController.text,
                        ),
                        note: _nullIfBlank(noteController.text),
                        source: _nullIfBlank(sourceController.text),
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

  /// 현재 그래프(중심 노드 + 연결 노드들)가 화면에 잘 들어오도록 자동으로 줌/팬을 맞춘다.
  void _fitToView(_GraphLayoutData layout) {
    // 노드 배치 반지름(현재 GraphLinePainter와 _buildWordNodes에서 쓰는 값과 맞춰야 함)
    final bounds = layout.fitBounds;

    // 중심 노드/주변 노드 크기(현재 위젯 크기와 맞춰야 함)
    final bboxW = max(bounds.width, 1.0);
    final bboxH = max(bounds.height, 1.0);

    // 여백(태그/선 고려)

    // 스케일 계산
    final sx = layout.viewportSize.width / bboxW;
    final sy = layout.viewportSize.height / bboxH;
    final scale = min(sx, sy).clamp(0.6, 3.5);

    // 바운딩 박스 중심
    final bboxCenter = bounds.center;

    // bbox 중심이 화면 중앙에 오도록 변환 설정
    final m = Matrix4.identity()
      ..translate(layout.viewportSize.width / 2, layout.viewportSize.height / 2)
      ..scale(scale)
      ..translate(-bboxCenter.dx, -bboxCenter.dy);

    _transformController.value = m;
    _updateCurrentScale(scale);
  }

  /// [관계 추가] 전체 흐름
  /// 1) 상대 단어 검색/선택
  /// 2) 관계 정보(카테고리/타입/노트/소스) 입력
  /// 3) 중복 관계 검사 후 INSERT
  /// 4) 그래프 갱신
  Future<void> _showAddRelationFlow() async {
    final relationSourceWordId = (_selectedWordId ?? '').trim();
    if (relationSourceWordId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('관계를 추가할 단어를 그래프에서 먼저 선택하세요.')),
      );
      return;
    }

    // 1) 상대 단어 선택
    final other = await _showSelectWordDialog(
      sourceWordId: relationSourceWordId,
    );
    if (other == null) return;

    // 자기 자신 선택 방지
    if (other.wordId == relationSourceWordId) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('자기 자신과의 관계는 추가할 수 없습니다.')));
      return;
    }

    // 2) 관계 입력
    final payload = await _showCreateRelationDialog(
      sourceWordId: relationSourceWordId,
      otherWordId: other.wordId,
      otherWordDisplayLabel: _graphRelationSearchResultLabel(other),
    );
    if (payload == null) return;

    // 3) 중복 검사
    final existingId = await _repository.findExistingRelationIdBySignature(
      relationSourceWordId,
      other.wordId,
      relationType: payload.relationType,
      directionCode: payload.directionCode,
    );

    if (existingId != null) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('이미 존재하는 관계'),
          content: const Text(
            '이 두 단어 사이의 관계가 이미 데이터베이스에 존재합니다.\n중복 생성은 막았습니다.',
          ),
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
      wordId1: relationSourceWordId,
      wordId2: other.wordId,
      categoryCode: payload.categoryCode,
      relationType: payload.relationType,
      directionCode: payload.directionCode,
      description: payload.description,
      relationGroupId: payload.relationGroupId,
      note: payload.note,
      source: payload.source,
    );
    widget.mutationImpactCollector?.recordGraphAffectedWords([
      relationSourceWordId,
      other.wordId,
    ]);

    // 5) 갱신
    WordGraphDataCache.invalidateMany([
      _centerWordId,
      relationSourceWordId,
      other.wordId,
    ]);
    await _loadConnectedWords();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('관계를 추가했습니다.')));
  }

  /// 상대 단어를 검색해서 고르는 다이얼로그
  Future<GraphRelationAddSearchResultItem?> _showSelectWordDialog({
    required String sourceWordId,
  }) async {
    final controller = TextEditingController();
    List<GraphRelationAddSearchResultItem> results = [];

    return showDialog<GraphRelationAddSearchResultItem?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> doSearch(String q) async {
              final r = await _repository.searchWords(q, limit: 200);
              // 기준 단어는 결과에서 제외(혼동 방지)
              final filtered = r
                  .where((item) => item.wordId != sourceWordId)
                  .toList();
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
                        labelText: '검색 (표기/의미/스트롱 번호)',
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
                                final item = results[i];
                                final subtitleSegments = <String>[
                                  if (item.primaryMeaning.isNotEmpty)
                                    item.primaryMeaning,
                                  if (item.displayStrongNumber.isNotEmpty)
                                    '스트롱 번호: ${item.displayStrongNumber}',
                                ];
                                return ListTile(
                                  title: Text(
                                    _graphRelationSearchResultLabel(item),
                                  ),
                                  subtitle: Text(
                                    subtitleSegments.join(' / '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => Navigator.pop(context, item),
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

  String _graphRelationSearchResultLabel(
    GraphRelationAddSearchResultItem item,
  ) {
    final spelling = item.representativeSpelling.trim();
    return spelling.isNotEmpty ? spelling : item.wordId;
  }

  String _relationTargetDisplayLabel({
    required String wordId,
    String? representativeSpelling,
  }) {
    final spelling = (representativeSpelling ?? '').trim();
    return spelling.isNotEmpty ? spelling : wordId;
  }
}

/// 연결선(엣지) 렌더러
class LegacyGraphLinePainter extends CustomPainter {
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

  LegacyGraphLinePainter(
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
  bool shouldRepaint(covariant LegacyGraphLinePainter oldDelegate) {
    // node 수나 색상이 변하면 다시 그리기
    return oldDelegate.edgeColors.length != edgeColors.length ||
        oldDelegate.edgeColors != edgeColors ||
        oldDelegate.edgeLabels.length != edgeLabels.length ||
        oldDelegate.edgeLabels != edgeLabels ||
        oldDelegate.showLabels != showLabels ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

class _GraphLinePainter extends CustomPainter {
  final _GraphLayoutData layout;
  final String? selectedWordId;
  final Set<String> selectedEdgeIds;
  final Set<String> actualPeripheralWordNodeIds;
  final bool showLabels;
  final double sceneScale;

  _GraphLinePainter({
    required this.layout,
    required this.selectedWordId,
    required this.selectedEdgeIds,
    required this.actualPeripheralWordNodeIds,
    required this.showLabels,
    required this.sceneScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (layout.edgeLayouts.isEmpty) return;

    final hasFocusedEdge = selectedWordId != null;
    final safeSceneScale = sceneScale.isFinite && sceneScale > 0
        ? sceneScale
        : 1.0;
    for (final edgeLayout in layout.edgeLayouts) {
      final bool isFocusedEdge = selectedEdgeIds.contains(edgeLayout.edgeId);
      final edgePriority = _edgeVisualPriorityFor(
        isFocusedEdge: isFocusedEdge,
        touchesCenter: edgeLayout.touchesCenter,
      );
      final edgeStyle = _edgeSemanticStyleForRelationType(
        edgeLayout.relationType,
      );
      final double strokeWidth;
      final double alpha;

      switch (edgePriority) {
        case _GraphEdgeVisualPriority.selected:
          strokeWidth = _selectedEdgeStrokeWidth;
          alpha = 1.0;
          break;
        case _GraphEdgeVisualPriority.center:
          strokeWidth = hasFocusedEdge
              ? _defaultEdgeStrokeWidth
              : _centerEdgeStrokeWidth;
          alpha = hasFocusedEdge ? _mutedCenterEdgeOpacity : _centerEdgeOpacity;
          break;
        case _GraphEdgeVisualPriority.expansion:
          strokeWidth = hasFocusedEdge
              ? _mutedEdgeStrokeWidth
              : _expansionEdgeStrokeWidth;
          alpha = hasFocusedEdge
              ? _mutedExpansionEdgeOpacity
              : _expansionEdgeOpacity;
          break;
      }
      final Color strokeColor = edgeLayout.color.withValues(alpha: alpha);

      final paint = Paint()
        ..color = strokeColor
        ..strokeWidth = strokeWidth / safeSceneScale
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      _drawStyledEdge(
        canvas,
        edgeLayout.start,
        edgeLayout.end,
        paint,
        edgeStyle,
        safeSceneScale,
      );
      _drawDirectionIndicator(
        canvas,
        edgeLayout.start,
        edgeLayout.end,
        edgeLayout.sourceId,
        edgeLayout.targetId,
        paint,
        edgeLayout.directionSummary,
        safeSceneScale,
      );
    }
  }

  void _drawStyledEdge(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    _GraphEdgeSemanticStyle edgeStyle,
    double safeSceneScale,
  ) {
    switch (edgeStyle) {
      case _GraphEdgeSemanticStyle.solid:
        canvas.drawLine(start, end, paint);
        return;
      case _GraphEdgeSemanticStyle.dashed:
        _drawSegmentedEdge(
          canvas,
          start,
          end,
          paint,
          segmentLength: _dashedEdgeDashLength / safeSceneScale,
          gapLength: _dashedEdgeGapLength / safeSceneScale,
        );
        return;
      case _GraphEdgeSemanticStyle.dotted:
        _drawSegmentedEdge(
          canvas,
          start,
          end,
          paint,
          segmentLength: _dottedEdgeDotLength / safeSceneScale,
          gapLength: _dottedEdgeGapLength / safeSceneScale,
        );
        return;
    }
  }

  void _drawSegmentedEdge(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    required double segmentLength,
    required double gapLength,
  }) {
    final delta = end - start;
    final totalLength = delta.distance;
    if (totalLength <= 0 || segmentLength <= 0) return;

    final direction = Offset(delta.dx / totalLength, delta.dy / totalLength);
    var drawnLength = 0.0;

    while (drawnLength < totalLength) {
      final segmentStart = start + direction * drawnLength;
      final segmentEndLength = min(drawnLength + segmentLength, totalLength);
      final segmentEnd = start + direction * segmentEndLength;
      canvas.drawLine(segmentStart, segmentEnd, paint);
      drawnLength += segmentLength + gapLength;
    }
  }

  void _drawDirectionIndicator(
    Canvas canvas,
    Offset start,
    Offset end,
    String sourceId,
    String targetId,
    Paint paint,
    _GraphEdgeDirectionSummary directionSummary,
    double safeSceneScale,
  ) {
    final delta = end - start;
    final totalLength = delta.distance;
    if (totalLength <= 0.001) return;

    final direction = Offset(delta.dx / totalLength, delta.dy / totalLength);
    const edgeInset = 8.0;
    const arrowLength = 14.0;

    switch (directionSummary) {
      case _GraphEdgeDirectionSummary.outgoing:
        final tip = end - direction * (_nodeHalfFor(targetId) + edgeInset);
        final tailReference = tip - direction * arrowLength;
        _drawArrowHead(canvas, tip, tailReference, paint, safeSceneScale);
        return;
      case _GraphEdgeDirectionSummary.incoming:
        final tip = start + direction * (_nodeHalfFor(sourceId) + edgeInset);
        final tailReference = tip + direction * arrowLength;
        _drawArrowHead(canvas, tip, tailReference, paint, safeSceneScale);
        return;
      case _GraphEdgeDirectionSummary.undirected:
      case _GraphEdgeDirectionSummary.unknown:
      case _GraphEdgeDirectionSummary.mixed:
        return;
    }
  }

  double _nodeHalfFor(String nodeId) {
    if (nodeId == layout.centerNodeId) {
      return _effectiveNodeHalf(_centerNodeHalf, sceneScale);
    }

    final baseNodeHalf =
        layout.nodeLayoutById[nodeId]?.nodeHalf ?? _connectedNodeHalf;
    if (actualPeripheralWordNodeIds.contains(nodeId)) {
      return _peripheralNodeEffectiveHalf(baseNodeHalf, sceneScale);
    }
    return _effectiveNodeHalf(baseNodeHalf, sceneScale);
  }

  void _drawArrowHead(
    Canvas canvas,
    Offset tip,
    Offset tailReference,
    Paint paint,
    double safeSceneScale,
  ) {
    final vector = tip - tailReference;
    final length = vector.distance;
    if (length <= 0.001) return;

    final direction = Offset(vector.dx / length, vector.dy / length);
    final perpendicular = Offset(-direction.dy, direction.dx);
    final wingLength = 8.0 / safeSceneScale + paint.strokeWidth;
    final wingWidth = wingLength * 0.56;
    final base = tip - direction * wingLength;
    final wingA = base + perpendicular * wingWidth;
    final wingB = base - perpendicular * wingWidth;
    final arrowPaint = Paint()
      ..color = paint.color
      ..strokeWidth = paint.strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(tip, wingA, arrowPaint);
    canvas.drawLine(tip, wingB, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _GraphLinePainter oldDelegate) {
    return oldDelegate.layout.contentBounds != layout.contentBounds ||
        oldDelegate.layout.ringRadii.length != layout.ringRadii.length ||
        oldDelegate.layout.edgeLayouts.length != layout.edgeLayouts.length ||
        oldDelegate.layout.edgeLayouts != layout.edgeLayouts ||
        oldDelegate.selectedWordId != selectedWordId ||
        oldDelegate.selectedEdgeIds.length != selectedEdgeIds.length ||
        oldDelegate.selectedEdgeIds.difference(selectedEdgeIds).isNotEmpty ||
        oldDelegate.actualPeripheralWordNodeIds.length !=
            actualPeripheralWordNodeIds.length ||
        oldDelegate.actualPeripheralWordNodeIds
            .difference(actualPeripheralWordNodeIds)
            .isNotEmpty ||
        oldDelegate.showLabels != showLabels ||
        oldDelegate.sceneScale != sceneScale;
  }
}
