# H116 시간·서사 부사 의미·비고 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-19 (Asia/Seoul)
- 대상: H0116 (H0116_0000)
- 승인 manifest: [h116_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h116_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 기존 6건 유지·신규 0
- 로컬 연구 산출물: 외부 reshet_research_output/H0116_cluster_20261019_b33fa822/
- 승인 원문·byte 백업·독립 검증: data/backups/approved_content_batch/h116_approval_20261019/
- 공식 snapshot·manifest 사본·result: data/backups/approved_content_batch/20261019T115536149133Z/

## 최종 결정

사용자는 Codex 추천안을 그대로 채택하고 DB·문서·필요 파일 작업을 승인했다. 검증 후 Git 완료와 이번 작업 브랜치 정리까지 승인했다.

|Strong|최종 ordered meaning|sense|비고|관계|hold|
|---|---|---:|---|---|---|
|H0116|seq 1: 그때·이에|1|아래 전문으로 NULL에서 교체|신규·교체·삭제 없음|없음|

최종 비고:

> 서사의 다음 국면을 잇는 아람어 부사로, 문맥에 따라 ‘그때에’, ‘그러자’, ‘그 다음에’ 등으로 옮긴다. ‘그러므로·드디어·이튿날에’는 문맥과 주변 어구를 반영한 번역이며 각각을 별도 뜻으로 나누지는 않는다. 스 5:16의 ‘그때부터’는 מִן과 결합한 표현이다. 어원은 확정되지 않았다.

기존 `이에, 그 때` 한 의미의 범위를 보존하면서 표기와 순서를 정돈했다. 가운데점은 같은 sense의 한국어 표현 병기이며 두 meaning으로 분리하지 않는다. Meaning replacement1·word note replacement1을 적용했다. 관계의 category/type/status/direction은 N/A다. 원어 אֱדַיִן·음역 에다인·발음·언어·Strong 번호·schema·seed·앱 코드·비대상 데이터와 기존 hold6건은 보존한다. 기존 active 결정을 대체하지 않아 supersession은 없다.

## 핵심 판단 근거

- Canonical Strong은 아람어 부사로 분류하고 기본 뜻을 시간상의 then으로 설명한다. Source의 uncertain derivation을 보존하며 어원을 확정하지 않는다.
- OSHB의 57회·53절 전체를 분석했다. 에스라11회·다니엘46회 모두 사건의 그때 또는 다음 서사 국면을 가리키는 범위로 설명된다. 기본 시간 지시를 앞에 둔 `그때·이에`를 사용자가 최종 채택했다.
- 단독형27·ב 접두형29·ו 접두형1을 같은 sense로 보았다. 스5:16의 두 번째 출현에서 ‘부터’는 앞 전치사 מִן과의 결합이므로 별도 기점 sense를 만들지 않는다.
- 단3:13·3:30의 ‘드디어’, 단5:9·5:24의 인과적 번역, 한국어 단6:19의 ‘이튿날에’는 문맥과 주변 어구를 함께 반영한다. 별도 의미로 늘리지 않는 이유를 비고에 남겼다. 단7:11의 당시 관찰 문맥도 포괄하도록 ‘그 다음에’만으로 좁히지 않았다.
- Canonical structured-reference closure는 node1·edge0·frontier0이다. 실제 DB 관계도 0행이다. 불확실한 비교 어원을 직접 파생이나 차용 관계로 만들지 않는 추천을 사용자가 채택했다.

Canonical Strong·OSHB를 authority로 사용했다. 로컬 사전1행과 KJV·개역개정·개역한글·새번역·원전분해의 적용 가능한 전체 용례를 비교했다. 자동 조회가 보류된 한국어 자료17회는 실제 절 문맥과 대상 행을 수동 대조했다. LXX 명시 조회61건과 외부 BDB는 reference-only로 검토했으며 전체 원문·감사표는 외부 Review·보충 자료에 보존한다.

## 채택하지 않은 주요 대안

|대안|채택하지 않은 핵심 이유와 보존|
|---|---|
|기존 이에, 그 때 그대로 유지|의미 범위 자체는 적절한 대안이다. 사용자가 시간 의미를 앞에 두고 표기를 정돈하는 추천을 채택했다.|
|그때 하나만 기록|간결하고 가능한 대안이다. 이번에는 익숙한 서사 연결 표현 이에도 같은 sense에 병기했다.|
|그러므로·마침내·이튿날에 등을 별도 의미로 추가|특정 번역 문맥을 어휘의 상시 뜻으로 일반화할 위험이 있다. 번역상 표현 가능성은 최종 비고에 보존했다.|
|지금을 독립 의미로 추가|Strong usage의 now와 스4:23 KJV 표현만으로 실제 현재 시점이라는 별도 뜻을 확정하기 어렵다.|
|추정 어원 관계 생성 또는 어원 불확실성을 이유로 word hold|직접 관계·방향을 입증할 근거는 부족하지만 부사의 의미는 전 용례에서 안정적이다. 어원 한계만 비고에 보존했다.|

## 남은 불확실성 및 재검토 조건

역사적 어원은 미확정이다. BDB의 히브리어 비교 형태·지시 어근·접미 요소 설명은 가능한 가설로 보존하며 Strong의 불확실성을 제거하지 않는다. 시간적 이행과 문맥상 결과 강조가 겹칠 수 있지만 별도 lexical sense를 요구하는 반례는 확인되지 않았다.

LXX 다니엘에는 내용·절 분절 차이가 있으며 조회 행 중 두 행은 Not Existed placeholder다. 이 자료는 upstream provenance·license가 미검증이고 자동 alignment·lemma inference authority가 아니다. 대응 불가를 억지로 맞추거나 그리스어 Strong 관계로 승인하지 않았다. 스5:4의 화자 차이도 H0116 자체의 의미 변화로 보지 않는다.

새 canonical 문맥에서 단일 시간·서사 뜻으로 설명되지 않는 용례가 확인되거나 직접 어원 관계를 입증할 비교언어학 근거·검증된 그리스어 전승의 유의미한 충돌 자료가 확보되면 재검토한다. 번역 표현 하나의 차이·번호 인접성·같은 자료 반복 확인만으로 sense나 관계를 자동 추가하지 않는다.

### 적용·검증

공식 dry-run의 사본 적용·실제 undo·원본 byte 불변 후 live apply가 성공했다. History group1792410937360285, ID6373–6374는 승인 대상 word update2·undone0이다. 독립 SQL53조회·247검증으로 전체13테이블·DDL·byte 백업·공식 snapshot을 대조했다. Integrity ok·FK0·sidecar0, 비대상 보호 입력180개와 원본 연구13파일 불변, 기존 applicator 테스트31건 통과다.

표준 progress JSON·CSV·Markdown을 공식 CLI로 생성하고 공식 renderer와 대조했다. 24개 검증에서 H0116만 explicit_approved로 바뀌었으며 승인394→395·미승인13898→13897·hold6·anomaly113·전체14298이다. Snapshot identity는 f2f827e49a3b0d0e10f4a746afdfd65eb22ac7f600847f1bc4507422fa9365a5다. UI·앱 코드·배포 seed 변경이 없어 수동 UI 테스트와 전체 앱 빌드는 N/A다.
