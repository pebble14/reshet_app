import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/domain/relation/relation_formatter.dart';

void main() {
  group('RelationFormatter.resolveDirectionForPair', () {
    test('w1_to_w2에서 center가 word1이면 forward다', () {
      final direction = RelationFormatter.resolveDirectionForPair(
        directionCode: 'w1_to_w2',
        wordId1: 'A',
        wordId2: 'B',
        centerWordId: 'A',
      );

      expect(direction, RelationDirection.forward);
    });

    test('w1_to_w2에서 center가 word2이면 reverse다', () {
      final direction = RelationFormatter.resolveDirectionForPair(
        directionCode: 'w1_to_w2',
        wordId1: 'A',
        wordId2: 'B',
        centerWordId: 'B',
      );

      expect(direction, RelationDirection.reverse);
    });

    test('w2_to_w1에서 center가 word2이면 forward다', () {
      final direction = RelationFormatter.resolveDirectionForPair(
        directionCode: 'w2_to_w1',
        wordId1: 'A',
        wordId2: 'B',
        centerWordId: 'B',
      );

      expect(direction, RelationDirection.forward);
    });

    test('w2_to_w1에서 center가 word1이면 reverse다', () {
      final direction = RelationFormatter.resolveDirectionForPair(
        directionCode: 'w2_to_w1',
        wordId1: 'A',
        wordId2: 'B',
        centerWordId: 'A',
      );

      expect(direction, RelationDirection.reverse);
    });

    test('unknown과 undirected는 neutral로 본다', () {
      expect(
        RelationFormatter.resolveDirectionForPair(
          directionCode: 'unknown',
          wordId1: 'A',
          wordId2: 'B',
          centerWordId: 'A',
        ),
        RelationDirection.neutral,
      );
      expect(
        RelationFormatter.resolveDirectionForPair(
          directionCode: 'undirected',
          wordId1: 'A',
          wordId2: 'B',
          centerWordId: 'A',
        ),
        RelationDirection.neutral,
      );
    });
  });

  group('RelationFormatter.formatForPair', () {
    test('compound는 center 위치에 따라 구성/합성으로 갈린다', () {
      final componentText = RelationFormatter.formatForPair(
        relationType: 'compound',
        directionCode: 'w1_to_w2',
        wordId1: 'A',
        wordId2: 'B',
        centerWordId: 'A',
        centerWord: '어근',
        targetWord: '합성어',
      );
      final compoundText = RelationFormatter.formatForPair(
        relationType: 'compound',
        directionCode: 'w1_to_w2',
        wordId1: 'A',
        wordId2: 'B',
        centerWordId: 'B',
        centerWord: '합성어',
        targetWord: '어근',
      );

      expect(componentText.shortLabel, '구성');
      expect(componentText.phrase, '합성어를 구성하는 요소');
      expect(componentText.sentence, '어근은 합성어를 이루는 구성 요소이다');

      expect(compoundText.shortLabel, '합성');
      expect(compoundText.phrase, '어근으로 이루어진 합성어');
      expect(compoundText.sentence, '합성어는 어근을 포함하는 합성어이다');
    });

    test('related는 neutral 문구를 유지한다', () {
      final text = RelationFormatter.formatForPair(
        relationType: 'related',
        directionCode: 'unknown',
        wordId1: 'A',
        wordId2: 'B',
        centerWordId: 'A',
        centerWord: '알파',
        targetWord: '알렙',
      );

      expect(text.shortLabel, '관련');
      expect(text.phrase, '알렙과 관련');
      expect(text.sentence, '알파와 알렙은 의미적으로 관련이 있다');
    });

    test('root-related는 neutral fallback을 사용한다', () {
      final text = RelationFormatter.formatForPair(
        relationType: 'root-related',
        directionCode: 'unknown',
        wordId1: 'A',
        wordId2: 'B',
        centerWordId: 'A',
        centerWord: '사랑하다',
        targetWord: '사랑하는',
      );

      expect(text.shortLabel, '어근');
      expect(text.phrase, '사랑하는과 어근 관련');
      expect(text.sentence, '사랑하다와 사랑하는은 어근상 관련이 있다');
    });

    test('transliteration 3종은 방향별 문구를 만든다', () {
      final direct = RelationFormatter.formatForPair(
        relationType: 'direct_transliteration',
        directionCode: 'w2_to_w1',
        wordId1: 'G',
        wordId2: 'H',
        centerWordId: 'G',
        centerWord: '아빠',
        targetWord: '아바',
      );
      final approx = RelationFormatter.formatForPair(
        relationType: 'approx_transliteration',
        directionCode: 'w2_to_w1',
        wordId1: 'G',
        wordId2: 'H',
        centerWordId: 'G',
        centerWord: '할렐루야',
        targetWord: '할렐루 야',
      );
      final conventional = RelationFormatter.formatForPair(
        relationType: 'conventional_transliteration',
        directionCode: 'w2_to_w1',
        wordId1: 'G',
        wordId2: 'H',
        centerWordId: 'G',
        centerWord: '예수',
        targetWord: '여호수아',
      );

      expect(direct.shortLabel, '직음역');
      expect(direct.phrase, '아바의 직접 음역');
      expect(direct.sentence, '아빠는 아바를 직접 음역한 표현이다');

      expect(approx.shortLabel, '근사음역');
      expect(approx.phrase, '할렐루 야의 근사 음역');
      expect(approx.sentence, '할렐루야는 할렐루 야를 가깝게 옮긴 음역 표현이다');

      expect(conventional.shortLabel, '관용음역');
      expect(conventional.phrase, '여호수아의 관용 음역');
      expect(conventional.sentence, '예수는 여호수아의 관용적 음역 표현이다');
    });

    test('relation_type이 null이면 일반 관계 문구를 쓴다', () {
      final text = RelationFormatter.formatForPair(
        relationType: null,
        directionCode: 'w1_to_w2',
        wordId1: 'A',
        wordId2: 'B',
        centerWordId: 'A',
        centerWord: '에피',
        targetWord: '에피스코포스',
      );

      expect(text.shortLabel, '관계');
      expect(text.phrase, '에피스코포스와의 관계');
      expect(text.sentence, '에피와 에피스코포스 사이의 관계이다');
    });

    test('미정의 relation_type은 unknown fallback을 쓴다', () {
      final text = RelationFormatter.formatForPair(
        relationType: 'mystery_link',
        directionCode: 'w1_to_w2',
        wordId1: 'A',
        wordId2: 'B',
        centerWordId: 'A',
        centerWord: '단어A',
        targetWord: '단어B',
      );

      expect(text.shortLabel, '관계');
      expect(text.phrase, '단어B와의 관계');
      expect(text.sentence, '단어A와 단어B 사이에 정의되지 않은 관계가 있다');
    });

    test('self-reference는 자기 참조로 고정한다', () {
      final text = RelationFormatter.formatForPair(
        relationType: 'related',
        directionCode: 'unknown',
        wordId1: 'A',
        wordId2: 'A',
        centerWordId: 'A',
        centerWord: '같은단어',
        targetWord: '같은단어',
      );

      expect(text.shortLabel, isEmpty);
      expect(text.phrase, '(자기 참조)');
      expect(text.sentence, '(자기 참조)');
    });
  });
}
