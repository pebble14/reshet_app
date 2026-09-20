# H31 클러스터 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-09-20
- 대상: H0031, G0010; H0001·H1935는 합성 관계의 구성 요소
- 승인 manifest: [h31_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h31_cluster_approved_content_slice.json)
- 관련 hold ledger: 변경 없음, 두 대상 hold 없음
- 로컬 연구 산출물: `H31_cluster_20260920_3d622133/00_cluster_summary.md`, `supplemental/`의 전체 Review·Packet·관계 자료
- 연구 문서 해시: manifest의 document_sha256은 UTF-8 LF 정규화 텍스트 기준 `b7f69726abe78557f59d86585a5f39de19287d1a2e5d9ead7224b496cdaa0d01`이다. 원본 CRLF 파일 바이트 SHA-256은 `17f254febb2ee09f4cf09989d8f86a4f19e527af8c78605d53225fb759760698`이며, 두 값의 차이는 줄바꿈 직렬화다. 원본 연구 문서와 적용 manifest는 변경하지 않았다.
- DB 적용: history group `1789867056755925`

## 최종 결정

사용자는 G0010에 간결한 대체안 `아비훗·아비-후드 (인)`을 선택하고 나머지 연구 추천안 및 DB·Git 실행을 승인했다.

- H0031·G0010 meaning: 각각 `아비훗·아비-후드 (인)` 한 행, sense 1.
- H0031 비고:

  > '아비훗'은 한국어 성경의 관용 표기이고, '아비-후드'는 אֲבִי와 הוּד의 구성을 드러낸 분석 표기이다. H0001(아버지)과 H1935(위엄·영예 계열)의 합성 이름으로 풀이되지만, 구성 전체의 해석은 '명예의 아버지·소유자'(Strong)와 '아버지는 위엄이 있다'(참고 사전) 등으로 다르다. 역대상 8:3은 인명으로 읽는 전통 외에 '에훗의 아버지'로 읽는 대안도 있다(새번역 각주). G0010과는 같은 이름의 언어별 형태이지 동일 인물이라는 뜻은 아니다.

- G0010 비고:

  > '아비훗'은 한국어 성경의 관용 표기이고, '아비우드'는 Ἀβιούδ의 헬라어형을 옮긴 표기이다. H0031과 같은 이름의 헬라어 음역이며, '아비-후드'의 붙임표는 헬라어 내부 형태소가 아니라 원천 히브리어 이름의 합성 경계를 표시한다. 마태복음 1:13에서 스룹바벨의 자손이자 엘리아김의 아버지로 두 번 나오며, 역대상 8:3의 인물과 동일인이라는 뜻은 아니다. 이름의 구성 전체에 대한 어원 풀이는 하나로 확정하지 않는다.

- H0001→H0031: relation id `22`, `morphological / compound / asserted`, 저장 pair `H0001_0000, H0031_0000`, `w1_to_w2`.
- H1935→H0031: relation id `5376`, `morphological / compound / asserted`, 저장 pair `H0031_0000, H1935_0000`, `w2_to_w1`.
- H0031→G0010: relation id `21`, `transliteration / direct_transliteration / asserted`, 저장 pair `G0010_0000, H0031_0000`, `w2_to_w1`.
- 각 relation의 유형·방향·id·pair를 보존하고 `inferred`를 `asserted`로 교체했다. Source는 각각 `RESHET-EC-H31-CLUSTER-H0001-H0031`, `RESHET-EC-H31-CLUSTER-H1935-H0031`, `RESHET-EC-H31-CLUSTER-H0031-G0010`이다. 기존 note 빈 문자열, description·relation_group_id NULL은 보존했다.
- 신규 relation·supersession·hold operation 없음. H1·H1935의 독립 의미, expression·발음, schema·seed는 변경하지 않았다.

## 핵심 판단 근거

H0031의 OSHB 전 용례 1회(대상 8:3)는 canonical 분석상 벨라 자손 명단의 인명이다. G0010의 TAGNT 전 용례 2회(마 1:13)는 스룹바벨 계보의 같은 인물을 대격·주격 자리에서 반복한다. 두 이름의 품사·문맥 차이는 별도 sense를 요구하지 않는다. 두 Strong이 같은 이름의 언어별 형태라는 사실과 두 본문 인물이 동일인이라는 주장은 구별했다.

Canonical Strong source는 H0031을 H0001과 H1935의 합성으로, G0010을 H0031의 히브리어 기원 이름으로 설명한다. Source-reference 화살표를 그대로 저장하지 않고 구성 요소→합성명, 원천 이름→음역 방향을 적용했다. 세 관계의 asserted는 이름 구조·전승에 한정하며 어원 문장 하나나 동일 인물 판단을 확정하지 않는다.

'아비훗'은 한국어 성경 관용명, '아비-후드'는 원천 이름의 구성 경계를 보이는 분석 표기다. G0010의 '아비우드'는 헬라어형을 드러내지만 사용자는 간결형을 선택하여 비고에 보존했다. 이 선택에 사용자가 별도로 밝히지 않은 이유를 부여하지 않는다.

## 채택하지 않은 주요 대안

- G0010 `아비훗·아비우드·아비-후드 (인)`: 유효한 표기 대안이나 사용자가 간결형을 선택했다. 아비우드는 비고에 보존했다.
- `아비훗 (인)`만 사용: 관용명으로 유효하지만 확인된 원천 이름의 구성 경계도 병기하는 추천안을 채택했다.
- `아비훗·아비-훗 (인)`: 단순 기호 정비보다 원문 및 원전분해의 아비후드 표기를 반영한 분석안을 채택했다.
- '위엄 있으신 나의 아버지'를 유일한 확정 풀이로 유지: Strong의 '명예의 아버지·소유자'와 참고 사전의 '아버지는 위엄이 있다' 차이를 보존하기 위해 비고를 교체했다.
- '에훗의 아버지'를 대표 meaning으로 교체: 새번역 각주에 있는 실제 대안이지만 canonical 인명 분석을 대신하지 않고 비고에 남겼다. 이 각주만으로 별도 Ehud 관계도 생성하지 않았다.

## 남은 불확실성 및 재검토 조건

H31의 source language `x-pn/unresolved`는 보존했다. 대상 8:3의 인명/구문 분석 대안과 이름 전체 어원 풀이 차이를 해소했다고 주장하지 않는다. 현재는 note로 한정하고 전체 hold를 두지 않는 추천안을 사용자가 승인했다. 특정 시대의 정확한 발음이나 헬라어 내부 합성 구조도 새로 확정하지 않았다.

로컬 참고자료는 reference-only이고, LXX 대상 8:3의 αβιουδ는 provenance/license unverified human reference다. CORE의 3개 occurrence와 적용 가능한 local reference는 전량 확인했지만 raw graph는 53 node/52 edge, frontier 45의 미완료 상태다. H1·H1935의 생산적 인명 구성 요소에 hub 예외를 적용했으며 전체 graph closure 완료가 아니다.

H1은 현재 DB가 후속 승인 표기 manifest와 일치하는데 progress가 이전 manifest의 projection mismatch로 미승인 분류한다. 이번에는 이 검출 불일치를 수정하거나 H1을 재승인하지 않았다.

새 원문·본문비평 근거가 인명 분석이나 H1·H1935 구성, H31→G10 전승을 실질적으로 부정할 때 재검토한다. 이미 보존한 어원 풀이 차이, 관용명·전사 방식 차이, 다른 허브 가지 발견만으로 자동 재검토하지 않는다.

## 적용 및 마감 검증

- 공식 dry-run exit 0, 의미 2·비고 2·관계 replacement 3, history 7행, `did_undo=true`, 원본 DB 불변.
- 공식 live apply exit 0. work SHA-256: `3d62213308ee031c769236aa9c58d56e6baba2a4ec649fbc2d364cb5e78f1ced` → `be51c0c430804b5827f1771383633961192b822c14dbb9bfdabfa15e68f02388`.
- seed SHA-256 불변: `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`.
- snapshot: `data/backups/approved_content_batch/20260920T011735914468Z/snapshot.db`, SHA-256 `89399837aa730c31e6c792477fd73895a0134bf93b715509372bac0cdb02a659`.
- Snapshot과 최종 DB의 schema·모든 사용자 테이블을 독립 비교했다. WORD_TABLE 2행, word_meaning_set 2행, WORD_RELATION 3행 및 CHANGE_HISTORY 신규 7행 외 차이 없음. history는 word update 4·relation update 3이며 undone_at은 모두 NULL이다.
- 최종 meaning 순서·비고·관계 exact pair/category/type/status/direction·중복 여부를 manifest와 독립 SQL 대조했다. Work·seed·snapshot integrity ok, FK 오류 0, sidecar 없음.
- H0031·G0010 모두 `explicit_approved / approved`. 전체 승인 80→82, hold 2 유지, 미승인 14,216→14,214, anomaly 113 유지. Progress snapshot identity `3e460ab553e06e085d78d5ce5c716c709a627e210ceddbee5ea3c9e90ebfa220`, JSON SHA-256 `92c2207f86a124257d457165385ca3b9f0c87be38f4d2577644943d2187d08cd`는 적용 시점의 derivative 기록이다.
- Targeted `approved_content_batch_service_test.dart` 29건 통과. 앱 코드·schema 변경 없음. Flutter UI 및 사용자 UX 테스트 N/A.
