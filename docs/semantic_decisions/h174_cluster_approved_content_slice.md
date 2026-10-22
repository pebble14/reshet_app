# H174·G250 침향 의미·비고 승인 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-22 (Asia/Seoul)
- 대상: H0174·G0250
- 승인 manifest: [h174_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h174_cluster_approved_content_slice.json)
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 관련 hold ledger: 변경 없음; 기존 6건 유지
- 로컬 연구 산출물: `reshet_research_output/H174_cluster_20261022_10508908/`; G250 전량 보충 검토는 `related_word_review/`
- 승인 원문·byte 백업·SQL 검증: `data/backups/approved_content_batch/h174_approval_20261022/`
- 공식 snapshot·result·manifest 사본: `data/backups/approved_content_batch/20261022T042605140165Z/`

## 최종 결정

사용자는 CodeX의 의미·비고·관계 유지 추천을 승인하고 DB·문서·필요 파일 반영, 단계별 안전 검증 후 커밋·push·fast-forward 병합과 이번 로컬·원격 작업 브랜치 정리까지 승인했다.

| Strong | 승인 meaning | sense 수 | 비고 |
|---|---|---:|---|
| H0174 | 침향(沈香) | 1 | Strong의 목재 설명, 나무/향료 문맥, 정확한 수종과 민24:6 LXX 대안의 한계 |
| G0250 | 침향(沈香) | 1 | 한국어 관용 번역명, 매장용 향료 문맥, Strong의 gum 설명과 수종·제형·직접 차용의 미확정성 |

Meaning replacement2·word note replacement2를 적용했다. 비고 전문은 manifest의 정확한 승인값을 따른다. 원어 spelling·음역·발음·언어는 보존했다. 침향은 해당 성경 어휘를 식별하는 관용 번역명이며 현대 식물분류상 특정 수종을 최종 동정한 선언이 아니다.

기존 관계 ID3064의 stored pair `G0250_0000 / H0174_0000`와 아래 값은 모두 그대로 유지했다.

| category_code | relation_type | status_code | direction_code |
|---|---|---|---|
| unspecified | related | inferred | unknown |

관계 생성·교체·삭제0, 신규 hold0이다. `unknown`을 `undirected`로 바꾸거나 기존 inferred를 asserted로 승격하지 않았다. H0168·G0174와 새 관계를 만들지 않았다. Schema·seed·앱 코드 및 비대상 어휘는 변경하지 않았다.

## 핵심 판단 근거

H174의 canonical Strong 정의는 aloe wood이며 민24:6은 심은 나무, 시45:9(OSHB; 한국어/KJV45:8)·잠7:17·아4:14는 향료 문맥이다. 같은 향목의 나무·목재·향료 사용을 한 대표 의미로 설명할 수 있어 기존 알로에와 침향의 두 표시를 별도 lexical sense로 유지하지 않는다.

G250의 canonical Strong gloss는 aloes (the gum)이며 TAGNT의 유일한 정본 용례 요19:39는 몰약과 섞어 매장에 가져온 향료다. 한국어 관용 번역 침향을 대표 의미로 채택하되 목재/진액/가공물의 정확한 형태를 확정하지 않는다. 사용자는 그리스어 읽기 알로에와 현대 식물명 알로에의 동일성 문제를 확인했고, 특정 수종의 완전한 동정은 아니라는 설명을 들은 뒤 추천안을 최종 채택했다. 사용자에게 그 이상의 개인적 선택 이유를 부여하지 않는다.

H1744/4·G2501/1 정본 token, HebGrkKo exact2행, 번역·분해 자료25대조와 LXX 명시4절을 검토했다. 시편 네 참고 자료의45:8/45:9 본문을 직접 비교해 해당 절만 수동 대응을 확인했으며 profile은 unverified로 유지했다. 원본 Packet·Review·state는 보존했다. 한국어 표기 정책에 따라 沈香을 확인했고, 새 발음 재구·고유명사 병기·합성 붙임표는 N/A다.

## 채택하지 않은 주요 대안

- 알로에와 침향을 두 meaning으로 유지: 한 문맥의 번역명·동정 후보 차이를 실제로 두 sense가 사용된 것으로 오해할 수 있어 채택하지 않았다. 알로에는 원어 읽기와 Strong의 영어 설명을 통해 보존한다.
- H174를 침향목만으로 대표: 나무와 목재에 적합한 대안이지만 향료 문맥3건을 포함하는 대표어로 침향을 선택했다.
- 향목 같은 일반명으로만 대체: 수종 불확실성은 줄지만 개별 어휘의 식별력이 낮아진다.
- 민24:6의 천막을 H174의 추가 meaning으로 승인: LXX의 대안 해석은 비고에 보존하되 고정 MT/OSHB의 향목 어휘 의미나 H168과의 어원 관계로 확정하지 않는다.
- H174→G250 직접 차용 또는 엄격 동의어로 확정: 비교 참조와 향료 문맥만으로 차용 경로·방향·동일 물질을 증명할 수 없어 기존 관계를 보존했다.

## 남은 불확실성 및 재검토 조건

정확한 식물 종·산지·전파 경로와 요19:39 물질의 제형은 미확정이다. 현대 Aloe 식물과 곧바로 동일시하지 않지만 그 가능성을 완전히 배제하는 botanical 최종 판정도 하지 않았다. 향목/향료의 식별 가능한 의미에는 word hold가 필요하지 않다고 결정했다.

고정 Greek XML G0250의 structured compare는 GREEK174이지만 별도 Strong 자료는 H174를 가리킨다. 이 source-reference 언어 충돌은 원자료 그대로 보존했고 자동 보정하거나 가시나무 계열로 의미 연구를 확장하지 않았다. H174의 공식 재귀 cluster는1node·frontier0·closure완료이며, G250은 기존 DB 관계 상대어로 full review를 보충했다. G250 경로의 전체 raw recursive closure 완료를 주장하지 않는다.

확보한 LXXStp 아4:14의 αλωθ와 로컬 사전의 알로에 설명 차이, 민24:6 천막 해석은 판본·표기·본문 해석의 한계로 남긴다. LXX 자료의 provenance·license 미검증과 reference-only 경계는 유지하며 자동 Hebrew–Greek alignment 근거로 사용하지 않는다.

새 원문·수종·제형 자료가 의미 범위를 실질적으로 바꾸거나 source-reference 언어 충돌을 검증된 authority로 정정할 때 재검토할 수 있다. 번역어 수, Strong 번호 인접성, 기존 표현 정비 이력만으로 이 결정을 자동 폐기하지 않는다.

## 적용 검증

공식 dry-run의 사본 적용·undo·원본 DB 불변과 기존 applicator 테스트31건을 확인한 뒤 live apply를 실행했다. History group1792643166409590, ID6582–6585는 word update4·undone0이다. 관계 이력과 생성·교체는 없다.

독립 SQL56조회·265검증으로 전체13테이블·DDL·byte 백업·공식 snapshot과 승인 projection을 대조했다. 승인 의미·비고·이력 및 history sequence 외 변경 없음, integrity ok·FK0·sidecar없음이다. 보호 입력194파일과 원본 연구19파일은 불변이다. Snapshot schema cookie1368→1369는 VACUUM INTO의 기존 계약이며 실제 DDL·적용 전 데이터는 일치한다.

Work SHA `105089085700b0f7fa1489eb4c40f61bf41c971d3aee6c42479ced378e306050` → `c7c39c98739337dfa6caec01b52d59d5c81504bc07384b802c07d7e269505359`. Seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1` 불변이다. Manifest SHA `0436056d28316e32446ea507beaf5d340eb10fa29c1a7c7868c5a0fd977a59c1`, 승인 원문 SHA `1b4b6908190a63eaf672092a7371e0c43cf27f58345a92e01b6529e32538e9ce`이며 manifest LF bytes를 보존한다.

표준 progress3종 공식 생성과21검증·CSV/Markdown renderer bytes 대조가 통과했다. H174·G250만 신규 승인됐고 비대상14,296행·anomaly·canonical lexical index는 exact 불변이다. 승인485→487·미승인13,807→13,805·hold6·anomaly113·전체14,298, snapshot identity `77a5664b849f83c33618ddd56f3b7f9727b75dcaca5717f943a4ae219eb78de5`다.

초기 dry-run의 Windows 임시 경로 권한 오류와 Flutter launcher 실행 문제는 공식 도구의 정상 권한·직접 런타임 재실행으로 해소했고 성공 로그를 보존했다. 임의 SQL live write는 사용하지 않았다. Work DB는 Git 미추적 로컬 자산이며 seed 교체·앱 배포·전체 빌드·UX 수동 테스트는 N/A다.
