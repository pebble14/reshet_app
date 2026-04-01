import 'package:flutter/material.dart';

import '../data/repositories/word_repository.dart';
import 'word_graph_cache.dart';
import 'word_expression_set.dart';

class WordEditScreen extends StatefulWidget {
  final Map<String, dynamic> word;

  const WordEditScreen({super.key, required this.word});

  @override
  State<WordEditScreen> createState() => _WordEditScreenState();
}

class _WordEditScreenState extends State<WordEditScreen> {
  final WordRepository _repository = WordRepository();

  late final TextEditingController _strongController;
  late final TextEditingController _noteController;
  late final TextEditingController _customLanguageController;
  final List<WordExpressionSetControllerGroup> _expressionSetControllerGroups =
      [];
  final List<TextEditingController> _meaningControllers = [];

  late String _selectedLanguageGroup;
  bool _isSaving = false;

  static const List<String> _languageGroups = [
    '히브리어/아람어',
    '헬라어',
    '라틴어',
    '영어',
    '기타',
  ];

  @override
  void initState() {
    super.initState();

    final originalLanguage = (widget.word['언어'] ?? '').toString();

    _selectedLanguageGroup = _resolveLanguageGroup(originalLanguage);
    _customLanguageController = TextEditingController(
      text:
          (_selectedLanguageGroup == '히브리어/아람어' ||
              _selectedLanguageGroup == '기타')
          ? originalLanguage
          : '',
    );

    _strongController = TextEditingController(
      text: (widget.word['스트롱넘버'] ?? '').toString(),
    );
    _expressionSetControllerGroups.addAll(
      createExpressionSetControllerGroups(widget.word),
    );
    final meaningValues = _loadMeaningValues(widget.word);
    if (meaningValues.isEmpty) {
      _meaningControllers.add(TextEditingController());
    } else {
      _meaningControllers.addAll(
        meaningValues.map((value) => TextEditingController(text: value)),
      );
    }
    _noteController = TextEditingController(
      text: (widget.word['비고'] ?? '').toString(),
    );
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

  List<String> _loadMeaningValues(Map<String, dynamic> word) {
    final values = <String>[];

    for (var index = 1; index <= 7; index++) {
      final value = (word['의미$index'] ?? '').toString().trim();
      if (value.isEmpty) {
        continue;
      }
      values.add(value);
    }

    return values;
  }

  List<String> _collectMeaningValues() {
    return _meaningControllers
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .take(7)
        .toList(growable: false);
  }

  Map<String, String?> _buildMeaningColumns(List<String> values) {
    final columns = <String, String?>{};

    for (var index = 1; index <= 7; index++) {
      columns['의미$index'] = index <= values.length ? values[index - 1] : null;
    }

    return columns;
  }

  void _addMeaningField() {
    if (_meaningControllers.length >= 7) {
      return;
    }

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
      _expressionSetControllerGroups.add(controllerGroup);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      controllerGroup.spellingFocusNode.requestFocus();
    });
  }

  void _removeExpressionSet(int index) {
    if (_expressionSetControllerGroups.length <= 1) {
      return;
    }

    final controllerGroup = _expressionSetControllerGroups.removeAt(index);
    controllerGroup.dispose();
  }

  Widget _buildMeaningSection(BuildContext context) {
    final theme = Theme.of(context);
    final canAddMeaning = !_isSaving && _meaningControllers.length < 7;

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
          Text('최대 7개까지 저장됩니다.', style: theme.textTheme.bodySmall),
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
    return WordExpressionSetSection(
      controllerGroups: _expressionSetControllerGroups,
      enabled: !_isSaving,
      onAddSet: _addExpressionSet,
      onRemoveSet: (index) {
        setState(() {
          _removeExpressionSet(index);
        });
      },
    );
  }

  Future<void> _save() async {
    final expressionColumns = fromExpressionSetList(
      collectExpressionSetDrafts(_expressionSetControllerGroups),
    );
    final spelling = expressionColumns['표기1'];

    if (spelling == null || spelling.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('첫 번째 표현 세트의 표기는 필수입니다.')));
      return;
    }

    final resolvedLanguage = _resolveLanguageValue();
    if (resolvedLanguage == null || resolvedLanguage.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('실제 언어명을 입력해주세요.')));
      return;
    }

    final strong = _strongController.text.trim().isEmpty
        ? null
        : _strongController.text.trim().toUpperCase();

    final duplicates = await _repository.findDuplicateCandidates(
      language: resolvedLanguage,
      strongNumber: strong,
      spelling1: spelling,
      excludeId: widget.word['id'].toString(),
    );

    if (duplicates.isNotEmpty) {
      final shouldContinue = await _showDuplicateWarningDialog(
        language: resolvedLanguage,
        strongNumber: strong,
        spelling1: spelling,
        candidates: duplicates,
      );

      if (shouldContinue != true) return;
    }

    setState(() => _isSaving = true);

    try {
      final meaningColumns = _buildMeaningColumns(_collectMeaningValues());

      await _repository.updateWord(
        id: widget.word['id'].toString(),
        language: resolvedLanguage,
        strongNumber: strong,
        spelling1: spelling,
        transliteration1: expressionColumns['음역1'],
        pronunciation1: expressionColumns['발음1'],
        expressionColumns: expressionColumns,
        meaning1: meaningColumns['의미1'],
        meaning2: meaningColumns['의미2'],
        meaning3: meaningColumns['의미3'],
        meaning4: meaningColumns['의미4'],
        meaning5: meaningColumns['의미5'],
        meaning6: meaningColumns['의미6'],
        meaning7: meaningColumns['의미7'],
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      WordGraphDataCache.clear();

      if (!mounted) return;

      final updatedWord = Map<String, dynamic>.from(widget.word);
      updatedWord['언어'] = resolvedLanguage;
      updatedWord['스트롱넘버'] = strong;
      updatedWord.addAll(expressionColumns);
      for (final entry in meaningColumns.entries) {
        updatedWord[entry.key] = entry.value;
      }
      updatedWord['비고'] = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim();

      Navigator.pop(context, updatedWord);
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
    required List<Map<String, dynamic>> candidates,
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
                        : '같은 언어/표기1을 가진 기존 단어가 있습니다.',
                  ),
                  const SizedBox(height: 12),
                  ...candidates.map((c) {
                    final id = (c['id'] ?? '').toString();
                    final lang = (c['언어'] ?? '').toString();
                    final strong = (c['스트롱넘버'] ?? '').toString();
                    final spelling = (c['표기1'] ?? '').toString();
                    final meaning = (c['의미1'] ?? '').toString();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '단어 ID: $id\n언어: $lang\n스트롱: $strong\n표기1: $spelling\n의미1: $meaning',
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
    final idText = (widget.word['id'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(title: const Text('단어 편집')),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
                  (lang) =>
                      DropdownMenuItem<String>(value: lang, child: Text(lang)),
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
    );
  }
}
