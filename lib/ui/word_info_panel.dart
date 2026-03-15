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
    final representativeSpelling = buildWordRepresentativeSpelling(
      wordMap,
      fallback: '상세 정보',
    );
    final spellings = _collectSeries('표기', 6);
    final transliterations = _collectSeries('음역', 6);
    final pronunciations = _collectSeries('발음', 6);
    final meanings = _collectSeries('의미', 7);
    final strong = formatWordDisplayStrong(_readValue('스트롱넘버'));
    final language = _readValue('언어');
    final note = _readValue('비고');
    final hasActions =
        onEdit != null ||
        onDelete != null ||
        onOpenDetail != null ||
        onShowGraph != null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          representativeSpelling,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (strong.isNotEmpty || language.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (strong.isNotEmpty)
                _WordMetaChip(label: 'Strong', value: strong),
              if (language.isNotEmpty)
                _WordMetaChip(label: '언어', value: language),
            ],
          ),
        ],
        const SizedBox(height: 16),
        const Divider(),
        if (spellings.isNotEmpty) _WordInfoRow(label: '표기', values: spellings),
        if (transliterations.isNotEmpty)
          _WordInfoRow(label: '음역', values: transliterations),
        if (pronunciations.isNotEmpty)
          _WordInfoRow(label: '발음', values: pronunciations),
        if (meanings.isNotEmpty) _WordInfoRow(label: '의미', values: meanings),
        if (note.isNotEmpty) _WordInfoRow(label: '비고', values: [note]),
        if (hasActions) ...[
          const SizedBox(height: 20),
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

class _WordInfoRow extends StatelessWidget {
  final String label;
  final List<String> values;

  const _WordInfoRow({required this.label, required this.values});

  @override
  Widget build(BuildContext context) {
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
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _WordMetaChip extends StatelessWidget {
  final String label;
  final String value;

  const _WordMetaChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $value'),
    );
  }
}
