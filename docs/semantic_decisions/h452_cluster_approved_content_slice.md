# H452 엘리야 이름군 승인 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-11-14
- 대상: H0452·G2243
- 승인 manifest: [h452_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h452_cluster_approved_content_slice.json)
- 연구: H0452_cluster_20261114_4fe18263, 최신 추천 R2

## 최종 결정

- H0452_0000: `엘리야·엘리-야·엘리-야후 (인)`, 1 sense.

> 이스라엘의 예언자 엘리야와 베냐민 사람 여로함의 아들(대상 8:27), 하림 자손 제사장(스 10:21), 엘람 자손(스 10:26)의 이름이다. אֵלִיָּה와 장형 אֵלִיָּהוּ는 H410 엘(하나님)과 H3050 야 계열의 합성 이름이며, BDB는 ‘야(야후)는 하나님’으로, Strong은 ‘여호와의 하나님’으로 풀이한다. 이름 풀이와 인명을 구별한다. 엘리야는 성경 관용명이고 엘리-야·엘리-야후는 두 이름형과 구성 경계를 보여 주는 교재식 읽기의 한글 근사다. 확보 정본에서 장형은 예언자에게만 확인되며 다른 세 인물의 장형이 직접 확인된 것은 아니다. 붙임표는 실제 마케프가 아니며 자음 길이와 정확한 고대 발음을 재현하지 않는다.

- G2243_0000: `엘리야·엘리-야 (인)`, 1 sense.

> H452 엘리야 이름의 헬라어형이다. 원천 이름은 엘(하나님)과 야 계열의 합성이며 BDB는 ‘야(야후)는 하나님’으로 풀이한다. 신약에서는 예언자 엘리야의 이야기·도래 기대와 세례 요한에 대한 역할 적용에 쓰인다. 마 17:12–13은 요한을 가리키지만 요 1:21에서 요한은 자신이 엘리야라는 질문을 부인한다. 롬 11:2는 엘리야에 관한 성경 대목을 가리킨다. 엘리야는 성경 관용명이고 엘리-야는 원천 히브리어 이름의 엘·야 구성 경계를 보존한 분석 표기이며, 헬라어 자체를 새 합성어로 분석한 것이 아니다. 엘리아스는 현재 등록된 Ἠλίας의 교재식 읽기의 한글 근사다. Strong·TAGNT lemma의 Ἡλίας와 정본 표면형의 Ἠλίας 계열은 숨표가 달라 원자료별로 구별한다. 눅 9:54의 엘리야 언급은 이번 정본 profile에서 제외된 이문이다.

- 관계 ID2106: H0410_0000 / H0452_0000 — morphological / compound / asserted / w1_to_w2; note/source는 승인 manifest와 같다.
- 관계 ID6053: H0452_0000 / H3050_0000 — morphological / compound / asserted / w2_to_w1; note/source는 승인 manifest와 같다.
- 관계 ID2107: G2243_0000 / H0452_0000 — transliteration / direct_transliteration / asserted / w2_to_w1; note/source는 승인 manifest와 같다.

신규 hold 없음. H410·G2241 기존 승인, H3050·H3068 및 제외 branch의 현행 상태를 보존한다. 표현·음역·발음·언어·schema·seed는 변경하지 않는다.

## 핵심 판단 근거

사용자는 R2 최신안을 채택하고 DB·문서·검증·Git 및 이번 작업 branch 정리까지 승인했다. H0452 정본71토큰·65절은 예언자68건과 다른 세 인물 각1건이며 같은 인명 한 sense다. 장형63·단형8을 확인해 관용명과 두 분석 표기를 병기하고 이름 풀이를 비고로 옮겼다. G2243 정본29토큰·29절도 한 이름의 사용이며 요한에 대한 역할 적용과 롬11:2의 성경 대목 환유를 독립 뜻으로 늘리지 않았다.

사용자의 일관성 검토에 따라 G2243은 엘리아스 병기 대신 엘리-야를 선택했다. G0007 아비-야와 G1158 다니-엘처럼 원천 이름의 확인된 경계를 전승 이름에서도 보존하며, 헬라어 자체를 합성어로 새로 분석하지 않는다. 엘리아스는 기존 음역에 보존했다. 두 구성 관계는 명시적 from H410 and H3050, 음역 관계는 structured Hebrew-origin H452 참조를 근거로 확정했다.

## 채택하지 않은 주요 대안

- G2243 엘리야·엘리아스: 잘못된 읽기는 아니지만 이번 이름군에서는 원천 구성의 일관성을 우선했다. 엘리아스는 음역·비고에 보존한다.
- 이름 풀이를 별도 meaning으로 유지하거나 인물별 meaning 분리: 이름의 지시 기능과 어원·referent 차이를 구별한다.
- Greek 엘리-아스 강제 분절, G2241과 이형/동의 관계: 근거 없는 형태소 분석 및 십자가 오청의 어휘 동일화를 피한다.

## 남은 불확실성 및 재검토 조건

이름 문장의 역사적 -i 해석과 정확한 고대 발음은 미확정이며 Strong과 BDB 풀이 차이를 비고에 보존했다. Greek 사전·lemma와 정본 표면형의 숨표 차이를 원자료별로 유지한다. 눅9:54의 TR/Byz 이문은 NA27/28 정본29건에 합산하지 않는다. LXX와 한국어 reference의 미검증 경계는 유지한다. 확보 LXX의 왕상20/21장과 말라기 끝부분 배열은 수동 대조했다. Hub 예외의 global closure 미완료·frontier292와 CORE2 전량 검토를 구별한다. 구성·identity를 실질적으로 바꾸는 인명학·본문비평 근거가 확보되면 해당 항목을 재검토한다.

## 적용 및 검증

공식 dry-run·실제 undo·원본 SHA 불변 및 적용기31테스트 통과 후 live apply1회. 의미2·비고2·관계교체3, history group1794625734702851의7행이다. 사용자 테이블12개·DDL·기존 이력·비대상 데이터 및 sqlite_sequence의 history +7 외 불변을 독립 대조했다. Work·seed·백업·snapshot integrity ok, FK0, sidecar없음.

- Work SHA: `871aab65fae654e1e80a5c1bcda31828d7a823aaf1668d3e830dae66f20c7820`
- Seed SHA: `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1`
- Receipt: `data/backups/approved_content_batch/20261114T030851685117Z/result.json`
- 독립 검증: `data/backups/approved_content_batch/h452_approval_20261114/independent_verification.json`
- Progress 승인1020→1022·미승인13272→13270, hold6·anomaly113 유지. 표준 JSON·CSV·Markdown 함께 갱신.
- Snapshot: `473d343f8cc3c0630dcc1552294551f5b29729516b913e9bef3f096a27b69904`
- Manifest 적용 바이트를 Git에서도 보존하도록 해당 파일에 -text metadata를 지정했다.
- 앱/UI 변경 없어 UI 테스트 N/A.
