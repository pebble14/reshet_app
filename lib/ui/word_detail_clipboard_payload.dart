import '../domain/word/word_detail_like_display_item.dart';

String buildWordDetailClipboardText(WordDetailLikeDisplayItem displayItem) {
  final lines = <String>[];

  _addScalarLine(lines, '대표 표기', displayItem.representativeSpelling);
  _addScalarLine(lines, '스트롱 번호', displayItem.displayStrongNumber);
  _addScalarLine(lines, '언어', displayItem.language);
  _addListSection(lines, '표기', displayItem.spellings);
  _addListSection(lines, '음역', displayItem.transliterations);
  _addListSection(lines, '발음', displayItem.pronunciations);
  _addListSection(lines, '의미', displayItem.meanings);
  _addNoteSection(lines, displayItem.note);

  return lines.join('\n');
}

void _addScalarLine(List<String> lines, String label, String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return;
  }

  lines.add('$label: $text');
}

void _addListSection(List<String> lines, String label, List<String> values) {
  final displayValues = [
    for (final value in values)
      if (value.trim().isNotEmpty) value.trim(),
  ];
  if (displayValues.isEmpty) {
    return;
  }

  _addSectionGap(lines);
  lines.add('$label:');
  for (final value in displayValues) {
    lines.add('- $value');
  }
}

void _addNoteSection(List<String> lines, String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return;
  }

  _addSectionGap(lines);
  lines.add('비고:');
  lines.add(text);
}

void _addSectionGap(List<String> lines) {
  if (lines.isNotEmpty) {
    lines.add('');
  }
}
