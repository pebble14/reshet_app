import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/word/word_detail_like_display_item.dart';
import 'word_detail_clipboard_payload.dart';

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
  final WordDetailLikeDisplayItem displayItem;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onOpenDetail;
  final VoidCallback? onShowGraph;
  final bool isDeleting;

  const WordInfoPanel({
    super.key,
    required this.displayItem,
    this.onEdit,
    this.onDelete,
    this.onOpenDetail,
    this.onShowGraph,
    this.isDeleting = false,
  });

  @override
  Widget build(BuildContext context) {
    final sections = <_WordInfoSection>[
      if (_hasText(displayItem.representativeSpelling))
        _WordInfoSection(
          label: '대표 표기',
          values: [displayItem.representativeSpelling!.trim()],
        ),
      if (_hasText(displayItem.displayStrongNumber))
        _WordInfoSection(
          label: '스트롱 번호',
          values: [displayItem.displayStrongNumber!.trim()],
        ),
      if (_hasText(displayItem.language))
        _WordInfoSection(label: '언어', values: [displayItem.language!.trim()]),
      if (displayItem.spellings.isNotEmpty)
        _WordInfoSection(label: '표기', values: displayItem.spellings),
      if (displayItem.transliterations.isNotEmpty)
        _WordInfoSection(label: '음역', values: displayItem.transliterations),
      if (displayItem.pronunciations.isNotEmpty)
        _WordInfoSection(label: '발음', values: displayItem.pronunciations),
      if (displayItem.meanings.isNotEmpty)
        _WordInfoSection(label: '의미', values: displayItem.meanings),
      if (_hasText(displayItem.note))
        _WordInfoSection(label: '비고', values: [displayItem.note!.trim()]),
    ];
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
        if (sections.isNotEmpty) const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            Tooltip(
              message: '상세 정보 복사',
              child: OutlinedButton.icon(
                onPressed: () => _copyDetailToClipboard(context),
                icon: const Icon(Icons.copy),
                label: const Text('복사'),
              ),
            ),
            if (onEdit != null)
              ElevatedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit),
                label: const Text('편집'),
              ),
            if (onOpenDetail != null)
              Tooltip(
                message: '삭제·그래프 보기 등 전체 작업용 상세 화면을 엽니다.',
                child: OutlinedButton.icon(
                  onPressed: onOpenDetail,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('상세 작업 화면 열기'),
                ),
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
    );
  }

  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  Future<void> _copyDetailToClipboard(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final payload = buildWordDetailClipboardText(displayItem);

    try {
      await Clipboard.setData(ClipboardData(text: payload));
      messenger.showSnackBar(const SnackBar(content: Text('상세 정보를 복사했습니다.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('복사에 실패했습니다.')));
    }
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
          Expanded(child: Text(values.join('\n'), style: valueStyle)),
        ],
      ),
    );
  }
}
