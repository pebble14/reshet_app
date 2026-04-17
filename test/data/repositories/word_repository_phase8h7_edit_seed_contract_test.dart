import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/data/adapters/legacy_word_expression_read_adapter.dart';
import 'package:reshet_app/data/repositories/word_repository.dart';
import 'package:reshet_app/domain/expression/expression_read_models.dart';
import 'package:reshet_app/domain/word/word_edit_seed.dart';
import 'package:reshet_app/domain/word/word_write_models.dart';

void main() {
  group('Phase 8-H-7 edit seed typed contract first slice', () {
    test('keeps current edit seed string and meaning rules', () {
      final seed = WordRepository().buildWordEditSeedFromWordRow({
        'id': ' E0000_0003 ',
        '언어': ' 영어 ',
        '스트롱넘버': ' h123 ',
        '비고': ' note ',
        '표기1': 'Adam',
        '의미1': ' first ',
        '의미2': '',
        '의미3': 'first',
        '의미4': '  ',
        '의미5': null,
        '의미6': ' second ',
        '의미7': ' first ',
      });

      expect(seed, isA<WordEditSeed>());
      expect(seed.wordId, ' E0000_0003 ');
      expect(seed.language, ' 영어 ');
      expect(seed.strongNumber, ' h123 ');
      expect(seed.note, ' note ');
      expect(seed.meanings, ['first', 'first', 'second', 'first']);
    });

    test(
      'reuses CanonicalExpressionReadResult and preserves hidden-slot exclusion issues',
      () {
        final seed = WordRepository().buildWordEditSeedFromWordRow({
          'id': 'H0000_0024',
          '언어': '히브리어',
          '표기1': 'כְּפַר נַחוּם',
          '음역1': '크파르 나훌',
          '표기2': '',
          '음역2': '케파르 나훌',
        });

        expect(seed.expressionReadResult, isA<CanonicalExpressionReadResult>());
        expect(seed.expressionReadResult.sets, hasLength(1));
        expect(seed.expressionReadResult.sets.single.spelling, 'כְּפַר נַחוּם');
        expect(seed.expressionReadResult.sets.single.transliteration, '크파르 나훌');
        expect(seed.expressionReadResult.issues, hasLength(1));
        expect(seed.hiddenSlotIssues, hasLength(1));

        final issue = seed.hiddenSlotIssues.single;
        expect(issue.issueCode, supplementalWithoutSpellingIssueCode);
        expect(issue.sourceKind, WordWriteExclusionSourceKind.legacyHiddenSlot);
        expect(issue.sourceIndex, 2);
        expect(issue.rawSpelling, isNull);
        expect(issue.rawTransliteration, '케파르 나훌');
        expect(issue.rawPronunciation, isNull);
        expect(issue.resolution, excludedFromWriteResolution);
      },
    );
  });
}
