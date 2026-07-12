import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reshet_app/theme_mode_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('저장 문자열을 ThemeMode로 변환하고 미지원 값은 시스템 모드로 처리한다', () {
    expect(ThemeModePreference.fromStorageValue('system'), ThemeMode.system);
    expect(ThemeModePreference.fromStorageValue('light'), ThemeMode.light);
    expect(ThemeModePreference.fromStorageValue('dark'), ThemeMode.dark);
    expect(ThemeModePreference.fromStorageValue(null), ThemeMode.system);
    expect(
      ThemeModePreference.fromStorageValue('unsupported'),
      ThemeMode.system,
    );
  });

  test('각 ThemeMode를 저장 문자열로 변환한다', () {
    expect(ThemeModePreference.toStorageValue(ThemeMode.system), 'system');
    expect(ThemeModePreference.toStorageValue(ThemeMode.light), 'light');
    expect(ThemeModePreference.toStorageValue(ThemeMode.dark), 'dark');
  });

  test('저장값이 없으면 시스템 모드를 불러온다', () async {
    expect(await ThemeModePreference.load(), ThemeMode.system);
  });

  test('선택한 ThemeMode를 저장하고 다시 불러온다', () async {
    for (final themeMode in ThemeMode.values) {
      expect(await ThemeModePreference.save(themeMode), isTrue);
      expect(await ThemeModePreference.load(), themeMode);
    }
  });

  test('알 수 없는 저장값은 시스템 모드로 불러온다', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'unsupported'});

    expect(await ThemeModePreference.load(), ThemeMode.system);
  });

  test('저장값 읽기 오류는 시스템 모드로 처리한다', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': true});

    expect(await ThemeModePreference.load(), ThemeMode.system);
  });
}
