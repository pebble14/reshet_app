class Word {
  final String id;
  final String? language;
  final String? strongNumber;
  final String? spelling1;
  final String? pronunciation1;
  final String? meaning1;

  Word({
    required this.id,
    this.language,
    this.strongNumber,
    this.spelling1,
    this.pronunciation1,
    this.meaning1,
  });

  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'] as String,
      language: map['언어'] as String?,
      strongNumber: map['스트롱넘버'] as String?,
      spelling1: map['표기1'] as String?,
      pronunciation1: map['발음1'] as String?,
      meaning1: map['의미1'] as String?,
    );
  }
}
