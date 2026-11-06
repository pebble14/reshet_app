# H330 실 의미·비고 결정

- 상태 `active`
- 기록 성격은 결정 적용과 동시 작성
- 판단 근거 복원 수준은 높음
- 결정일 2026-11-06 (Asia/Seoul)
- 대상 H0330 (`H0330_0000`)
- 승인 manifest [h330_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h330_cluster_approved_content_slice.json)
- 관련 [hold ledger](../../tool/data_provenance/manifests/semantic_research_dispositions.json)
- 로컬 연구 산출물 `reshet_research_output/H0330_cluster_20261106_b04c8fff/00_cluster_summary.md` (v1), `H330_review.md`
- 로컬 승인 원문·적용 전 백업·독립 검증 `data/backups/approved_content_batch/h330_approval_20261106/`
- 공식 적용 receipt `data/backups/approved_content_batch/20261106T144145149499Z/result.json`

## 최종 결정

사용자가 연구 v1의 추천을 채택하고 작업 DB 적용, 문서 갱신, 검증 및 Git 게시·브랜치 정리를 승인했다. 기존 `실, 이불` 한 행을 아래 값으로 교체하고 비고를 추가했다.

| 순서 | 최종 meaning |
|---|---|
| 1 | 실 |

> 잠언 7:16의 ‘이집트산 실’은 침상에 깐 천의 재료로 이해할 수 있다. 번역에서는 이를 고운 베나 무늬 있는 이불로도 옮긴다. 섬유 종류와 직조 방식은 확정하기 어렵다. Strong은 꼰 실로 풀이하고 ‘묶다’로 추정한 미사용 어근을 제시한다. 이집트어 차용설도 있어 어원은 미확정이다.

관계는 비생성, word-level hold는 미설정이다. 관계 category·type·status·direction과 기존 결정 대체는 N/A다.

## 핵심 판단 근거

정본의 유일한 용례는 잠언 7:16의 남성 단수 연계형 `אֵט֥וּן`이다. 절 전반의 H4765는 침상에 까는 깔개를 가리킨다. 후반의 `אֵטוּן מִצְרָיִם`은 그 깔개를 짠 이집트산 재료로 읽을 수 있다. Strong의 꼰 실 풀이와 BDB의 `thread, yarn`을 고려하여 대표어를 `실`로 정했다. 한국어 성경의 ‘이불’과 LXX의 깔개는 문맥에서 완성된 물품을 표현한다. [Strong XML](https://github.com/openscriptures/HebrewLexicon/blob/21c9add13bc727d3a951361778e97e3ff7afd1ce/HebrewStrong.xml#L1966) · [OSHB 잠언 7:16](https://github.com/openscriptures/morphhb/blob/3d15126fb1ef74867fc1434be1942e837932691f/wlc/Prov.xml#L1948) · [BDB](https://hebrewcollege.edu/wp-content/uploads/2018/10/BDB.pdf)

H2646의 `덮개`와 `방(房)`은 서로 다른 용례를 근거로 구분했다. H0330에서는 한 용례에 재료와 완성품 해석이 겹치므로 단일 의미를 채택했다. `실`은 고유어 표기를 사용한다. [H2646 결정](h2646_approved_content_slice.md) · [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)

HebGrkKo의 H0331 파생설은 H0331의 정본 8건과 대조했다. 이 용례들은 입술·귀·창을 닫거나 막는 뜻이며, H0330으로 이어지는 형태 근거는 부족하다. LXX 잠언의 깔개 표현과 신약의 직물 어휘는 구절과 어휘를 비교하는 근거로 삼았다.

## 채택하지 않은 주요 대안

- `이불`을 별도 meaning으로 추가하거나 현행 `실, 이불`을 유지하는 안은 문맥에서 만들어진 물품을 독립 의미로 확정할 근거가 부족해 비고의 번역 설명으로 보존했다.
- `고운 베`는 유효한 번역 대안이며, 특정 섬유와 직물 자체를 뜻하는지 유일한 용례로 확정하기 어렵다. `꼰 실`은 Strong의 풀이로 비고에 남겼다.
- H0331 파생 및 이집트어·헬라어 차용 관계는 비교에 머문다. 어원과 재질의 불확실성은 단어 전체의 hold 없이 비고에 보존했다.

## 남은 불확실성 및 재검토 조건

잠 7:16의 분리 악센트를 따라 ‘무늬 직물, 이집트산 베’처럼 병렬로 읽는 안이 있다. 정본 1건을 검토해 `실`로 주 배정했으며, 완성 직물 독법은 같은 토큰의 대안이다. 정확한 섬유·직조 방식과 차용 경로는 미확정이다. 독립 용례가 완성 직물의 전문 명칭을 입증하면 의미를, 규칙적인 형태 대응과 전승 경로가 확인되면 관계를 재검토한다. [잠언 7:16의 구문·어원 논의](https://repozytorium.kul.pl/bitstreams/0f14bbea-ebda-4515-afff-8028613f7cd6/download)
