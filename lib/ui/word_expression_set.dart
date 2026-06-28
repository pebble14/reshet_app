/*
  word_expression_set.dart

  단어 입력/편집 화면에서 표기/음역/발음을 하나의 "표현 세트"로 묶어
  다루기 위한 UI 전용 모델과 공통 위젯을 제공한다.

  역할:
  1. WORD_TABLE의 표기1~6 / 음역1~6 / 발음1~6 컬럼을 UI 리스트 구조로 변환
  2. 입력 중인 표현 세트를 컨트롤러 묶음으로 관리
  3. 편집 화면과 생성 다이얼로그에서 공통 UI를 재사용

  향후 확장:
  - 세트 순서 변경(reorder)
  - 세트 단위 validation 고도화
  - 카드 스타일 세분화
*/

import 'package:flutter/material.dart';

import '../data/adapters/legacy_word_expression_read_adapter.dart';
import '../domain/expression/expression_read_models.dart';
import '../domain/word/word_edit_seed.dart';
import '../domain/word/word_write_models.dart';

/// 표현 세트 1건을 UI에서 다루기 위한 초안 모델이다.
class WordExpressionSetDraft {
  final String spelling;
  final String transliteration;
  final String pronunciation;

  const WordExpressionSetDraft({
    required this.spelling,
    required this.transliteration,
    required this.pronunciation,
  });

  const WordExpressionSetDraft.empty()
    : spelling = '',
      transliteration = '',
      pronunciation = '';

  WordExpressionSetDraft normalized() {
    return WordExpressionSetDraft(
      spelling: spelling.trim(),
      transliteration: transliteration.trim(),
      pronunciation: pronunciation.trim(),
    );
  }

  bool get hasAnyValue {
    final normalizedDraft = normalized();
    return normalizedDraft.spelling.isNotEmpty ||
        normalizedDraft.transliteration.isNotEmpty ||
        normalizedDraft.pronunciation.isNotEmpty;
  }
}

enum WordExpressionSetIssueSeverity { error, warning }

class WordExpressionSetValidationIssue {
  final WordExpressionSetIssueSeverity severity;
  final String message;
  final int setIndex;

  const WordExpressionSetValidationIssue({
    required this.severity,
    required this.message,
    required this.setIndex,
  });

  bool get isError => severity == WordExpressionSetIssueSeverity.error;

  bool get isWarning => severity == WordExpressionSetIssueSeverity.warning;
}

class WordExpressionSetValidationResult {
  final List<WordExpressionSetValidationIssue> errors;
  final List<WordExpressionSetValidationIssue> warnings;

  const WordExpressionSetValidationResult({
    this.errors = const [],
    this.warnings = const [],
  });

  bool get hasErrors => errors.isNotEmpty;

  List<WordExpressionSetValidationIssue> errorsForSet(int setIndex) {
    return errors
        .where((issue) => issue.setIndex == setIndex)
        .toList(growable: false);
  }

  List<WordExpressionSetValidationIssue> warningsForSet(int setIndex) {
    return warnings
        .where((issue) => issue.setIndex == setIndex)
        .toList(growable: false);
  }
}

/// 표현 세트 1건의 입력 상태를 컨트롤러 단위로 관리한다.
class WordExpressionSetControllerGroup {
  final TextEditingController spellingController;
  final TextEditingController transliterationController;
  final TextEditingController pronunciationController;
  final FocusNode spellingFocusNode;
  final FocusNode transliterationFocusNode;
  final FocusNode pronunciationFocusNode;

  WordExpressionSetControllerGroup({
    String spelling = '',
    String transliteration = '',
    String pronunciation = '',
  }) : spellingController = TextEditingController(text: spelling),
       transliterationController = TextEditingController(text: transliteration),
       pronunciationController = TextEditingController(text: pronunciation),
       spellingFocusNode = FocusNode(),
       transliterationFocusNode = FocusNode(),
       pronunciationFocusNode = FocusNode();

  factory WordExpressionSetControllerGroup.fromDraft(
    WordExpressionSetDraft draft,
  ) {
    return WordExpressionSetControllerGroup(
      spelling: draft.spelling,
      transliteration: draft.transliteration,
      pronunciation: draft.pronunciation,
    );
  }

  WordExpressionSetDraft toDraft() {
    return WordExpressionSetDraft(
      spelling: spellingController.text,
      transliteration: transliterationController.text,
      pronunciation: pronunciationController.text,
    );
  }

  void dispose() {
    spellingController.dispose();
    transliterationController.dispose();
    pronunciationController.dispose();
    spellingFocusNode.dispose();
    transliterationFocusNode.dispose();
    pronunciationFocusNode.dispose();
  }
}

/// DB의 표현 컬럼을 UI 리스트 구조로 변환한다.
List<WordExpressionSetDraft> toExpressionSetList(Map<String, dynamic> word) {
  final readResult = readLegacyWordExpressionRow(word);
  return _expressionSetDraftsFromReadResult(readResult);
}

/// draft를 canonical write 세트로 정리한다.
/// - 표기가 있는 세트만 저장 후보로 유지한다.
/// - representative는 compacting 이후 항상 seq=1 세트로 재배치된다.
CanonicalizedExpressionSetWriteResult canonicalizeExpressionSetDrafts(
  List<WordExpressionSetDraft> drafts, {
  List<WordWriteExclusionIssue> legacyHiddenSlotIssues = const [],
}) {
  final expressionSets = <CanonicalExpressionWriteSet>[];
  final exclusionIssues = <WordWriteExclusionIssue>[...legacyHiddenSlotIssues];

  for (var index = 0; index < drafts.length; index++) {
    final draft = drafts[index].normalized();
    final hasSupplementalValue =
        draft.transliteration.isNotEmpty || draft.pronunciation.isNotEmpty;

    if (draft.spelling.isNotEmpty) {
      final seq = expressionSets.length + 1;
      expressionSets.add(
        CanonicalExpressionWriteSet(
          spelling: draft.spelling,
          transliteration: _nullIfEmpty(draft.transliteration),
          pronunciation: _nullIfEmpty(draft.pronunciation),
          seq: seq,
          isRepresentative: seq == 1,
        ),
      );
      continue;
    }

    if (!hasSupplementalValue) {
      continue;
    }

    exclusionIssues.add(
      WordWriteExclusionIssue(
        issueCode: supplementalWithoutSpellingWriteIssueCode,
        sourceKind: WordWriteExclusionSourceKind.draft,
        sourceIndex: index + 1,
        rawSpelling: _nullIfEmpty(draft.spelling),
        rawTransliteration: _nullIfEmpty(draft.transliteration),
        rawPronunciation: _nullIfEmpty(draft.pronunciation),
        resolution: excludedFromWriteResolution,
      ),
    );
  }

  return CanonicalizedExpressionSetWriteResult(
    expressionSets: expressionSets,
    exclusionIssues: exclusionIssues,
  );
}

List<WordWriteExclusionIssue> buildLegacyHiddenSlotWriteExclusionIssues(
  Map<String, dynamic> word,
) {
  final readResult = readLegacyWordExpressionRow(word);
  return buildLegacyHiddenSlotWriteExclusionIssuesFromReadResult(readResult);
}

List<WordWriteExclusionIssue>
buildLegacyHiddenSlotWriteExclusionIssuesFromReadResult(
  CanonicalExpressionReadResult readResult,
) {
  return buildWordEditHiddenSlotIssuesFromReadResult(readResult);
}

/// 기존 단어 맵을 컨트롤러 리스트로 변환하되 최소 1세트를 보장한다.
List<WordExpressionSetControllerGroup> createExpressionSetControllerGroups(
  Map<String, dynamic> word,
) {
  final readResult = readLegacyWordExpressionRow(word);
  return createExpressionSetControllerGroupsFromReadResult(
    readResult,
    wordId: (word['id'] ?? '').toString(),
  );
}

List<WordExpressionSetControllerGroup>
createExpressionSetControllerGroupsFromReadResult(
  CanonicalExpressionReadResult readResult, {
  required String wordId,
}) {
  _logExpressionSetReadIssues(wordId, readResult);
  final drafts = _expressionSetDraftsFromReadResult(readResult);
  final seededDrafts = drafts.isEmpty
      ? const [WordExpressionSetDraft.empty()]
      : drafts;

  return seededDrafts
      .map(WordExpressionSetControllerGroup.fromDraft)
      .toList(growable: true);
}

List<WordExpressionSetDraft> _expressionSetDraftsFromReadResult(
  CanonicalExpressionReadResult readResult,
) {
  return readResult.sets
      .map(
        (set) => WordExpressionSetDraft(
          spelling: set.spelling,
          transliteration: set.transliteration ?? '',
          pronunciation: set.pronunciation ?? '',
        ).normalized(),
      )
      .toList(growable: false);
}

void _logExpressionSetReadIssues(
  String wordId,
  CanonicalExpressionReadResult readResult,
) {
  if (readResult.issues.isEmpty) {
    return;
  }

  final normalizedWordId = wordId.trim();
  final sourceSlots = readResult.issues
      .map((issue) => issue.sourceSlot.toString())
      .join(',');

  debugPrint(
    '[ExpressionReadIssue] '
    'wordId=$normalizedWordId '
    'issueCount=${readResult.issues.length} '
    'sourceSlots=$sourceSlots',
  );
}

/// 현재 입력 중인 컨트롤러 값을 UI 모델 리스트로 수집한다.
List<WordExpressionSetDraft> collectExpressionSetDrafts(
  List<WordExpressionSetControllerGroup> controllerGroups,
) {
  return controllerGroups
      .map((group) => group.toDraft())
      .toList(growable: false);
}

/// raw draft 기준으로 표현 세트 저장 규칙을 검사한다.
WordExpressionSetValidationResult validateExpressionSetDrafts(
  List<WordExpressionSetDraft> drafts,
) {
  final errors = <WordExpressionSetValidationIssue>[];
  final warnings = <WordExpressionSetValidationIssue>[];
  final limitedDrafts = drafts.map((draft) => draft.normalized()).toList();

  if (limitedDrafts.isEmpty || limitedDrafts.first.spelling.isEmpty) {
    errors.add(
      const WordExpressionSetValidationIssue(
        severity: WordExpressionSetIssueSeverity.error,
        message: '세트 1은 표기를 입력해야 저장됩니다.',
        setIndex: 1,
      ),
    );
  }

  for (var index = 1; index < limitedDrafts.length; index++) {
    final draft = limitedDrafts[index];
    final hasSupplementalValue =
        draft.transliteration.isNotEmpty || draft.pronunciation.isNotEmpty;

    if (draft.spelling.isEmpty && hasSupplementalValue) {
      warnings.add(
        WordExpressionSetValidationIssue(
          severity: WordExpressionSetIssueSeverity.warning,
          message: '표기 없는 보조 입력은 저장 시 제외됩니다.',
          setIndex: index + 1,
        ),
      );
    }
  }

  return WordExpressionSetValidationResult(errors: errors, warnings: warnings);
}

/// 세트 제거 직후 프레임에서 위젯이 트리에서 빠진 뒤 dispose되도록 예약한다.
void disposeExpressionSetControllerGroupAfterFrame(
  WordExpressionSetControllerGroup controllerGroup,
) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    controllerGroup.dispose();
  });
}

String? _nullIfEmpty(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

Future<bool?> showWordWriteExclusionDialog(
  BuildContext context,
  List<WordWriteExclusionIssue> issues,
) {
  final draftIssues = issues
      .where((issue) => issue.sourceKind == WordWriteExclusionSourceKind.draft)
      .toList(growable: false);
  final legacyIssues = issues
      .where(
        (issue) =>
            issue.sourceKind == WordWriteExclusionSourceKind.legacyHiddenSlot,
      )
      .toList(growable: false);
  final theme = Theme.of(context);

  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('저장 제외 항목 확인'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('다음 입력은 표기가 없어 저장되지 않고 제외됩니다.'),
                if (draftIssues.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    '이번 입력에서 제외될 세트',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...draftIssues.map(
                    (issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _WordWriteExclusionIssueCard(issue: issue),
                    ),
                  ),
                ],
                if (legacyIssues.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    '기존 데이터에서 함께 정리될 숨김 슬롯',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('기존 DB에 남아 있던 표기 없는 보조 입력도 이번 저장에서 정리됩니다.'),
                  const SizedBox(height: 8),
                  ...legacyIssues.map(
                    (issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _WordWriteExclusionIssueCard(issue: issue),
                    ),
                  ),
                ],
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
            child: const Text('제외하고 저장'),
          ),
        ],
      );
    },
  );
}

/// 표현 세트 리스트를 카드 형태로 표시하는 공통 섹션 위젯이다.
class WordExpressionSetSection extends StatelessWidget {
  final List<WordExpressionSetControllerGroup> controllerGroups;
  final bool enabled;
  final VoidCallback? onAddSet;
  final ValueChanged<int>? onMakeRepresentative;
  final ValueChanged<int>? onRemoveSet;
  final VoidCallback? onChanged;
  final ValueChanged<int>? onSetFocusLost;
  final WordExpressionSetValidationResult validationResult;
  final Set<int> visibleIssueSetIndexes;
  final int? maxSets;

  const WordExpressionSetSection({
    super.key,
    required this.controllerGroups,
    required this.enabled,
    required this.onAddSet,
    required this.onMakeRepresentative,
    required this.onRemoveSet,
    required this.onChanged,
    required this.onSetFocusLost,
    this.validationResult = const WordExpressionSetValidationResult(),
    this.visibleIssueSetIndexes = const <int>{},
    this.maxSets,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAdd =
        enabled && (maxSets == null || controllerGroups.length < maxSets!);
    final emptySetPolicyText = maxSets == null
        ? '아무 값도 없는 세트는 저장되지 않습니다.'
        : '아무 값도 없는 세트는 저장되지 않습니다. 최대 $maxSets개까지 저장됩니다.';

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
            '표현 세트',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text('세트 1은 대표 세트이며 표기가 필요합니다.', style: theme.textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            '추가 세트는 다른 표기나 보조 정보를 입력할 때 사용합니다.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 2),
          Text(emptySetPolicyText, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          for (var index = 0; index < controllerGroups.length; index++) ...[
            KeyedSubtree(
              key: ObjectKey(controllerGroups[index]),
              child: _buildExpressionSetCard(context, index),
            ),
            if (index < controllerGroups.length - 1) const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: canAdd ? onAddSet : null,
              icon: const Icon(Icons.add),
              label: const Text('+ 세트 추가'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpressionSetCard(BuildContext context, int index) {
    final theme = Theme.of(context);
    final group = controllerGroups[index];
    final setIndex = index + 1;
    final hasSpelling = group.spellingController.text.trim().isNotEmpty;
    final canMakeRepresentative =
        enabled && index > 0 && hasSpelling && onMakeRepresentative != null;
    final canRemove =
        enabled && controllerGroups.length > 1 && onRemoveSet != null;
    final showIssues = visibleIssueSetIndexes.contains(setIndex);
    final List<WordExpressionSetValidationIssue> errors = showIssues
        ? validationResult.errorsForSet(setIndex)
        : const <WordExpressionSetValidationIssue>[];
    final List<WordExpressionSetValidationIssue> warnings = showIssues
        ? validationResult.warningsForSet(setIndex)
        : const <WordExpressionSetValidationIssue>[];

    return Focus(
      canRequestFocus: false,
      onFocusChange: (hasFocus) {
        if (!hasFocus) {
          onSetFocusLost?.call(setIndex);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.35,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  setIndex == 1 ? '세트 1 (대표)' : '세트 $setIndex',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (canMakeRepresentative)
                  TextButton(
                    onPressed: () => onMakeRepresentative!(index),
                    child: const Text('대표로 설정'),
                  ),
                IconButton(
                  onPressed: canRemove ? () => onRemoveSet!(index) : null,
                  tooltip: '세트 삭제',
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: group.spellingController,
              focusNode: group.spellingFocusNode,
              enabled: enabled,
              textInputAction: TextInputAction.next,
              onChanged: (_) => onChanged?.call(),
              onSubmitted: (_) => group.transliterationFocusNode.requestFocus(),
              decoration: const InputDecoration(labelText: '표기'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: group.transliterationController,
              focusNode: group.transliterationFocusNode,
              enabled: enabled,
              textInputAction: TextInputAction.next,
              onChanged: (_) => onChanged?.call(),
              onSubmitted: (_) => group.pronunciationFocusNode.requestFocus(),
              decoration: const InputDecoration(labelText: '음역'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: group.pronunciationController,
              focusNode: group.pronunciationFocusNode,
              enabled: enabled,
              textInputAction: index < controllerGroups.length - 1
                  ? TextInputAction.next
                  : TextInputAction.done,
              onChanged: (_) => onChanged?.call(),
              onSubmitted: (_) {
                if (index < controllerGroups.length - 1) {
                  controllerGroups[index + 1].spellingFocusNode.requestFocus();
                  return;
                }
                group.pronunciationFocusNode.unfocus();
              },
              decoration: const InputDecoration(labelText: '발음'),
            ),
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...errors.map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    issue.message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            if (warnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...warnings.map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    issue.message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WordWriteExclusionIssueCard extends StatelessWidget {
  final WordWriteExclusionIssue issue;

  const _WordWriteExclusionIssueCard({required this.issue});

  @override
  Widget build(BuildContext context) {
    final values = <String>[
      if ((issue.rawSpelling ?? '').trim().isNotEmpty)
        '표기: ${issue.rawSpelling!.trim()}',
      if ((issue.rawTransliteration ?? '').trim().isNotEmpty)
        '음역: ${issue.rawTransliteration!.trim()}',
      if ((issue.rawPronunciation ?? '').trim().isNotEmpty)
        '발음: ${issue.rawPronunciation!.trim()}',
    ];

    final title = issue.sourceKind == WordWriteExclusionSourceKind.draft
        ? '세트 ${issue.sourceIndex}'
        : '숨김 슬롯 ${issue.sourceIndex}';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          if (values.isEmpty)
            const Text('저장 제외 대상 입력이 있습니다.')
          else
            Text(values.join('\n')),
        ],
      ),
    );
  }
}
