# H228 가열 동사 의미·비고 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-26 (Asia/Seoul)
- 대상: H0228_0000, 아람어 אֲזָא
- 승인 manifest: [h228_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h228_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 로컬 연구 산출물: `reshet_research_output/H0228_cluster_20261026_a99d0a9c/`, 추천 revision `H0228-R1-20261026`; Full Review와 `01_supplemental_evidence.json`
- 승인 원문·적용 전 byte 백업·검증: `data/backups/approved_content_batch/h228_approval_20261026/`
- 공식 적용 receipt: `data/backups/approved_content_batch/20261026T092934349622Z/result.json`

## 최종 결정

사용자는 CodeX R1 추천안대로 DB·문서·기타 필요 파일 반영, 검토 후 커밋·작업 브랜치 push·main ff-only 병합과 push·이번 작업 브랜치의 로컬·원격 정리까지 승인했다. 의미 교체1·비고 교체1을 적용했다.

|Strong|변경 전 meaning|최종 ordered meaning|sense|hold|
|---|---|---|---:|---|
|H0228|뜨겁다|seq1 `뜨겁게 하다`|1|없음|

최종 비고 전문:

> Strong은 불붙이다와 그에 함축된 뜨겁게 하다로 풀이한다. 단 3:19의 두 부정사는 화덕을 달구는 행위를, 3:22의 수동분사는 달구어져 뜨거운 상태를 나타낸다. Strong은 אֲזָה도 같은 항목의 형태로 제시한다.

관계 생성·교체·삭제, 새 hold·hold 해제·supersession은 없다. אֲזָה는 같은 Strong entry 안의 형태로 설명하며 별도의 Strong pair를 만들지 않는다. 원문 expression·음역·발음·언어·schema·seed·비대상 어휘와 기존 관계·hold ledger는 보존했다. 새 고유명사 표기나 발음 정비를 승인한 결정이 아니다.

## 핵심 판단 근거

- Canonical Strong XML의 H228 entry 전체와 OSHB의3토큰·2절, 단3:18–23의 문단을 검토했다. HebGrkKo exact entry와 KJV·개역개정·개역한글·새번역·원전분해의 적용 가능한 두 절 전체를 대조했다. 탐색은1 node·관계 근거0·frontier0으로 닫혔으며 허브 제외가 없다.
- 단3:19의 לְמֵזֵא와 לְמֵזְיֵהּ는 화덕을 달구는 행위를 나타내는 페알 부정사다. 첫 번째는 더 달구라는 명령의 내용이며 두 번째는 평소의 달굼을 비교 기준으로 둔다. 단3:22의 אֵזֵה는 달구어진 결과 상태의 수동분사다. `뜨겁게 하다`는 두 능동 용례의 행위성을 담고 수동형의 상태도 설명한다. 한국어 `~하게 하다`를 아람어의 별도 사역 어간이라고 주장하지 않는다.
- Strong은 불붙임과 그에 함축된 가열을 설명한다. 불붙임 풀이를 비고에 보존하고, 능동·수동이나 번역 문체의 차이만으로 별도 meaning을 만들지 않았다. 일곱 배·심히·불꽃·죽이다는 다른 단어의 뜻으로 구별했다.
- [H215 결정](h215_cluster_approved_content_slice.md)은 빛남·비춤 외의 실제 불붙임 용례 때문에 별도 meaning을 두었다. H228에서는 모든 출현이 화덕 가열의 같은 범위이므로 그 의미 수를 기계적으로 복제하지 않는다. [H201 결정](h201_cluster_approved_content_slice.md)의 H560에서 발화의 명령 기능을 비고에 담은 원칙도 대조했다. 기존 승인된 관련어는 변경하지 않는다.
- LXX는 두 절을 명시 조회하여 비교했으나 human-reference 경계를 유지했다. Strong과 BDB의 해당 entry도 가열 동사를 뒷받침한다. BDB는 해당 사전 entry만 열람했으며 전문을 읽었다고 주장하지 않는다.
- 사용자는 위 evidence에 근거한 추천을 최종 채택했다. 사용자 개인의 별도 선택 이유를 추정하지 않는다. `뜨겁게 하다`는 고유어 일반 뜻풀이로 한자·외래어 받침·고유명사 병기는 N/A다.

## 채택하지 않은 주요 대안

|대안|채택하지 않은 이유·보존|
|---|---|
|기존 뜨겁다 유지|수동분사의 한국어 실현에는 자연스럽지만 능동 부정사 두 번의 행위성이 대표 meaning에서 덜 드러난다. 오역이라고 전면 폐기하지 않고 결과 상태를 비고에 보존했다.|
|달구다|문맥상 유효한 대안이다. 대표 meaning에는 쉬운 일반 표현을 선택하고 비고에서 화덕을 달구는 풀이를 사용했다.|
|불붙이다 / 뜨겁게 하다 두 sense|현행 세 출현에서 독립적인 점화 의미와 가열 의미를 분리할 근거가 부족하다. Strong의 불붙임 설명은 비고에 보존했다.|
|뜨겁게 되다를 별도 meaning으로 추가|능동 행위와 수동 결과라는 태의 차이로 설명된다. 활용·번역 차이만으로 sense를 늘리지 않았다.|
|H215 또는 특정 Greek Strong과 관계 생성|뜻의 겹침·번호 인접성·LXX 구절만으로 정확한 어원·번역 pair를 승인하지 않는다. 현행 구조화된 incoming/outgoing 관계 evidence는0이다.|
|어휘 전체 hold|어휘 identity와 일반 의미는 충분히 확인되었다. 역사적 어원·발음·참고본문 문제를 word-level hold로 확대하지 않는다.|

## 남은 불확실성 및 재검토 조건

Canonical3토큰 전부를 한 의미에 배정했고 미검토·ambiguous·의미 배정 미해결·확인된 반례는 각각0이다. 이것이 다른 시대·방언의 모든 아람어 corpus나 미열람 사전 전문까지 확인했다는 뜻은 아니다. 일반 의미와 역사적 어원·정확한 고대 발음의 확실성을 구별한다.

LXXStp의 upstream provenance·license와 한국어 참고자료의 전체 versification profile은 미검증 상태로 유지한다. LXXStp 단3:22는 현행 아람어·한국어·KJV의 경비병 사망 서술과 내용이 다르다. 정확한 전승·판본 대응은 미확정으로 남기며 자동 lemma/Strong 정렬이나 새 관계로 승격하지 않는다. BDB 웹 재록의 일부 철자 표시 차이도 OSHB 원문 교정 근거로 사용하지 않는다.

현재의 가열 의미로 설명되지 않는 실제 아람어 용례, 점화와 가열의 독립 의미 분리를 뒷받침하는 corpus·문법 근거, canonical identity·형태 분석의 실질적 정정이 나오면 해당 판단을 재검토한다. 번역 문체나 같은 사전 재록 수만으로 의미 수·관계를 자동 변경하지 않는다. 일반 표기 정책 개정도 기존 원문·음역·발음의 자동 변경 권한이 아니다.

### 적용·검증

공식 dry-run에서 사본 적용2건·실제 undo·원본 DB byte 불변을 확인하고 기존 applicator 회귀 테스트31개 통과 후 live apply를1회 수행했다. History group `1793006975693234`, ID `6998·6999`는 word update2·undone0이다.

전체13테이블·DDL을 적용 전 byte 백업과 공식 snapshot에 독립 대조하고 SQL43조회·244검증을 통과했다. 승인 meaning·비고·history2 및 history sequence 외 변화는 없다. Integrity ok·FK0·sidecar 없음·seed 불변·보호 입력178개·원본 연구8파일 불변을 확인했다.

Work SHA `a99d0a9c76cd5cb3556ccc19cd648ca392b4db69ee6e380be090c64fbcf94e31` → `ca96cc7afa291895fb594c3df8d72cae2ae97f2587ce609b5f05ee748b4117d4`; seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1` 불변이다. Manifest SHA `5ae1320b56bd109aa126ea39d1437900ff1ab4fd255739f5a54213e6eed06fee`는 현재 파일·적용 사본과 일치하며 파일별 LF 속성을 사용한다.

표준 progress JSON·CSV·Markdown은 공식 도구로 갱신했고 독립23검증·공식 renderer exact 대조를 통과했다. 대상1개만 신규 승인되어646→647·미승인13646→13645·hold6·anomaly113·전체14298이며 비대상14297행·기존 authority·lexical index·anomaly는 exact 불변이다. Snapshot identity는 `272fc210525378b9db5eafc147df88b36f0cecd41da03c4b2aba2f2ef6de239d`다.

Work DB는 Git 미추적 로컬 자산으로 유지한다. 앱 코드·UI·schema 변경, seed 교체·배포·전체 빌드·수동 UI 테스트는 N/A다. 상세 evidence는 외부 연구 파일과 로컬 적용 검증에 보존한다.
