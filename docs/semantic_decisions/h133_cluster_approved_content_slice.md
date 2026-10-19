# H133 아드마다·아드마타 인명 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-20 (Asia/Seoul)
- 대상: H0133 (H0133_0000)
- 승인 manifest: [h133_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h133_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 기존 6건 유지·신규 0
- 로컬 연구 산출물: 외부 reshet_research_output/H0133_cluster_20261020_2de906f1/
- 승인 원문·byte 백업·독립 검증: data/backups/approved_content_batch/h133_approval_20261020/
- 공식 snapshot·manifest 사본·result: data/backups/approved_content_batch/20261019T165427716854Z/

## 최종 결정

사용자는 CodeX 추천안을 그대로 채택하고 DB·문서·필요 파일 작업, 검증 후 Git 완료 및 이번 작업 브랜치 정리를 승인했다.

|Strong|최종 ordered meaning|sense|비고|관계|hold|
|---|---|---:|---|---|---|
|H0133|seq 1: 아드마다·아드마타 (인)|1|아래 전문으로 NULL에서 교체|신규·교체·삭제 없음|없음|

최종 비고:

> 에스더 1:14에 나오는, 아하수에로 왕을 가까이에서 섬긴 페르시아와 메대의 일곱 고관(高官) 중 한 사람이다. 아드마다는 한국어 성경의 관용 표기이며, 아드마타는 히브리어 전승형을 옮긴 교재식 근사 표기이다. Strong은 페르시아어계 어원을 추정하나 이름의 본뜻과 내부 구성은 확정하지 않는다.

아드마다와 아드마타는 동일 인명의 두 표기이며 별도 sense로 나누지 않는다. Meaning replacement1·word note replacement1을 적용했다. Relation category/type/status/direction은 모두 N/A다. 기존 spelling·transliteration·pronunciation·언어·Strong 번호·schema·seed·앱 코드·hold ledger와 비대상 데이터는 보존한다. 기존 active semantic 결정의 대체나 supersession은 없다.

## 핵심 판단 근거

- Canonical Strong은 남성 인명 n-pr-m, Admatha, a Persian nobleman으로 설명한다. Direct source의 probably of Persian derivation을 추정 강도 그대로 보존하며 원래 페르시아어 형태나 본뜻을 확정하지 않는다.
- OSHB의 유일 용례 에스더 1:14 전체를 검토했다. 왕에게 가까이 있는 페르시아·메대의 일곱 고관 중 한 사람을 가리키므로 인명 의미 하나로 설명된다. 1:13–15 원문 문맥도 대조했다.
- 개역개정·개역한글·새번역은 아드마다, KJV는 Admatha를 준다. HebGrkKo exact row와 원전분해, 기존 DB 음역은 아드마타를 제공한다. 사용자는 관용명과 기존 원문 기반 교재식 근사 표기의 병기 추천을 최종 채택했다.
- 원문 기반 근사를 특정 시대의 실제 발음 재구로 취급하지 않는다. 내부 구성이 확인되지 않아 분석적 붙임표를 쓰지 않는다.
- Canonical lexical index의 in/out direct edge와 실제 DB 관계는 모두 0이다. 페르시아어계라는 추정만으로 연결 Strong이나 차용 원형을 특정할 수 없어 관계 비생성을 채택했다. 인명 식별은 충분하므로 어원 불확실성은 비고에 한정하고 hold를 두지 않는다.

Canonical Strong·OSHB를 authority로 사용하고 확보된 로컬 사전1행 및 번역·원전분해 전체1/1절을 비교했다. LXX는 Esther 1:14 explicit lookup만 human reference로 검토했다. 상세 원문·전체 감사표·SQL·hash는 외부 연구 산출물에 보존한다.

## 채택하지 않은 주요 대안

|대안|채택하지 않은 핵심 이유와 보존|
|---|---|
|아드마다 (인) 그대로 유지|의미상 적절하고 간결한 대안이다. 사용자가 원문 기반 근사 표기와 연결되는 병기 추천을 채택했다.|
|아드마타 (인)만 사용|원문 기반 근사에 가깝지만 한국어 성경 관용 식별명을 meaning에서 잃는다. 두 표기를 한 meaning에 함께 보존했다.|
|고관(高官)을 별도 meaning으로 추가|고유명사가 가리키는 인물의 신분이지 이름 자체의 독립 lexical sense가 아니다. 신분은 비고에 설명했다.|
|H119 계열과의 어근 관계·확정 차용 관계 생성|번호·철자 유사성이나 probably Persian이라는 source 문구만으로 구체적인 상대 어휘와 방향을 입증하지 못한다. 관계를 생성하지 않았다.|
|어원 미정 또는 source x-pn을 이유로 word hold|본문의 인명 기능과 식별은 안정적이다. 원래 어원과 발음의 한계는 비고에 남겼다.|

## 남은 불확실성 및 재검토 조건

원래 이름의 언어·어형·본뜻·내부 구성과 기록 당시 실제 발음은 미확정이다. 원천 x-pn은 현행 mapping상 unresolved이며 DB의 히브리어 분류나 히브리어 본문 표기만으로 원래 이름의 언어를 확정하지 않는다. 이번에는 언어 필드를 바꾸지 않았다.

LXXStp의 같은 절은 히브리어와 다른 인명 목록을 주므로 H0133의 일대일 그리스어 대응형을 확정하지 않는다. 이 자료의 upstream provenance·license는 미검증이고 자동 alignment·lemma inference authority가 아니다. 이 차이는 히브리어의 canonical occurrence1회나 최소 인명 의미를 취소하는 근거가 아니다. 본문 밖 인물의 실존을 입증했다고 주장하지 않는다.

H133 개별 이름에 직접 대응하는 신뢰할 만한 고대 인명 자료·전문 원어 연구나 원형을 특정하는 어원 근거, 검증된 그리스어 전승 대응이 확보되면 해당 범위만 재검토한다. 번호 인접성·철자 유사성·동일 자료 반복 확인·번역 직위 표현 차이만으로 sense나 관계를 자동 추가하지 않는다.

### 적용·검증

공식 dry-run에서 사본 적용·실제 undo 및 원본 byte 불변을 확인한 뒤 live apply가 성공했다. History group1792428868942486, ID6433–6434는 승인 대상 word update2·undone0이다. 독립 SQL56조회·194검증으로 전체13테이블·DDL·byte 백업·공식 snapshot·최종 projection을 대조했다. Integrity ok·FK0·sidecar0, 보호146파일(원본 연구8 포함) 불변, 기존 applicator 테스트31건 통과다.

표준 progress JSON·CSV·Markdown을 공식 CLI로 생성하고 공식 renderer와 대조했다. 18검증에서 H0133만 explicit_approved로 바뀌었으며 승인418→419·미승인13874→13873·hold6·anomaly113·전체14298이다. Snapshot identity는 3a10c956cc42dd13ee19c069f3a88579f37c9827a8d41f270c73189e608adb8b다. 실제 적용 manifest의 CRLF bytes를 보존하도록 해당 경로만 -text로 지정했다. DB는 Git 미추적 로컬 자산이며 수동 UI 테스트·앱 배포·seed 교체·전체 앱 빌드는 N/A다.
