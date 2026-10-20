# H143·H144 아달월 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-20 (Asia/Seoul)
- 대상: H0143, H0144
- 승인 manifest: [h143_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h143_cluster_approved_content_slice.json)
- 관련 hold ledger: 변경 없음; 기존 hold6 유지, 신규 hold 없음
- 로컬 연구 산출물: reshet_research_output/H0143_cluster_20261020_4c155203/
- 승인 원문·byte 백업·독립 검증: data/backups/approved_content_batch/h143_approval_20261020/
- 공식 snapshot·result: data/backups/approved_content_batch/20261020T142127455398Z/
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)

## 최종 결정

사용자는 완료된 Codex 추천안대로 DB·문서·필요 파일을 반영하고, 검증 후 Git 작업과 이번 작업 브랜치 정리까지 승인했다. 의미2·비고2·관계 생성1을 적용했다.

| Strong | 최종 meaning | sense | canonical 출현 |
|---|---|---:|---:|
| H0143 | 아달·아다르 (월) | 1 | 8 |
| H0144 | 아달·아다르 (월) | 1 | 1 |

두 표기는 동일한 월명의 표기 차이이며 각 단어의 seq1 한 행이다. 기존 원어·음역·발음·언어를 유지하고 schema·seed·앱 코드는 변경하지 않았다.

### 승인 비고 전문

**H0143**

> ‘아달’은 한국어 성경의 관용 표기, ‘아다르’는 원문 אֲדָר를 옮긴 한글 근사 표기다. 니산월을 첫째로 세는 달력의 열두째 달이며, 양력으로 대체로 2~3월 무렵에 해당한다. Strong은 외래어 기원과 ‘불’이라는 어원 뜻을 추정하지만, 성경 용례는 달 이름이므로 ‘불’을 별도 의미로 확정하지 않는다.

**H0144**

> ‘아달’은 한국어 성경의 관용 표기, ‘아다르’는 원문 אֲדָר를 옮긴 한글 근사 표기다. 니산월을 첫째로 세는 달력의 열두째 달이며, 양력으로 대체로 2~3월 무렵에 해당한다.

### 관계와 hold

- 관계 ID 7962: H0143_0000 ↔ H0144_0000.
- category_code: `etymological`; relation_type: `root_shared`; status_code: `asserted`; direction_code: `undirected`.
- 저장 pair는 H0143_0000 < H0144_0000이다. description과 relation_group_id는 NULL이다.
- 관계 비고: 같은 달 이름의 히브리어·아람어 대응형이다. Strong의 H144는 H143에 대응한다고 설명한다. 두 언어 사이의 직접 차용·파생 방향이나 ‘불’이라는 어원을 확정하지 않는다.
- 관계 source: `Open Scriptures HebrewLexicon, HebrewStrong.xml, H144 source; commit 21c9add13bc727d3a951361778e97e3ff7afd1ce`.
- `root_shared`는 같은 월명의 언어 간 대응을 표현한다. 특정 생산적 히브리어 어근이나 직접 차용 방향을 확정하지 않는다.
- 다른 Strong과의 관계 생성·교체·삭제 없음. 신규 word hold 없음, 기존 ledger6 유지.

## 핵심 판단 근거

H143은 에스더3:7·3:13·8:12·9:1·9:15·9:17·9:19·9:21의8회 모두 월명이다. 앞 네 구절은 열두째 달임을 직접 명시하고, 나머지는 같은 달의 사건·기념일을 지정한다. H144는 에스라6:15 아람어 본문의 성전 완공 날짜에 쓰인 월명1회다. 전체9회가 하나의 의미로 설명되며 미분류·의미 반례는0이다.

Strong의 동일 표제 אֲדָר와 H144의 `(Aramaic) corresponding to H143`, 두 언어의 실제 월명 문맥이 대응 관계를 뒷받침한다. 사전의 참조 방향 H144→H143을 차용·파생 방향으로 복사하지 않았다. 무방향 공통 어휘 대응을 표현한 기존 [H104·H107 결정](h104_cluster_approved_content_slice.md)의 분류 관례를 따른다.

아달은 한국어 성경의 관용명이고 아다르는 원문·기존 expression 음역·참고사전이 지지하는 한글 근사다. 사용자는 두 표기를 meaning 한 행에 병기하는 추천을 채택했다. 특정 시대의 정확한 발음이나 어원을 새로 확정하지 않았고, 합성 경계 근거가 없어 붙임표를 넣지 않았다. `(월)`은 기존 분류 표지이므로 한자를 기계적으로 추가하지 않았다.

Strong XML 두 entry·OSHB9회·HebGrkKo2행·다섯 로컬 성경자료45건·LXX explicit9절을 검토했다. 원본 full Review와 상세 증거는 외부 연구 폴더에 그대로 보존한다.

## 채택하지 않은 주요 대안

- `아달(월)` 유지: 의미상 정확하고 여전히 가능한 대안이다. 사용자는 원문 기반 근사 표기와의 연결을 meaning에서도 볼 수 있는 병기를 선택했다.
- `열두째 달`만 기록: 월명 자체가 사라지고 현대 양력12월로 오해할 수 있으므로 달력 설명을 비고에 배치했다.
- `불`을 별도 meaning으로 추가: Strong의 `perhaps` 어원 추정이며 성경의 월명 용례에서 독립 의미로 입증되지 않는다. H143 비고에 추정과 한계를 보존했다.
- 방향 있는 `borrowed_from`·`derived`: 직접 차용·형성 경로를 입증하지 못하므로 채택하지 않았다. 관계 비생성도 보수적 대안이지만 동일 월명 대응의 탐색 가치를 반영해 무방향 관계를 승인했다.
- 어원 불확실성으로 단어 전체 hold: 월명 식별은9/9회에서 충분히 명확하므로 채택하지 않았다.

## 남은 불확실성 및 재검토 조건

H143 source의 `probably of foreign derivation; perhaps meaning fire;`는 궁극적 어원·언어·경로를 확정하지 않는다. 원천 언어 코드 x-pn에 따른 unresolved metadata도 유지하며 실제 에스더의 히브리어 용례와 구분한다.

에스더3:7에서 새번역은 칠십인역을 따랐다는 각주와 함께13일을 제시하지만, 확보된 LXXStp 본문은14일을 제시한다. OSHB 해당 월명 문구에는 날짜 숫자가 없다. 이 차이는 미해결로 보존하며 다른 월명 sense로 만들지 않는다. LXX 에9:17은 월명 대신 같은 달로 표현하는 등 번역 문맥 차이도 있다. 양력2~3월은 대략적 계절 대응이며 고대 날짜의 정확한 현대 역법 환산은 수행하지 않았다.

한국어 local reference profile 및 LXX upstream provenance·license 미검증 경계는 그대로다. 월명 외 의미의 검증된 원문 용례, 실제 Strong identity 충돌, 직접 차용 방향을 확증하는 자료, 또는 사용자의 표기 선택 변경이 있으면 재검토한다. 번호 인접성·단순 번역 차이·새 자료 없는 어원 추정만으로 자동 재검토하지 않는다.

### 적용 검증

공식 dry-run의 사본 적용·실제 undo·원본 불변 검증 후 live apply가 성공했다. History group `1792506088692035`, ID6435–6439는 word update4·relation create1·undone0이다. 독립 SQL42조회·220검증에서 전체13테이블·DDL·byte 백업·공식 snapshot을 대조했고 승인 projection·history·해당 sequence 외 변경이 없다. Work·백업·snapshot integrity ok·FK0·sidecar0, seed와 보호152파일(원본 연구14파일 포함) 불변이며 기존 applicator 테스트31건이 통과했다.

Work SHA `4c155203f4db21aa465d0502efa663e5763382c2e09eb2f8560a316497998215` → `38a30e02359ffa75331a3285cc6b4085118a7ca05078393d64556c77c797c1c4`. Seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1` 불변. 승인 원문 SHA `e7bbf17a1fa74813ce864b02cfda2df9220f64ef3c764dd6bbf1a4b784030d63`, manifest SHA `30b5c94ff8714613b9ee268fa0f3adf574d3877c8e6fc84afba7afa93a110202`. 신규 manifest는 LF bytes를 고정한다.

표준 semantic_progress JSON·CSV·Markdown을 공식 생성하고28검증 및 renderer 대조를 통과했다. H143·H144만 승인 상태로 전환되어 explicit_approved419→421·unapproved13,873→13,871·hold6·anomaly113·전체14,298이다. Snapshot identity `273413f7acf3f3ac18a60b0a342ad1129a5296bb0916796f20dd3075d7fa747d`. 비대상 row·canonical relation index·anomaly는 불변이다.

정상 CORE2 closure·frontier0이다. 원본 연구는 변경하지 않고 외부 applied-content 기록에 적용 결과를 별도로 남긴다. DB는 Git 미추적 로컬 자산이며 seed 교체·앱 배포는 수행하지 않았다. 앱/UI 변경이 없어 수동 UI 테스트와 전체 앱 빌드는 N/A다.
