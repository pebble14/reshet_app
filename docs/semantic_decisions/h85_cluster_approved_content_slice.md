# H85·G11 이름군 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-15
- DB 반영일: 2026-10-16 (Asia/Seoul)
- 연구 CORE: H0085·G0011·H0087·H0048
- 이번 변경 대상: H0085·G0011 및 기존 관계 ID23·24·5377
- 승인 manifest: [h85_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h85_cluster_approved_content_slice.json)
- 기존 승인 authority: [H48·H87 이름군 결정](h48_cluster_approved_content_slice.md), 해당 값은 유지
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 기존 6건 유지·신규 0건
- 로컬 연구 산출물: `C:/Users/kkiih/Documents/Workspace/FlutterWorkspace/reshet_research_output/H0085_cluster_20261015_4ffa7ba1`
- 승인 원문·dry-run·독립 검증: `data/backups/approved_content_batch/h85_approval_20261015/`
- 공식 snapshot·result·manifest 사본: `data/backups/approved_content_batch/20261015T150001848447Z/`

## 최종 결정

사용자는 최신 제안을 의미의 최종 결정으로 채택하고 DB·문서 및 필요한 파일의 반영을 승인했다. H0085와 G0011은 각각 seq1의 단일 meaning으로 저장했다. H0087·H0048의 기존 승인은 재작성하거나 supersede하지 않는다.

| Strong | 최종 meaning | 조치 |
|---|---|---|
| H0085 | 아브라함·아브-라함 (인) | 기존 slash 병기를 정리, 비고 교체 |
| G0011 | 아브라함·아브-라함 (인) | 같은 원천 이름의 분석 경계를 보존, 비고 교체 |
| H0087 | 아브람·아브-람 (인) | 기존 승인 meaning·비고 유지 |
| H0048 | 아비람·아비-람 (인) | 기존 승인 meaning·비고 유지 |

승인 비고:

- **H0085**: 아브람(H0087)의 이후 이름이다(창 17:5; 대상 1:27; 느 9:7). 창 17:5는 이 이름을 ‘여러 민족의 아버지’라는 약속과 연결한다. ‘아브-라함’은 Strong이 제시한 ‘아버지’(H0001) 요소와 나머지 요소의 경계를 드러내는 분석 표기다. Strong은 후반 요소를 ‘아마 인구가 많다를 뜻하는 미사용 어근’으로 설명한다. 본문의 이름 풀이와 역사적 어원을 구분하며, ‘라함’을 하몬(H1995)의 확정된 단축형으로 보지 않는다.
- **G0011**: 히브리어 아브라함(H0085)을 옮긴 헬라어 이름이다. ‘아브라함’은 한국어 성경의 관용 표기이며, ‘아브-라함’은 헬라어 합성 분석이 아니라 원천 이름의 ‘아버지’ 요소 경계를 보존한 표기다. 헬라어 철자에 따른 교재식 음역 ‘아브라암’은 음역란에 유지한다. 행 7:16의 본문은 아브라함으로 읽지만, Strong은 ‘아마 야곱으로 읽어야 한다’고 제안한다. 이 제안을 별도 의미나 확정된 본문 교정으로 채택하지 않는다.

기존 관계는 ID와 canonical pair를 보존하여 다음 세 건만 교체했다. 방향은 저장 순서와 별도인 `direction_code`로 표현한다.

| ID | 의미 방향 | 저장 pair | 최종 분류·유형·상태·방향 |
|---|---|---|---|
| 23 | H0085 → G0011 | G0011_0000, H0085_0000 | transliteration / direct_transliteration / asserted / w2_to_w1 |
| 24 | H0001 → H0085 | H0001_0000, H0085_0000 | morphological / compound / asserted / w1_to_w2 |
| 5377 | H1995 → H0085 | H0085_0000, H1995_0000 | unspecified / related / asserted / w2_to_w1 |

ID23은 Strong G11의 명시적 Hebrew origin, ID24는 H85의 명시적 H1 ‘아버지’ 요소를 근거로 inferred→asserted로 바꾼다. ID24가 후반 미사용 어근의 뜻이나 H1995 결합까지 확정하지는 않는다. ID5377은 기존 morphological/compound를 본문 이름 풀이의 관련 관계로 교체한다. H1995→H85는 이름 풀이에 쓰인 어휘에서 설명되는 이름으로 향하며 역사적 파생 방향을 뜻하지 않는다. 관계의 정확한 note·source와 교체 전 값은 manifest에 보존한다.

기존 승인 관계 ID25·26·5378·5379·7480·7715는 전부 유지했다. 신규 관계·삭제·supersession·word hold 변경은 없다. Expression·음역·발음·언어·schema·seed·canonical source와 참고자료 파일도 보존한다.

## 핵심 판단 근거

- Canonical Strong와 OSHB/TAGNT의 CORE4 전체 320토큰을 검토했다. H85는 175토큰/159절, G11은 73토큰/69절, H87은 61토큰/50절, H48은 11토큰/9절이다. 이름이 가리키는 인물과 본문 기능을 대조했으며 각 표제어는 하나의 lexical sense로 설명된다. 인명에 붙는 용례별 역할을 별도 meaning으로 늘리지 않는다.
- 창17:5·대상1:27·느9:7은 아브람과 아브라함의 이름 관계를 뒷받침한다. 창17:5의 H1995는 약속과 이름을 연결하는 본문 설명의 직접 증거다. 이 연결을 아브라함의 역사적 어원 전체를 증명하는 자료로 확대하지 않는다.
- Strong H85는 H1에서 축약된 ‘아버지’ 요소를 명시하지만 후반 어근 설명에는 추정이 붙는다. 따라서 `아브-라함`은 확인된 첫 요소와 나머지 이름 부분의 경계만 표시한다. `라함`을 독립된 확정 어근 또는 H1995의 단축형으로 승인하지 않는다.
- Strong G11은 히브리어 H85의 음역임을 명시한다. G11의 meaning에는 관용 이름 `아브라함`과 원천 이름의 분석 표기 `아브-라함`을 가운데점으로 병기하고, 헬라어 철자에 따른 `아브라암`은 기존 expression의 음역란에 보존한다. 서로 다른 언어의 표기와 형태 분석을 구분하는 현행 정책에 따른다.
- 행7:16의 지시·서술 문제 1건은 해석상 불확실성이다. Canonical G11 token은 아브라함이며 Strong의 야곱 제안은 확정 교정이나 별도 어휘 의미로 처리하지 않는다. CORE에서 lexical counterexample와 미분류 용례는 각각 0건이다.
- H87·H48의 기존 결정은 이번 전량 용례 검토와 충돌하지 않는다. 이미 승인된 의미·비고·관계는 그대로 두고 새 승인 operation을 만들지 않았다.

## 채택하지 않은 주요 대안

- **H85·G11에 `많은 자들의 아버지` 또는 `여러 민족의 아버지`를 별도 meaning으로 추가**: 본문 이름 풀이와 어원 설명은 비고로 보존한다. 실제 인명 용례를 일반명사의 별도 sense로 바꾸지 않는다.
- **G11 meaning을 `아브라암`으로만 교체하거나 분석 표기를 제거**: 헬라어 음역은 expression에 이미 보존되어 있다. Meaning은 한국어 관용 이름과 확인된 원천 이름의 경계를 함께 보여 준다.
- **H1995를 H85의 확정된 compound 구성요소로 승인**: 창17:5의 직접 연결은 확인되지만 역사적 형태 파생을 확정할 근거는 부족하다. 기존 관계를 삭제하는 대신 본문 이름 풀이를 명시하는 related 관계로 고쳤다.
- **G11의 행7:16에 `야곱`을 별도 의미로 추가하거나 본문을 교정**: Strong의 추정과 canonical 본문을 구분하여 비고에 남긴다. 이번 데이터 결정은 본문 교정 승인이 아니다.
- **H87·H48 및 hub 주변 전체를 새 batch로 재승인**: 기존 승인에 변화가 없고 H1·H7311의 다른 어휘군을 전량 연구한 것이 아니므로 이번 적용 범위에 넣지 않았다.

## 남은 불확실성 및 재검토 조건

H85 후반부의 역사적 어원, H1995와의 구체적인 형태 관계, 행7:16의 서술 문제는 미확정이다. 새 비교언어·문헌·본문 근거가 실제 어원 분석이나 인물 지시를 바꾸거나 사용자가 새 결정을 내리면 재검토한다. 동일한 사전 설명의 반복만으로 기존 결정을 다시 열지 않는다. 현재 불확실성은 비고와 관계 분류에 한정하여 보존할 수 있어 신규 word hold를 두지 않는다.

연구 범위는 CORE4, CONTEXT H0001·H7311·H1995, HUB-EXCLUDED62로 제한했다. 공식 batch 원본은 visited4·frontier39·resume0·`max_nodes_reached`이며 discovery/research_complete는 false다. H1·H7311의 허브 경계와 이 frontier를 유지하며 전역 closure를 선언하지 않는다. 원본 Packet·Review·machine state/queue와 연구 전 snapshot은 보존한다. 적용 후 상태는 별도 `00_applied_content.md/json`에서 확인한다.

로컬 6개 자료와 LXX는 참고용이며 upstream provenance·license 및 global reference profile의 미검증 경계를 유지한다. LXX 217개 명시적 조회 중 216개가 연결됐고 관련 본문은 히브리어 unique verse215개 중214개다. 렘33:26은 미연결로 남기며 인접 두 절 후보를 대상 본문으로 사용하지 않았다. 창32:10→로컬32:9, 신29:12→29:13, 시47:10→47:9의 개별 대조와 시105:6의 합절 참조는 해당 연구 자료에 기록한다. 로컬 오탈자는 새로운 인명 표기의 근거로 사용하지 않는다.

공식 dry-run에서 7건의 사본 적용·실제 undo와 원본 불변을 확인했고 live apply가 성공했다. 독립 SQL75조회·242검증으로 13개 테이블·DDL·byte 백업·공식 snapshot을 비교했다. 승인 meaning2·비고2·기존 관계3과 history7·해당 history sequence 외 차이가 없다. 교체 pair는 각각 승인된 단일 관계만 남으며 중복·이전 관계 잔존이 없다. History group은 `1792076403128673`, active ID6076–6082이며 work·seed·snapshot·byte 백업은 integrity ok·FK0·sidecar0이다. Seed SHA는 불변이다.

공식 progress JSON·CSV·Markdown을 함께 갱신하고27항목을 검증했다. H85·G11만 explicit_approved로 바뀌어 승인281→283·hold6·미승인14,011→14,009·anomaly113이며, H87·H48과 비대상 행은 불변이다. 기존 applicator Flutter 테스트31건이 통과했다. 앱/UI 코드 변경이 없어 사용자 UI 테스트와 전체 앱 빌드는 N/A다.
