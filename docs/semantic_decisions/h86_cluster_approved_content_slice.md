# H86 외침 어휘 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-16 (Asia/Seoul)
- 대상: H0086 (`H0086_0000`)
- 승인 manifest: [h86_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h86_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), H86 신규 hold 없음·기존 6건 유지
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 로컬 연구 산출물: `C:/Users/kkiih/Documents/Workspace/FlutterWorkspace/reshet_research_output/H86_cluster_20261016_55db8b35`
- 승인 원문·byte 백업·검증: `data/backups/approved_content_batch/h86_approval_20261016/`
- 공식 snapshot·result·manifest 사본: `data/backups/approved_content_batch/20261015T155253183782Z/`

## 최종 결정

사용자는 Codex의 추천안을 최종 채택하고 DB·문서 및 필요한 파일 반영을 승인했다. H86의 meaning을 seq1 `무릎을 꿇다` 하나로 교체하고 다음 비고를 추가했다. 이는 Strong의 전통적 대표 풀이를 채택한 결정이며 정확한 어의·어원은 미확정이다.

> 창세기 41:43에서 요셉 앞에서 외친 말이다. ‘무릎을 꿇어라’는 Strong·KJV 등이 따른 전통적 풀이이며, 개역개정·개역한글은 ‘엎드리라’, 새번역은 ‘물러나거라’로 옮긴다. 어원과 정확한 뜻은 불확실하며, 이집트어 기원설과 히브리어의 ‘무릎 꿇다’ 어근에 연결하는 해석 등이 있다. 이 뜻은 대표 풀이로 사용하되 확정된 어원이나 동사 형태를 뜻하지 않는다.

현재 H86 관계 0건을 유지하고 신규 관계를 생성하지 않는다. 따라서 semantic direction 및 category/type/status/direction code는 N/A다. 새 hold를 만들지 않고 기존 hold ledger도 수정하지 않는다. 현재 expression `אַבְרֵךְ`, 한글 음역 `아브레크`, 발음 및 관련 metadata는 유지한다. 기존 active semantic 결정이 없어 supersession은 없다.

## 핵심 판단 근거

- Canonical Strong entry는 `kneel`, `bow the knee`를 제시하며 이집트어 기원에는 `probably`를 붙인다. 대표 meaning은 이 기존 풀이를 보존한다.
- OSHB 전체 출현은 창세기 41:43 한 건이다. 요셉 앞에서 외친 말이라는 문맥을 주변 41:39–45와 함께 확인하고, 로컬 참고자료 6종의 본문·각주·난외 및 LXX 명시 조회를 전량 검토했다. 동일한 한 용례의 번역 차이를 복수 lexical sense로 늘리지 않는다.
- 현재 row의 `엎드리다`는 개역 번역 표현으로 비고에 보존한다. Meaning은 대표 풀이 하나로 정리하고, 경쟁 번역·어원·형태의 한계는 비고에 명시한다.
- 이집트어 원천은 특정되지 않았고 히브리어 어근과의 연결도 해석이 갈린다. Canonical lexical graph에서 관련 edge가 없으므로 추정 어원·합성·LXX 번역 관계를 새로 승인하지 않는다.
- 사용자는 이러한 불확실성을 비고로 보존하는 추천안을 채택했으므로 신규 hold는 두지 않는다. 어의가 확정되었다고 선언한 것은 아니다.

## 채택하지 않은 주요 대안

- **기존 `무릎 꿇다, 엎드리다` 그대로 유지**: 같은 용례의 풀이를 대표 meaning과 번역 표현으로 구분하는 안을 채택했다. `엎드리다`는 오역으로 배제한 것이 아니라 비고에 보존했다.
- **`물러나거라`, `길을 비켜라`, `주의하라`를 새 meaning으로 추가**: 새번역 등에서 경쟁 가치가 있는 해석이지만 별도 용례로 확인된 sense가 아니다. 새번역의 표현을 비고에 보존한다.
- **KJV 난외의 `Tender father`를 meaning·합성 관계로 승인**: 역사적 대안은 연구 자료에 보존하지만 확정 형태 분석이나 독립 sense의 근거가 부족하다.
- **H86 전체 hold**: 확정 어의만 승인하는 기준에서는 가능한 대안이다. 이번에는 Strong의 대표 풀이를 사용하면서 실제 한계를 비고로 드러내는 안을 최종 채택했다.
- **BRK 계열·특정 이집트어·LXX 어휘와 신규 relation 생성**: 특정 어휘 identity·파생 방향·단어 alignment를 확정할 근거가 없어 생성하지 않는다.

## 남은 불확실성 및 재검토 조건

유일 용례의 정확한 뜻과 역사적 어원은 미해결이다. Strong의 품사 v, OSHB HD(부사), 원전분해의 히필 부정사 절대, NET의 사역 명령형 해석을 서로 같은 분석으로 합치지 않는다. NABRE·BDB의 어의 불확실성과 LXX의 명시적 무릎 꿇기 표현 부재도 연구 자료에 보존했다. 의미의 대표 풀이를 선택했지만 이 차이들은 해소하지 않았다.

원천 언어의 해당 형태·의미를 입증하는 독립 1차 문헌이나 경쟁 가설을 판별하는 충분한 언어학적 논증이 확보되면 사용자 판단으로 재검토할 수 있다. 단순 번역 다수결·철자 유사·자동 edge 증가·동일 사전 설명 반복만으로 결정을 자동 변경하지 않는다. 로컬 자료와 LXX의 reference-only 및 upstream provenance/license 미검증 경계도 유지한다.

공식 dry-run은 승인 2건의 사본 적용·undo와 원본 불변을 확인했고 live apply가 성공했다. 독립 SQL 55조회·66검증에서 전체 13개 테이블·DDL·snapshot·byte 백업을 대조하여 승인 meaning·비고, history 2행 및 history sequence 외 차이가 없음을 확인했다. History group은 `1792079574370818`, active ID6083–6084다. Work·seed·snapshot·byte 백업 integrity ok·FK0·sidecar0이며 seed는 불변이다. 기존 applicator 테스트31건이 통과했다.

공식 progress JSON·CSV·Markdown을 갱신했고 H86만 explicit_approved로 전환했다. 승인283→284·hold6·미승인14,009→14,008·anomaly113이며 비대상 행과 anomaly는 불변이다. 연구 원본은 적용 전 snapshot으로 보존하고, 적용 결과는 외부 `00_applied_content.md/json`으로 구분한다. 앱/UI 코드 변경이 없어 사용자 UI 테스트와 전체 앱 빌드는 N/A다.
