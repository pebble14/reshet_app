import 'dart:convert';
import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'approved_content_sha256.dart';

/// 승인된 공개 영문 원천에서 작성한 한글 설명을 배포 후보에만 적용한다.
final class SeedRmacPolicy {
  SeedRmacPolicy._(this.hash, this._translations);

  final String? hash;
  final Map<String, Map<String, String>> _translations;
  static const columns = [
    'Part_of_Speech',
    'Tense',
    'Voice',
    'Mood',
    'Person',
    'Case',
    'Number',
    'Gender',
    'Degree',
    'Form',
  ];

  static Future<SeedRmacPolicy> read(File file) async {
    if (!await file.exists()) return SeedRmacPolicy._(null, {});
    final bytes = await file.readAsBytes();
    final value = jsonDecode(utf8.decode(bytes));
    if (value is! Map ||
        value['format'] != 1 ||
        value['scope'] != 'seed_only_korean_retranslation' ||
        value['license'] != 'Public Domain' ||
        value['translations'] is! List ||
        (value['translations'] as List).isEmpty) {
      throw StateError('지원하지 않는 RMAC 번역 목록입니다.');
    }
    final translations = <String, Map<String, String>>{};
    for (final raw in value['translations'] as List) {
      if (raw is! Map ||
          raw.length != 5 ||
          raw['column'] is! String ||
          !columns.contains(raw['column']) ||
          raw['english'] is! String ||
          (raw['english'] as String).isEmpty ||
          raw['korean'] is! String ||
          (raw['korean'] as String).trim().isEmpty ||
          raw['source_url'] is! String ||
          !RegExp(
            r'^https://www\.modernliteralversion\.org/K4-5/RMAC/[A-Z0-9-]+\.htm$',
          ).hasMatch(raw['source_url'] as String) ||
          raw['source_sha256'] is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(raw['source_sha256'] as String)) {
        throw StateError('RMAC 번역 목록의 값이 잘못되었습니다.');
      }
      final values = translations.putIfAbsent(
        raw['column'] as String,
        () => {},
      );
      if (values.containsKey(raw['english'])) {
        throw StateError('RMAC 번역이 중복입니다.');
      }
      values[raw['english'] as String] = raw['korean'] as String;
    }
    return SeedRmacPolicy._(ApprovedContentSha256.bytes(bytes), translations);
  }

  List<Map<String, Object?>> translate(
    List<Map<String, Object?>> english,
    List<Map<String, Object?>> korean,
  ) {
    final byCode = {for (final row in korean) row['RMAC']: row};
    if (english.length != korean.length ||
        byCode.length != korean.length ||
        english.map((r) => r['RMAC']).toSet().length != english.length ||
        !english.every((r) => byCode.containsKey(r['RMAC']))) {
      throw StateError('영문·한글 RMAC 식별자가 일치하지 않습니다.');
    }
    return [
      for (final source in english) _translate(source, byCode[source['RMAC']]!),
    ];
  }

  Map<String, Object?> _translate(
    Map<String, Object?> source,
    Map<String, Object?> old,
  ) {
    final result = Map<String, Object?>.from(old);
    for (final column in columns) {
      final value = source[column];
      if (value == null) {
        result[column] = null;
      } else {
        final translated = _translations[column]?[value];
        if (translated == null) {
          throw StateError('승인 목록에 없는 RMAC 영문 설명입니다: $column / $value');
        }
        result[column] = translated;
      }
    }
    return result;
  }

  void transformProjection(Map<String, Object?> tables) {
    if (hash == null) return;
    final english = Map<String, Object?>.from(tables['RMAC_TABLE'] as Map);
    final korean = Map<String, Object?>.from(tables['RMAC_TABLE_KR'] as Map);
    final translated = translate(
      [
        for (final row in english.values)
          Map<String, Object?>.from(jsonDecode(row as String) as Map),
      ],
      [
        for (final row in korean.values)
          Map<String, Object?>.from(jsonDecode(row as String) as Map),
      ],
    );
    final byCode = {for (final row in translated) row['RMAC']: row};
    tables['RMAC_TABLE_KR'] = {
      for (final entry in korean.entries)
        entry.key: jsonEncode(
          byCode[(jsonDecode(entry.value as String) as Map)['RMAC']],
        ),
    };
  }

  Future<void> apply(Transaction txn) async {
    if (hash == null) return;
    final translated = translate(
      await txn.query('RMAC_TABLE'),
      await txn.query('RMAC_TABLE_KR'),
    );
    for (final row in translated) {
      final changed = await txn.update(
        'RMAC_TABLE_KR',
        {for (final column in columns) column: row[column]},
        where: 'RMAC = ?',
        whereArgs: [row['RMAC']],
      );
      if (changed != 1) throw StateError('RMAC 번역 수정 행 수가 잘못되었습니다.');
    }
  }
}
