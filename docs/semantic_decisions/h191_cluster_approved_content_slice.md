# H191 클러스터 어리석음 계열 의미·비고·관계 승인 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-22 (Asia/Seoul)
- 대상: H0191·H0196·H0200
- 승인 manifest: [h191_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h191_cluster_approved_content_slice.json)
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음·신규 hold 없음
- 로컬 연구 산출물: `reshet_research_output/H0191_cluster_20261022_419adfde/`; 초기 연구 summary·전량 출현 평가·세 항목 full Review 보존
- 최신 승인 보완: 같은 연구 폴더의 `00_approved_content_followup.md`; 초기 H191 추천보다 최종 승인값을 우선한다.
- 승인 원문·적용 전 byte 백업·독립 검증: `data/backups/approved_content_batch/h191_approval_20261022/`
- 공식 적용 receipt: `data/backups/approved_content_batch/20261022T143427741982Z/result.json`

## 최종 결정

사용자는 공유하는 기본 의미의 한국어 표현을 통일한 아래 의미·비고·관계를 승인하고, DB·문서·필요 파일 반영과 단계별 안전 검증 후 커밋·작업 브랜치 push·main fast-forward 병합·main push·이번 로컬 및 원격 작업 브랜치 정리를 승인했다.

| Strong | 최종 ordered meaning | sense | 처리 |
|---|---|---:|---|
| H0191 | 어리석은 | 1 | 기존 미련한을 계열 공통 표현으로 교체 |
| H0196 | 어리석은 | 1 | 현재 meaning 유지 및 명시적 승인 |
| H0200 | 어리석음 | 1 | 기존 한 meaning 행의 동의 표현을 대표어 하나로 정리 |

최종 비고:

**H0191**

> 주로 지혜(智慧)와 훈계(訓戒)를 거부하는 어리석음을 나타내며, ‘어리석은 자’를 가리키는 쓰임이 많다. 이사야 35:8은 이들이 길을 잃지 않는다는 번역과 그 길로 다니지 못한다는 번역이 갈린다. 호세아 9:7은 예언자(豫言者)에 대한 비난(非難)으로 읽는 번역도 있어, 그 사람의 실제 성격을 이 말만으로 확정하지 않는다.

**H0196**

> 스가랴 11:15–17에서는 양 떼를 돌보지 않는 목자(牧者)의 모습이 드러나므로, 단순히 솜씨가 서툴다는 뜻으로만 제한하지 않는다.

**H0200**

> 태도나 말과 행동으로 드러나는 어리석음을 가리키며, 잠언 14:1에서는 집을 허무는 여자로 그려진다. 잠언 14:24의 첫 단어를 소유(所有)나 능력(能力)으로 읽는 견해(見解)도 있으나, 현재 확보된 근거만으로 별도 의미를 확정하기는 어렵다.

최종 관계:

| ID | semantic 관계 | category_code | relation_type | status_code | direction_code |
|---|---|---|---|---|---|
| 8027 | H0191 → H0196 | morphological | derived | asserted | w1_to_w2 |
| 8028 | H0191 ↔ H0200 | etymological | root_shared | asserted | undirected |

두 pair는 각각 `(H0191_0000,H0196_0000)`, `(H0191_0000,H0200_0000)`의 canonical lexical 순서로 저장한다. H0200↔H0193 관계 및 H0196↔H0200의 별도 직접 관계는 생성하지 않는다. 신규 hold도 없다. 기존 원어·음역·발음·언어·비대상 어휘·기존 관계·hold ledger·schema·seed·앱 코드는 유지한다.

공식 dry-run은 write7건과 meaning 유지 승인1건, undo 성공 및 원본 DB 불변을 확인했다. 기존 applicator 테스트31건 후 실제 DB에 1회 적용했다. History group `1792679669000146`, ID6671–6677은 word update5·relation create2이며 모두 active다. 독립 SQL59조회·95검증에서 전체13테이블·DDL·적용 전 byte 백업·공식 snapshot을 비교해 승인 projection·신규 history·관련 sequence 외 변화 없음, work/seed/snapshot integrity ok·FK0·sidecar 없음·seed 불변을 확인했다. 보호 입력204개 중 승인 work DB만 변경됐고 초기 연구22파일은 불변이다.

Work SHA `419adfde3371b7dcf542f460f22b4339ca6e550bbdc2532c4dabe7e28485fc2a` → `4525081ee72dd83a5d43bcbf66e52a62727fd64667687bfd6d342310c63b410f`; seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1` 불변이다. Manifest SHA `db32941c64e7606f8471b788805a5fe79627ef9f9ee734fa4ee44318a3988c5b`는 적용 사본·현재 파일·Git index의 LF bytes가 일치한다.

표준 progress JSON·CSV·Markdown 갱신과 독립22검증·공식 renderer 대조에서 세 항목만 신규 승인됐다. 승인521→524·미승인13,771→13,768·hold6·anomaly113·전체14,298이다. 적용 전 byte 백업과 당시99개 manifest로 이전 snapshot identity를 정확히 복원해 비대상14,295행·lexical index·anomaly의 exact 불변을 대조했다. 최종 snapshot identity는 `19eb33fac2454f41c173bc4fd788b452d4802f9e8346fb4fb232db498e9e4121`이다. Work DB는 Git 미추적 로컬 자산이며 seed 교체·앱 배포·전체 빌드·사용자 UX 테스트는 N/A다.

## 핵심 판단 근거

- Canonical Strong HebrewLexicon commit `21c9add13bc727d3a951361778e97e3ff7afd1ce`의 세 entry와 OSHB morphhb commit `3d15126fb1ef74867fc1434be1942e837932691f`의 전체52토큰을 검토했다. 세 node·두 edge, frontier0으로 recursive closure가 완료됐고 hub 예외는 없다.
- H191과 H196은 어리석다는 기본 형용사 의미를 공유하며 H200은 이에 대응하는 명사다. 최초 추천의 H191 미련한 유지는 기존 DB 표현을 보존하려는 판단이었고, 두 형용사 사이의 차이를 입증해 달리 옮긴 것이 아니었다. 사용자는 공유 의미의 표현 통일을 선택했다. 명사적 쓰임과 개별 문맥의 성격은 비고에 보존한다.
- H191의 26토큰과 H196의 1토큰은 각각 단일 sense로 설명된다. H191 잠7:22의 전승 차이, 사35:8의 문장 해석, 호9:7의 비난 인용 여부를 구별하며 모든 지시 인물의 실제 성격을 단어 하나로 단정하지 않는다.
- H200의 25토큰 중24개는 어리석음으로 분명히 설명된다. 잠14:24 첫 토큰은 개역의 소유 및 참고사전의 능력·탁월 해석이 남아 잠정1개로 보존했다. 같은 절의 두 번째 토큰과 혼동하지 않으며 일반 meaning을 승인하되 미해결 해석은 비고로 한정한다.
- H196의 `from H191`은 기초어→파생어 방향이다. H200의 `from the same as H191`은 공통 어근 관계로 보존하며 H191 어형에서 직접 파생됐다는 주장으로 강화하지 않는다. 이는 Strong의 분석을 관계로 채택한 것이고 쓰이지 않는 어근의 역사적 실재를 새로 입증했다는 뜻이 아니다.
- 로컬 사전 exact3행과 번역·원전분해의 전체 출현을 비교했다. 출현×5자료의 260비교 슬롯 중 시편 두 구절의 8슬롯은 수동 보충했고 Korean profile을 자동 검증 상태로 바꾸지 않았다. LXX는 명시적50절 조회의 본문 비교에만 사용했으며 provenance/license 미검증·자동 Hebrew-Greek 정렬 금지를 유지한다.
- 한국어 세 meaning은 고유어로 정리하고 필요한 비고의 실질 한자어는 병기했다. 새로운 고유명사·합성 경계·발음 체계 변경은 N/A이며 기존 expression 필드를 변경하지 않는다.

## 채택하지 않은 주요 대안

- H191 미련한 유지: 가능한 동의 표현이지만 사용자 선택에 따라 H196과 공통 표현인 어리석은으로 통일했다. 원문에 근거한 서로 다른 sense로 보지 않는다.
- H191 어리석은 자를 별도 meaning으로 추가: 명사적 쓰임은 중요하지만 형용사의 수식·서술 기능과 같은 기본 의미이므로 비고로 설명한다.
- H196 미숙한·불경건한을 별도 meaning으로 추가: 확보 LXX의 경험 부족 표현 및 Strong의 도덕적 설명을 보존하되 단일 용례에서 독립 sense를 늘릴 근거는 부족하다.
- H200 우매함(愚昧함) 병렬 유지: 같은 sense의 가능한 대안이지만 어리석음 하나로 범위를 포괄한다. 기존 값은 원래1행이므로 다의어 병합으로 기록하지 않는다.
- H200 소유·능력·탁월을 별도 meaning으로 추가하거나 H193 관계 생성: 잠14:24 첫 토큰의 실제 대안이지만 일반 의미와 확정 어원으로 승격할 독립 근거가 부족하다. 비고와 원본 evidence에 보존한다.
- 전체 hold: 일반 meaning의 근거가 충분하며 특정 구절 해석의 불확실성을 항목 전체의 판단 불가로 확대할 필요가 낮다.

## 남은 불확실성 및 재검토 조건

H191의 세 문맥·전승 쟁점과 H200 잠14:24 첫 토큰의 경쟁 해석은 해결된 것으로 선언하지 않는다. 출처가 분명한 독립 사전·어원·본문비평 근거가 별도 lexical identity 또는 H193 관계를 입증할 때 재검토한다. 단순한 번역어 차이나 유사 철자만으로 sense·관계·hold를 자동 변경하지 않는다. 연구 artifact의 초기 추천과 최종 결정이 다르면 현재 DB와 이 승인 manifest를 우선한다.
