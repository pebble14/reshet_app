import 'package:flutter/material.dart';

String buildWordRepresentativeSpelling(
  Map<String, dynamic> wordMap, {
  String fallback = '',
}) {
  for (var index = 1; index <= 6; index++) {
    final value = (wordMap['표기$index'] ?? '').toString().trim();
    if (value.isNotEmpty) {
      return value;
    }
  }

  return fallback;
}

String buildWordDisplayStrong(Map<String, dynamic> wordMap) {
  final strong = (wordMap['스트롱넘버'] ?? '').toString();
  return formatWordDisplayStrong(strong);
}

String formatWordDisplayStrong(String strong) {
  final trimmed = strong.trim();
  final match = RegExp(r'^([A-Za-z])(\d+)$').firstMatch(trimmed);
  if (match == null) {
    return trimmed;
  }

  final prefix = match.group(1)!.toUpperCase();
  final numericPart = int.tryParse(match.group(2)!);
  if (numericPart == null) {
    return trimmed;
  }

  return '$prefix$numericPart';
}

class WordInfoPanel extends StatelessWidget {
  final Map<String, dynamic> wordMap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onOpenDetail;
  final VoidCallback? onShowGraph;
  final bool isDeleting;

  const WordInfoPanel({
    super.key,
    required this.wordMap,
    this.onEdit,
    this.onDelete,
    this.onOpenDetail,
    this.onShowGraph,
    this.isDeleting = false,
  });

  @override
  Widget build(BuildContext context) {
    final representativeSpelling = buildWordRepresentativeSpelling(wordMap);
    final strong = buildWordDisplayStrong(wordMap);
    final language = _readValue('언어');
    final spellings = _collectSeries('표기', 6);
    final transliterations = _collectSeries('음역', 6);
    final pronunciations = _collectSeries('발음', 6);
    final meanings = _collectSeries('의미', 7);
    final note = _readValue('비고');
    final sections = <_WordInfoSection>[
      if (representativeSpelling.isNotEmpty)
        _WordInfoSection(label: '대표 표기', values: [representativeSpelling]),
      if (strong.isNotEmpty)
        _WordInfoSection(label: '스트롱 번호', values: [strong]),
      if (language.isNotEmpty) _WordInfoSection(label: '언어', values: [language]),
      if (spellings.isNotEmpty) _WordInfoSection(label: '표기', values: spellings),
      if (transliterations.isNotEmpty)
        _WordInfoSection(label: '음역', values: transliterations),
      if (pronunciations.isNotEmpty)
        _WordInfoSection(label: '발음', values: pronunciations),
      if (meanings.isNotEmpty) _WordInfoSection(label: '의미', values: meanings),
      if (note.isNotEmpty) _WordInfoSection(label: '비고', values: [note]),
    ];
    final hasActions =
        onEdit != null ||
        onDelete != null ||
        onOpenDetail != null ||
        onShowGraph != null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var index = 0; index < sections.length; index++) ...[
          _WordInfoRow(
            label: sections[index].label,
            values: sections[index].values,
            emphasizeValue: sections[index].label == '대표 표기',
          ),
          if (index < sections.length - 1) const Divider(height: 24),
        ],
        if (hasActions) ...[
          if (sections.isNotEmpty) const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (onEdit != null)
                ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('편집'),
                ),
              if (onOpenDetail != null)
                OutlinedButton.icon(
                  onPressed: onOpenDetail,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('상세화면에서 열기'),
                ),
              if (onShowGraph != null)
                ElevatedButton.icon(
                  onPressed: onShowGraph,
                  icon: const Icon(Icons.account_tree_outlined),
                  label: const Text('그래프 보기'),
                ),
              if (onDelete != null)
                FilledButton.icon(
                  onPressed: isDeleting ? null : onDelete,
                  icon: isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete),
                  label: Text(isDeleting ? '삭제 중...' : '삭제'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  String _readValue(String key) {
    return (wordMap[key] ?? '').toString().trim();
  }

  List<String> _collectSeries(String prefix, int count) {
    final values = <String>[];

    for (var index = 1; index <= count; index++) {
      final value = _readValue('$prefix$index');
      if (value.isEmpty || values.contains(value)) {
        continue;
      }
      values.add(value);
    }

    return values;
  }
}

class _WordInfoSection {
  final String label;
  final List<String> values;

  const _WordInfoSection({required this.label, required this.values});
}

class _WordInfoRow extends StatelessWidget {
  final String label;
  final List<String> values;
  final bool emphasizeValue;

  const _WordInfoRow({
    required this.label,
    required this.values,
    this.emphasizeValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueStyle = emphasizeValue
        ? Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              values.join('\n'),
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}
