/// WORD_TABLE의 한 행을 앱에서 다루기 위한 모델 클래스
/// - DB 컬럼(한글 이름)을 Dart 필드(영문)로 매핑한다.
/// - fromMap()은 DB 조회 결과 Map을 Word 객체로 변환한다.
class Word {
  final String id;
  final String? language;
  final String? strongNumber;
  final String? spelling1;
  final String? transliteration1;
  final String? pronunciation1;
  final String? meaning1;

  Word({
    required this.id,
    this.language,
    this.strongNumber,
    this.spelling1,
    this.transliteration1,
    this.pronunciation1,
    this.meaning1,
  });

  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'] as String,
      language: map['언어'] as String?,
      strongNumber: map['스트롱넘버'] as String?,
      spelling1: map['표기1'] as String?,
      transliteration1: map['음역1'] as String?,
      pronunciation1: map['발음1'] as String?,
      meaning1: map['의미1'] as String?,
    );
  }
}
