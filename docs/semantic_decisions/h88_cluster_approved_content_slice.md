# H88·H178 지명·부대·신접 어휘군 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-16 (Asia/Seoul)
- 대상: H0088 (`H0088_0000`), H0178 (`H0178_0000`)
- 승인 manifest: [h88_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h88_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 신규 hold 없음·기존 6건 유지
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 로컬 연구 산출물: `C:/Users/kkiih/Documents/Workspace/FlutterWorkspace/reshet_research_output/H0088_cluster_20261016_1eca4a97`
- 승인 원문·적용 전 byte 백업·독립 검증: `data/backups/approved_content_batch/h88_approval_20261016/`
- 공식 snapshot·result·manifest 사본: `data/backups/approved_content_batch/20261015T164427883724Z/`

## 최종 결정

사용자는 Codex의 1순위 3 sense 추천안을 채택하고 DB·문서·기타 필요한 파일·Git 게시 및 문제없는 경우 작업 브랜치 정리까지 승인했다. 다음 ordered meanings를 적용했다.

| Strong | seq | 최종 meaning | 적용 방식 |
| --- | --- | --- | --- |
| H0088 | 1 | 오봇 (지) | 기존 projection 유지·meaning_approvals 승인 |
| H0178 | 1 | 신접한 자(神接한 者) | 기존 쉼표 결합 1행을 3행으로 교체 |
| H0178 | 2 | 가죽 부대 | 별도 meaning |
| H0178 | 3 | 죽은 이의 영(靈) | 별도 meaning |

두 word note를 NULL에서 다음으로 교체했다.

**H0088**

> H178의 ‘가죽 부대’에 해당하는 복수형에서 온 지명이다. 이스라엘이 광야 행군 중 진을 친 곳으로 민 21:10–11과 33:43–44에 나온다. 정확한 현대 위치는 확정하지 않는다.

**H0178**

> 욥 32:19에서는 액체를 담는 가죽 부대를 뜻한다. 신접 관련 용례에서는 죽은 이를 불러 묻는 사람과 그가 다루는 영을 구별하여 이해한다. 삼상 28:7–8과 대상 10:13의 אוב를 영 또는 술법 자체로 읽는 분석이 있으며, 사 29:4도 죽은 이의 영과 신접한 자의 목소리 사이에 해석 차이가 있다. 여기서는 술법을 별도 의미로 확정하지 않고 비고에 보존한다. Strong의 중얼거림·복화술 설명과 H1 ‘아버지’에 연결하는 어원은 실제 용례만으로 확정할 수 없다.

신규 relation ID7862는 **H0178 → H0088**, `morphological / derived / asserted`다. 저장 pair는 `word_id_1=H0088_0000`, `word_id_2=H0178_0000`, `direction_code=w2_to_w1`이며 description·relation_group_id는 NULL이다. Source는 `RESHET-EC-H88-CLUSTER-H0178-H0088`다.

> H178의 가죽 부대에 해당하는 복수형이 지명 H88로 사용됨. 지명의 본문 의미를 일반명사 가죽 부대로 대체하는 관계는 아님.

H0001–H0178 추정 어원 관계는 생성하지 않는다. H0001의 현재 승인 meaning·비고·기존 관계를 유지하며 새 hold는 없다. Expression·음역·발음·언어·schema·seed·canonical source·local reference·기존 hold ledger는 변경하지 않았다. 기존 active semantic 결정과 충돌이 없어 supersession은 없다.

## 핵심 판단 근거

- Canonical Strong 원문은 H88을 광야 지명, H178의 복수형 및 water-skins로 설명한다. OSHB 민21:10–11·33:43–44 전체4회는 진침·이동의 장소이며 한국어 참고역도 오봇으로 옮긴다. 기존 meaning을 유지하고 어원 풀이를 비고와 형성 관계에 둔다.
- H178의 전체17 canonical token(16절)을 Strong 및 확보된 로컬6종과 비교했다. 현재 `신접한 자, 가죽 부대`는 다른 뜻을 한 행에 섞은 상태이므로 분리하고, 삼상28:7–8·사29:4의 영 독법을 추가한다. 대표 독법 배정은 사람12·부대1·영4다.
- 이 배정 중9 token에는 사람/영/술법의 경쟁 독법이 있다. 사용자 승인은 모든 token의 독법을 확정한 것이 아니라3 sense와 불확실성 비고를 채택한 것이다. 신접술을 별도 의미로 늘리지 않는 최소 의미 구조를 선택했다.
- H88에 이미 음역 오보트가 있으므로 meaning에 같은 전사를 중복 병기하지 않는다. 고유명사에 한자를 만들거나 불확실한 합성 붙임표를 추가하지 않고, H178의 神接·者·靈을 의미에 병기했다.
- H178→H88은 복수형이 지명으로 어휘화된 형성 관계다. Source-reference H88→H178의 화살표를 DB semantic direction으로 복사하지 않는다. H178의 H1 어원 설명에는 apparently가 있으므로 확정 관계로 승인하지 않는다.
- 사용자는 이 evidence-backed 추천안을 최종 채택했다. 별도 개인적 선택 이유는 추정해 기록하지 않는다.

## 채택하지 않은 주요 대안

- **H88 meaning을 가죽 부대들로 변경**: 지명 본문의 의미와 어원 풀이를 혼동하므로 채택하지 않았다. 어원은 비고와 relation에 보존한다.
- **오봇·오보트 병기**: 오보트가 기존 expression에 있으며 이번 의미 식별에 독립적인 이득이 작아 추가하지 않았다.
- **H178 현재1행 또는 사람/부대의2 sense만 유지**: 다른 뜻을 혼재시키거나 영 자체의 독법을 meaning에서 가리므로3 sense안을 채택했다.
- **죽은 이를 불러 묻는 술법(術法)을 네 번째 의미로 추가**: BDB의 삼상28:7 두 회·28:8·대상10:13 분석을 지지하는 유효한 경쟁안이며 오답으로 배제하지 않았다. 영/사람으로도 읽을 수 있어 이번에는 별도 meaning을 확정하지 않고 비고에 보존한다. 이4 sense안의 대표 배정은 사람11·부대1·영1·술법4다.
- **중얼거림·복화술사·구멍 추가 또는 H1 어원 관계 생성**: Strong의 설명과 reference-only 어원 주장을 실제 성경 용례의 독립 sense·확정 파생으로 승격할 근거가 부족하다.
- **H178→H88을 inflected로 저장**: 단순 수 굴절보다 별도 지명 lexeme 형성이라는 점을 드러내도록 derived를 선택했다.
- **단어 전체 hold**: 현재 의미와 대상 식별은 가능한 범위에서 승인하고 위치·어원·문맥별 해석 차이를 비고에 남기는 안을 채택했다.

## 남은 불확실성 및 재검토 조건

H88의 정확한 현대 위치는 미확정이다. 로컬 사전의 Ain el-Weiba 동일시를 확정하지 않는다. 원천 XML의 x-pn과 DB 언어 히브리어도 같은 검증 결과로 합치지 않으며 언어 필드는 수정하지 않았다.

H178의 사람·영·술법 경계와 가죽 부대/신접 의미의 역사적 기원은 미해결이다. H1 연결과 Strong의 중얼거림·복화술 설명, 로컬 사전의 수메르·아카드·우가릿 및 구멍 주장은 확정 어원으로 채택하지 않는다. 새로운1차 언어 자료나 본문·구문 연구가 competing sense 또는 지리 식별을 실질적으로 판별할 때 사용자 판단으로 재검토한다. 단순 번역 다수결·철자 유사·자동 edge 증가·동일 사전 반복만으로 자동 재검토하지 않는다.

LXX는 명시한20절을 human-reference로 확인했다. 대상10:13의 사무엘 응답 추가, 욥32:19의 풀무 비유 및 땅에서 말함 표현은 전승·번역 차이로 보존하며 자동 Hebrew↔Greek alignment·NT Strong 연결·새 Hebrew sense를 생성하지 않는다. 로컬 자료·LXX의 reference-only 및 provenance/license 미검증 경계도 유지한다.

공식 dry-run의 사본 적용·undo·원본 불변과 live apply가 성공했다. History group `1792082669067326`, ID6085–6088는 active4행(word update3·relation create1, undone0)이다. H88 의미 유지 승인은 DB write·history를 추가하지 않는다. 독립 SQL 52조회·53검증에서 전체13테이블·DDL·byte 백업·공식 snapshot을 대조했고 승인 의미·비고·relation 및 해당 history/sequence 외 차이가 없다. Work·seed·snapshot·byte 백업 integrity ok·FK0·sidecar0이며 seed는 불변이다. 기존 applicator Flutter 테스트31건 통과.

공식 표준 progress JSON·CSV·Markdown을 갱신했다. H88·H178만 explicit_approved로 전환되어 승인284→286·미승인14,008→14,006·hold6·anomaly113이며 비대상 행과 anomaly는 불변이다. 원본 연구16개 artifact는 적용 전 snapshot으로 보존하고 현재 적용 결과는 외부 `00_applied_content.md/json`으로 구분한다. 앱/UI 코드 변경이 없어 UI 수동 테스트·전체 앱 빌드는 N/A다.
