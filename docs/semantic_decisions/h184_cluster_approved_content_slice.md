# H184 표시 동사 의미·비고 승인 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-22 (Asia/Seoul)
- 대상: H0184
- 승인 manifest: [h184_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h184_cluster_approved_content_slice.json)
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음
- 로컬 연구 산출물: `reshet_research_output/H0184_cluster_20261022_41160168/`; 최신 추천은 `01_feedback_reassessment.md`
- 승인 원문·적용 전 byte 백업·독립 검증: `data/backups/approved_content_batch/h184_approval_20261022/`
- 공식 적용 receipt: `data/backups/approved_content_batch/20261022T114333948543Z/result.json`

## 최종 결정

사용자는 최초 추천의 경계를 긋다가 문맥의 대상을 어휘 의미에 포함한 것은 아닌지 재검토를 요청했다. 후속 추천인 표시하다(標示하다)와 비고를 채택하고 DB·문서·필요 파일 반영, 검증 후 커밋·작업 브랜치 push·main ff-only 병합·main push·이번 로컬 및 원격 작업 브랜치 정리를 승인했다.

| Strong | 최종 meaning | sense | 처리 |
|---|---|---:|---|
| H0184 | 표시하다(標示하다) | 1 | 기존 표시하다의 의미 내용 유지·한자 병기 |

최종 비고:

> 민수기 34:10에서는 동쪽 경계의 경로를 정해 표시하는 뜻으로 쓰인다. 같은 철자의 H0183 ‘바라다’와는 별도 어휘로 구분한다.

관계 생성·교체·삭제와 새 word hold는 없다. 관계 category/type/status/direction은 N/A다. H0183의 기존 승인과 다른 어휘·표현·음역·발음·schema·seed·앱 코드는 유지한다.

의미 교체1·비고 추가1을 공식 dry-run·undo와 기존 applicator 테스트31건 후 적용했다. History group `1792669415172952`, ID6660–6661은 H0184 word update2이며 undone0이다. 독립 SQL51조회·55검증에서 전체13테이블·DDL·byte 백업·공식 snapshot을 비교해 승인 projection·history·관련 sequence 외 변화 없음, integrity ok·FK0·sidecar없음·seed 불변을 확인했다. 보호 입력176파일 중 work DB만 변경됐다.

Work SHA `41160168d5f14ae7496e8e3327e728e8d4ba98ecf43e7f2c47bb0bbda60e4535` → `7d479eb153a6a8fb3df17edc7a52daff7960ab1523160e52e2a5752bf534a9b7`. Seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1` 불변이다. Manifest 적용 사본·물리 파일·Git index의 LF bytes SHA는 `a8e5e93c958eec6e9c03b52154c6dde256ef3857d74cf1fc10d14d669ba7d7b0`로 일치한다.

표준 progress JSON·CSV·Markdown 갱신과 독립31검증·공식 renderer 대조에서 H0184만 신규 승인됐다. 승인516→517·미승인13,776→13,775·hold6·anomaly113·전체14,298이며 비대상14,297행은 exact 불변이다. Snapshot identity는 `fc2260aa094f04dfa7aec2fc159305d20a51319989705d7365faa772981049af`다. Work DB는 Git 미추적 로컬 자산이며 seed 교체·앱 배포·UI 수동 테스트는 N/A다.

## 핵심 판단 근거

- Canonical Strong HebrewLexicon commit `21c9add13bc727d3a951361778e97e3ff7afd1ce`의 H184는 표시·구획하는 기능을 제시한다. OSHB morphhb commit `3d15126fb1ef74867fc1434be1942e837932691f`에서 유일한 출현인 민수기 34:10 전체를 확인했다. H184 자체와 별도 명사 H1366 경계의 역할을 구분한다.
- 경계를 긋다는 그 절의 타당한 번역이지만, 경계라는 대상을 H184의 필수 의미로 고정할 독립 근거는 충분하지 않다. 1/1회 설명 가능하다는 coverage와 대표 meaning의 추상화 수준은 별개다. 사용자는 이 구분을 반영한 후속 추천을 채택했다.
- 기존 표시하다를 유지하면 사전적 표시 기능을 보존하면서 특정 문맥의 대상을 일반 의미로 고정하지 않을 수 있다. 범위나 경로를 정하는 기능과 구체적인 경계 문맥은 연구 자료·비고로 보완한다. 한국어 표시하다의 모든 현대적 용법이 히브리어에서도 입증됐다는 뜻은 아니다.
- 한자는 [국립국어원 표시하다2](https://krdict.korean.go.kr/kor/dicSearch/SearchView?ParaWordNo=88636)의 標示를 사용한다. 고유명사·붙임표·발음 변경은 N/A다. 로컬 번역·BDB·LXX는 참고이며 canonical authority나 자동 관계로 승격하지 않는다.

## 채택하지 않은 주요 대안

- 경계(境界)를 긋다: 민수기 34:10의 유효한 문맥 번역으로 보존한다. 대표 meaning으로는 구문이 제공하는 대상을 지나치게 구체화하므로 후속 검토에서 우선순위를 철회했다.
- 뻗다: Strong의 설명은 원자료에 보존한다. 단 한 번의 용례에서 일반적인 뻗다를 별도 sense로 추가할 증거는 충분하지 않다.
- 측량하다: LXX 구절과 사전의 측정 풀이를 참고할 수 있으나 이를 히브리어 독립 sense나 특정 측정 방식으로 확정하지 않는다.
- H0183과의 병합·관계 생성: 같은 철자와 발음만으로 파생·공통 어근·동의 관계가 입증되지 않는다. BDB의 다른 어근 비교도 확정 관계로 올리지 않는다.

## 남은 불확실성 및 재검토 조건

출현은 한 번뿐이므로 경계 밖에서의 표시 기능이나 역사적 어원 전체를 대조할 독립 용례가 없다. 경계라는 대상이 어휘적으로 반드시 내재하지 않는다고 최종 증명한 것도 아니다. 실제 선 긋기·표지 설치·측정 방식은 특정하지 않는다. 대표 한국어 선택과 문맥 밖 의미 범위의 확신도는 중간이며, 해당 절의 경계 지정 기능은 명확하다.

새 원문·본문비평·어휘 자료가 민수기 34:10의 식별·구문이나 표시 기능의 범위를 실질적으로 바꿀 때 해당 쟁점을 재검토한다. 단순 번역 표현 차이·번호 인접성·동형 철자·웹 표제만으로 자동 병합하거나 승인 전체를 다시 열지 않는다. 기존 원본 Review와 최초 추천은 외부 연구 이력으로 보존한다.
