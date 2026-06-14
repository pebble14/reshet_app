import 'package:flutter/material.dart';

import '../data/repositories/word_repository.dart';
import '../domain/graph/graph_center_word_display_item.dart';
import '../domain/word/word_detail_like_display_item.dart';
import '../domain/word/word_edit_save_result.dart';
import 'explorer_workspace/explorer_workspace_contract.dart';
import 'explorer_workspace/word_explorer_workspace_projection_adapter.dart';
import 'word_detail_route_result.dart';
import 'word_detail_screen.dart';
import 'word_edit_screen.dart';
import 'word_graph_screen.dart';
import 'word_info_panel.dart';
import 'word_navigation_history.dart';

class _ExplorerHistorySnapshot {
  final String centerWordId;
  final String? selectedWordId;

  const _ExplorerHistorySnapshot({
    required this.centerWordId,
    required this.selectedWordId,
  });
}

class _ExplorerCenterDisplaySeed {
  final String centerWordId;
  final String representativeSpelling;
  final String displayStrongNumber;
  final String representativeTransliteration;

  const _ExplorerCenterDisplaySeed({
    required this.centerWordId,
    required this.representativeSpelling,
    required this.displayStrongNumber,
    required this.representativeTransliteration,
  });

  factory _ExplorerCenterDisplaySeed.idOnly(String centerWordId) {
    final normalizedCenterWordId = centerWordId.trim();

    return _ExplorerCenterDisplaySeed(
      centerWordId: normalizedCenterWordId,
      representativeSpelling: normalizedCenterWordId,
      displayStrongNumber: '',
      representativeTransliteration: '',
    );
  }

  factory _ExplorerCenterDisplaySeed.fromDisplayItem({
    required String centerWordId,
    required WordDetailLikeDisplayItem displayItem,
  }) {
    final normalizedCenterWordId = centerWordId.trim();
    final fallbackSpelling = (displayItem.representativeSpelling ?? '').trim();
    final fallbackTransliteration = displayItem.transliterations.isEmpty
        ? ''
        : displayItem.transliterations.first.trim();

    return _ExplorerCenterDisplaySeed(
      centerWordId: normalizedCenterWordId,
      representativeSpelling: fallbackSpelling.isNotEmpty
          ? fallbackSpelling
          : normalizedCenterWordId,
      displayStrongNumber: formatWordDisplayStrong(
        (displayItem.displayStrongNumber ?? '').trim(),
      ),
      representativeTransliteration: fallbackTransliteration,
    );
  }

  factory _ExplorerCenterDisplaySeed.fromTooltipDisplay(
    WordNavigationHistoryTooltipDisplay tooltipDisplay, {
    String? centerWordId,
  }) {
    final normalizedCenterWordId = (centerWordId ?? tooltipDisplay.wordId)
        .trim();
    final fallbackSpelling = tooltipDisplay.representativeSpelling.trim();

    return _ExplorerCenterDisplaySeed(
      centerWordId: normalizedCenterWordId,
      representativeSpelling: fallbackSpelling.isNotEmpty
          ? fallbackSpelling
          : normalizedCenterWordId,
      displayStrongNumber: tooltipDisplay.displayStrongNumber.trim(),
      representativeTransliteration: tooltipDisplay
          .representativeTransliteration
          .trim(),
    );
  }
}

_ExplorerCenterDisplaySeed _resolveExplorerBootstrapCenterDisplaySeed({
  required String wordId,
  required GraphCenterWordDisplayItem? centerDisplayItem,
  required WordDetailLikeDisplayItem? selectedDisplayItem,
}) {
  if (centerDisplayItem != null) {
    final centerWordId = centerDisplayItem.wordId.trim();
    final fallbackSpelling = centerDisplayItem.representativeSpelling.trim();

    return _ExplorerCenterDisplaySeed(
      centerWordId: centerWordId,
      representativeSpelling: fallbackSpelling.isNotEmpty
          ? fallbackSpelling
          : centerWordId,
      displayStrongNumber: centerDisplayItem.displayStrongNumber.trim(),
      representativeTransliteration: centerDisplayItem
          .representativeTransliteration
          .trim(),
    );
  }

  if (selectedDisplayItem == null) {
    return _ExplorerCenterDisplaySeed.idOnly(wordId);
  }

  return _ExplorerCenterDisplaySeed.fromDisplayItem(
    centerWordId: wordId,
    displayItem: selectedDisplayItem,
  );
}

WordNavigationHistoryTooltipDisplay _buildExplorerHistoryTooltipDisplay(
  _ExplorerCenterDisplaySeed centerDisplaySeed,
) {
  final centerWordId = centerDisplaySeed.centerWordId.trim();
  final fallbackSpelling = centerDisplaySeed.representativeSpelling.trim();
  final representativeSpelling = fallbackSpelling.isNotEmpty
      ? fallbackSpelling
      : centerWordId;
  final strongNumber = centerDisplaySeed.displayStrongNumber.trim();

  return WordNavigationHistoryTooltipDisplay(
    wordId: centerWordId,
    representativeSpelling: representativeSpelling,
    displayStrongNumber: strongNumber,
    representativeTransliteration: centerDisplaySeed
        .representativeTransliteration
        .trim(),
  );
}

@visibleForTesting
WordNavigationHistoryTooltipDisplay
resolveExplorerBootstrapCenterTooltipDisplayForTesting({
  required String wordId,
  required GraphCenterWordDisplayItem? centerDisplayItem,
  required WordDetailLikeDisplayItem? selectedDisplayItem,
}) {
  return _buildExplorerHistoryTooltipDisplay(
    _resolveExplorerBootstrapCenterDisplaySeed(
      wordId: wordId,
      centerDisplayItem: centerDisplayItem,
      selectedDisplayItem: selectedDisplayItem,
    ),
  );
}

class WordExplorerScreen extends StatefulWidget {
  final String initialWordId;
  final void Function(String wordId, String displayStrongNumber)?
  onSelectedStrongWordChanged;

  const WordExplorerScreen({
    super.key,
    required this.initialWordId,
    this.onSelectedStrongWordChanged,
  });

  @override
  State<WordExplorerScreen> createState() => _WordExplorerScreenState();
}

class _WordExplorerScreenState extends State<WordExplorerScreen> {
  final WordRepository _repository = WordRepository();

  late String _centerWordId;
  late _ExplorerCenterDisplaySeed _centerDisplaySeed;
  String? _selectedWordId;
  WordDetailLikeDisplayItem? _selectedWordDisplayItem;
  int _graphRevision = 0;
  bool _isDetailLoading = false;
  String? _detailError;
  String? _detailUnavailableMessage;
  WordNavigationHistoryEntry<_ExplorerHistorySnapshot>?
  _availablePreviousHistoryEntry;
  WordNavigationHistoryEntry<_ExplorerHistorySnapshot>?
  _availableNextHistoryEntry;
  int _historyNavigationValidationToken = 0;
  int _selectionRequestToken = 0;

  final WordNavigationHistoryController<_ExplorerHistorySnapshot> _history =
      WordNavigationHistoryController<_ExplorerHistorySnapshot>();

  @override
  void initState() {
    super.initState();
    _centerWordId = widget.initialWordId.trim();
    _centerDisplaySeed = _ExplorerCenterDisplaySeed.idOnly(_centerWordId);
    _selectedWordId = null;
    _selectedWordDisplayItem = null;
    _isDetailLoading = true;
    _history.reset(
      _createHistoryEntry(
        centerDisplaySeed: _centerDisplaySeed,
        selectedWordId: null,
      ),
    );
    _refreshHistoryNavigationAvailability();
    _initializeExplorerBootstrap();
  }

  String? _normalizeReadOnlyProjectionWordId(String? wordId) {
    if (wordId == null) {
      return null;
    }

    final normalizedWordId = wordId.trim();
    if (normalizedWordId.isEmpty) {
      return null;
    }

    return normalizedWordId;
  }

  ExplorerWorkspaceState? get _readOnlyWorkspaceProjection {
    final normalizedCenterWordId = _centerWordId.trim();
    if (normalizedCenterWordId.isEmpty) {
      return null;
    }

    final normalizedSelectedWordId = _normalizeReadOnlyProjectionWordId(
      _selectedWordId,
    );
    final detailTargetWordId = _selectedWordDisplayItem != null
        ? normalizedSelectedWordId
        : null;

    return WordExplorerWorkspaceProjectionAdapter.project(
      selectedWordId: normalizedSelectedWordId,
      graphCenterWordId: normalizedCenterWordId,
      detailTargetWordId: detailTargetWordId,
      layoutPreset: ExplorerWorkspaceLayoutPreset.balanced,
      origin: ExplorerWorkspaceTransitionOrigin.routeAlias,
    );
  }

  bool _debugValidateHiddenVisualProbe(ExplorerWorkspaceState projection) {
    final candidateSlots = <String>[
      if (projection.graphCenterWordId != null) 'graph',
      if (projection.detailTargetWordId != null) 'detail',
    ];
    final candidateLabels = <String>[
      if (projection.selectedWordId != null) projection.selectedWordId!,
      if (projection.graphCenterWordId != null) projection.graphCenterWordId!,
      if (projection.detailTargetWordId != null) projection.detailTargetWordId!,
      projection.layoutPreset.name,
      projection.origin.name,
    ];
    bool readCandidateRepresentation() {
      return candidateSlots.isNotEmpty &&
          candidateLabels.every((label) => label.trim().isNotEmpty);
    }

    final detailTargetWordId = projection.detailTargetWordId;

    return readCandidateRepresentation() &&
        (detailTargetWordId == null ||
            detailTargetWordId == projection.selectedWordId);
  }

  @override
  Widget build(BuildContext context) {
    final workspaceProjection = _readOnlyWorkspaceProjection;
    assert(() {
      final projection = workspaceProjection;
      if (projection == null) {
        return true;
      }

      final detailTargetWordId = projection.detailTargetWordId;
      return projection.graphCenterWordId != null &&
          projection.layoutPreset == ExplorerWorkspaceLayoutPreset.balanced &&
          projection.origin == ExplorerWorkspaceTransitionOrigin.routeAlias &&
          (detailTargetWordId == null ||
              detailTargetWordId == projection.selectedWordId) &&
          _debugValidateHiddenVisualProbe(projection);
    }());

    return Scaffold(
      appBar: AppBar(title: const Text('탐색')),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: WordGraphScreen(
              key: ValueKey(_graphRevision),
              centerWordId: _centerWordId,
              selectedWordId: _selectedWordId,
              appBarActionPrefix: _buildHistoryActions(),
              onSelectWordId: (selectedWordId) async {
                await _selectWord(selectedWordId);
              },
              onClearSelection: _clearSelectedWordPanel,
              onChangeCenterWordId: (centerWordId) async {
                await _selectWord(centerWordId, changeCenterWord: true);
              },
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(flex: 2, child: _buildDetailPane()),
        ],
      ),
    );
  }

  Widget _buildDetailPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDetailPaneContextStrip(),
        const Divider(height: 1),
        Expanded(child: _buildDetailPanel()),
      ],
    );
  }

  Widget _buildDetailPaneContextStrip() {
    final centerLabel = _buildDetailPaneContextWordLabel(
      fallbackWordId: _centerWordId,
      representativeSpelling: _centerDisplaySeed.representativeSpelling,
      displayStrongNumber: _centerDisplaySeed.displayStrongNumber,
      representativeTransliteration:
          _centerDisplaySeed.representativeTransliteration,
    );
    final selectedLabel = _buildDetailPaneContextSelectedLabel();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          '중심 단어: $centerLabel · $selectedLabel',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  String _buildDetailPaneContextSelectedLabel() {
    final selectedWordId = _selectedWordId?.trim();
    if (selectedWordId == null || selectedWordId.isEmpty) {
      return '선택 없음';
    }

    final displayItem = _selectedWordDisplayItem;
    if (displayItem == null) {
      return '선택: $selectedWordId';
    }

    final selectedWordLabel = _buildDetailPaneContextWordLabel(
      fallbackWordId: selectedWordId,
      representativeSpelling: displayItem.representativeSpelling,
      displayStrongNumber: displayItem.displayStrongNumber,
      representativeTransliteration: _firstNonEmptyText(
        displayItem.transliterations,
      ),
    );

    return '선택: $selectedWordLabel';
  }

  String _buildDetailPaneContextWordLabel({
    required String fallbackWordId,
    required String? representativeSpelling,
    required String? displayStrongNumber,
    required String? representativeTransliteration,
  }) {
    final normalizedFallbackWordId = fallbackWordId.trim();
    final normalizedRepresentativeSpelling = (representativeSpelling ?? '')
        .trim();
    final normalizedStrongNumber = formatWordDisplayStrong(
      displayStrongNumber ?? '',
    );
    final normalizedTransliteration = (representativeTransliteration ?? '')
        .trim();
    final primaryLabel = normalizedRepresentativeSpelling.isNotEmpty
        ? normalizedRepresentativeSpelling
        : normalizedFallbackWordId;
    final labelSegments = <String>[
      primaryLabel,
      if (normalizedStrongNumber.isNotEmpty) normalizedStrongNumber,
      if (normalizedTransliteration.isNotEmpty) normalizedTransliteration,
    ].where((segment) => segment.isNotEmpty);

    return labelSegments.join(' · ');
  }

  String _firstNonEmptyText(List<String> values) {
    for (final value in values) {
      final normalizedValue = value.trim();
      if (normalizedValue.isNotEmpty) {
        return normalizedValue;
      }
    }

    return '';
  }

  Future<void> _selectWord(
    String selectedWordId, {
    bool changeCenterWord = false,
  }) async {
    final selectionRequestToken = ++_selectionRequestToken;
    final normalizedSelectedWordId = selectedWordId.trim();
    final shouldChangeCenterWord = changeCenterWord;

    setState(() {
      if (shouldChangeCenterWord) {
        _centerWordId = normalizedSelectedWordId;
      }
      _isDetailLoading = true;
      _detailError = null;
      _detailUnavailableMessage = null;
    });

    try {
      final selectedDisplayItem = await _loadSplitViewDisplayItem(
        normalizedSelectedWordId,
      );

      if (!mounted || selectionRequestToken != _selectionRequestToken) return;

      final resolvedSelectedWordId = selectedDisplayItem == null
          ? null
          : normalizedSelectedWordId;
      final resolvedCenterDisplaySeed = shouldChangeCenterWord
          ? selectedDisplayItem == null
                ? _ExplorerCenterDisplaySeed.idOnly(normalizedSelectedWordId)
                : _ExplorerCenterDisplaySeed.fromDisplayItem(
                    centerWordId: normalizedSelectedWordId,
                    displayItem: selectedDisplayItem,
                  )
          : _centerDisplaySeed;
      setState(() {
        if (shouldChangeCenterWord) {
          _centerWordId = resolvedCenterDisplaySeed.centerWordId;
          _centerDisplaySeed = resolvedCenterDisplaySeed;
        }
        _selectedWordId = resolvedSelectedWordId;
        _selectedWordDisplayItem = selectedDisplayItem;
        _isDetailLoading = false;
        _detailUnavailableMessage = selectedDisplayItem == null
            ? '선택한 단어의 상세 정보를 찾을 수 없습니다.'
            : null;
        if (shouldChangeCenterWord) {
          _pushHistoryEntry(
            centerDisplaySeed: _centerDisplaySeed,
            selectedWordId: resolvedSelectedWordId,
          );
        } else {
          _replaceCurrentHistoryEntry(
            centerDisplaySeed: _centerDisplaySeed,
            selectedWordId: resolvedSelectedWordId,
          );
        }
      });
      _notifySelectedStrongWordChanged(
        selectedWordId: normalizedSelectedWordId,
        selectedDisplayItem: selectedDisplayItem,
      );
    } catch (e) {
      if (!mounted || selectionRequestToken != _selectionRequestToken) return;

      setState(() {
        _detailError = '상세 정보를 불러오지 못했습니다: $e';
        _isDetailLoading = false;
        _detailUnavailableMessage = null;
      });
    }
  }

  void _notifySelectedStrongWordChanged({
    required String selectedWordId,
    required WordDetailLikeDisplayItem? selectedDisplayItem,
  }) {
    final callback = widget.onSelectedStrongWordChanged;
    if (callback == null) return;

    final normalizedSelectedWordId = selectedWordId.trim();
    final displayStrongNumber = formatWordDisplayStrong(
      (selectedDisplayItem?.displayStrongNumber ?? '').trim(),
    );

    callback(normalizedSelectedWordId, displayStrongNumber);
  }

  Future<WordDetailLikeDisplayItem?> _loadSplitViewDisplayItem(
    String wordId,
  ) async {
    return _repository.getWordDetailLikeDisplayItemByIdForSplitView(wordId);
  }

  Future<void> _initializeExplorerBootstrap() async {
    final initialWordId = widget.initialWordId.trim();
    if (initialWordId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _detailError = '탐색할 단어 ID가 비어 있습니다.';
        _isDetailLoading = false;
        _detailUnavailableMessage = null;
      });
      return;
    }

    try {
      final centerDisplayItem = await _repository
          .getGraphCenterWordDisplayItemByIdForGraphCenterSingleWord(
            initialWordId,
          );
      final selectedDisplayItem = await _loadSplitViewDisplayItem(
        initialWordId,
      );
      if (!mounted) return;

      final resolvedCenterDisplaySeed =
          _resolveExplorerBootstrapCenterDisplaySeed(
            wordId: initialWordId,
            centerDisplayItem: centerDisplayItem,
            selectedDisplayItem: selectedDisplayItem,
          );
      final resolvedSelectedWordId = selectedDisplayItem == null
          ? null
          : initialWordId;

      setState(() {
        _centerWordId = resolvedCenterDisplaySeed.centerWordId;
        _centerDisplaySeed = resolvedCenterDisplaySeed;
        _selectedWordId = resolvedSelectedWordId;
        _selectedWordDisplayItem = selectedDisplayItem;
        _isDetailLoading = false;
        _detailError = null;
        _detailUnavailableMessage = selectedDisplayItem == null
            ? '?좏깮???⑥뼱???곸꽭 ?뺣낫瑜?李얠쓣 ???놁뒿?덈떎.'
            : null;
      });
      _replaceCurrentHistoryEntry(
        centerDisplaySeed: resolvedCenterDisplaySeed,
        selectedWordId: resolvedSelectedWordId,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _detailError = '탐색 초기 정보를 불러오지 못했습니다. $e';
        _isDetailLoading = false;
        _detailUnavailableMessage = null;
      });
    }
  }

  Future<void> _refreshSelectedWord({
    required String wordId,
    bool syncCenterWord = false,
    bool refreshGraphIfChanged = false,
  }) async {
    final previousDisplayItem = _selectedWordDisplayItem;

    setState(() {
      _isDetailLoading = true;
      _detailError = null;
      _detailUnavailableMessage = null;
    });

    try {
      final refreshedDisplayItem = await _loadSplitViewDisplayItem(wordId);
      final resolvedSelectedWordId = refreshedDisplayItem == null
          ? null
          : wordId.trim();
      final hasChanged =
          previousDisplayItem != refreshedDisplayItem ||
          _selectedWordId != resolvedSelectedWordId;

      if (!mounted) return;

      setState(() {
        _selectedWordId = resolvedSelectedWordId;
        _selectedWordDisplayItem = refreshedDisplayItem;
        _detailUnavailableMessage = refreshedDisplayItem == null
            ? '선택한 단어의 상세 정보를 찾을 수 없습니다.'
            : null;
        if (syncCenterWord && refreshedDisplayItem != null) {
          _centerWordId = wordId.trim();
          _centerDisplaySeed = _ExplorerCenterDisplaySeed.fromDisplayItem(
            centerWordId: wordId,
            displayItem: refreshedDisplayItem,
          );
        }
        if (refreshGraphIfChanged && hasChanged) {
          _graphRevision++;
        }
        _isDetailLoading = false;
        _replaceCurrentHistoryEntry(
          centerDisplaySeed: _centerDisplaySeed,
          selectedWordId: _selectedWordId,
        );
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _detailError = '상세 정보를 불러오지 못했습니다: $e';
        _isDetailLoading = false;
        _detailUnavailableMessage = null;
      });
    }
  }

  Future<void> _openEditSelectedWord() async {
    final selectedWordId = _selectedWordId;
    if (selectedWordId == null) return;

    final editSeed = await _repository.getWordEditSeedForExplorerEdit(
      selectedWordId,
    );
    if (!mounted) return;
    if (editSeed == null) {
      _showWordNavigationUnavailableSnackBar();
      return;
    }

    final result = await Navigator.push<WordEditSaveResult>(
      context,
      MaterialPageRoute(
        builder: (_) => WordEditScreen.fromSeed(seed: editSeed),
      ),
    );

    if (result == null || !mounted) return;

    await _refreshSelectedWord(
      wordId: result.wordId,
      syncCenterWord: _centerWordId == result.wordId,
      refreshGraphIfChanged: true,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('단어 정보가 수정되었습니다.')));
  }

  Future<void> _openSelectedWordDetail() async {
    final selectedWordId = _selectedWordId;
    final selectedDisplayItem = _selectedWordDisplayItem;
    if (selectedWordId == null || selectedDisplayItem == null) return;

    final wasCenterWord = _centerWordId == selectedWordId;

    final detailResult = await Navigator.push<WordDetailRouteResult>(
      context,
      MaterialPageRoute(
        builder: (_) => WordDetailScreen(
          wordId: selectedWordId,
          initialDisplayItem: selectedDisplayItem,
          editActionMode: WordDetailEditActionMode.returnToCaller,
          graphActionMode: WordDetailGraphActionMode.returnToCaller,
        ),
      ),
    );

    if (!mounted || selectedWordId.isEmpty) return;

    if (detailResult is WordDetailDeletedResult) {
      final deletedWordId = detailResult.wordId.trim();
      final expectedDeletedWordId = selectedWordId.trim();

      if (deletedWordId != expectedDeletedWordId) {
        await _refreshSelectedWord(
          wordId: selectedWordId,
          syncCenterWord: wasCenterWord,
          refreshGraphIfChanged: true,
        );
        return;
      }

      await _handleDeletedSelectedWord(wasCenterWord: wasCenterWord);
      return;
    }

    if (detailResult is WordDetailEditRequestedResult) {
      await _openEditSelectedWord();
      return;
    }

    if (detailResult is WordDetailGraphRequestedResult) {
      await _selectWord(detailResult.wordId, changeCenterWord: true);
      return;
    }

    await _refreshSelectedWord(
      wordId: selectedWordId,
      syncCenterWord: wasCenterWord,
      refreshGraphIfChanged: true,
    );
  }

  void _showWordNavigationUnavailableSnackBar() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('단어 정보를 찾을 수 없습니다.')));
  }

  Future<void> _handleDeletedSelectedWord({required bool wasCenterWord}) async {
    if (!wasCenterWord) {
      _clearSelectedWordPanel(refreshGraph: true);
      return;
    }

    final previousEntry = _history.previousEntry;
    if (await _isHistoryEntryAvailable(previousEntry)) {
      final entry = _history.goBack();
      if (entry != null) {
        _applyHistoryEntry(entry);
        return;
      }
    }

    final nextEntry = _history.nextEntry;
    if (await _isHistoryEntryAvailable(nextEntry)) {
      final entry = _history.goForward();
      if (entry != null) {
        _applyHistoryEntry(entry);
        return;
      }
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _clearSelectedWordPanel({bool refreshGraph = false}) {
    if (_selectedWordDisplayItem == null &&
        !_isDetailLoading &&
        _detailError == null &&
        _detailUnavailableMessage == null &&
        !refreshGraph) {
      return;
    }

    _selectionRequestToken++;
    setState(() {
      _selectedWordId = null;
      _selectedWordDisplayItem = null;
      _isDetailLoading = false;
      _detailError = null;
      _detailUnavailableMessage = null;
      if (refreshGraph) {
        _graphRevision++;
      }
      _replaceCurrentHistoryEntry(
        centerDisplaySeed: _centerDisplaySeed,
        selectedWordId: null,
      );
    });
    _notifySelectedStrongWordChanged(
      selectedWordId: '',
      selectedDisplayItem: null,
    );
  }

  List<Widget> _buildHistoryActions() {
    return [
      IconButton(
        tooltip: _buildHistoryTooltip('뒤로', _availablePreviousHistoryEntry),
        onPressed: _availablePreviousHistoryEntry != null
            ? _goBackInHistory
            : null,
        icon: const Icon(Icons.arrow_back),
      ),
      IconButton(
        tooltip: _buildHistoryTooltip('앞으로', _availableNextHistoryEntry),
        onPressed: _availableNextHistoryEntry != null
            ? _goForwardInHistory
            : null,
        icon: const Icon(Icons.arrow_forward),
      ),
    ];
  }

  Future<void> _goBackInHistory() async {
    final previousEntry = _history.previousEntry;
    if (!await _isHistoryEntryAvailable(previousEntry)) {
      await _refreshHistoryNavigationAvailability();
      return;
    }

    final entry = _history.goBack();
    if (entry == null) {
      await _refreshHistoryNavigationAvailability();
      return;
    }

    _applyHistoryEntry(entry);
  }

  Future<void> _goForwardInHistory() async {
    final nextEntry = _history.nextEntry;
    if (!await _isHistoryEntryAvailable(nextEntry)) {
      await _refreshHistoryNavigationAvailability();
      return;
    }

    final entry = _history.goForward();
    if (entry == null) {
      await _refreshHistoryNavigationAvailability();
      return;
    }

    _applyHistoryEntry(entry);
  }

  void _applyHistoryEntry(
    WordNavigationHistoryEntry<_ExplorerHistorySnapshot> entry,
  ) {
    final snapshot = entry.payload;

    setState(() {
      _centerWordId = snapshot.centerWordId;
      _centerDisplaySeed = _ExplorerCenterDisplaySeed.fromTooltipDisplay(
        entry.tooltipDisplay,
        centerWordId: snapshot.centerWordId,
      );
      _selectedWordId = null;
      _selectedWordDisplayItem = null;
      _detailError = null;
      _isDetailLoading = false;
      _detailUnavailableMessage = null;
    });
    _refreshHistoryNavigationAvailability();
  }

  void _pushHistoryEntry({
    required _ExplorerCenterDisplaySeed centerDisplaySeed,
    required String? selectedWordId,
  }) {
    final entry = _createHistoryEntry(
      centerDisplaySeed: centerDisplaySeed,
      selectedWordId: selectedWordId,
    );
    final currentEntry = _history.currentEntry;

    if (currentEntry != null &&
        _isSameHistoryLocation(currentEntry.payload, entry.payload)) {
      _history.replaceCurrent(entry);
      _refreshHistoryNavigationAvailability();
      return;
    }

    _history.push(entry);
    _refreshHistoryNavigationAvailability();
  }

  void _replaceCurrentHistoryEntry({
    required _ExplorerCenterDisplaySeed centerDisplaySeed,
    required String? selectedWordId,
  }) {
    _history.replaceCurrent(
      _createHistoryEntry(
        centerDisplaySeed: centerDisplaySeed,
        selectedWordId: selectedWordId,
      ),
    );
    _refreshHistoryNavigationAvailability();
  }

  Future<void> _refreshHistoryNavigationAvailability() async {
    final previousEntry = _history.previousEntry;
    final nextEntry = _history.nextEntry;
    final validationToken = ++_historyNavigationValidationToken;

    try {
      final existingWordIds = await _loadExistingHistoryWordIds([
        previousEntry,
        nextEntry,
      ]);

      if (!mounted || validationToken != _historyNavigationValidationToken) {
        return;
      }

      final resolvedPreviousEntry = _resolveAvailableHistoryEntry(
        previousEntry,
        existingWordIds,
      );
      final resolvedNextEntry = _resolveAvailableHistoryEntry(
        nextEntry,
        existingWordIds,
      );

      if (_availablePreviousHistoryEntry == resolvedPreviousEntry &&
          _availableNextHistoryEntry == resolvedNextEntry) {
        return;
      }

      setState(() {
        _availablePreviousHistoryEntry = resolvedPreviousEntry;
        _availableNextHistoryEntry = resolvedNextEntry;
      });
    } catch (_) {
      if (!mounted || validationToken != _historyNavigationValidationToken) {
        return;
      }

      setState(() {
        _availablePreviousHistoryEntry = null;
        _availableNextHistoryEntry = null;
      });
    }
  }

  Future<Set<String>> _loadExistingHistoryWordIds(
    Iterable<WordNavigationHistoryEntry<_ExplorerHistorySnapshot>?> entries,
  ) async {
    final candidateIds = <String>[];
    final seenIds = <String>{};

    for (final entry in entries) {
      final wordId = entry?.wordId.trim() ?? '';
      if (wordId.isEmpty || !seenIds.add(wordId)) {
        continue;
      }
      candidateIds.add(wordId);
    }

    if (candidateIds.isEmpty) {
      return const <String>{};
    }

    return _repository.probeExistingWordIdsForExplorerHistory(candidateIds);
  }

  WordNavigationHistoryEntry<_ExplorerHistorySnapshot>?
  _resolveAvailableHistoryEntry(
    WordNavigationHistoryEntry<_ExplorerHistorySnapshot>? entry,
    Set<String> existingWordIds,
  ) {
    if (entry == null) {
      return null;
    }

    final wordId = entry.wordId.trim();
    if (wordId.isEmpty || !existingWordIds.contains(wordId)) {
      return null;
    }

    return entry;
  }

  Future<bool> _isHistoryEntryAvailable(
    WordNavigationHistoryEntry<_ExplorerHistorySnapshot>? entry,
  ) async {
    final wordId = entry?.wordId.trim() ?? '';
    if (wordId.isEmpty) {
      return false;
    }

    final existingWordIds = await _repository
        .probeExistingWordIdsForExplorerHistory([wordId]);
    return existingWordIds.contains(wordId);
  }

  WordNavigationHistoryEntry<_ExplorerHistorySnapshot> _createHistoryEntry({
    required _ExplorerCenterDisplaySeed centerDisplaySeed,
    required String? selectedWordId,
  }) {
    return WordNavigationHistoryEntry<_ExplorerHistorySnapshot>(
      tooltipDisplay: _buildExplorerHistoryTooltipDisplay(centerDisplaySeed),
      payload: _ExplorerHistorySnapshot(
        centerWordId: centerDisplaySeed.centerWordId.trim(),
        selectedWordId: selectedWordId,
      ),
    );
  }

  bool _isSameHistoryLocation(
    _ExplorerHistorySnapshot left,
    _ExplorerHistorySnapshot right,
  ) {
    return left.centerWordId == right.centerWordId &&
        left.selectedWordId == right.selectedWordId;
  }

  String _buildHistoryTooltip(
    String label,
    WordNavigationHistoryEntry<_ExplorerHistorySnapshot>? entry,
  ) {
    if (entry == null) {
      return '$label: 기록 없음';
    }

    final parts = entry.tooltipDisplay.tooltipLines;

    if (parts.isEmpty) {
      return '$label: 중심';
    }

    return '$label: 중심\n${parts.join('\n')}';
  }

  Widget _buildDetailPanel() {
    if (_isDetailLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_detailError != null) {
      return Center(child: Text(_detailError!));
    }

    final displayItem = _selectedWordDisplayItem;
    if (displayItem == null) {
      final detailUnavailableMessage = _detailUnavailableMessage;
      if (detailUnavailableMessage != null) {
        return Center(child: Text(detailUnavailableMessage));
      }
      return _buildNoSelectionDetailPanel();
    }

    return WordInfoPanel(
      displayItem: displayItem,
      onEdit: _openEditSelectedWord,
      onOpenDetail: _openSelectedWordDetail,
    );
  }

  Widget _buildNoSelectionDetailPanel() {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app_outlined,
                size: 34,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                '그래프에서 단어를 선택하세요',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '선택한 단어의 상세 정보가 이 영역에 표시됩니다.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '중심 단어 정보는 상단 표시줄에서 확인할 수 있습니다.',
                style: textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
