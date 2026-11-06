# H332 연결 어휘군 의미·비고·관계 결정

- 상태 `active`
- 기록 성격은 결정 적용과 동시 작성
- 판단 근거 복원 수준은 높음
- 결정일 2026-11-07 (Asia/Seoul)
- 대상 H0332·H0333·H0334
- 승인 manifest [h332_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h332_cluster_approved_content_slice.json)
- 로컬 연구 산출물 `reshet_research_output/H0332_cluster_20261107_c62a5c05/00_cluster_summary.md` 및 Strong별 Review. 아래 H332 비고는 후속 검토를 반영한 최종 문구다.

## 최종 결정

사용자는 후속 검토를 반영한 연결군의 의미·비고·관계와 적용을 승인했다.

| Strong | 의미 순서 1 | 조치 |
|---|---|---|
| H0332 | 닫다 | 기존 의미 승인 |
| H0333 | 아델·아테르 (인) | 교체 |
| H0334 | 왼손잡이인 | 교체 |

**H332 비고**

> 시 69:15(히브리어 69:16)에서 화자는 웅덩이가 입을 닫아 자신을 가두지 않게 해 달라고 간구한다. BDB는 이 어근의 풀이에 ‘묶다’도 제시한다. 이 동사의 성경 용례에서 직접 확인되는 뜻은 ‘닫다’다.

**H333 비고**

> 아델은 한국어 성경 관용명이고 아테르는 אָטֵר의 교재식 한글 근사다. 히스기야와 연결된 귀환 가문과 성전 문지기 가문, 언약에 인친 백성의 지도자 명단에 나오는 이름이다. Strong은 ‘몸에 손상을 입은’, BDB는 ‘묶는 사람?’이라는 어원 풀이를 제시한다.

**H334 비고**

> 두 용례(삿 3:15, 20:16)에서 ‘오른손 쓰임이 제한된’으로 풀이되는 표현에 쓰인다. 에훗은 왼손으로 칼을 뽑는다(삿 3:21). 칠십인역은 두 곳을 ‘양손을 능숙하게 쓰는’으로 옮긴다. 오른손의 상태와 왼손 사용의 경위는 본문에서 확정하기 어렵다.

| 관계 ID | 의미 방향 | 저장 pair | category / type / status / direction |
|---|---|---|---|
| 8286 | H0332 → H0333 | H0332_0000 / H0333_0000 | `morphological / derived / hypothesized / w1_to_w2` |
| 8287 | H0332 → H0334 | H0332_0000 / H0334_0000 | `morphological / derived / asserted / w1_to_w2` |

H0333과 H0334의 직접 관계는 비생성, 세 어휘의 hold는 미설정이다.

## 핵심 판단 근거

H0332의 시편 용례에서 웅덩이가 입을 닫는다. BDB와 Klein은 어근에 ‘묶다’를 제시하며, Klein의 성경 칼 용례와 HALOT의 시편 풀이는 ‘닫다’다. H0333의 ‘묶는 사람?’은 이름의 어원설이어서 동사의 별도 의미를 입증할 독립 근거로 세지 않았다. H0334의 오른손 표현도 실제 결박을 확정하지 않는다. [BDB](https://github.com/openscriptures/HebrewLexicon/blob/21c9add13bc727d3a951361778e97e3ff7afd1ce/BrownDriverBriggs.xml#L1782-L1792) · [Klein](https://man-child.com/wp-content/uploads/2020/05/a-comprehensive-etymological-dictionary-of-the-hebrew-language-ernest-klein-1987-OCR.pdf) · [HALOT](https://yausha.com.br/wp-content/uploads/2024/02/The-Hebrew-and-Aramaic-lexicon-of-the-Old-Testament-study-edition-volume-1.pdf)

H0333은 세 한국어 판본의 관용명과 원문 교재식 근사를 한 의미로 병기했다. H0334의 ‘왼손잡이인’은 사사기의 두 용례와 에훗이 왼손을 쓰는 문맥에 근거한다. Strong은 두 파생을 명시한다. H0333은 이름의 어원 풀이가 갈려 가설로, H0334는 동일 어근과 형용사의 뜻을 함께 고려해 확정으로 기록했다. [Strong 원문](https://github.com/openscriptures/HebrewLexicon/blob/21c9add13bc727d3a951361778e97e3ff7afd1ce/HebrewStrong.xml#L1978-L1995)

## 채택하지 않은 주요 대안

- H0332 ‘묶다’의 독립 의미 추가는 고대 히브리어 동사 용례의 근거가 부족해 어근 풀이를 비고에 담았다.
- H0333 인명의 어원 풀이와 인물·가문별 의미 분리는 채택하지 않았다. 관용명과 근사는 같은 이름의 표기다.
- H0334 ‘양손을 능숙하게 쓰는’은 칠십인역의 경쟁 풀이로 비고에 담았다. [NETS 사사기](https://ccat.sas.upenn.edu/nets/edition/07-judges-nets.pdf)

## 남은 불확실성 및 재검토 조건

H0332와 동일한 동사가 무엇을 묶는 데 쓰인 고대 히브리어 자료가 확인되면 의미를 재검토한다. H0333의 명명 이유와 명단 간 인물·가문의 동일성은 불확실하다. H0334의 파생 관계와 별개로 양손 숙련, 오른손의 상태, 훈련 여부는 해석 문제로 남는다.

## 적용 검증

공식 dry-run·undo와 적용기 테스트 31개 통과 후 live apply 1회. 독립 대조에서 승인 대상 값, 관계 2건, history 7행(ID 7533–7539, group `1794007374208822`), DDL과 비대상 행, seed SHA를 확인했다. 작업 DB integrity `ok`, FK 위반·sidecar 0건이다. 작업 DB SHA-256은 `c62a5c056b906b4537f1ec71f2cd66961d540f0ed7158e3413cccb9a649533e6`에서 `bf6d0c232261e75c3be381b2eb2b6a04d9092ebf14cb43a4c1626dcea3f49fd1`로 바뀌었다. 승인·백업은 `data/backups/approved_content_batch/h332_approval_20261107/`, 공식 receipt는 `data/backups/approved_content_batch/20261106T232251465994Z/result.json`에 보존했다.
