# Google Play 비공개 테스트 준비

## 2026-11-04 데이터 업데이트 후보

- Play Console에서 비공개 테스트 Alpha의 활성 버전 코드가 2임을 확인했다. 새 AAB는 패키지 `org.reshet.study`, versionName `1.0.0`, versionCode `3`이다.
- Windows와 공통인 데이터 버전 `2026.11.04`, seed SHA256 `014d48c6d53a6948a149986a39d21497e07163a76f8b8bf06fc619f1c6717791`을 포함한다. 시험용 관계 7546의 note/source를 정리했고, 기존 발음 보류 11개·RMAC 정책을 유지했다. 편집 이력은 배포 seed에서만 비웠다.
- AAB: Git 제외 `build/common_release_20261104/public/Reshet-1.0.0+3.aab`. 기존 업로드 인증서 일치, 서명·bundletool 검증, 64-bit 라이브러리 8개의 16 KB 이상 LOAD 정렬, 내장 seed·법적 안내 일치를 확인했다. 관련 기존 테스트 19개가 통과했다.
- 기존 사용자 DB는 앱 업데이트만으로 교체하지 않는다. 새 자료를 쓰려면 외부 백업 후 `제공 데이터로 전체 교체`를 선택한다. 기존 편집 데이터와 병합하지 않는다.
- 사용자가 Google 검토 제출을 별도로 명시 승인했다. AAB 업로드·출시 노트 저장·검토 제출 요청을 완료했고, 게시 개요에서 이 Alpha 업데이트 1건만 `검토 중인 변경사항`으로 표시됨을 확인했다. 당시 사전 자동 검사는 진행 중이며 통과 후 Google 검토로 넘어간다. 관리형 게시는 사용 중지 상태이므로 승인 후 기존 테스터에게 제공된다. 프로덕션·테스터 범위는 변경하지 않았다.
- 새 버전의 실기기 수동 확인과 실제 테스터 배포 완료는 아직 확인하지 않았다. 아래 날짜별 기록과 초기 준비 설명은 당시 상태를 설명한다.

## 이번 배포의 범위

- 목표: 2026년 10월 2일, 늦어도 10월 3일까지 테스트 시작 준비. 실제 시작은 개발자 계정 확인과 Google 처리 상태에 따라 달라진다.
- 앱: Reshet / 패키지 `org.reshet.study` / 버전 `1.0.0+1`
- 무료·광고 없음, 우선 성인 테스터 대상. 콘텐츠 등급 설문은 실제 콘텐츠에 맞게 답하며 성인 대상 지정과 등급 결과는 구분한다.
- 문의: `reshetcontact@gmail.com`
- 앱의 검색·그래프·상세·편집은 오프라인 동작한다. 회원가입과 개발자 서버 전송·분석 SDK가 없다.

## Console 앱 생성 준비 (2026-10-02)

사용자가 개인 인증과 전화번호 인증 완료 및 Console 홈의 '첫 번째 앱 만들기' 표시를 보고했다. 이는 사용자 보고이며 에이전트가 Console 화면을 직접 확인한 결과는 아니다. 앱 생성·외부 입력·파일 업로드·제출은 아직 하지 않았다.

앱 생성 입력안:

| 항목 | 입력안 |
| --- | --- |
| 앱 이름 | Reshet |
| 기본 언어 | 한국어 — ko-KR |
| 앱 / 게임 | 앱 |
| 무료 / 유료 | 승인된 테스트 방향에 따라 무료 |
| 문의 이메일 | reshetcontact@gmail.com |
| 패키지 이름 입력란이 있는 경우 | org.reshet.study — 기존 Android applicationId와 같아야 함 |

앱 생성은 등록 항목을 만드는 단계이고 실제 테스트 배포·일반 공개와 구분한다. 정책·수출·앱 서명 관련 선언은 사용자가 내용을 읽고 동의한다. 실제 화면에서 아직 제출 파일 업로드를 요구하지 않는다면, 이전 AAB를 먼저 업로드하지 않는다. 최신 출처 안내와 seed를 포함한 새 AAB가 필요하다.

공식 절차: https://support.google.com/googleplay/android-developer/answer/9859152?hl=ko

전화번호 인증과 Android 실제 기기 인증은 구분한다. 홈에 'Android 휴대기기에 액세스할 수 있는지 확인'이 남아 있다면 Play Console 모바일 앱에서 별도로 처리한다. 개인·전화 인증만으로 이 항목도 완료됐다고 기록하지 않는다. 공식 안내: https://support.google.com/googleplay/android-developer/answer/14316361?hl=ko

신규 개인 계정의 프로덕션 신청 조건은 비공개 테스트에서 12명 이상이 14일 연속 참여 선택 상태를 유지하는 것이다. 내부 테스트를 진행해도 이 조건을 대신하지 않는다. 현재 목표는 비공개 테스트 시작 준비이며 10월 2~3일의 실제 시작을 보장하지 않는다. 공식 안내: https://support.google.com/googleplay/android-developer/answer/14151465?hl=ko

## 서명과 파일 관리

- 업로드 키: Git 제외 파일 `android/upload-keystore.jks`, 설정 `android/key.properties`. 비밀번호를 문서·대화·Git에 기록하지 않는다.
- 로컬 보존 사본: Git 제외 폴더 `data/backups/android_signing/20260930/`. 같은 디스크의 사본은 디스크 고장 대비 백업이 아니므로 사용자는 두 파일을 별도 안전한 저장소에도 보관한다.
- Google Play에서는 Play App Signing을 사용한다. 업로드 키와 Google이 설치 앱에 사용하는 서명 키는 역할이 다르다.
- 출시 빌드는 업로드 키로 서명하며 개발용 서명으로 우회하지 않는다. Debug 빌드는 기존 개발용 서명을 유지한다.
- 업로드 키로 직접 설치하는 출시 APK, 기존 Debug 앱, Play가 배포하는 앱은 서명이 다를 수 있다. 서명이 다른 앱을 기존 앱 위에 설치할 수 없으며, 기존 앱을 제거하면 내부 DB가 사라질 수 있다. 실제 휴대폰은 먼저 외부 백업을 저장한 뒤 전환 방법을 결정한다. 이번 준비에서 기존 휴대폰 앱을 제거하지 않는다.

재현 명령:

```powershell
flutter build appbundle --release --no-pub
flutter build apk --release --no-pub
```

- Play 제출 파일: `build/app/outputs/bundle/release/app-release.aab`
- 직접 설치 확인용 파일: `build/app/outputs/flutter-apk/app-release.apk`
- 검증 기록: Git 제외 `build/play_release/`의 DB·패키지·배포 파일·테스트 기록. 서명 비밀번호는 포함하지 않는다.
- 다음 업로드 전에 이미 사용한 `versionCode`를 다시 쓰지 않는다. 버전을 바꾸면 앱의 프로그램 정보 표시도 함께 갱신한다.

## 스토어 소개 초안

앱 이름: Reshet

짧은 설명: 성서 어휘의 뜻과 단어 관계를 검색하고 그래프로 탐색하는 연구 도구

상세 설명:

Reshet는 성서 어휘와 단어 사이의 관계를 탐색하고 자신의 연구 내용을 정리하는 도구입니다.

• 표기, 음역, 뜻풀이, Strong 번호로 어휘 검색
• 단어 상세 정보와 연결 관계 확인
• 그래프로 단어 관계 탐색
• 뜻풀이, 메모, 관계 편집
• 전체 데이터 백업과 복원
• 자신의 데이터를 유지하거나 앱에 포함된 제공 데이터로 전체 교체

핵심 기능은 인터넷 연결 없이 사용할 수 있습니다. 회원가입과 광고는 없습니다.

연구 자료는 지속적으로 검토·갱신하는 중이며, 완성된 사전이나 모든 관계에 대한 최종 판단을 의미하지 않습니다. 앱을 업데이트해도 기존 사용자 데이터를 자동으로 덮어쓰지 않습니다. 제공 데이터로 전체 교체할 때는 기존 데이터의 백업을 먼저 저장합니다.

이번 버전은 성인 사용자를 대상으로 하는 비공개 테스트 버전입니다. 오류나 개선 의견은 reshetcontact@gmail.com으로 알려주세요.

출시 메모:

첫 비공개 테스트 버전입니다. 어휘 검색, 단어 상세, 관계 그래프, 데이터 편집, 백업·복원 및 제공 데이터 전체 교체를 확인해주세요.

## 등록 자료와 Console 항목

- 지원 이메일: `reshetcontact@gmail.com`
- 개인정보처리방침: 공개 확인된 `https://pebble14.github.io/reshet-info/privacy_policy.html`을 Console에 등록한다. 앱 안에는 동일 내용의 `privacy_policy.md`를 포함한다.
- 앱 접근: 로그인·회원가입·초대 코드가 없으므로 앱 기능 접근에 별도 인증이 필요하지 않는다. 비공개 테스트 참여 링크는 별개다.
- 광고: 없음.
- 대상 사용자: 승인된 방향에 따라 성인(18세 이상). Console의 실제 항목을 확인해 입력한다.
- 데이터 보안 신고 초안: 출시 manifest에는 INTERNET 권한이 없고 코드·패키지에서 원격 전송 SDK를 확인하지 못했다. 검색·메모·관계·이력은 로컬 처리하며 백업은 사용자 선택 저장 위치로 내보낸다. 이메일 문의는 사용자가 앱 밖에서 자발적으로 제공하는 정보다. 현재 앱 동작 기준으로 앱의 사용자 데이터 수집·공유 없음으로 작성하되, Console의 각 정의·질문과 실제 배포 파일을 마지막으로 대조한다.
- 콘텐츠 등급·저작권·건강/금융 등 설문: 앱의 실제 기능과 콘텐츠에 맞게 답한다. 종교 콘텐츠라는 이유만으로 모든 항목을 일괄 '없음' 처리하지 않는다.
- 그래픽: 앱 아이콘 512×512, 기능 그래픽 1024×500, 실제 Android 화면 스크린샷을 준비한다. 구현하지 않은 기능이나 가짜 화면을 넣지 않는다.

## 배포 DB 확인과 남은 판단

- 이번 seed SHA256(2026-10-02 철자 6개 정리·발음 11개 보류·RMAC 한글 재작성 반영): `e44bb989bebdc46a22bba2efac9defd06f3bdfd500577153de85adfa1bc148bb`
- work/seed의 `PRAGMA integrity_check`는 `ok`, `PRAGMA foreign_key_check`는 0행. seed의 `CHANGE_HISTORY`는 0행, work는 1740행이다.
- `WORD_TABLE.비고`에서 교체 확인용·48-B3·테스트용·임시 메모 문자열은 발견하지 못했다. 이 좁은 점검은 모든 비공개 내용의 부재나 콘텐츠 연구 완성을 보증하지 않는다.
- 원천 연구 cache와 참고 코퍼스 파일을 앱 asset에 추가하지 않는다.
- Strong 공개 출처와 라이선스는 `docs/legal/data_attributions.md`에 안내한다. 사용자는 한국어 뜻풀이·비고를 참고 자료를 바탕으로 직접 작성했다고 설명했다. RMAC는 아래 2026-10-02 승인 정비에서 공개 영문 원천을 대조하고 seed의 한글 설명을 새로 작성했다. 이 확인을 과거 모든 입력 경위의 복구나 DB 전체에 대한 법적 보증으로 확대하지 않는다. DB 연구의 완성도는 첫 비공개 테스트의 선행 조건이 아니다.
- Reshet 자체의 소스 코드에 공개 라이선스를 임의로 부여하지 않는다.

## 테스터 안내

초대 링크는 Play Console에서 만든 뒤 이 안내에 붙인다. 링크를 받기 전 기존 Reshet를 삭제하지 않는다. 기존 개발용 앱이 설치돼 있으면 서명 차이 때문에 Play 설치가 막힐 수 있으므로 먼저 데이터를 백업하고 문의한다.

1. 참여에 사용할 Google 계정으로 테스트 초대를 수락하고 Play에서 설치한다.
2. 첫 실행에서 오류 없이 단어 목록이 나타나는지 확인한다. `G25`, `G185`, `G153`, `H39`로 검색하고 상세 정보와 관계 그래프를 연다.
3. 단어 메모를 '비공개 테스트 확인용'으로 편집하고 앱을 닫았다 다시 열어 메모가 유지되는지 확인한다.
4. '데이터 백업'으로 파일을 저장한다. '제공 데이터로 전체 교체'의 '내 데이터 유지'를 선택하면 메모가 유지돼야 한다.
5. '전체 교체'를 선택하고 백업 저장 창에서 취소하면 메모가 유지돼야 한다.
6. 다시 '전체 교체'를 선택하고 별도의 백업 파일을 저장하면 제공 데이터로 바뀌어 확인용 메모가 사라져야 한다. 앞서 만든 백업을 덮어쓰지 않는다.
7. '데이터 복원'에서 교체 전에 저장한 백업을 선택하면 자신의 메모가 돌아와야 한다. 앱을 다시 열어 확인한다.
8. 프로그램 정보에서 개인정보처리방침·자료 출처·소프트웨어 라이선스를 읽고 닫을 수 있는지 확인한다.

오류 제보에는 기기 모델, 수행한 순서, 기대했던 결과, 실제 결과, 필요하면 화면 캡처를 포함한다. 개인 메모나 전체 DB는 보내지 않아도 된다. 오류 없이 확인한 경우에도 확인한 항목과 날짜를 기록한다.

## 공식 참고

- https://docs.flutter.dev/deployment/android
- https://support.google.com/googleplay/android-developer/answer/14151465
- https://support.google.com/googleplay/android-developer/answer/11926878
- https://support.google.com/googleplay/android-developer/answer/10144311
- https://developer.android.com/guide/practices/page-sizes
- https://developer.android.com/tools/bundletool


## 이번 실행 결과

- 정식 업로드 키로 AAB와 APK 빌드 성공. AAB signature와 APK v2 signature 검증 성공.
- Google bundletool 1.18.3의 AAB validate 및 설치용 APK 생성 성공. JDK jarsigner는 self-signed·timestamp·ZIP entry 순서 관련 경고를 출력했으며, 로컬 서명 검증과 bundletool 변환의 성공을 Play Console의 최종 승인으로 해석하지 않는다.
- 실제 출시 manifest: minSdk 24, targetSdk 36, INTERNET·외부 저장소 광역 접근·카메라·위치·연락처 권한 없음. 앱 내부 receiver 보호 permission만 존재한다.
- AAB 내부 seed SHA는 원본 seed와 일치한다. 자료 cache·백업 폴더는 포함되지 않는다.
- 64비트 native library 8개의 ELF LOAD 정렬이 16KB 이상이며 출시 APK zipalign 16KB 검증도 성공. 실제 16KB 기기의 runtime 검증을 수행한 것은 아니다.
- 독립된 Android 에뮬레이터에서 출시 APK 신규 설치·DB 초기화·단어 목록·상세·그래프 표시를 확인했다. AAB에서 생성한 APK의 덮어쓰기 설치와 재실행도 성공했으며 첫 실행 안내 설정이 유지됐다. 이 에뮬레이터 검증 단계에서는 사용자 휴대폰 앱과 DB를 변경하지 않았다. 이후 휴대폰 업데이트와 수동 확인은 아래에 별도로 기록한다.
- 앱 법적 안내 및 기존 백업·복원 화면 자동 테스트 12개 통과. 변경 영역 analyze는 기존 print 안내 4개만 남으며 오류·경고는 없다.
- 스토어 이미지: `build/play_release/play_icon_512.png`, `play_feature_graphic.png`, `play_screenshot_01.png`~`03.png`. 화면 캡처는 실제 Android 에뮬레이터이며 사용자 기기의 수동 UX 확인과 구분한다.
- 남은 사항: 초기 자료 재배포 근거, 개발자 계정 완료·Console 입력·최종 제출 승인. 개인정보처리방침 공개 URL은 2026-10-01 확인 완료했다. 사용자 Android 확인은 아래 기록과 같이 통과했으며, Git 커밋·main 병합·push는 사용자 승인을 받았다.


## 사용자 휴대폰 확인 준비 (2026-09-30)

Samsung SM-A175N의 기존 Debug 앱과 최신 Debug APK의 인증서 SHA256이 같음을 확인했다. 앱을 종료하고 내부 work/seed 및 존재하는 SQLite sidecar와 기존 APK를 PC로 보존한 다음 `adb install -r`로 업데이트했다. 앱 제거·데이터 초기화·자동 실행은 하지 않았다. 업데이트 전후 모든 대상 DB 파일의 SHA256이 일치한다.

- 사전 백업: `C:/Users/kkiih/Documents/Workspace/FlutterWorkspace/reshet_app/data/backups/android_app_update/20260930T141151Z`
- 백업 DB integrity: `ok`, foreign_key_check: 0행, 단어: 15009행.
- 이 Debug APK는 실제 휴대폰 테스트용이다. Google Play 제출 파일은 앞서 정식 서명한 AAB이며 두 파일의 역할을 혼동하지 않는다.
- 사용자 확인 완료: 아래 8개 항목 모두 정상 작동한다고 보고했다(2026-09-30). 데이터 유지·저장 취소·전체 교체·백업 복원·원래 데이터 복원 후 재실행·법적 안내 화면 확인을 사용자 수동 검증 결과로 기록한다. 자동 검증과 구분한다.

휴대폰 아이콘으로 실행한 뒤 다음을 확인한다.

1. 단어 목록이 정상적으로 나타나는지 확인하고, 우선 '데이터 백업'으로 현재 데이터를 `Android_original.db` 같은 구분 가능한 파일로 저장한다. 이 파일은 마지막 원상 복구에 사용하므로 덮어쓰지 않는다.
2. G25 상세의 메모에 'Android 교체 확인용'을 추가하고 저장한다. 앱을 다시 열어 메모가 유지되는지 확인한다. 이 상태를 `Android_test.db`로 별도 백업한다.
3. '제공 데이터로 전체 교체'에서 '내 데이터 유지'를 선택한다. 확인용 메모가 유지돼야 한다.
4. 다시 '전체 교체'를 선택하고 백업 저장 창에서 취소한다. 메모가 유지돼야 한다.
5. 다시 '전체 교체'를 선택하고 새로운 파일 이름으로 백업을 저장한다. 제공 seed로 바뀌고 확인용 메모가 사라져야 한다.
6. '데이터 복원'에서 `Android_test.db`를 선택한다. 메모가 다시 나타나야 한다.
7. 마지막으로 `Android_original.db`를 복원하면 테스트 전 자신의 데이터로 돌아간다. 앱을 종료했다 다시 열어 확인한다.
8. 프로그램 정보에서 개인정보처리방침·자료 출처·소프트웨어 라이선스를 각각 읽고 닫을 수 있는지 확인한다.

실패 시 앱을 제거하거나 데이터를 지우지 않고 단계와 증상을 기록한다. PC 사전 백업도 보존돼 있다.

개인정보처리방침은 `docs/legal/privacy_policy.html`의 내용을 검토한 뒤 별도 공개 주소로 게시한다. 문의 이메일은 사용자 승인 값 `reshetcontact@gmail.com`이다. Git 커밋·main 병합·push는 승인됐으며, 외부 게시는 별도 승인 전이다. 사이트 주소가 실제 열리고 앱 내 문서와 같은 내용인지 확인한 뒤 Console에 입력한다.

## 표기·발음 출처 후속 점검 (2026-10-01)

사용자는 e-Sword Strong과 영어판·그리스어판 Wiktionary에서 철자·발음 표기를 복사했으며, 의미·비고는 참고 후 직접 작성했다고 설명했다. 이 범위를 반영해 작성 자료와 외부 참고 표기를 구분한다.

배포 seed 15,257 expression을 고정 Strong 원천의 기존 v2 파서와 실제 `WORD_TABLE.스트롱넘버`로 연결했다. 두 XML의 SHA256은 manifest와 일치한다. 발음 칸의 상호 배타적 분류는 다음과 같다.

| 분류 | expression 수 | 판단 범위 |
| --- | ---: | --- |
| 공식 발음 exact 일치 | 6,370 | 현재 값의 공개 원천 대조 근거 |
| 공식 음역 NFC 일치 | 506 | 음역이며 발음 검증과 구분 |
| 음역의 대소문자·아포스트로피 차이 후보 | 438 | 후보 비교만 수행, 저장값 변경 없음 |
| 발음의 대소문자·아포스트로피 차이 후보 | 3 | 후보 비교만 수행, 저장값 변경 없음 |
| Strong 항목은 있지만 위 비교에서 다른 값 | 7,064 | 히브리어/아람어 7,031, 헬라어 33; 출처 불법 또는 Wiktionary 복사로 단정하지 않음 |
| 공식 Strong 원천 밖의 발음 | 677 | 영어 154, 헬라어 369, 히브리어/아람어 6, 라틴어 145, 기타 3 |
| 발음 없음 | 199 | 복사 발음 내용 없음 |

기존 50-T 190개와 50-V 771개 대상은 현재 pronunciation·notation과 모두 일치한다. 조회 목적은 제공 seed의 표기·발음 대조이며, SQL과 항목별 결과·원천 고정 정보는 Git 제외 `build/play_release/data_source_review_20261001.json`에 보관한다. 원문 설명·개인 메모는 이 검토 목록에 포함하지 않는다. 후보 URL은 검색 편의를 위해 현재 철자로 만든 미검증 주소이며, 역사적 provenance나 재배포 조건 확인 완료를 뜻하지 않는다.

영어 Assyria의 현재 DB 발음 `əˈsɪɹi.ə`는 https://en.wiktionary.org/wiki/Assyria 의 영어 발음과 일치한다. 라틴어 Augustus의 `au̯ˈɡus.tus`는 https://en.wiktionary.org/wiki/Augustus 의 현대 이탈리아식 교회 라틴어 표기와 일치한다. 후자는 같은 페이지의 고전 라틴어 `au̯ˈɡʊs.tʊs`와 다른 체계다. 이 두 사례는 현재 대조 확인이며 과거 복사 시점·판본을 입증하지 않는다. 그리스어판 원문 확인은 이번 웹 도구에서 실패했으므로 확인 완료로 기록하지 않는다.

후속 배포 안내에는 실제 유지할 Wiktionary 자료의 페이지와 기여자·적용 라이선스·수정 사실 및 필요한 동일조건배포 범위를 표시한다. 단순 후보 링크 목록이나 Wiktionary 이름 추가만으로 준수 완료를 선언하지 않는다. 현재 단계에서는 앱 내 출처 문서·DB·빌드 파일을 변경하지 않았으며 전체 자료 배포권 확인은 아직 보류한다.

개인정보처리방침 공개 URL은 https://pebble14.github.io/reshet-info/privacy_policy.html 이다. 2026-10-01 인증 없는 HTTP 200 응답과 원본 HTML 바이트 일치를 확인했다. 공개 URL 마련은 완료됐으며, 앱 안내 내용이 바뀌면 공개 문서도 함께 갱신한다.

### Wiktionary 후보 페이지 연결과 안내 추가안

공식 API로 영어판 후보 701개 표제어(710 expression: Strong 범위 밖 677개와 남은 헬라어 33개)를 조회했다. 710개 모두 조회 결과를 기록했으며 564 expression은 현재 페이지가 존재하고 146개는 현재 철자로 페이지를 찾지 못했다. 원문 문자열 출현 51개 중 단순 direct IPA template의 전체 표기가 일치한 것은 45개다. DB 언어별로 영어 36, 헬라어 4, 아람어 3, 라틴어 2다. DB 언어 구분과 해당 IPA template의 언어·시대가 같은지는 별도 검토 대상이다. 예를 들어 현대 그리스어(`el`)와 고전 그리스어(`grc`)를 혼동하지 않는다. 자동 생성 발음·중첩 template은 이 exact 비교 범위 밖이므로 불일치를 오류로 해석하지 않는다.

원문 page ID·revision ID·timestamp·URL과 대조 결과를 검토 artifact에 기록했다. 현재 페이지의 존재·문자열 일치·IPA 일치 모두 과거 복사 출처를 입증하지 않는다. 찾지 못한 주소를 실제 출처처럼 출처 안내에 넣지 않는다. 원문 cache는 `build/play_release/wiktionary_review_cache/`이며 Git·앱 asset에 포함하지 않는다.

영어판과 그리스어판의 공식 `action=query&meta=siteinfo&siprop=rightsinfo` 응답에서 CC BY-SA 4.0을 확인했다. 그리스어판 단어 페이지의 웹 도구 조회 실패와 공식 API의 라이선스 확인 성공은 구분한다.

앱 내 자료 출처 안내에 넣을 추가 문구의 초안은 다음과 같다. 아직 앱 asset에는 반영하지 않았으며 이 문구만으로 항목별 출처와 재사용 조건 검토가 완료되는 것은 아니다.

> 일부 철자와 발음 표기는 영어판·그리스어판 Wiktionary를 참고하여 입력했습니다. 자료 제공자: Wiktionary 기여자. 보호되는 재사용 자료의 적용 라이선스는 CC BY-SA 4.0입니다. 해당 자료와 그 가공물에는 라이선스가 요구하는 출처 표시와 동일조건배포 조건을 유지합니다. 발음 구분 기호 생략·표기 정리 등 가공이 있을 수 있습니다. 이 안내는 Reshet 앱 코드나 독립적으로 작성한 한국어 설명 전체에 동일한 라이선스를 부여하는 선언이 아닙니다. 실제 유지 자료의 확인된 원문 링크 목록을 함께 제공합니다.

공식 조건: https://foundation.wikimedia.org/wiki/Policy:Terms_of_Use#7._Licensing_of_Content 및 https://creativecommons.org/licenses/by-sa/4.0/

후속은 146개의 미발견 페이지와 발음 체계·원문 대응이 미확정인 항목을 좁혀 검토하는 것이다. 일괄 발음 교체, 임의 데이터 라이선스 확정, source provenance의 추정 확정은 수행하지 않는다. DB 전체 배포권 검토 완료로 선언하지 않는다.

### 2026-10-01 후속: 대체 표제어와 언어 대조

미발견 146 expression에 대해 Latin 강세·장음 기호와 합자, Greek 장단 표시, Hebrew 모음 기호를 검색 후보에서만 정리했다. 104개는 대체 표제어 페이지에 연결됐고 42개는 아직 연결되지 않았다. 단어의 실제 철자·음역·발음·DB 값은 변경하지 않았다. 새 후보도 과거 복사 출처나 의미의 동일성을 자동 확정하지 않는다.

원문 direct IPA template의 전체 표기와 언어 코드를 함께 비교해 43 expression의 현재 원문 대응을 확인했다. 이 중 현대 그리스어(`el`) 4개는 고전 그리스어(`grc`)와 구분한다. `ecstasy`의 Dutch, `metrum`의 Indonesian, `sex`의 Norwegian Bokmål/Romanian, `Ægýptus`의 English 일치는 DB 언어와 달라 확인 출처 목록에 넣지 않았다. 이 불일치를 곧바로 DB 오류 또는 원래 복사 출처로 단정하지 않는다.

앱 asset인 `docs/legal/data_attributions.md`에 Wiktionary 기여자·CC BY-SA 4.0·가공 안내와 언어가 맞는 43개 대조 항목의 고정 revision 링크를 추가했다. 이는 실제 수정된 앱 내 안내이며 DB 전체의 배포권 검토 완료나 과거 provenance의 복구를 의미하지 않는다. 새 패키지·schema·DB·UI code 변경은 없다.

남은 42개와 generated pronunciation·nested template 등 direct 비교 밖의 자료는 출처 검토 목록에 그대로 보존한다. 확인된 항목의 원문 링크만 안내에 반영했으며 현재 후보만으로 미확정 자료의 재배포 조건 준수를 선언하지 않는다. Android 수동 기능 확인은 기존 통과 기록을 유지한다. 자료 출처 안내가 변경됐으므로 기존 출시 AAB/APK는 최신 안내를 포함하지 않으며 실제 제출 전 다시 빌드해야 한다.

### 남은 42개 검토 결론

42개를 모두 검토 목록에서 분류했다. “위키 페이지 미발견”을 “배포 불가” 또는 “데이터 오류”로 바꾸지 않는다.

| 구분 | 수 | 처리 제안 |
| --- | ---: | --- |
| 이미 Strong 번호와 공식 entry가 있으나 현재 값·어형이 다른 경우 | 22 | 공식 entry의 존재와 현재 표현의 재사용 근거를 구분한다. 다른 어형·음역·발음 체계를 단순 교체하지 않는다. |
| Strong 번호는 없지만 공개 Strong 발음과 같은 독립 대조 후보 | 2 | G0000_0037 / G5361, G0000_0367 / G5372. 발음 문자열은 exact이며 철자 대조에는 대소문자·기호 제거가 포함된다. Strong 번호 배정·고유명사/형용사 의미 통합은 하지 않는다. |
| 이번 제한된 기록·원천 대조로 역사적 출처를 확정하지 못한 경우 | 18 | 현행 DB를 보존한다. 현재 원문과 독립 대조하거나 별도 작성 근거를 마련한 뒤 배포 자료 판단을 한다. |

Wiktionary 공식 API의 title 검색은 `search-title-disabled`였고 이어 HTTP 429 조회 제한이 발생했다. 조회 실패를 원문 부재로 집계하지 않았으며 추가 반복 요청은 중단했다. 현재 페이지 검색으로 과거 입력 이력을 복구할 수 있다는 전제는 두지 않는다.

추가 실제 원문 확인 사례:

- G0164의 현재 `αἰχμαλωτός`와 달리 https://en.wiktionary.org/wiki/αἰχμάλωτος 는 고전 그리스어 표제어와 시대별 IPA를 제공한다. 원문 발견과 현재 DB 값의 정확한 대응은 별개다.
- 라틴어 아드라미티온의 관련 원문 https://en.wiktionary.org/wiki/Adramyttium 에 `Adramyttēum` 대체형이 있으나 현재 `Adramyttéum` 철자·발음의 출처까지 확정하지 않는다.
- https://en.wiktionary.org/wiki/iustus 는 Latin 형용사 `iūstus`와 고전/교회식 발음을 제공한다. 현재 고유명사 항목과 의미·발음이 같다고 자동 판단하지 않는다.

이번 결과를 현재 원천 검색의 최소 충분 결론으로 삼는다. 원문 미발견 수를 0으로 만들기 위한 반복 검색이나 모든 발음을 일괄 교체하는 작업은 수행하지 않는다. 필요한 후속은 출처 미확정 자료를 배포용으로 유지할 근거 또는 독립 재구축안을 마련하는 것이며, 실제 값 변경·제외·데이터 라이선스 범위 결정은 사용자에게 구체적으로 제시하고 승인받는다.

항목별 현재 값·공개 Strong 후보·원문 링크·한국어 의미·분류는 기존 Git 제외 검토 artifact에 보관했다. 앱 안내에 추가된 43개 검증 링크는 유지했다. work/seed SHA는 조사 시작 시점과 동일하며 앱 코드·DB·schema 변경은 없다. 문서만 추가 갱신했으므로 관련 UI 테스트 2개 통과 기록을 재사용하며 테스트를 반복하지 않았다. Git 커밋·병합·push와 출시 파일 재생성은 아직 하지 않았다.

### 2026-10-02: 출처 미확정 18개의 현재 자료 대조와 수정 제안

현재 자료와 대조한 결과이며 과거 입력 당시의 복사 출처를 복구한 결과가 아니다. 아래의 유지·수정은 제안이다. DB, 의미, 비고, 관계, Strong 번호를 변경하지 않았다. 원문 철자는 표의 가독성을 위해 NFC로 표시하며, 실제 저장값과 식별자는 기존 검토 artifact에서 보존한다.

| 항목 / 현재 의미 | 현재 철자 / 발음 칸 | 현재 자료의 확인 범위 | 처리 제안 |
| --- | --- | --- | --- |
| G0000_0008 아드라미티온 | `Ἀδραμύττειον` / `adramutteion` | [Adramyttium](https://en.wiktionary.org/wiki/Adramyttium)의 어원에 `Ἀδραμύττιον`이 나온다. 현재 로마자 값의 발음 대응은 미확인이다. | `ει`와 `ι`를 단순 치환하지 않는다. 어형 근거와 로마자 음역 체계를 먼저 구분한다. |
| G0000_0009 아드리아 | `Ἀδρία` / `Adria` | [Ἀδρίας](https://en.wiktionary.org/wiki/Ἀδρίας)는 아드리아해 표제어이며 어원에서 도시 이름 `Ἀδρία`를 구분한다. 현재 도시 표제어 자체의 발음은 확인하지 못했다. | 도시와 바다 중 무엇을 뜻하는지 확인하기 전 `ς`를 붙이거나 바다의 IPA로 교체하지 않는다. |
| G0000_0015 가다라 | `Γαδαρά` / `ɡá.da.ra` | [Γάδαρα](https://en.wiktionary.org/wiki/Γάδαρα)의 기원전 5세기 Attic IPA와 발음 값 전체가 일치한다. | 발음 유지, 철자 `Γάδαρα`를 승인 후보로 제시한다. |
| G0000_0042 경기/경쟁/시합 | `ἄθλος` / `ˈa.tʰlos` | [ἆθλος](https://en.wiktionary.org/wiki/ἆθλος)의 서기 1세기 Egyptian IPA와 일치한다. 같은 페이지의 기원전 5세기 발음은 다르다. | 발음을 오류로 보지 않는다. 철자 `ἆθλος`는 의미 대응 검토 후 결정한다. 이번 철자 정리 대상에서는 보류한다. |
| G0000_0048 맹렬히 움직이다 / 쏘다 | `ἀΐ́σσω` / `aː.ís.sɔː` | [ἀΐσσω](https://en.wiktionary.org/wiki/ἀΐσσω)는 대응 표제어이나 현재 IPA와 전체 일치는 아니다. DB 철자는 NFC에서도 iota에 강세가 중복된다. | 철자 중복 기호 제거와 발음 재구 변경을 별개로 취급한다. 이번 발음 교체 대상에서 보류한다. |
| G0000_0101 작은 | `ἔλαχυς` / `e.la.kʰýs` | [ἐλαχύς](https://en.wiktionary.org/wiki/ἐλαχύς)의 기원전 5세기 Attic IPA와 일치한다. | 발음 유지, 철자 `ἐλαχύς`를 승인 후보로 제시한다. |
| G0000_0102 상아 / 코끼리 | `ἔλεφας` / `e.lé.pʰaːs` | [ἐλέφας](https://en.wiktionary.org/wiki/ἐλέφας)의 기원전 5세기 Attic IPA와 일치한다. 표제어에는 장음 표시가 덧붙은 `ἐλέφᾱς`도 있다. | 발음 유지, 별도 장음 기호를 새로 도입하지 않고 철자 `ἐλέφας`를 승인 후보로 제시한다. |
| G0000_0172 잠수하는 사람 / 물에 뛰어드는 사람 | `κολυμβος` / `kó.lym.bos` | [κόλυμβος](https://en.wiktionary.org/wiki/κόλυμβος)의 기원전 5세기 Attic IPA와 일치한다. 이는 현재 한국어 의미 전부의 재검증을 뜻하지 않는다. | 발음 유지, 철자 `κόλυμβος`를 승인 후보로 제시한다. 의미·비고는 보존한다. |
| G0000_0201 (동물성)기름 | `λιπος` / `lí.pos` | [λίπος](https://en.wiktionary.org/wiki/λίπος)의 기원전 5세기 Attic IPA와 일치한다. | 발음 유지, 철자 `λίπος`를 승인 후보로 제시한다. |
| G0000_0246 연민/동정 | `οἰκτος` / `ôi̯k.tos` | [οἶκτος](https://en.wiktionary.org/wiki/οἶκτος)의 기원전 5세기 Attic IPA와 일치한다. | 발음 유지, 철자 `οἶκτος`를 승인 후보로 제시한다. |
| G0000_0280 곁에 자리한 | `πρόσεδρος` / `ˈpɾo.se.ðɾos` | [그리스어 언어센터 현대어 사전](https://www.greek-language.gr/greekLang/modern_greek/tools/lexica/triantafyllides/search.html?dq=&lq=%CE%A0%CF%81%CF%8C%CF%82&page=6)에 철자와 현대어 읽기 `[próseδros]`가 있다. DB IPA의 exact 대응과 고대 읽기는 미확인이다. | 현대어 읽기와 고대어 의미를 구분한다. 사전의 별도 재사용 조건을 확인하지 않았으므로 앱에 그 표기를 새로 복사하지 않는다. |
| G0000_0389 expression 2, 피하다 등 | `ἀλέκω` / `alékō` | [Perseus 표제어](https://atlas.perseus.tufts.edu/dictionaries/headword/ἀλέκω/)에서 철자를 확인했다. 현재 로마자 값은 IPA 확인 결과가 아니다. | 로마자 음역 후보로 분류하고 값을 보존한다. 임의 IPA를 만들지 않는다. |
| G0000_0479 expression 2, 가시엉겅퀴 | `γνάφος` / `gnáphos` | [T. S. Green 사전](https://www.gutenberg.org/files/40935/40935-h/40935-h.htm)의 `Γναφεύς` 설명에서 `γνάφος`를 확인했다. 발음 기호는 없다. | 철자 근거와 발음 근거를 구분한다. `gnáphos`는 로마자 음역 후보로 보존한다. 사전 설명을 새로 가져오지 않는다. |
| H0000_0041 동사 어근: 보내다 | `ל־א־ך` / `l-ʾ-k` | 이번 제한된 대조에서 이 어근의 독립 원천과 모음 있는 읽기를 확정하지 못했다. 자음 틀은 완전한 단어의 IPA가 아니다. | 근거 없는 모음을 넣지 않는다. 어근 설명·재구 여부를 따로 확인할 대상으로 유지한다. |
| L0000_0003（ID 끝에 tab 존재）아드라미티움 | `Adramyttéum` / `ad.raˈmyt.ti.um` | [Adramyttium](https://en.wiktionary.org/wiki/Adramyttium)에 대체형 `Adramyttēum`이 있다. 제시된 고전/교회식 IPA는 현재 값과 다르며 다른 철자에 대응한다. | 대체형과 발음의 조합을 확인하기 전 교체하지 않는다. ID 끝의 tab도 이번 작업에서 수정하지 않는다. |
| L0000_0026 유스투스 | `Iūstus` / `ˈi̯uːs.tus` | [iustus](https://en.wiktionary.org/wiki/iustus)의 형용사 표제어와 시대별 발음은 관련 자료다. 현재 고유명사와 IPA의 exact 대응은 미확인이다. | 인명을 형용사 항목으로 바꾸거나 현재 발음을 다른 시대의 발음으로 자동 교체하지 않는다. |
| L0000_0142 바쿠스 찬송 / 개선 등 | `triúmpus` / `triˈum.pʰus` | [triumphus](https://en.wiktionary.org/wiki/triumphus)는 어원에서 Old Latin `triumpus`를 구분한다. 그 페이지의 `pʰ` 발음은 `triumphus`에 대응한다. | 오래된 어형을 오타로 단정하지 않는다. 현재 어형·발음의 시대 조합은 보류한다. |
| L0000_0159 예수 | `IESUS` / `예수스` | [Iesus](https://en.wiktionary.org/wiki/Iesus)는 `Iēsūs`와 별도 변이형·시대별 IPA를 제공한다. 현재 `예수스`는 한글 음역이며 IPA가 아니다. | 대문자 철자와 한글 음역을 곧바로 오류로 보지 않는다. 발음 칸 분류 정비와 IPA 도입은 별도 결정한다. |

현재 IPA의 전체 대응은 7개다. 6개는 기원전 5세기 Attic, `ἆθλος` 1개는 서기 1세기 Egyptian이다. 나머지 11개는 현재 값 전체와 발음 체계의 대응까지 확인한 것으로 집계하지 않는다. 이 7개를 앞선 direct-template 43개와 동일 방식의 자동 검증 결과로 합산하지 않는다. 이번 7개는 실제 페이지에 렌더링된 시대별 발음을 사람이 대조한 결과다.

권장하는 다음 최소 작업은 다음과 같다. 아직 실행하지 않았다.

1. 위의 7개 대조 페이지를 앱 출처 안내에 추가하고 발음 시대·가공 여부를 명시한다. 현재 자료 대조와 과거 복사 provenance는 구분한다.
2. `G0000_0015`, `G0000_0101`, `G0000_0102`, `G0000_0172`, `G0000_0201`, `G0000_0246`의 철자만 표의 후보 값으로 정리한다. 발음·한국어 음역·의미·비고·관계·Strong 번호는 유지한다. work DB의 승인 slice를 먼저 검증한 후 기존 seed 준비 절차로 배포 seed에 반영한다. 사용자 설치 DB를 자동 수정하지 않는다.
3. 나머지 항목은 원본을 보존하고 어형·음역·시대 구분을 후속 판단 대상으로 둔다. 미확정을 확인 완료로 표시하거나 이번 18개만으로 전체 DB 배포권 검토가 끝났다고 선언하지 않는다. 제출용 자료에 미확정 발음을 그대로 유지할지, 확인 원천으로 재작성할지, 배포 seed에서 발음만 제외할지는 별도 승인안이 필요하다.

표기 정책 검토: 한국어 meaning·고유명사 관용명·한자·합성 경계를 바꾸는 제안은 N/A다. 시대·전사와 실제 원문 대응을 구분했고, `ἆθλος`의 의미 대응 및 어근의 재구 문제는 보류했다. 기존 값 변경은 위 6개 철자로 승인 범위를 한정한다. schema·새 의존성·출시 빌드·Git 발행은 이 대조 작업에서 N/A다. 문서 변경 검증과 work/seed 바이트 보존을 확인하며 앱 테스트는 문서 대조표 추가만으로 반복하지 않는다.

### 2026-10-02 승인 범위 반영

사용자가 위 6개 철자 정리와 7개 출처 안내 추가를 승인했다. 작업 DB 반영 후 사본 rollback·전체 테이블 비교·integrity/FK 검사로 철자 6개 이외의 변경이 없음을 확인했다. work의 편집 이력 1,740건도 보존했다. 기존 seed 준비 도구가 원본 보존·내용 일치·runtime probe 검사를 통과했고, 후보 보고서 전체 차이가 승인 철자 6개뿐임을 확인한 뒤 seed를 승격했다. 이전 work/seed 백업은 보존한다. 보류 항목·의미·비고·관계·발음·schema와 실제 사용자 설치 DB는 변경하지 않았다.

앱 출처 안내에 원문 고정 판본 7개를 추가했다. 6개는 기원전 5세기 Attic, `G0000_0042`는 서기 1세기 Egyptian이며, 후자는 앱 철자 `ἄθλος`를 보존하면서 원문 대조 표제어 `ἆθλος`와 구분해 표시한다. 원문 조회 결과·SQL·원본 백업·변경값·SHA 기록은 기존 Git 제외 검토 artifact와 `build/play_release/spelling_six_receipt.json`에 남긴다. 검증한 SQL은 `UPDATE word_expression_set SET spelling=? WHERE word_id=? AND seq=? AND spelling=?`이며 수정 행 수는 6, 그 외 전체 테이블의 값 변경은 0이다.

기존 출시 AAB/APK는 이번 출처 안내와 새 seed를 포함하지 않는다. 새 출시 파일 생성·Git 커밋·병합·push·Play 제출은 수행하지 않았다. 남은 미확정 발음의 배포 판단과 전체 재배포 검토는 계속 보류한다.

최종 검증: 이전 work와 현재 work, 이전 seed와 현재 seed를 각각 전체 테이블로 대조하여 승인 철자 6개만 다른 것을 확인했다. 양쪽 `integrity_check=ok`, foreign key 위반과 sidecar는 0이다. work/seed의 업무 데이터 내용은 일치하고 편집 이력은 위 정책의 차이만 유지한다. 자료 출처 안내 관련 widget 테스트 2개와 `git diff --check`를 통과했다. 수동 UI 테스트는 이번 작업에서 수행하지 않았다. DB는 기존 `.gitignore`의 `*.db` 규칙으로 Git 제외이며, 이를 임의로 변경하거나 DB를 강제 staging하지 않았다.

### 남은 11개 발음의 첫 배포 처리안 — 승인 전

현재 원문에서 값 전체와 발음 체계를 확정하지 못한 11개를 첫 테스트 seed에서 발음만 보류하는 안을 제시한다. 출처 미확정 또는 문자열 불일치는 위법·오류의 증거가 아니다. 이 안은 불확실한 발음을 임의로 재작성하지 않고 연구 원본을 보존하는 배포 선택이며, 다른 표기나 전체 DB의 재배포 검토까지 해결한다는 뜻은 아니다.

| 정확한 대상 (expression seq) | 식별용 현재 의미 | 현재 발음 칸 |
| --- | --- | --- |
| G0000_0008 (1) | 아드라미티온 | adramutteion |
| G0000_0009 (1) | 아드리아 | Adria |
| G0000_0048 (1) | 맹렬히 움직이다 / 쏘다 | aː.ís.sɔː |
| G0000_0280 (1) | 곁에 자리한 | ˈpɾo.se.ðɾos |
| G0000_0389 (2) | 피하다 / 물리치다 등 | alékō |
| G0000_0479 (2) | 가시엉겅퀴 | gnáphos |
| H0000_0041 (1) | 동사 어근: 보내다 | l-ʾ-k |
| L0000_0003\t (1, ID 끝의 tab 보존) | 아드라미티움 | ad.raˈmyt.ti.um |
| L0000_0026 (1) | 유스투스 | ˈi̯uːs.tus |
| L0000_0142 (1) | 바쿠스 찬송 / 개선 등 | triˈum.pʰus |
| L0000_0159 (1) | 예수 | 예수스 |

제안 범위: 실제 작업 DB와 사용자 설치 DB는 보존한다. 첫 배포용 seed에서만 위 11개 expression의 `pronunciation`, `pronunciation_notation`, `pronunciation_notation_name`을 함께 NULL로 한다. 기존 `readStoredPronunciation`은 발음이 NULL인데 표기 metadata가 남아 있으면 오류를 내므로 세 값을 함께 비워야 한다. 철자·음역·의미·비고·관계·Strong 번호·expression seq·ID는 유지한다. 단어 전체를 삭제하지 않는다. 동일 단어의 다른 expression도 유지한다.

기존 `docs/database/SEED_RELEASE.md`는 작업 DB의 모든 내용 보존과 이력만 비우는 것을 정책으로 한다. 따라서 실제 반영하려면 승인한 식별자·seq·원래 값으로 고정한 배포 예외 목록과 준비/검증 절차를 마련해야 한다. 이번 안을 기존 후보의 report만 바꾸거나 후보 파일을 몰래 편집하는 방식으로 승격하지 않는다. 정책 변경 및 도구의 승인 목록 지원은 별도 승인 대상이다.

시험은 Git 제외 `build/play_release/pronunciation_hold_proposal/trial_seed.db`에서만 수행했다. 현재 seed의 사본에서 위 세 필드를 비운 결과 수정 expression은 11행이고, schema·나머지 모든 필드·다른 테이블·행 수는 그대로다. `integrity_check=ok`, foreign key 위반 0이며 실제 work/seed SHA는 실행 전후 그대로다. 항목별 정확한 원래 값·SQL·검증은 같은 디렉터리의 `proposal.json`에 기록했다. 이는 검토용 사본으로, 배포 seed나 정식 prepare/promote 후보가 아니다. 사용자 수동 UI 검증과 Dart Repository를 통한 실행 검증은 이 제안 시험에서 수행하지 않았다.

승인이 없으므로 실제 seed 제외, seed 도구 수정, 정책 변경, 출시 파일 재생성, Git 발행은 수행하지 않았다. 사용자 승인 후 필요한 도구·정책 변경과 그 검증을 진행한다.

### 2026-10-02 발음 보류 승인·구현·실제 반영 완료

사용자가 위 11개를 첫 배포용 seed에서만 보류하고, 원본 보존을 위한 정책·준비 도구 변경을 승인했다. `SeedReleaseService`가 고정 목록을 자동 적용하고 format 2 보고서에 목록과 SHA를 기록하도록 구현했다. 원래 값 불일치·중복 대상을 거부하며, 후보 생성 전후 원본 DB·목록 SHA 불변을 확인한다. 승격 시 현재 목록과 승인 보고서가 같아야 하고 보류 후보의 작업 DB SHA와 전체 내용도 재검증한다. 허용되는 차이는 승인 발음 11개와 두 metadata의 NULL 및 이력 제거뿐이다. 의미·관계·철자·음역·schema를 바꾸는 일반 변환 도구로 확장하지 않았다.

seed 및 법적 안내 테스트 총 15개를 통과했다. 새 회귀 검사는 발음 비움의 읽기 계약·그 외 필드 보존·목록 원래 값 불일치/중복 거부·검사 후 목록 변경 거부·후보의 비고 변조 거부를 다룬다. 기존 성공·실패 복구 테스트도 통과했다. 변경 Dart 파일의 analyze는 `No issues found`다.

실제 후보 `data/backups/seed_release/candidate_976fc8af/report.json`의 전체 차이가 승인 11개뿐임을 독립 대조한 후 승격했다. 보고서 SHA는 `5bf49e869574b14f11c49c197aadf32cecae32c01d667f0838ae568f7078f8fc`, 목록 SHA는 `b32eb3e32d8b9e88e745508777943668db98896c1494939bd4e6564a0d25b21a`다. 이전 seed는 같은 디렉터리의 `previous_seed.db`에 보존한다. 이전 seed SHA `1e30237f8fac176386db41d5d3b34dd11aa87ceef52f047aaafdef41219c5b2c`, 새 seed SHA `8e67a67ecafd507a6287ed7919b5ce2902fc51c899dc8d669279f589a8d6e1de`이며 작업 DB SHA는 `4512e6bdcaae25ddd0fe774863718351350a0d0a11f5cf57a218b8982935ded6`로 바이트까지 그대로다.

승격 후 읽기 전용 전체 비교와 `integrity_check=ok`, foreign key 위반 0, sidecar 0을 확인했다. 양쪽 단어 15,029·관계 7,508행은 유지하고 work의 편집 이력 1,740건과 seed의 0건을 유지했다. 실제 SQL은 대상 `word_id,seq`와 원래 값 확인 후 `UPDATE word_expression_set SET pronunciation=NULL, pronunciation_notation=NULL, pronunciation_notation_name=NULL WHERE word_id=? AND seq=?`이며 후보의 변경 expression은 11행이다. 독립 검증 결과는 Git 제외 `build/play_release/seed_holds_receipt.json`에 보관한다.

수동 UI 검증·사용자 설치 DB 변경·새 AAB/APK 빌드·Git 발행·Play Console 입력/제출은 이번 승인 범위에서 수행하지 않았다. 이 11개 보류를 전체 DB의 재배포 검토 완료로 선언하지 않는다.

### 2026-10-02 RMAC 출처 정비 및 seed 한글 설명 재작성 완료

사용자는 공개 원천을 기준으로 문법표를 정리하고 seed에만 반영하는 범위를 승인했다. 현재 영문 설명의 서로 다른 값 97개를 MLV Teams RMAC의 55개 페이지와 대조했다. 각 페이지는 RMAC 자료를 Public Domain으로 명시하며, 사이트 전체 콘텐츠의 저작권 조건과 구분한다. 대소문자·문장부호·HTML 공백 차이는 대조에서만 정규화했다. 기존 영문 표를 교체하거나 과거 스크랩 출처를 소급 확정하지 않았다.

공개 영문에서 한글 설명 94종류를 새로 작성했다. 새 목록과 `SeedRmacPolicy`를 기존 seed 도구에 연결해 이후 prepare에도 자동 적용한다. 번역은 후보의 `RMAC_TABLE_KR`에만 반영한다. 실제 이전 seed 대비 한글 행 1,223개가 달라졌고 영문·한글 각각 1,227개 RMAC 코드와 NULL 배치는 보존됐다. schema·어휘·의미·비고·관계·편집 이력·기존 발음 보류 값은 모두 이전 seed와 같다.

관련 자동 테스트는 총 19개 통과했고 수정 Dart 파일 analyze는 `No issues found`다. 새 검사는 번역 적용과 영문/작업본 보존, 미확인 영문 또는 코드 집합 불일치 거부, 검사 후 번역 목록 변경 거부, 후보 한글 변조 거부를 다룬다. 첫 테스트 명령에는 존재하지 않는 출처 화면 테스트 경로를 넣어 실패했으며 실제 `test/ui/legal_document_dialog_test.dart` 경로로 재실행해 통과했다. 앱 UI 구조 변경은 없고 이번 Android 수동 UI 확인은 수행하지 않았다.

실제 후보는 `data/backups/seed_release/candidate_1c77e507/report.json`이며 보고서 SHA256은 `4510fe076bc09abd9e37c3a4dec8be8b5f7577e2c0ced37798eea29298d43543`, 번역 목록 SHA256은 `ad273a36e5877376472dbb7d3b3a424ca274f8041326e0c4544ac158d7497727`이다. 읽기 전용 전체 비교로 작업본 대비 승인 변환만, 이전 seed 대비 한글 RMAC 변경만 있음을 확인한 뒤 승격했다. 이전 seed SHA256 `8e67a67ecafd507a6287ed7919b5ce2902fc51c899dc8d669279f589a8d6e1de`를 같은 폴더의 `previous_seed.db`에 보존했다. 새 seed SHA256은 `e44bb989bebdc46a22bba2efac9defd06f3bdfd500577153de85adfa1bc148bb`다. 작업 DB SHA256 `4512e6bdcaae25ddd0fe774863718351350a0d0a11f5cf57a218b8982935ded6`는 바이트까지 보존됐다.

SQL 검증: `PRAGMA integrity_check`는 work/seed 모두 `ok`, `PRAGMA foreign_key_check` 결과는 모두 0건이다. `SELECT * FROM RMAC_TABLE` 및 `RMAC_TABLE_KR`과 나머지 모든 표를 전체 비교했다. 실제 후보에서만 `UPDATE RMAC_TABLE_KR SET <설명 열 10개>=? WHERE RMAC=?`를 실행했다. `V-AAI-1S`의 한글 시제는 `부정과거 G5777`로 반영됐다. 양쪽 단어 15,029·관계 7,508건은 같고 work 이력 1,740건/seed 이력 0건을 유지했다. sidecar는 0이다. 상세 SQL 목적·보호 비교·SHA·예시는 Git 제외 `build/play_release/rmac_receipt.json`에 보관한다.

앱 출처 안내에 RMAC 공개 원천과 한글 재작성 사실을 추가했다. Git의 자동 줄바꿈 변환으로 승인 목록의 바이트 SHA가 달라지지 않도록 두 seed 예외 JSON에 LF 규칙을 추가했다. 이후 Git 마무리에서는 앱 자료 출처 asset에도 LF를 고정해 실제 빌드에 포함한 문서 바이트를 보존한다. RMAC 출처 정비는 이번 범위에서 완료했다. 새 출시 AAB/APK 생성, 사용자 기기 설치, Google Play 설정·업로드 및 Git 커밋·병합·push는 수행하지 않았다. 기존 출시 파일에는 이번 정비가 포함되지 않으므로 실제 제출 전에 다시 빌드해야 한다.

### 2026-10-02 최신 Android 제출 파일 생성·검증

최신 seed와 출처 안내를 포함한 출시 AAB/APK를 기존 업로드 키로 다시 생성했다. 패키지는 `org.reshet.study`, 버전은 `1.0.0+1`, minSdk 24·targetSdk 36이다. 현재 기록상 아직 Play에 업로드하지 않은 첫 제출 버전이며, Console에서 이미 사용한 versionCode가 있다면 재사용하지 않고 새 버전으로 생성해야 한다.

- AAB: `build/app/outputs/bundle/release/app-release.aab`, 51,033,291 bytes, SHA256 `fc1e7e4965f6692fb3429e3c6afe72bd720093f4643acb79b9361be50a164865`.
- APK: `build/app/outputs/flutter-apk/app-release.apk`, 61,001,309 bytes, SHA256 `54b577d97b5ad915df9b9b368e6df84c3fcbfecf00b1b2befbda766622480291`.
- 두 파일의 내장 seed·자료 출처·개인정보처리방침은 저장소의 최신 파일과 각각 바이트 SHA가 같다. seed SHA는 `e44bb989bebdc46a22bba2efac9defd06f3bdfd500577153de85adfa1bc148bb`, 출처 안내 SHA는 `7ba77af275e8f462cfccb6521856f38e5049cca7a89d37d29dee21d82253cfec`이다. 작업 DB·원천 cache·백업·배포 정책 목록은 포함하지 않았다.
- bundletool 구조 검증 통과, AAB 서명 검증 통과, APK v2 서명 및 zipalign 16 KB 검사 통과. AAB와 APK의 서명 인증서 SHA256은 `e3de0b3448c11e9e29c79780ac6f73752c184fd2841d37aaba42f03b4a012f72`로 같다. jarsigner가 표시한 자체 서명·인증서 체인·타임스탬프 경고는 업로드 인증서 검증 결과와 함께 보존했다. 키나 비밀번호는 출력하지 않았다.
- 64-bit native library 전체의 ELF LOAD alignment는 최소 16,384이고 AAB 설정은 `PAGE_ALIGNMENT_16K`다. 이는 정적 검사이며 실제 16 KB 페이지 크기 기기 실행은 미수행이다. INTERNET 권한이 없는 출시 manifest와 소프트웨어 라이선스 안내 포함도 확인했다.
- 관련 자동 테스트 19개(배포 seed 17개, 출처 UI 2개)의 통과 기록을 재사용했다. Git·빌드만을 이유로 같은 테스트를 반복하지 않았다. 작업 DB·seed SHA는 빌드 전후 그대로다.

최신 검증 기록은 Git 제외 `build/play_release/source_review_artifacts.json`과 `source_review_*` 로그다. 기존 `artifact_verification.json`의 9월 30일 파일은 최신 출시 파일의 증거로 사용하지 않는다. 이전 준비 기록과 최신 수동 검사 여부를 분리한다.

현재 `adb devices -l`에서 연결 기기 0개다. 이번 새 출시 파일의 실제 휴대폰 설치와 수동 UI 확인은 아직 하지 않았다. 기존 9월 30일 휴대폰 검사는 과거 앱의 결과로 유지한다. 기존 개발용 앱의 서명은 이번 출시 APK와 다를 수 있으므로 삭제하지 않고 연결 후 서명과 백업을 확인하여 업데이트 방법을 정한다. 이번 작업에서 휴대폰 앱·사용자 DB 변경과 Play Console 업로드·제출은 수행하지 않았다.

Git 발행 전 줄바꿈 점검: 두 seed 정책 JSON의 실제 파일이 CRLF였으므로 Git의 LF 정규화와 일치하도록 실제 파일도 LF로 맞췄다. 번역 목록 생성 도구도 LF를 직접 출력하도록 수정했다. 값·승인 대상은 그대로이고 정규화 후 발음 목록 SHA256은 `fb9723e5cbea927cc1f1b67e1856a595d170f377109a92049e84ed101c006879`, 번역 목록은 `b8960dac7303f86163d939e8eeb8cc6d91e989bf5a97f26151a212d24e3e48a8`다. 앞선 승격 기록의 목록 SHA는 당시 CRLF 파일의 역사적 값이다. 새 prepare 보고서 `candidate_17e62176/report.json` SHA256 `8c2f34fd9c88f0d4fc08d9806bbd351e561941fcba171c30cf8e85c4e9d651e2`로 정규화 후 정책을 재검증했다. 기존 seed 대비 전체 차이는 0이며 새 후보와 실제 seed의 바이트 SHA도 같다. DB 재교체나 앱 재빌드는 불필요했다. 옛 보고서는 현재 정책 SHA와 다르므로 재승격하지 않는다.

## 2026-10-11 비공개 테스트 업데이트 준비 — 1.0.0+2

사용자는 최신 작업 DB의 배포 반영과 AAB 생성을 승인했고, Play Console의 최대 업로드 versionCode가 1임을 확인했다. 표시 버전 1.0.0을 유지하고 versionCode와 앱 프로그램 정보를 2로 갱신했다. 기존 11개 발음 보류는 사용자 재확인에 따라 모두 유지한다. 최신 승인 표현값과 라틴어 ID 교정은 보류 목록의 대조 기준에만 반영하며, 배포 후보의 해당 발음·유형·체계명은 계속 NULL이다.

- 작업 DB SHA256 `b5a87078fad6438642c620194546f40520493e1a62939f82f978f48e6ec364ab`와 편집 이력 5,847행을 보존했다. 후보에는 기존 승인 RMAC 변환·11개 발음 보류·이력 제거만 적용했다. 후보 생성의 전체 내용·구조 대조, runtime probe, 무결성 및 외래키 검사를 통과했다.
- 새 seed SHA256 `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1`. 후보는 `data/backups/seed_release/candidate_4627583b/`, 보고서 SHA256은 `7e3ea266dc3b5310ba043832488198345287461a4c95109a81c1e70560de5339`다. 이전 seed SHA256 `e44bb989bebdc46a22bba2efac9defd06f3bdfd500577153de85adfa1bc148bb`를 같은 폴더의 `previous_seed.db`에 백업했다.
- AAB: `build/play_release/update_20261011/Reshet-1.0.0+2.aab`, 51,083,882 bytes, SHA256 `4ba59f14ebc80d3d42c83617ef8b4b5a8418433bc0907cfbb451ae11b12777a0`. 기존 빌드 경로에도 같은 파일이 있으며 이전 AAB는 업데이트 기록 폴더의 `previous-app-release.aab`에 보존했다.
- bundletool 검증과 jarsigner 서명 검증을 통과했다. 업로드 인증서 SHA256은 기존과 같은 `e3de0b3448c11e9e29c79780ac6f73752c184fd2841d37aaba42f03b4a012f72`다. 자체 서명·인증서 체인·타임스탬프 및 JarInputStream manifest 순서 경고는 이전 AAB에서도 관찰된 유형이며 로그에 보존했다.
- 내장 seed·개인정보처리방침·자료 출처 안내는 현재 파일과 바이트가 같다. 작업 DB·백업·후보·보고서는 포함하지 않았다. manifest의 패키지 `org.reshet.study`, versionCode 2·versionName 1.0.0, minSdk 24·targetSdk 36을 확인했다. 64-bit ELF LOAD alignment 최소 16,384와 bundle 설정 `PAGE_ALIGNMENT_16K`도 확인했다. 실제 16 KB 기기 실행은 미수행이다.
- 배포 seed와 출처 안내 관련 기존 자동 테스트 19개가 통과했다. 배포 DB의 `PRAGMA integrity_check`는 `ok`, `PRAGMA foreign_key_check`는 0행, `SELECT COUNT(*) FROM CHANGE_HISTORY`는 0이다. `word_id`·`seq`로 보류 대상 11행의 `pronunciation`·`pronunciation_notation`·`pronunciation_notation_name`을 조회해 모두 NULL임을 확인했다. 이는 구조·참조·이력 제거와 보류 유지 검증이며 의미의 정당성을 새로 승인하는 검사는 아니다.

검증 로그와 DB 보류 목록 변경 근거는 Git 제외 `build/play_release/update_20261011/`에 보존한다. 새 APK 생성·휴대폰 설치·수동 UI 확인·Play 업로드·Git 커밋·병합·push는 이번 작업에서 수행하지 않았다. 기존 설치자는 앱 업데이트만으로 DB가 바뀌지 않으며, 새 제공 데이터를 쓰려면 백업과 전체 교체 범위를 확인하고 앱의 `제공 데이터로 전체 교체`를 선택해야 한다.

후속 Git 정리 검증에서는 위 업데이트 변경을 최신 `main`의 H54 승인 기록 위에 보존했다. 이후 H54 연구가 반영된 작업 DB와 10월 11일 배포 seed·AAB를 각각 그대로 유지하며, seed 재생성·교체나 앱 재빌드는 수행하지 않았다. 두 DB의 무결성은 `ok`, 외래키 위반은 0행이며 작업 이력은 work 5,901행·seed 0행이다. 보류 11개 expression의 작업본 원래 값과 seed의 발음·유형·체계명 NULL을 확인했고, AAB 내장 seed·법적 안내도 현재 배포 파일과 일치했다. 배포 관련 자동 테스트 19개가 다시 통과했다. `home_screen.dart` 정적 분석은 기존의 `avoid_print` 정보 4개로 종료 코드 1이며, 해당 네 줄이 이번 변경 전과 같음을 확인했다. 실기기 수동 UI 확인과 Play 업로드는 이 후속 정리에서도 수행하지 않았다. 원본 백업과 검증 결과는 Git 제외 `data/backups/seed_release/update_test_seed_closeout_20261012/`에 보존한다.
