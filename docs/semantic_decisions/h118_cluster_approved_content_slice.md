# H118 아달리야·아달랴 인명 의미·비고 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-19 (Asia/Seoul)
- 대상: H0118 (H0118_0000)
- 승인 manifest: [h118_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h118_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 기존 6건 유지·신규 0
- 로컬 연구 산출물: 외부 reshet_research_output/H0118_cluster_20261019_e2fa8f22/
- 승인 원문·byte 백업·독립 검증: data/backups/approved_content_batch/h118_approval_20261019/
- 공식 snapshot·manifest 사본·result: data/backups/approved_content_batch/20261019T122532669685Z/

## 최종 결정

사용자는 아달랴가 기존 음역 필드에 있더라도 meaning에 함께 병기하는 쪽을 선호한다고 명시했다. 이 수정과 기존 추천 비고·관계 비생성·hold 없음, DB·문서·필요 파일 작업을 승인했으며 검증 후 Git 완료와 이번 작업 브랜치 정리까지 승인했다.

|Strong|최종 ordered meaning|sense|비고|관계|hold|
|---|---|---:|---|---|---|
|H0118|seq 1: 아달리야·아달랴 (인)|1|아래 전문으로 NULL에서 교체|신규·교체·삭제 없음|없음|

최종 비고:

> 하만의 열 아들 가운데 한 사람이다(에 9:7–10). Strong은 페르시아어 기원으로 설명하지만, 이름의 구체적인 뜻은 제시하지 않는다.

기존 `아달리야 (인)`에 `아달랴`를 같은 인명의 표기로 병기했다. 가운데점은 동일 지시 대상의 표기 병기이며 별도 lexical sense를 만들지 않는다. Meaning replacement1·word note replacement1을 적용했다. 관계 category/type/status/direction은 N/A다. 원어 אֲדַלְיָא·기존 음역 아달랴·발음·언어·Strong 번호·schema·seed·앱 코드와 비대상 데이터·기존 hold6건은 보존한다. 기존 semantic 승인 기록을 대체하는 작업이 아니므로 supersession은 없다.

## 핵심 판단 근거

- Canonical Strong의 품사는 남성 인명이며 meaning은 하만의 아들인 Adalja, usage는 Adalia다. Source는 `of Persian derivation;`이라고 설명하지만 구체적인 페르시아어 원형이나 이름 뜻을 제시하지 않는다.
- OSHB의 유일한 용례 에9:8은 אֲדַלְיָ֖א, lemma118, HNp이며 9:7–10의 하만의 열 아들 명단에 포함된다. 1/1회 전체를 한 인명 sense로 분류했고 미분류·sense ambiguity·의미 반례는 각각0이다.
- 확보된 개역개정·개역한글·새번역의 관용 표기는 아달리야로 일치한다. 원전분해의 읽기와 기존 음역은 아달랴다. 사용자는 두 표기의 meaning 병기를 선택했다. 이는 특정 시대의 실제 발음을 확정하거나 발음·음역 필드를 교정하는 결정이 아니다.
- 비고에는 meaning만으로 드러나지 않는 인물 식별과 Strong의 기원 설명 범위를 기록했다. 명시적 lexical reference와 현재 DB 관계가 모두0이므로 신규 관계를 만들지 않았다.

Canonical Strong·OSHB를 authority로 삼고 local 6종의 적용 가능한 자료를 전량 비교했다. 추가로 OSHB 문맥12절과 번역4종 문맥40행을 확인했다. LXX는 에9:8 명시 조회만 human reference로 검토했으며 upstream provenance·license 미검증 경계를 유지했다. 전체 감사표·원문·SQL은 외부 Review·cluster summary·부가 evidence에 보존한다.

## 채택하지 않은 주요 대안

|대안|채택하지 않은 핵심 이유와 보존|
|---|---|
|아달리야 (인)만 유지|관용 표기로 적절한 대안이지만 사용자는 기존 음역의 존재와 별개로 아달랴도 meaning에 병기하는 쪽을 선호했다.|
|아달랴 (인)만 사용|개역 등에서 사용하는 아달리야의 식별 가치를 함께 보존하기로 했다.|
|두 표기를 별도 meaning으로 분리|동일 인명의 표기 차이이므로 단일 sense와 가운데점 병기를 선택했다.|
|추정한 페르시아어 이름 뜻을 meaning에 추가|현재 검토 source가 원형·구성요소·뜻을 입증하지 않아 추가하지 않았다. 기원 설명의 범위는 비고에 보존한다.|
|HebGrkKo의 하만과 함께 처형되었다 서술 채택|동시 처형으로 이해하면 에7:10의 하만 처형과 9:6–14의 아들들 사망·이후 매달림의 사건 순서와 맞지 않아 채택하지 않았다.|
|하만 또는 LXX 이름과 lexical 관계 생성|인물 관계는 어휘 파생 관계의 근거가 아니며 LXX의 이름별 직접 대응도 미확정이다.|

## 남은 불확실성 및 재검토 조건

Source의 언어 코드 x-pn은 현행 manifest에서 unresolved이며, 현재 DB의 히브리어 언어값이나 Strong의 Persian derivation 설명과 구분한다. 언어를 추정하여 바꾸지 않았다. 구체적인 페르시아어 어원·이름 뜻·고대 발음은 미확정이다. 아달리야는 한국어 성경 관용명, 아달랴는 기존 원문 근사 읽기의 한글 표기로 보존하며 고대 발음 재구를 주장하지 않는다. 한자 병기는 음역 인명이므로 N/A이고, 합성 경계가 입증되지 않아 붙임표를 넣지 않았다.

LXX 에9:8의 이름 목록은 MT와 이름별 직접 대응을 확정하지 않았다. 위치나 소리만으로 Greek lemma·Strong·관계를 추론하지 않는다. 이 한계는 인명 식별과 단일 sense를 뒤집는 반례가 아니므로 hold를 설정하지 않았다.

검증된 전문 어원·본문비평 자료가 구체적인 원형이나 전승 대응을 제시하거나 canonical identity 충돌이 발견되면 재검토한다. 같은 용례·번역의 반복 확인, 번호 인접성 또는 기존 음역 필드와의 중복만으로 사용자 승인 병기를 제거하거나 sense를 분리하지 않는다.

### 적용·검증

공식 dry-run의 사본 적용·실제 undo·원본 byte 불변 후 live apply가 성공했다. History group 1792412733873222, ID6375–6376은 승인 대상 word update2·undone0이다. 독립 SQL53조회·201검증으로 전체13테이블·DDL·byte 백업·공식 snapshot을 대조했다. 승인 meaning·비고·history·해당 sequence 외 변경이 없고 integrity ok·FK0·sidecar0다. 보호 입력138개와 원본 연구9파일 불변, 기존 applicator 테스트31건 통과다.

표준 semantic_progress JSON·CSV·Markdown을 공식 CLI로 갱신하고 30검증과 공식 renderer 대조를 통과했다. H0118만 explicit_approved로 바뀌었으며 전체14298, 승인395→396·미승인13897→13896·hold6·anomaly113이다. Snapshot identity는 b8370deca5b863eed632b382e8000f578acc9276c16cc39f2311919330a9da92다. UI·앱 코드·배포 seed 변경이 없어 수동 UI 테스트와 전체 앱 빌드는 N/A다.
