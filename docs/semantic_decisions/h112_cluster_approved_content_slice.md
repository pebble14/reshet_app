# H112 잇도 의미 유지·비고 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-19 (Asia/Seoul)
- 대상: H0112 (H0112_0000)
- 승인 manifest: [h112_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h112_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 기존 6건 유지·신규 0
- 로컬 연구 산출물: 외부 reshet_research_output/H0112_cluster_20261019_e4be5ce9/
- 승인 원문·byte 백업·독립 검증: data/backups/approved_content_batch/h112_approval_20261019/
- 공식 snapshot·manifest 사본·result: data/backups/approved_content_batch/20261019T022723799259Z/

## 최종 결정

사용자는 meaning을 기존값으로 유지하고 나머지 추천을 채택했다. DB·문서·필요 파일 작업을 승인했고, 이상이 없으면 Git 완료와 이번 작업 브랜치 정리까지 승인했다.

|Strong|최종 ordered meaning|sense|비고|관계|hold|
|---|---|---:|---|---|---|
|H0112|seq 1: 잇도 (인)|1|아래 문자열로 NULL에서 교체|신규·교체·삭제 없음|없음|

최종 비고:

> 잇도는 한국어 성경의 관용 표기이고, 읻도는 אִדּוֹ의 중복 자음을 드러내는 교재식 한글 근사 표기이다. 특정 시대의 실제 발음을 확정한 것은 아니다. 스 8:17에서 가시뱌의 지도자로 두 번 언급되며, 에스라가 성전 봉사자를 구하려고 사절을 보낸 대상이다. 이름의 어원은 확실하지 않다.

기존 meaning을 `meaning_approvals` 1건으로 승인했다. meaning replacement는 0건이며 실제 DB 쓰기는 word note replacement 1건이다. 기존 한글 음역 `읻도`, 원어 `אִדּוֹ`, 발음·언어·Strong 번호·schema·seed·앱 코드·비대상 데이터는 보존했다. 현재 대상 관계 0행과 기존 hold ledger 6건도 유지한다. 새 relation의 category/type/status/direction은 N/A다. 기존 active semantic 결정을 대체하지 않으므로 supersession은 없다.

## 핵심 판단 근거

- 정본 OSHB 2 token은 모두 에스라 8:17의 같은 가시뱌 지도자를 가리킨다. 첫 언급은 사절이 찾아갈 지도자이고 둘째 언급은 메시지를 전할 같은 인물이다. 현재 `잇도 (인)` 1 sense로 두 용례를 충분히 설명하므로 사용자가 기존 meaning 유지를 선택했다.
- Canonical Strong의 표제어는 אִדּוֹ, 품사는 n-pr-m이며 인명으로 설명한다. source는 `of uncertain derivation`이라고 명시하므로 어원 번역·합성 분절·파생 관계를 확정하지 않는다.
- 개역개정·개역한글·새번역의 관용명, KJV의 Iddo, HebGrkKo의 인물 설명, 원전분해의 두 인명 항목이 이 식별과 부합한다. 한국어 조사 결합 `잇도와`를 별도 sense로 분리하지 않는다.
- 비고는 성경 관용 표기와 이미 등록된 교재식 한글 음역의 차이, 특정 인물의 본문상 역할, 어원 불확실성을 설명한다. meaning을 병기형으로 바꾸거나 expression을 다시 수정하는 승인이 아니다.
- 현재 canonical structured-reference graph의 H112 cluster는 1 node·edge 0·frontier 0으로 닫혔다. 불확실한 어원이나 번호 인접성·문맥 공기어만으로 관계를 만들지 않는 추천을 사용자가 채택했다.
- 인명 식별과 두 용례의 지시는 명확하다. 어원과 고대 실제 발음의 불확실성을 비고에 한정하고 word-level hold를 만들지 않는다.

Canonical Strong·OSHB를 authority로, 로컬 6종은 reference-only로 사용했다. Canonical 2/2 token과 해당 절의 확보 참고자료 전량, 에스라 8:15-20 문맥을 검토했다. LXX는 명시적 Ezra 8:17 단일 절만 human reference로 조회했다. 전체 원문과 자료 확인 감사표는 외부 full Review·cluster summary에 보존하며 이 결정 기록에 복제하지 않는다.

## 채택하지 않은 주요 대안

|대안|채택하지 않은 핵심 이유와 보존|
|---|---|
|잇도·읻도 (인)으로 meaning 병기|같은 인명을 관용명과 교재식 근사로 병기하는 유효한 편집 대안이다. 사용자는 기존 meaning을 유지하기로 결정했다. 읻도는 현재 음역란과 최종 비고에 보존한다.|
|읻도 (인)만으로 교체|관용명 잇도를 제거할 필요가 없으며 이번 승인도 기존 meaning 유지다. 읻도를 잘못된 표기라고 판정한 것은 아니다.|
|비고 NULL 유지|표기 층위·인물 식별·어원 불확실성을 안내하는 추천 비고를 사용자가 채택했다.|
|별도 어원 meaning·합성 분석·추정 관계 생성|확보된 canonical source가 어원을 확정하지 않고 상대 Strong도 제시하지 않는다. 임의의 lexical sense·상대 어근·관계를 만들지 않는다.|
|어원 불확실성을 이유로 word hold|확인 가능한 인명 의미와 두 용례의 지시는 안정적이므로 어원 한계만 비고에 남긴다.|

## 남은 불확실성 및 재검토 조건

이름의 역사적 어원·원천 언어·고대 실제 발음은 확정하지 않는다. Strong의 x-pn은 현행 계약상 unresolved이며, 현재 DB의 히브리어 분류를 그 어원의 증명으로 사용하지 않는다. 읻도는 교재식 근사이지 특정 시대 발음 복원이 아니다.

LXX 참고 본문에서는 잇도 이름의 명시적 음역을 확인하지 못했다. 해당 자료의 upstream provenance·license는 미검증이며, 차이의 원인이나 자동 Hebrew↔Greek 대응을 확정하지 않는다. 가시뱌 지도자라는 식별을 넘어 잇도의 구체 성직·집단 소속·귀환 동행 또는 동명이인 동일시를 추가하지 않는다.

신뢰 가능한 새로운 어원 자료, 이름 형태나 인물 식별을 바꾸는 직접 본문비평 근거, 검증된 Greek 전승의 충돌 evidence가 확보되면 재검토한다. 번역 스타일·같은 한국어 이름·번호 인접성·한글 음가 차이·같은 자료의 반복 확인만으로 자동 재검토하거나 승인값을 변경하지 않는다.

### 적용·검증

공식 dry-run에서 사본의 비고 1건 적용과 실제 undo, 원본 DB byte 불변, 기존 meaning approval 1건의 exact projection을 확인한 뒤 live apply했다. History group `1792376844994593`, ID `6295`는 active word update 1행, undone 0이다. meaning과 관계는 쓰지 않았다.

독립 SQL 55조회·218검증으로 전체 13테이블·DDL·byte 백업·공식 snapshot을 대조했다. 승인 비고 1행·history 1행·CHANGE_HISTORY sequence 외 차이가 없고 work·seed·snapshot·byte 백업은 integrity ok·FK 0·sidecar 0이다. 원본 연구를 포함한 보호 입력 157개가 불변이며 기존 applicator 테스트 31건이 통과했다. SQL 목적·실행문·결과·해석은 `05_independent_db_verification.json`에 있다.

Work SHA `e4be5ce9eb92cbbebef5195da12b10ca0d088990360152b284553fd617147856` → `a70dcd894eb63f7ad48990664f1ebae37e1fa0224682f2771b50092f7fe4405f`. Seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1`는 불변이다. Approval SHA `2e95c1f1a6d1513c7e21a236d479874544ac7235164f6771cfa49d886379b5e9`, manifest SHA `c803a1ef17c9d65fad7519211b858e5df8bd441e9044ac300bc0a1eb7f8fee9f`이며 실제 적용 UTF-8 CRLF bytes를 보존하도록 신규 manifest 경로에만 `-text whitespace=cr-at-eol`을 지정했다.

표준 외부 semantic_progress JSON·CSV·Markdown과 38검증에서 H0112만 explicit_approved로 전환되었다. 승인 366→367·미승인 13,926→13,925·hold 6·anomaly 113·분모 14,298이다. Snapshot identity는 `4dd63268b0d65b414e917448b2b6a81494c62ec5bf25967673765247e99f336e`이며 비대상 row·anomaly·canonical relation index·기존 source fingerprint와 CSV/Markdown 공식 render가 일치한다.

원본 연구는 적용 전 상태로 보존하고 외부 `00_applied_content.md/json`에 사용자 최종 선택과 적용 결과를 별도로 기록한다. DB는 Git 미추적 로컬 자산이다. 앱 배포·seed 교체는 수행하지 않았으며 앱/UI·UX 변경이 없어 수동 UI 테스트·전체 앱 빌드는 N/A다.
