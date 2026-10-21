# H149 충실한 이행 부사 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-21 (Asia/Seoul)
- 대상: H0149 (`H0149_0000`), 아람어 부사 `אַדְרַזְדָּא`
- 승인 manifest: [h149_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h149_cluster_approved_content_slice.json)
- 관련 hold ledger: 변경 없음; 기존 hold6 유지, 신규 hold 없음
- 로컬 연구 산출물: `reshet_research_output/H0149_cluster_20261021_38a30e02/`
- 후속 어원·후보 비교: 위 폴더의 `01_etymology_followup.md` 및 사용자 판단 대화
- 승인 원문·byte 백업·독립 검증: `data/backups/approved_content_batch/h149_approval_20261021/`
- 공식 snapshot·result: `data/backups/approved_content_batch/20261021T010032203146Z/`
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)

## 최종 결정

사용자는 최신 추천인 `충실히(忠實히)` 단일 의미와 명령 이행 문맥 비고를 채택하고 DB·문서·Git·이번 작업 브랜치 정리까지 승인했다. 의미1·비고1을 반영했다.

| Strong | 변경 전 meaning | 최종 meaning | sense | canonical 출현 |
|---|---|---|---:|---:|
| H0149 | 주의깊게, 부지런히 | 충실히(忠實히) | 1 | 1 |

최종 meaning은 `word_meaning_set`의 seq1 한 행이다. 원어·음역·발음·언어·graph 설정·schema·seed·앱 코드는 변경하지 않았다.

### 승인 비고 전문

> 스 7:23에서는 명령을 정해진 대로 소홀함 없이 이행하는 뜻이다.

### 관계와 hold

관계 생성·교체·삭제 모두0, H149 관련 현재 `WORD_RELATION` 행0이다. category_code·relation_type·status_code·direction_code는 모두 N/A다. 원천 이란어 재구나 번역 대응을 DB의 확정 어휘 관계로 승격하지 않았다. 신규 word hold 없음, 기존 hold6과 ledger는 유지한다.

## 핵심 판단 근거

OSHB의 유일한 용례 에스라7:23에서 이 단어는 성전에 관한 하나님의 명령을 이행하는 방식을 나타내는 아람어 부사(AD)다. 단일 의미로1/1회를 설명하며, 번역 표현 차이를 여러 sense로 분리하지 않는다. 개역개정·개역한글·원전분해의 삼가, KJV의 diligently, 새번역의 빠짐없는 준수 문맥을 함께 확인했다.

Canonical Strong은 `quickly or carefully`, usage `diligently.`, source `(Aramaic) probably of Persian origin;`를 제공한다. 이 자료는 유지하며 경쟁 풀이를 삭제하거나 페르시아어 기원을 단정하지 않는다. BDB·CAL·추가 전문 연구는 비교 근거이며 canonical source를 교체하는 authority가 아니다.

Noonan(2019,44쪽)은 고대 이란어 재구형 `*drazdā-`와 신뢰·충실함 계열을 연결하고 H149를 성실하고 마음을 다한 수행의 부사로 해석한다. Weiss(2017,4–6쪽)도 비교언어학 논의에서 에스라7:23의 단어를 충실한 수행으로 풀이한다. 어원만으로 현재 의미를 결정하지 않고 해당 구절에 대한 해석·품사·명령 이행 문맥을 함께 반영했다.

`충실히`는 명령 내용에 맞는 수행과 소홀함 없는 성실한 이행을 함께 담는다. 한국어 부사 忠實히의 의미와 명령을 충실히 이행한다는 실제 용법도 국립국어원 자료에서 확인했다. 한자 忠實을 병기하여 充實과 구분했다. 사용자는 이 evidence-backed 최신 추천을 최종 채택했으며, 별도의 개인적 판단 이유를 덧붙여 추정하지 않는다.

참고 출처:

- [Noonan, Non-Semitic Loanwords in the Hebrew Bible (2019) 서지](https://www.eisenbrauns.org/books/titles/978-1-57506-774-2.html). 해당44쪽·관련291쪽은 공개 표시 원저 본문에서 확인했으며 상세 열람 위치는 외부 후속 연구에 기록했다.
- [Weiss, The Inner Revolution: Old But Not That Old (2017)](https://rootsofeurope.ku.dk/kalender/arkiv_2017/the-split-reconstructing-early-indo-european-language-and-culture/Weiss_-_The_inner_revolution__old_but_not_that_old__handout_.pdf).
- [BDB·Strong H149 항목](https://www.blueletterbible.org/lexicon/h149/kjv/wlc/0-1/).
- [국립국어원 충실히²(忠實히)](https://krdict.korean.go.kr/eng/dicSearch/SearchView?ParaWordNo=79533&nation=eng).

## 채택하지 않은 주요 대안

- `삼가`: 해당 한국어 성경 구절의 전통 번역으로는 이해할 수 있다. 그러나 현대 한국어의 겸손·정중함이 부각되어 원어의 충실한 이행을 대표하는 meaning으로 채택하지 않았다.
- `정확히(正確히)`: BDB·CAL의 풀이와 명령 내용에 맞는 수행을 잘 반영하는 유효한 대안이다. 최종 선택에서는 성실한 이행까지 포괄하는 충실히를 우선했고, 정해진 대로 수행한다는 측면은 비고에 반영했다.
- `주의 깊게`, `부지런히` 및 기존 meaning 유지: 가능한 번역이지만 각각 주의의 태도 또는 노력·활동의 측면이 부각될 수 있다. 대표 부사 하나로 압축하며 별도 sense로 추가하지 않았다.
- `빨리`: canonical Strong의 경쟁 풀이로 보존한다. 유일한 용례와 추가 연구만으로 독립 속도 의미를 확정할 근거가 부족하여 별도 meaning으로 승인하지 않았다. 완전히 반증된 풀이로 취급하지 않는다.
- `마음을 주다`, `신뢰하다`: 어원 이해를 위한 설명이다. 실제 아람어 품사는 부사이므로 동사를 meaning으로 대체하지 않았다.
- 어원 추정 관계 또는 단어 전체 hold: 구체 원천어 관계를 확정하지 않으며, 일반적인 부사 의미·문맥은 승인할 수 있으므로 관계 비생성과 잔여 불확실성 기록으로 처리했다.

## 남은 불확실성 및 재검토 조건

절대적인 최초 의미·최초 사용 시점과 의미 변화의 모든 중간 단계는 확인되지 않았다. 신뢰·충실함 계열 재구와 BDB의 굳셈·온전함 계열 비교 설명을 구분해 보존한다. 별표 재구형을 직접 발견된 고대 페르시아어 token으로 취급하지 않는다. 마음 요소의 더 깊은 비교어원 분석에도 논쟁이 남아 있다.

Nober(1958)·Rundgren(1982–1983) 원논문은 직접 확보하지 못했고 Noonan·Weiss를 통해 견해를 확인했다. HALOT 전체 원항목을 직접 검토했다고 주장하지 않는다. 해당 불확실성과 canonical Strong의 속도 풀이를 DB 비고에 새로 확장하지 않고 이 결정 기록과 외부 연구에 보존한다. 승인된 DB 비고는 위 한 문장이다.

한국어 local reference profile 및 LXX upstream provenance·license 미검증 경계는 유지한다. LXX 해당 구절은 문장 구성이 달라 H149와 특정 Greek lemma의 일대일 대응을 확정하지 않는다. 이런 자료를 canonical occurrence나 확정 관계로 승격하지 않는다.

검증된 아람어 추가 용례·원천어 자료가 의미 범위를 실질적으로 바꾸거나, source identity·본문 대응에 serious conflict가 확인되거나, 사용자가 대표 의미를 변경할 때 재검토한다. 번호 인접성·단순 번역어 차이·새 근거 없는 어원 추정만으로 자동 재검토하지 않는다.

### 적용 검증

공식 dry-run 사본 적용·실제 undo·원본 불변 검증 뒤 기존 applicator 테스트31건을 통과하고 live apply했다. History group `1792544433429479`, ID6440–6441은 H149 word update2·undone0이다. 의미 교체 뒤 비고 추가의 before/after 연쇄도 일치한다.

독립 SQL55조회·263검증에서 전체13테이블·DDL·공식 snapshot을 적용 전 byte 백업과 비교했다. 승인된 H149 의미1·비고1·이력2 및 history sequence 외 변경이 없다. Work·백업·snapshot·seed integrity ok·FK0·sidecar0이며 보호202파일과 원본 연구13파일이 불변이다.

Work SHA `38a30e02359ffa75331a3285cc6b4085118a7ca05078393d64556c77c797c1c4` → `c7f4d41c93067d16229bc56f438f43a938724654e9c8c81c321ddff924c87b01`. Seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1` 불변. 승인 원문 SHA `30d10a011b374ef145fc9e8a1e67382a2e89cf9bd1903d5941c3bd9d2701df42`, manifest SHA `cb158e7f9ddbe0c819e2f095027506e287012464f80a1f2ff8abd4e8a6dd15f7`이다. 새 manifest 경로의 LF bytes를 고정한다.

표준 semantic_progress JSON·CSV·Markdown을 공식 재생성하고30검증 및 renderer byte 대조를 통과했다. H149만 승인되어 explicit_approved421→422·unapproved13,871→13,870·hold6·anomaly113·전체14,298이며 비대상 row와 canonical relation index는 불변이다. Snapshot identity `2b5ba8d157f8aaf73b5effe1a775550770b40f588b2677c27511a7c7d6aeca99`다.

원본 연구는 보존하고 최종 적용 기록을 외부 폴더에 별도로 둔다. DB는 Git 미추적 로컬 자산이다. seed 교체·앱 배포·앱 코드·UI 변경은 없으며 UI 테스트·전체 앱 빌드는 N/A다.
