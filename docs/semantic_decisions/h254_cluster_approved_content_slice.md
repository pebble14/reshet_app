# H254 화로 의미·비고 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-29 (Asia/Seoul)
- 대상: H0254_0000
- 승인 manifest: [h254_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h254_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 기존 6건 유지
- 로컬 연구 산출물: `reshet_research_output/H254_cluster_20261029_b5baa317/`, R1
- 승인·적용 전 byte 백업·독립 검증: `data/backups/approved_content_batch/h254_approval_20261029/`

## 최종 결정

사용자는 H254 R1 추천안에 동의하고 DB·문서·기타 파일 반영, 검증, Git 및 이번 작업 브랜치 정리까지 승인했다.

- ordered meaning: seq1 `화로(火爐)` (기존 `화로`에서 한자 보완), 1 sense.
- 비고: 아래 승인문으로 NULL에서 교체.
- 신규·교체·삭제 관계 없음. Word-level hold 없음.
- H251·H253·H741·H2025 기존 승인 유지. 이번 operation 대상에 포함하지 않음.

> 불을 담아 난방 등에 쓰는 기구다. 렘 36:22–23에서는 왕 앞에 놓여 있고 두루마리를 태우는 데 쓰이며, 불 자체는 אֵשׁ(H784)로 따로 표현된다. 어원은 불명확하며 BDB는 이집트어 차용설을 제시한다. 사전의 여성명사 분류와 OSHB의 남성 단수 분석은 구별해 보존한다.

## 핵심 판단 근거

Canonical Strong의 fire-pot/chafing dish 풀이와 OSHB 렘36:22–23의 3토큰·2절 전체는 불을 담는 기구라는 한 의미로 설명된다. 왕 앞 난방 기구와 두루마리 소각 기구는 같은 대상을 지시한다. 불 자체는 אֵשׁ(H784)로 따로 표현되어 기구와 내용물을 구별했다.

HebGrkKo exact1행, KJV·개역개정·개역한글·새번역·원전분해의 해당2절 전체를 대조했다. 난로는 같은 대상의 번역 대안이며 별도 sense를 요구하지 않는다. LXX는 같은 번호36:22–23의 내용 불일치를 확인한 뒤 명시적43:22–23을 수동 대조했다. 자동 alignment·Greek lemma/Strong 관계는 생성하지 않았으며 human-reference와 provenance/license 미확인 경계를 보존한다.

한자 火爐를 확인하고 한국어 표기 정책에 따라 보완했다. H162 결정의 감탄사 H253, H251 결정의 형제, H220 결정의 제단 화덕과 현재 DB·manifest를 대조했다. 동일 철자나 영어 hearth의 겹침만으로 어휘·의미를 합치지 않는다. 사용자는 이 근거를 갖춘 추천안을 채택했으며 별도의 개인적 동기를 추정하지 않는다.

## 채택하지 않은 주요 대안

- 난로(暖爐): 유효한 번역 대안이지만 불을 담는 기구라는 풀이에 기존 화로가 더 직접적이다. 별도 meaning으로 추가하지 않았다.
- 화덕: 가능한 번역이지만 기존 의미를 바꿀 이득이 낮다. H741/H2025는 제단 문맥을 보존하며 두 어휘군의 의미가 배타적이라고 단정하지 않는다.
- 불·숯불: 기구와 내용물·연료를 혼합하므로 별도 meaning으로 채택하지 않았다.
- 공통 철자·추정 차용·LXX 대응 관계: 확정 유형·방향·원천 entity를 입증하지 않아 DB relation을 생성하지 않았다.
- Word-level hold: 일반 의미와 Strong identity는 충분히 명확하다. 어원·문법·본문 문제는 해당 범위의 비고와 연구 evidence에 보존했다.

## 남은 불확실성 및 재검토 조건

전체3토큰 검토3·미검토0, sense1 배정3·ambiguous0·의미 배정 미해결0·확정 반례0이다. 문법 성의 자료 차이3토큰과36:22 구문 문제1토큰은 주 배정에 겹치는 태그다.

Strong·BDB의 여성명사 분류와 OSHB의 남성 단수 분석을 구별한다. BDB의36:22 수정 독법은 현행 원문이나 Qere가 아니다. Strong의 어원 미상과 BDB의 이집트어 차용설을 구별하며 인용 원논문은 열람하지 않았다. 정확한 기구 형상·재료·연료·차용 경로는 미확정이다. 새로운 비판 사전·직접 본문/역사언어학·고고학 근거가 현재 판단을 바꿀 때 재검토하되 같은 번역 표현의 반복이나 번호 인접성만으로 자동 변경하지 않는다.

### 적용·검증

공식 dry-run의2건 적용·undo·원본 byte 불변 및 기존 applicator 테스트31개 통과 후 live apply를1회 수행했다. 독립 검증은 전13테이블·DDL·공식 snapshot 논리 내용과 적용 전 백업을 대조했으며 승인 projection·history2건과 history sequence 외 변화가 없다. 대상 meaning의 surrogate ID 교체는 공식 replacement 동작이다. 공식 snapshot의 schema cookie 차이는 receipt 계약에 따라 논리 검증과 구별했다.

History group `1793247277942994`, IDs7275·7276, undone 없음. Work SHA `b5baa3174508420f0b5e40fcc080cfb8d7ab755b1d0351b99285e91cc7618dbe` → `dda4f45b64ce67622eb4f98069c26a20991508ffe1657f42bc353328be1b6730`. Seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1` 불변. Integrity ok·FK0·sidecar 없음이다.

표준 progress는 승인736→737, 미승인13556→13555, hold6·anomaly113·전체14298 유지다. 비대상14297행과 lexical index·anomalies가 동일하고 공식 CSV/Markdown renderer와 byte 일치한다. 앱 코드·UI·schema·원문·음역·발음·seed 배포 변경과 사용자 UI 테스트는 N/A다.
