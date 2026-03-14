import 'package:flutter/material.dart';

import '../data/repositories/word_repository.dart';
import 'word_graph_cache.dart';

class WordEditScreen extends StatefulWidget {
  final Map<String, dynamic> word;

  const WordEditScreen({super.key, required this.word});

  @override
  State<WordEditScreen> createState() => _WordEditScreenState();
}

class _WordEditScreenState extends State<WordEditScreen> {
  final WordRepository _repository = WordRepository();

  late final TextEditingController _strongController;
  late final TextEditingController _spellingController;
  late final TextEditingController _pronunciationController;
  late final TextEditingController _meaningController;
  late final TextEditingController _noteController;
  late final TextEditingController _customLanguageController;

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
    _spellingController = TextEditingController(
      text: (widget.word['표기1'] ?? '').toString(),
    );
    _pronunciationController = TextEditingController(
      text: (widget.word['발음1'] ?? '').toString(),
    );
    _meaningController = TextEditingController(
      text: (widget.word['의미1'] ?? '').toString(),
    );
    _noteController = TextEditingController(
      text: (widget.word['비고'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _strongController.dispose();
    _spellingController.dispose();
    _pronunciationController.dispose();
    _meaningController.dispose();
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

  Future<void> _save() async {
    final spelling = _spellingController.text.trim();
    if (spelling.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('표기1은 필수입니다.')));
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
      await _repository.updateWord(
        id: widget.word['id'].toString(),
        language: resolvedLanguage,
        strongNumber: strong,
        spelling1: spelling,
        pronunciation1: _pronunciationController.text.trim().isEmpty
            ? null
            : _pronunciationController.text.trim(),
        meaning1: _meaningController.text.trim().isEmpty
            ? null
            : _meaningController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      WordGraphDataCache.clear();

      if (!mounted) return;

      final updatedWord = Map<String, dynamic>.from(widget.word);
      updatedWord['언어'] = resolvedLanguage;
      updatedWord['스트롱넘버'] = strong;
      updatedWord['표기1'] = spelling;
      updatedWord['발음1'] = _pronunciationController.text.trim().isEmpty
          ? null
          : _pronunciationController.text.trim();
      updatedWord['의미1'] = _meaningController.text.trim().isEmpty
          ? null
          : _meaningController.text.trim();
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
                          'id: $id\n언어: $lang\n스트롱: $strong\n표기1: $spelling\n의미1: $meaning',
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
              labelText: 'id',
              helperText: '현재 단계에서는 id를 수정하지 않습니다.',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedLanguageGroup,
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
          TextField(
            controller: _spellingController,
            enabled: !_isSaving,
            decoration: const InputDecoration(labelText: '표기1'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pronunciationController,
            enabled: !_isSaving,
            decoration: const InputDecoration(labelText: '발음1'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _meaningController,
            enabled: !_isSaving,
            maxLines: 2,
            decoration: const InputDecoration(labelText: '의미1'),
          ),
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
