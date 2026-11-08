# H0390 악갓·아카드 뜻·비고 결정

- 상태는 `active`다.
- 기록 성격은 결정 적용과 동시 작성이다. 판단 근거 복원 수준은 높음이다.
- 결정일은 2026-11-08이다. 대상은 H0390 `אַכַּד`다.
- 연구 원자료는 로컬 `reshet_research_output/H0390_cluster_20261108_27d2b34f/00_cluster_summary.md`에 있다. SHA-256은 `61df5f9cf3dcda8943cb1974534fc934fc0943026a22f2b30c9e65f4438fbb93`다.
- [승인 manifest](../../tool/data_provenance/manifests/h390_cluster_approved_content_slice.json) · [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)

## 최종 결정

뜻 seq 1을 `악갓 (지)`에서 **`악갓·아카드 (지)`**로 교체했다. 두 표기는 같은 도시를 가리키므로 한 뜻으로 병기한다. 관계 비생성, 신규 hold 없음으로 결정했다.

**승인 비고**

> 창세기 10:10에서 니므롯 왕국의 초기 중심지로 열거된 시날 땅의 도시다. 일반적으로 사르곤 왕조의 수도였던 아카드와 같은 도시로 보며, 정확한 유적 위치는 미확정이다. 개역개정·개역한글·새번역은 ‘악갓’, 천주교 성경은 ‘아카드’, 공동번역은 ‘아깟’으로 적는다. Strong의 ‘요새’ 풀이는 ‘강하게 하다’라는 뜻의 미사용 어근을 가정한 것이며, 이름의 어원은 미확정이다.

## 핵심 판단 근거

- 창 10:10의 유일한 OSHB 토큰은 시날 땅에서 니므롯 왕국의 초기 중심지를 열거하는 구절의 도시명이다. 전체 1토큰을 검토했고 지명에 1건을 배정했다. 미검토·미해결·반례는 각각 0건이다. [OSHB 창세기](https://github.com/openscriptures/morphhb/blob/3d15126fb1ef74867fc1434be1942e837932691f/wlc/Gen.xml#L3591-L3601)
- 사용자는 교재식 근사 `악카드`의 표기 일관성을 인정하면서 국내에서 널리 알려진 역사 지명 `아카드`를 뜻에 택했다. 개역개정·개역한글·새번역의 `악갓`과 천주교 성경의 `아카드`를 병기하고, 공동번역의 `아깟`은 판본 확인을 위해 비고에 적었다. [천주교 성경](https://bible.cbck.or.kr/Knb/Gn/10) · [공동번역](https://bible.cbck.or.kr/Ncb/Gn/10)
- 양방향 탐색은 CORE 1, 관계 증거 0, frontier 0으로 끝났다. LXX 절의 `Αρχαδ`는 지명 전승 대조에 쓰였다. Strong의 ‘요새’는 미사용 어근을 가정한 설명이라 비고에 출처를 밝히고, 뜻은 본문에 나타나는 도시 이름으로 두었다. [Strong 원문](https://github.com/openscriptures/HebrewLexicon/blob/21c9add13bc727d3a951361778e97e3ff7afd1ce/HebrewStrong.xml#L2327-L2332) · [독일성서공회 LXX](https://www.die-bibel.de/bibel/LXX/GEN.10)

## 채택하지 않은 주요 대안

- `악갓·악카드·아카드 (지)`의 세 표기 병기는 국내 관용명을 우선한 사용자 결정에 따라 두 표기로 줄였다. 교재식 근사 설명도 비고에서 덜었다.
- `아카드(Agade)`의 괄호 표기는 대응 음역으로 읽힐 수 있어 덜었다. `Agade`는 쐐기문자 `a-ga-de₃`에 근거한 학술 명칭이며, 도시와 지역을 구분하는 데 쓰이기도 한다. [수메르어 전자사전](https://oracc.museum.upenn.edu/epsd2/o0043186) · [Foster의 아카드 항목](https://doi.org/10.1002/9781444338386.wbeah01005)

## 남은 불확실성 및 재검토 조건

사르곤 왕조의 수도와의 식별은 통상적 견해다. 정확한 유적 위치와 이름의 궁극 어원은 미확정이다. 출토 맥락이 확인된 지명 명문이나 이름의 형성·전승을 설명하는 독립 자료가 확보되면 해당 설명을 재검토할 수 있다. [유적 위치 연구](https://kokushikan.repo.nii.ac.jp/record/15919/files/0285_4406_044_03.pdf)

## 적용 검증

공식 사본 적용·되돌리기와 기존 적용기 테스트 31개를 통과했다. 이력 그룹 `1794149175408410`의 2행과 적용 전 백업·공식 snapshot·전체 13개 테이블·DDL을 독립 대조했다. 무결성은 `ok`, FK 위반과 sidecar는 0건이다. Work SHA-256은 `f94459c7057aa53ac8f92fde9cc5c0697f5c4cce401bbef41717a9f407484365`이고 seed 해시는 적용 전후 일치했다.

표준 진행 현황에서 H0390은 `explicit_approved`로 바뀌었다. 전체 승인은 876→877, 미승인은 13,416→13,415이며 hold 6건과 anomaly 113건은 동일하다. 비대상 14,297행이 일치했다. Snapshot ID는 `5520922072e293629c14657e2c4a8f9ddecff5dddaf7908183f9e995512772b3`다. 검증 기록은 로컬 `data/backups/approved_content_batch/h390_approval_20261108/`에, 공식 적용 receipt는 `data/backups/approved_content_batch/20261108T144612055231Z/result.json`에 있다.
