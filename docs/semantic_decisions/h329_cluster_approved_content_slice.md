# H329 가시나무·아닷 지명 의미 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-11-01 (Asia/Seoul)
- 대상: H0329 (`H0329_0000`)
- 승인 manifest: [h329_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h329_cluster_approved_content_slice.json)
- 관련 hold ledger: [현행 ledger](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음
- 로컬 연구 산출물: reshet_research_output/H0329_cluster_20261101_a2d865cb/00_cluster_summary.md (r1), H329_review.md, 00_manual_evidence.json, 00_occurrence_assessment.json
- 승인 원문·백업·독립 검증: data/backups/approved_content_batch/h329_approval_20261101/
- 공식 receipt: data/backups/approved_content_batch/20261101T132959743953Z/result.json

## 최종 결정

사용자는 직전 r1 추천안의 DB·문서·필요 파일 반영과 검증, 커밋·작업 branch push·main ff-only 병합·push·이번 작업 branch의 로컬·원격 정리를 승인했다.

|seq|최종 meaning|
|---|---|
|1|가시나무|
|2|아닷·아타드 (지)|

기존 한 행 `가시나무, 아닷`을 위 두 행으로 교체하고 NULL 비고를 다음 전문으로 교체했다.

> 가시가 많은 식물을 가리키며 정확한 종은 미확정이다. Strong은 특히 갈매나무류(buckthorn)로 풀이하지만, Astragalus속의 가시 관목류를 제안한 전문 연구도 있다. 삿 9:14–15에서는 왕으로 추대되는 나무로 의인화되며, 시 58:9(히브리어 절 번호 58:10)는 보통 땔감 문맥으로 이해하지만 구문과 본문 해석에 이견이 있다. 창 50:10–11의 아닷은 야곱의 장례 행렬이 머문 타작마당과 관련된 지명이며 정확한 위치는 확정하지 않는다. ‘타작마당’은 גֹּרֶן(H1637)의 뜻이다. 아닷은 한국어 성경 관용명이고 아타드는 אָטָד의 교재식 읽기를 한글로 근사한 표기다. Strong의 ‘찌르다 또는 단단히 고정하다’라는 미사용 어근 연결은 추정이다.

관계 생성·교체·삭제0, word-level hold 없음. 관계 category/type/status/direction은 N/A다. H67과 같은 장소 문맥 및 LXX 대응을 word-level synonym·variant·어원 관계로 만들지 않는다. 기존 결정을 대체하지 않아 supersession 없음. 원문·음역·발음·언어·schema·seed·앱 구현은 보존했다.

## 핵심 판단 근거

Canonical Strong entry와 OSHB6/6토큰·5절, 로컬 사전 exact row1개, 다섯 본문 자료의30개 occurrence-source 대조 및 LXX 관련5절을 검토했다. 자동26개와 시편 수동4개를 구별하며 LXX 번호 확인용2절은 occurrence에 합산하지 않는다.

사사기3회·시편1회는 가시 식물, 창세기2회는 타작마당과 관련된 장소명이다. 실제 사용 차이에 따라 두 meaning으로 구별했다. 왕·폭군은 의인화와 우화의 지시 대상, 불은 문맥의 별도 요소, 타작마당은 H1637의 뜻이므로 별도 meaning으로 추가하지 않는다.

아닷은 관용명, 아타드는 원어의 교재식 읽기를 한글로 근사한 이름이다. 같은 지명 표기 병기는 한 sense다. 원문 내부 합성 경계가 없어 붙임표를 추가하지 않는다. 현행 한국어 표기 정책과 사용자 기준에 따라 제1·2·3·5항을 적용하고 제4항을 제외하되 된소리로 기계 변환하지 않는다. 고유어·음역·분류에는 한자를 만들지 않는다.

[H7740 결정](h52_cluster_approved_content_slice.md)의 보통명사·지명 구별, [H67 결정](h58_cluster_approved_content_slice.md)의 이름과 명명 설명 구별을 대조했다. [H93 결정](h93_cluster_approved_content_slice.md)은 전문 근거로 수종을 구체화했지만 이번 자료는 특정 종에 수렴하지 않는다. 같은 판단 원칙을 적용하여 포괄 번역명을 유지했다.

Strong·BDB의 전통 식별과 Vainstub의 Astragalus속 제안을 구별한다. 새 제안을 학계 합의로 승격하지 않는다. [BDB H329](https://www.blueletterbible.org/lexicon/h329/wlc/wlc/0-1/), [Vainstub 논문](https://janes.scholasticahq.com/api/v1/articles/32974-the-biblical-_-a-ad_-a-new-proposal-for-its-identification.pdf).

## 채택하지 않은 주요 대안

- 가시나무·지명을 한 meaning에 나열: 실제 용법과 식별 기능의 차이가 불명확해진다.
- 가시덤불: 실제 번역 대안이나 집합·엉킴을 강조할 수 있어 대표어는 현행 가시나무를 유지했다. 오역으로 기각하지 않는다.
- 갈매나무·찔레나무·들장미 등 특정 종: 경쟁 식별을 판별할 근거가 부족해 비고에 수종 불확실성을 남겼다.
- 아닷 또는 아타드만 표기: 이번 고유명사 기본 병기 원칙에 따라 두 층위를 보존했다.
- 불·폭군·타작마당·찌르다 등을 추가 meaning으로 생성: 문맥·다른 단어·추정 어원을 독립 뜻으로 승격하지 않는다.
- 신규 관계 또는 단어 전체 hold: 직접 lexical edge가 없고 일반 의미와 지명은 식별되므로 불확실성을 비고로 한정한다.

## 남은 불확실성 및 재검토 조건

전체6·검토6·미검토0, 주 배정은 식물4·지명2, 두 sense 사이 ambiguous0·의미 배정 미해결0·확인된 반례0이다. 시편1회의 전체 구문 해석 미확정은 별도 중복 태그이며 모든 본문 문제가 해결됐다는 뜻이 아니다. 창50:10의 고정 OSHB morph=HTd 불완전 표지도 보존한다.

정확한 종·미사용 어근·지명 위치·명명 배경, 시편의 구문·본문 해석은 미확정이다. 새 일차 언어·식물·본문비평·지리 근거가 이를 실질적으로 판별할 때 재검토한다. 같은 번역 목록·추정 어원 반복으로 자동 변경하거나 hold하지 않는다. LXX upstream provenance·license 및 local unverified profile 경계는 유지한다.

공식 dry-run·undo·원본 SHA 불변 및 적용기31개 테스트 통과 후 live apply1회. 의미 replacement1·비고 replacement1·history2행(group 1793539802658310)이며 전체13테이블·DDL 독립 대조에서 승인 대상 및 기대 history/sequence 외 불변이다. Integrity ok·FK0·sidecar0·seed 불변. Work SHA after `b04c8fff2dc9350c3e69c161195ff497ef812771bee48697a6bc56ebf176290e`. 표준 progress 승인832→833·미승인13460→13459, hold6·anomaly113 및 비대상14297행 불변이다. UI·build·schema migration·seed 배포는 N/A다.
