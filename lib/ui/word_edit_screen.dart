import 'package:flutter/material.dart';

import '../data/repositories/word_repository.dart';
import '../domain/word/duplicate_candidate_display_item.dart';
import '../domain/word/word_edit_save_result.dart';
import '../domain/word/word_edit_seed.dart';
import '../domain/word/word_write_models.dart';
import '../domain/word/word_write_service.dart';
import 'word_graph_cache.dart';
import 'word_expression_set.dart';

class WordEditScreen extends StatefulWidget {
  final Map<String, dynamic>? word;
  final WordEditSeed? seed;

  const WordEditScreen({super.key, required Map<String, dynamic> word})
    : word = word,
      seed = null;

  const WordEditScreen.fromSeed({super.key, required WordEditSeed seed})
    : word = null,
      seed = seed;

  @override
  State<WordEditScreen> createState() => _WordEditScreenState();
}

class _WordEditScreenState extends State<WordEditScreen> {
  final WordRepository _repository = WordRepository();
  final WordWriteService _wordWriteService = WordWriteService();

  late final TextEditingController _strongController;
  late final TextEditingController _noteController;
  late final TextEditingController _customLanguageController;
  late final List<WordWriteExclusionIssue> _legacyHiddenSlotIssues;
  late final WordEditSeed _editSeed;
  final List<WordExpressionSetControllerGroup> _expressionSetControllerGroups =
      [];
  final List<TextEditingController> _meaningControllers = [];

  late String _selectedLanguageGroup;
  bool _isSaving = false;
  bool _didAttemptExpressionSetSave = false;
  bool _isClosingExpressionSetUi = false;
  bool _isChangingExpressionSetRepresentative = false;
  final Set<int> _blurredExpressionSetIndexes = <int>{};

  static const List<String> _languageGroups = [
    '히브리어/아람어',
    '헬라어',
    '라틴어',
    '영어',
    '기타',
  ];

  WordEditSeed _resolveInitialEditSeed() {
    final seed = widget.seed;
    if (seed != null) {
      return seed;
    }

    final word = widget.word;
    if (word == null) {
      throw StateError('WordEditScreen requires either word or seed.');
    }

    return _repository.buildWordEditSeedFromWordRow(word);
  }

  @override
  void initState() {
    super.initState();

    _editSeed = _resolveInitialEditSeed();
    final originalLanguage = _editSeed.language;

    _selectedLanguageGroup = _resolveLanguageGroup(originalLanguage);
    _customLanguageController = TextEditingController(
      text:
          (_selectedLanguageGroup == '히브리어/아람어' ||
              _selectedLanguageGroup == '기타')
          ? originalLanguage
          : '',
    );

    _strongController = TextEditingController(text: _editSeed.strongNumber);
    _legacyHiddenSlotIssues = _editSeed.hiddenSlotIssues;
    _expressionSetControllerGroups.addAll(
      createExpressionSetControllerGroupsFromReadResult(
        _editSeed.expressionReadResult,
        wordId: _editSeed.wordId,
      ),
    );
    final meaningValues = _editSeed.meanings;
    if (meaningValues.isEmpty) {
      _meaningControllers.add(TextEditingController());
    } else {
      _meaningControllers.addAll(
        meaningValues.map((value) => TextEditingController(text: value)),
      );
    }
    _noteController = TextEditingController(text: _editSeed.note);
  }

  @override
  void dispose() {
    _strongController.dispose();
    for (final controllerGroup in _expressionSetControllerGroups) {
      controllerGroup.dispose();
    }
    for (final controller in _meaningControllers) {
      controller.dispose();
    }
    _noteController.dispose();
    _customLanguageController.dispose();
    super.dispose();
  }

  String _resolveLanguageGroup(String language) {
    if (language.contains('히브리') || language.contains('아람')) {
      return '히브리어/아람어';
    }
    if (language.contains('헬라')) return '헬라어';
    if (language.contains('라틴')) return '라틴어';
    if (language.contains('영어')) return '영어';
    return '기타';
  }

  String? _resolveLanguageValue() {
    if (_selectedLanguageGroup == '히브리어/아람어' ||
        _selectedLanguageGroup == '기타') {
      final v = _customLanguageController.text.trim();
      if (v.isEmpty) return null;
      return v;
    }
    return _selectedLanguageGroup;
  }

  List<String> _collectMeaningValues() {
    return _meaningControllers
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  void _addMeaningField() {
    setState(() {
      _meaningControllers.add(TextEditingController());
    });
  }

  void _removeMeaningField(int index) {
    final controller = _meaningControllers.removeAt(index);
    controller.dispose();
  }

  void _addExpressionSet() {
    if (_expressionSetControllerGroups.length >= 6) {
      return;
    }

    final controllerGroup = WordExpressionSetControllerGroup();

    setState(() {
      _blurredExpressionSetIndexes.clear();
      _expressionSetControllerGroups.add(controllerGroup);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _isClosingExpressionSetUi ||
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
    _blurredExpressionSetIndexes.clear();
    final controllerGroup = _expressionSetControllerGroups.removeAt(index);
    disposeExpressionSetControllerGroupAfterFrame(controllerGroup);
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

  Widget _buildMeaningSection(BuildContext context) {
    final theme = Theme.of(context);
    final canAddMeaning = !_isSaving;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '의미',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text('입력한 순서대로 저장됩니다.', style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          if (_meaningControllers.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '등록된 의미가 없습니다. 아래 버튼으로 추가하세요.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          for (var index = 0; index < _meaningControllers.length; index++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _meaningControllers[index],
                    enabled: !_isSaving,
                    maxLines: 2,
                    decoration: InputDecoration(labelText: '의미 ${index + 1}'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          setState(() {
                            _removeMeaningField(index);
                          });
                        },
                  tooltip: '의미 삭제',
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ],
            ),
            if (index < _meaningControllers.length - 1)
              const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: canAddMeaning ? _addMeaningField : null,
              icon: const Icon(Icons.add),
              label: const Text('+ 의미 추가'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpressionSetSection() {
    final validationResult = _buildExpressionSetValidationResult();

    return WordExpressionSetSection(
      controllerGroups: _expressionSetControllerGroups,
      enabled: !_isSaving,
      validationResult: validationResult,
      visibleIssueSetIndexes: _visibleExpressionSetIssueIndexes(),
      onAddSet: _addExpressionSet,
      onChanged: () {
        if (!mounted || _isClosingExpressionSetUi) {
          return;
        }
        setState(() {});
      },
      onSetFocusLost: (setIndex) {
        if (!mounted ||
            _isClosingExpressionSetUi ||
            _isChangingExpressionSetRepresentative ||
            _didAttemptExpressionSetSave ||
            _blurredExpressionSetIndexes.contains(setIndex)) {
          return;
        }

        setState(() {
          _blurredExpressionSetIndexes.add(setIndex);
        });
      },
      onRemoveSet: (index) {
        setState(() {
          _removeExpressionSet(index);
        });
      },
      onMakeRepresentative: (index) {
        _makeExpressionSetRepresentative(index);
      },
    );
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

    final resolvedLanguage = _resolveLanguageValue();
    if (resolvedLanguage == null || resolvedLanguage.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('실제 언어명을 입력해주세요.')));
      return;
    }

    final canonicalizationResult = canonicalizeExpressionSetDrafts(
      expressionSetDrafts,
      legacyHiddenSlotIssues: _legacyHiddenSlotIssues,
    );
    final strong = _strongController.text.trim().isEmpty
        ? null
        : _strongController.text.trim().toUpperCase();
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();
    final payload = CanonicalWordWritePayload(
      language: resolvedLanguage,
      strongNumber: strong,
      expressionSets: canonicalizationResult.expressionSets,
      meanings: _collectMeaningValues(),
      note: note,
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

    final duplicates = await _repository.findDuplicateCandidates(
      language: payload.language,
      strongNumber: payload.strongNumber,
      spelling1: payload.representativeSpelling,
      excludeId: _editSeed.wordId,
    );

    if (duplicates.isNotEmpty) {
      final shouldContinue = await _showDuplicateWarningDialog(
        language: payload.language,
        strongNumber: payload.strongNumber,
        spelling1: payload.representativeSpelling,
        candidates: duplicates,
      );

      if (shouldContinue != true) return;
    }

    setState(() => _isSaving = true);

    try {
      await _wordWriteService.execute(
        UpdateWordCommand(wordId: _editSeed.wordId, payload: payload),
      );
      WordGraphDataCache.clear();

      if (!mounted) return;

      _isClosingExpressionSetUi = true;
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.pop(context, WordEditSaveResult(wordId: _editSeed.wordId));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    }
  }

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
                        ? '같은 스트롱넘버를 가진 기존 단어가 있습니다.'
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
                          '단어 ID: ${c.wordId}\n언어: ${c.language}\n스트롱: ${c.strongNumber}\n대표 표기: ${c.representativeSpelling}\n의미1: ${c.primaryMeaning}',
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
              child: const Text('계속 저장'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final idText = _editSeed.wordId;

    return WillPopScope(
      onWillPop: () async {
        _isClosingExpressionSetUi = true;
        FocusManager.instance.primaryFocus?.unfocus();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('단어 편집')),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            TextFormField(
              initialValue: idText,
              enabled: false,
              decoration: const InputDecoration(
                labelText: '단어 ID',
                helperText: '현재 단계에서는 id를 수정하지 않습니다.',
              ),
            ),
            const SizedBox(height: 12),
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
              onChanged: _isSaving
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() {
                        _selectedLanguageGroup = v;
                        if (v != '히브리어/아람어' && v != '기타') {
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
                enabled: !_isSaving,
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
              enabled: !_isSaving,
              decoration: const InputDecoration(labelText: '스트롱넘버 (없으면 비워둠)'),
            ),
            const SizedBox(height: 12),
            _buildExpressionSetSection(),
            const SizedBox(height: 12),
            _buildMeaningSection(context),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              enabled: !_isSaving,
              maxLines: 2,
              decoration: const InputDecoration(labelText: '비고'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}
