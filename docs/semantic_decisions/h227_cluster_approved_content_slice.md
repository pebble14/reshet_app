# H227·H233 시간·상황 지시 부사 클러스터 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-26 (Asia/Seoul)
- 대상: H0227, H0233
- 승인 manifest: [h227_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h227_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 로컬 연구 산출물: `reshet_research_output/H0227_cluster_20261026_bf00d5c4/00_cluster_summary.md`, 추천 revision `2026-10-26-r1`, `04_semantic_assessment.json`
- 승인 원문·byte 백업·독립 검증: `data/backups/approved_content_batch/h227_approval_20261026/`
- 공식 적용 receipt: `data/backups/approved_content_batch/20261026T052927997134Z/result.json`

## 최종 결정

사용자는 Codex 추천안 그대로 meaning·비고·관계를 채택하고 DB·문서·필요 파일 반영, 검토 후 커밋·작업 브랜치 push·main ff-only 병합·push·이번 작업 브랜치의 로컬·원격 정리를 승인했다. 의미 교체2·비고 교체2·관계 생성1을 적용했다.

|Strong|변경 전 meaning|최종 ordered meaning|sense|hold|
|---|---|---|---:|---|
|H0227 אָז|그 때에, 그 후에|seq1 그때·그러면|1|없음|
|H0233 אֲזַי|그 때에|seq1 그때·그러면|1|없음|

가운데점은 앞서 제시한 때나 상황을 받아 그 국면을 잇는 한 의미 범위의 한국어 표현 병기다. 시간과 논리 기능을 없애거나 ‘그 후에’라는 시간 순서만으로 제한한 결정이 아니다. 새 고유명사·음역·발음 표기를 승인한 것이 아니며, 의미란의 고유어에 한자나 외래어 표기 규칙을 기계적으로 적용하지 않는다.

### 최종 비고 전문

**H0227**

> 앞서 제시된 때나 상황을 받아 그 시점의 일이나 그 경우에 따르는 내용을 잇는 지시 부사다. 과거·미래의 ‘그때(에)·이에’와 조건·가정의 ‘그러면·그렇다면’을 포괄한다. מִן과 결합한 מֵאָז·מִן־אָז는 ‘그때부터·예로부터’로 옮기며, ‘부터’는 전치사에서 온다. ‘그 후에·그제야·이제·반드시·그래도’ 등은 문맥과 주변 어구를 반영한 번역이므로 각각을 별도 뜻으로 나누지 않는다. Strong는 장소 지시도 적지만 확보한 성경 용례에서 독립된 장소 의미는 확인되지 않았다. 렘 11:15는 문장 해석이 불확실하다.

**H0233**

> אָז(H227)와 같은 시간·상황 지시 범위의 부사다. 성경에서는 시 124:3–5에 세 번 나오며, 1–2절의 ‘여호와께서 우리 편이 아니셨다면’을 받아 ‘그때는·그랬다면’으로 결과를 잇는다. 반복은 그 시의 대조를 강조하지만 별도의 더 강한 뜻을 확정하지 않는다. Strong는 H227에서의 유래를 probably로, BDB는 방언형 가능성을 추정하므로 정확한 형성 과정은 확정하지 않는다.

### 관계

|관계 ID|canonical 저장 pair|category / type / status|direction|
|---|---|---|---|
|8130|H0227_0000 — H0233_0000|morphological / variant / hypothesized|undirected|

관계 비고:

> אָז(H227)와 אֲזַי(H233)는 같은 시간·상황 지시 범위를 공유한다. Strong의 H233은 probably from H227, BDB는 probably a dialectic form으로 설명하므로 구체적인 형성 경로와 방향을 확정하지 않는 가설적 이형 관계다.

관계 source:

> Open Scriptures HebrewLexicon, HebrewStrong.xml H233 (21c9add13bc727d3a951361778e97e3ff7afd1ce); Brown–Driver–Briggs אֲזַי entry, Bible Hub, 2026-10-26 열람

description·relation_group_id는NULL이다. 기존 관계 교체·삭제·추가 synonym 생성은 없다. Source-reference H233→H227을 의미 방향으로 복사하지 않았다. 직접 파생의 형성 경로·방향은 확정하지 않고 무방향 가설적 이형 관계로 보존한다.

신규 word hold는0이며 기존 hold6건을 유지한다. 기존 H116 등의 승인값·원문·음역·발음·언어·schema·seed·앱 코드·비대상 데이터·원본 연구 파일은 보존했다. Supersession은 없다.

## 핵심 판단 근거

- Canonical Strong의 두 entry와 OSHB의 H227141회·133절, H2333회·3절을 모두 검토했다. 로컬 사전2행, KJV·개역개정·개역한글·새번역·원전분해의 적용 가능한 전체 용례를 비교했고 한국어 자동 보류13토큰·12절은 원문·실제 절 문맥으로 수동 대조했다. LXX는 명시 조회158건 중 대상136절의134절에서 해당 문맥을 확인한 human-reference다.
- H227의 창12:6·13:7, 삼하23:14는 당시 상태를 가리킨다. 출15:1 등의 서사 연결과 사35:5–6의 미래 시점도 포괄하므로 ‘그 후에’만으로 좁히지 않았다.
- 수1:8·잠2:5·9·사58:8–9·14의 조건 뒤 결과, 욥3:13·9:31·시119:92의 가정·반사실 후건, 전2:15의 논리적 질문도 확인했다. ‘그때·그러면’은 시간과 상황 지시를 함께 드러낸다. 사용자는 이 두 기능을 한 의미 범위로 묶는 추천을 채택했으며, 그 외 개인적 선택 이유를 추정하지 않는다.
- מֵאָז18토큰과 앞에 별도 מִן이 있는 렘44:18의1토큰은 전치사 결합이다. ‘부터·예로부터’를 단독 부사의 별도 뜻으로 늘리지 않고 비고에 보존했다. Augmented lemma `227 a/b`도 원자료대로 구별한다.
- H233 세 용례는 모두 시124:1–2의 לוּלֵי 조건을 받는3–5절의 후건이다. H227의 시119:92와 기능이 겹친다. 형태 길이·시의 반복만으로 H233에 더 강한 독립 의미를 만들지 않고 같은 한국어 범위를 사용했다.
- Strong는 H233의 유래를 probably로, BDB는 방언형 가능성을 추정한다. 형태·의미의 연결성을 보존하면서도 직접 파생·역사적 방향을 확정하지 않는 variant/hypothesized/undirected 관계를 채택했다.
- [H116의 그때·이에 결정](h116_cluster_approved_content_slice.md)에서 번역 문체와 전치사 기여를 별도 sense로 늘리지 않은 이유를 대조했다. 이번 CORE의 조건·논리 기능은 `그러면`으로 직접 드러낸다. 이 비교가 H116의 기존 값을 바꾸거나 모든 시간 부사를 자동 통합하는 규칙은 아니다.

추가 사전 근거는 [BDB אָז 항목](https://biblehub.com/hebrew/227.htm)과 [BDB אֲזַי 항목](https://biblehub.com/hebrew/233.htm)의 해당 entry다. 상세 원문·용례 배정·출처 경계는 외부 Full Review와 cluster summary에 보존한다.

## 채택하지 않은 주요 대안

|대안|채택하지 않은 이유·보존|
|---|---|
|그때 단독|기본 시간 지시는 적절하지만 논리적 질문·가정 후건이 meaning에서 덜 드러난다. 비고로 보완하는 유효한 대안이다.|
|그때에 / 그러면 두 sense|BDB의 시간/논리 분류를 직접 드러내는 가능한 분석이다. 이번에는 하나의 지시 범위에 두 기능을 보이고, 겹치는 용례의 차이는 비고·분류로 보존했다.|
|기존 meaning 그대로 유지|시간 풀이 자체가 오답은 아니지만 조건·논리 연결과 관련어의 공통 범위를 더 명확히 드러내는 안을 채택했다.|
|그러므로·예로부터·반드시·그래도·그곳에를 각각 추가|인과·전치사·문맥·사전 표현을 독립 lexical sense로 자동 승격하지 않는다. 필요한 표현과 장소 풀이의 미확인은 비고에 남겼다.|
|H233에 더 강한 별도 의미|세 번의 반복을 어휘 자체의 강도로 일반화할 근거가 부족하다. 반복의 수사 기능은 비고에 보존했다.|
|직접 파생 asserted 또는 가설적 단방향 derived|Probably와 방언형 가능성을 확정 경로로 올리지 않는다. 단방향 가설도 가능한 분석이지만 이번에는 무방향 variant를 우선했다.|
|관계 비생성·단어 전체 hold|관계 비생성은 보수적인 대안이나 연결성의 설명 가치를 보존하는 가설적 관계를 채택했다. 일반 의미는 안정적이므로 특정 본문·형성 문제를 word hold로 확대하지 않았다.|

## 남은 불확실성 및 재검토 조건

H227141토큰 전량을 검토했으며140은 제안 의미에 배정하고 렘11:15의1토큰은 문장 해석·주 배정을 유보했다. Ambiguous tag4는 배정·미해결과 겹쳐 집계한다. 배정한 용례에서 추천 범위를 뒤집는 반례는 확인되지 않았지만 미해결1건의 반례 판정도 유보한다. H233는3/3 배정이며 미검토·미해결0이다.

렘11:15의 MT 문장과 LXX·새번역의 읽기 차이를 MT 어휘의 확정 의미로 대체하지 않는다. 삼하19:7의 Ketiv לא/Qere לוּ와 삼하5:24의 청각 표현 이형은 주변 본문 문제이며 대상 부사의 새 어휘 관계가 아니다. Strong의 장소 풀이도 원자료에 보존하지만 현행 corpus에서 독립된 장소 의미를 확인하지 못했다. H233의 정확한 방언·형성 경로와 의미 확장 역사도 미확정이다.

LXXStp의 상류 provenance·license와 한국어 reference profile은 계속 미검증이다. 수20:6·잠20:14는 확인한 로컬 행에서 대응 본문을 확보하지 못했다. 모든 LXX 판본에 부재한다고 단정하지 않으며 자동 그리스어 lemma/Strong 정렬이나 신약 관계로 확대하지 않는다.

현재 의미 범위로 설명되지 않는 실제 새 용례, 장소 용법의 검증 가능한 원문 근거, 렘11:15를 실질적으로 해소하는 본문·문법 자료, H233의 역사적 형성 방향 근거가 나오면 해당 판단을 재검토한다. 번역 표현 하나의 차이·번호 인접성·같은 자료의 반복 확인만으로 sense나 관계를 자동 변경하지 않는다.

### 적용·검증

공식 dry-run의 사본 적용5건·실제 undo·원본 불변, applicator 테스트31개 통과 후 live apply를1회 수행했다. History group `1792992569289133`, ID6993–6997은 word update4·relation create1·undone0이다. 독립 SQL42조회·70검증에서 전체13테이블·DDL·byte 백업·공식 snapshot을 대조하여 승인 meaning·note·관계·history 및 관련 sequence 외 변화가 없음을 확인했다. Integrity ok·FK0·sidecar0·seed 불변·보호 입력182개 중 work만 변경·도구 관리 원본 연구8파일 불변이다.

Work SHA는 `bf00d5c478365d3f6b3ef4fe9aee77b9a54515adb393bcc240fa7d977e022607`에서 `a99d0a9c76cd5cb3556ccc19cd648ca392b4db69ee6e380be090c64fbcf94e31`로 바뀌었다. Manifest SHA는 `5ac309b45219ab4786f17168c3a7f7528b8c801ae5ca18abaa88e4de3d75f9ac`이며 적용 사본과 일치하고 파일별 LF 속성을 사용한다. 표준 progress3종·독립24검증·공식 renderer exact 대조에서 대상2개만 신규 승인되어644→646·미승인13648→13646·hold6·anomaly113·전체14298이다. 비대상14296행·lexical index·anomaly는 exact 불변이다. Snapshot identity는 `ecfb07c3cda6f3b716185d154257ad51645ee362cd6bfe58db822862af76669d`다.

Work DB는 Git 미추적 로컬 자산으로 유지한다. Seed 교체·앱 배포·전체 빌드·UI 테스트는N/A다. Sandbox 임시 사본·Flutter cache lock 권한 문제는 같은 공식 명령을 허용된 환경에서 재실행하여 해결했으며 최종 dry-run·테스트·적용 결과는 성공이다.
