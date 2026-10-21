# H163 아하와 지명 의미·비고 승인 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-21 (Asia/Seoul)
- 대상: H0163 / H0163_0000
- 승인 manifest: [h163_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h163_cluster_approved_content_slice.json)
- 관련 hold authority: [현행 ledger](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음
- 연구 산출물: 로컬 `reshet_research_output/H0163_cluster_20261021_7dc485d7/`
- 승인 원문·적용 전 byte 백업·독립 검증: `data/backups/approved_content_batch/h163_approval_20261021/`
- 공식 snapshot·result·manifest 사본: `data/backups/approved_content_batch/20261021T142357020580Z/`
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)

## 최종 결정

사용자는 완료된 Codex 추천안대로 DB·문서·필요 파일을 반영하고, 각 단계 검증 후 Git 반영과 로컬·원격 작업 브랜치 정리까지 승인했다.

| Strong | 승인 meaning | 순서 | sense | canonical 출현 |
|---|---|--:|--:|--:|
| H0163 | 아하와 (지) | 1 | 1 | 3 |

현재 meaning 문자열은 교체하지 않고 `meaning_approvals`로 승인했다. 비고는 NULL에서 다음 문장으로 변경했다.

> 바벨론의 강 이름으로, 에스라 일행은 그 강가에 모여 예루살렘 귀환을 준비하고 금식했다(스 8:15, 21, 31). 8:15의 ‘아하와로 흐르는 강’이라는 표현은 같은 이름의 지점을 가리킬 가능성도 남긴다. 정확한 위치와 어원은 현재 자료로 확정할 수 없으며, Strong은 외래 기원으로 추정한다.

신규·교체·삭제 관계는 없고, 기존 H0163 관련 관계도 0건이다. 관계의 category/type/status/direction 지정은 N/A다. 신규 hold 없음, 기존 ledger 6건 유지다. 원어·음역·발음·언어·schema·seed·앱 코드와 비대상 데이터는 유지했다. 기존 active 결정을 대체하는 작업이 아니므로 supersession은 없다.

## 핵심 판단 근거

고정된 Open Scriptures HebrewStrong.xml의 H163은 `אַהֲוָא`, 지명 품사 `n-pr-loc`이며 바벨론의 강으로 설명한다. source의 `probably of foreign origin;`는 외래 기원 추정으로 보존하며 특정 기원 언어나 차용 상대를 확정하지 않는다. Canonical lexical source는 commit `21c9add13bc727d3a951361778e97e3ff7afd1ce`다.

OSHB 에스라 8:15·21·31의 세 용례를 모두 분석했다. 8:15는 아하와로 흐르는 강가의 집결·체류, 8:21은 그 강가에서의 금식, 8:31은 아하와 강에서의 출발이다. 같은 귀환 서사의 동일 지명으로 설명되며, 단일 sense 3/3·미분류 0·sense 모호 0·반례 0이다. 다만 8:15의 지점 식별 세부는 모호하므로 비고에 가능성으로 보존했다.

HebGrkKo exact row 1개, KJV·개역개정·개역한글·새번역·원전분해의 세 절씩 총 15건을 전량 비교했다. LXX는 같은 세 절을 explicit lookup으로 수동 검토했다. 번역 표현 차이와 LXX의 이름 표기 차이를 새 sense나 어휘 관계로 승격하지 않았다. 로컬 자료는 reference-only, LXX는 provenance·license unverified인 human reference 경계를 유지한다.

‘아하와’는 한국어 성경 관용 표기이며 특정 고대 발음의 재구가 아니다. 고유명사에 한자를 만들거나 근거 없는 합성 경계를 넣지 않는다. 기존 meaning은 이미 간결하고 충분하므로 사용자는 이를 유지하면서 지리·어원 불확실성을 비고에 보완하는 추천을 채택했다.

양방향 lexical discovery는 CORE 1개, relation evidence 0, frontier 0으로 닫혔다. Strong의 특정 참조와 DB 관계가 모두 없어 relation을 만들지 않는다. 이름 식별과 일반 의미는 충분하여 위치·어원의 작은 불확실성으로 단어 전체를 hold하지 않는다.

## 채택하지 않은 주요 대안

- `아하와 강 (지)`: 강이라는 구체 식별이 명료한 가능한 대안이다. 다만 기존 meaning보다 독립적인 이득이 작고 8:15의 지점 해석 여지를 좁히므로, 강 설명은 비고에 두었다.
- 도시 아하와와 강 아하와의 2 sense: 8:15와 나머지 두 절의 구문 차이는 있으나 별도 도시와 독립 lexical sense를 확정하기에 부족하다. 지점 가능성만 비고에 보존했다.
- `아하와·아하바 (지)`: v 계열 읽기 근사를 병기할 수 있지만 식별 이득이 작고 Strong 영어식 발음 안내를 특정 시대 실제 발음으로 오해할 수 있어 추가하지 않았다. 기존 expression 필드의 `아하와(바)`는 보존했다.
- 특정 현대 하천·도시 또는 외국어와의 확정 관계: 현재 근거가 부족하다. HebGrkKo의 수도 근처라는 추정도 확정 위치로 채택하지 않았다.

## 남은 불확실성 및 재검토 조건

정확한 현대 위치, 어원·기원 언어, 에스라 8:15에서 강과 같은 이름의 독립 지점이 전제되는지는 미확정이다. 원자료 언어 코드 `x-pn`의 unresolved 상태와 히브리어 본문 사용을 구분하며, DB의 언어 표기를 변경하지 않았다.

출처가 분명한 지리·비문·전문 어원 자료가 구체 위치나 독립 지점을 판별하거나, 검증 가능한 본문·lemma 근거가 Strong identity 또는 용례 범위를 바꿀 때 재검토한다. 번역본의 단순 표현 차이, 번호 인접성, 이미 확인한 읽기 차이만 반복되는 경우 자동 재검토하지 않는다.

### 적용 검증

공식 dry-run에서 임시 사본의 비고 적용·undo·원본 DB 불변을 확인했고, 기존 applicator 테스트 31건이 통과한 뒤 live apply했다. Meaning approval 1·word note replacement 1이며 history group `1792592638288579`, ID `6541`은 H0163 word update 1건, undone 없음이다.

독립 SQL 56조회·220검증에서 전체 13테이블·DDL·적용 전 byte 백업·공식 snapshot을 비교했다. 승인된 비고·history·관련 sequence 외 변경 없음, integrity ok·FK 위반 0·sidecar 없음, 보호 입력 168파일 불변을 확인했다. Snapshot의 schema cookie 1368→1369는 기존 VACUUM INTO 계약이며 실제 DDL과 적용 전 데이터는 일치한다.

Work SHA `7dc485d7a300912a5a5478d4c6fc8664c496d3dee8620a71104f5876cce21aab` → `81afd7d3da5b5450f03b11c76de939e0af768150110f4af64878a0f0a166606a`. Seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1` 불변. Manifest SHA `7c2c353372d98470ce9fdad632d5d9494e3db3b15aa375365c6ef416d082b3a6`, 승인 원문 SHA `00e1c8eac8eaf3389c1731304e515aea712c73a2daa474342b3997aa7e287052`다.

표준 semantic_progress JSON·CSV·Markdown 생성 후 18검증과 공식 renderer byte 대조가 통과했다. H0163만 신규 승인되어 explicit_approved 465→466·unapproved 13,827→13,826·hold 6·anomaly 113·전체 14,298이다. 비대상 14,297행·anomaly·canonical lexical index는 exact 불변이며 snapshot identity는 `1929c7c5355a294f1092a63df2bd71752717d83a1c95184992f3064c47162309`다.

원본 연구는 그대로 보존하고 적용 결과는 별도 로컬 기록으로 남긴다. DB는 Git 미추적 로컬 자산이며 manifest와 결정 기록을 Git으로 보존한다. Seed 교체·앱 배포·schema·UI 변경은 없어 전체 빌드와 수동 UI 테스트는 N/A다.
