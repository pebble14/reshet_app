# H89·H90·H91 인명·가문 소속형 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-16 (Asia/Seoul)
- 대상: H0089 (`H0089_0000`), H0090 (`H0090_0000`), H0091 (`H0091_0000`)
- 승인 manifest: [h89_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h89_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 새 hold 없음·기존 6건 유지
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 로컬 연구 산출물: `C:/Users/kkiih/Documents/Workspace/FlutterWorkspace/reshet_research_output/H89_cluster_20261016_5751bea2`
- 승인 원문·적용 전 byte 백업·검증: `data/backups/approved_content_batch/h89_approval_20261016/`
- 공식 snapshot·result·manifest 사본: `data/backups/approved_content_batch/20261016T014727086038Z/`

## 현재 H91 후속 결정 — 2026-10-29

H91 meaning은 `아각·아가그 가문(家門) 사람`으로 표기 정리했다. 기존 비고·관계·혈통 관련 제한은 유지한다. H89·H90은 변경하지 않는다. [H251·H91 후속 결정](h251_cluster_approved_content_slice.md)이 H91 meaning에 한하여 기존 batch 승인을 대체한다. 아래 적용 기록은 2026-10-16의 값이다.

## 2026-10-16 결정

사용자는 H91의 가문 풀이와 기반 인명 병기를 포함한 최신 추천안을 채택하고 DB·문서·필요한 파일·Git 게시와 이상 없는 경우 이번 작업 브랜치 정리까지 승인했다. 다음 세 meaning은 각각 seq1, sense1이다.

| Strong | 최종 meaning | 적용 방식 |
| --- | --- | --- |
| H0089 | 아게 (인) | 현재 meaning 유지·meaning_approvals 승인 |
| H0090 | 아각·아가그 (인) | 관용명과 원문 기반 표기 병기 |
| H0091 | 아각 사람·아가그 가문(家門) 사람 | 관용 표현과 전통적 소속·계통 풀이 병기 |

세 word note를 NULL에서 다음으로 교체했다.

**H0089**

> 다윗의 용사 삼마의 아버지로 나온다(삼하 23:11). 이름의 어원은 불확실하다.

**H0090**

> 아말렉 왕의 이름으로 나온다. Strong은 아말렉 왕들의 칭호로 설명하지만, 민 24:7과 삼상 15장의 아각이 동일 인물인지, 왕들이 공유한 칭호인지는 본문만으로 확정하기 어렵다. Strong의 ‘불꽃’ 풀이는 어원이 불확실한 이름에 대한 설명이며 별도 일반명사 의미로 두지 않는다. ‘아각’은 한국어 성경 관용 표기이고, ‘아가그’는 원문 철자를 드러내는 표기다.

**H0091**

> 에스더서에서 하만에게 붙는 소속·계통 명칭이다. Strong은 아각·아가그(H90)에서 나온 출신·소속형 또는 부칭형으로 설명한다. ‘가문 사람’은 전통적인 후손·소속자 풀이를 반영한 표현이다. 사무엘이 죽인 특정 아각에게 이어지는 실제 혈통이나 어느 동명이인을 가리키는지는 확정하지 않으며, 문학적 호칭으로 보는 해석도 있다.

신규 relation ID7863은 **H0090 → H0091**, `morphological / derived / asserted`이다. 저장 pair는 `word_id_1=H0090_0000`, `word_id_2=H0091_0000`, `direction_code=w1_to_w2`이며 description·relation_group_id는 NULL이다. Source는 `RESHET-EC-H89-CLUSTER-H0090-H0091`이다.

> 아각·아가그(H90)에서 형성된 소속·계통형. 어휘 파생을 나타내며 하만의 구체적 역사적 혈통을 확정하지 않는다.

H0089–H0090의 상호 compare는 DB 관계로 만들지 않는다. 세 Strong 모두 새 hold는 없고 기존 hold6건은 유지한다. Expression·음역·발음·언어·schema·seed·canonical source·local reference는 변경하지 않았다. 기존 active semantic 승인과 충돌하지 않으므로 supersession은 없다.

## 핵심 판단 근거

- 정상 cluster closure는 H89·H90·H91의3개, frontier0이다. Canonical OSHB 전체14 token/12절과 확보된 local reference6종, 명시적 LXX12절을 전량 비교했다. H89 1회는 삼마의 아버지 인명, H90 8회는 왕명·인명, H91 5회는 하만에게 붙는 소속·계통형이다. 인물의 역사적 동일성과 lexical sense 수를 구분하여 각각 한 의미로 둔다.
- H89는 현재 관용명과 expression이 아게로 일치하므로 의미를 유지한다. 참고사전의 도망자 풀이는 canonical Strong이 확정하지 않은 이름 어원이고 일반명사 용례도 없어 별도 meaning으로 넣지 않는다.
- H90은 성경 관용명 아각을 보존하면서 원문 אֲגַג/אֲגָג의 자음 형태를 드러내는 아가그를 병기한다. 같은 이름의 두 표기이며 특정 시대의 실제 발음 복원이나 두 sense라는 뜻이 아니다. Strong의 불꽃 풀이와 왕들의 칭호 설명은 비고에서 출처의 설명으로 보존한다.
- H91의 canonical Strong은 H90에서 나온 patrial or patronymic이며 후손 또는 소속자로 설명한다. 기반 인명의 어휘 연결과 하만의 구체적 역사적 혈통은 별개다. [H33·H373 결정](h33_cluster_approved_content_slice.md), 특히 어느 예테르인지 확정하지 않은 채 가문 풀이를 채택한 [H3505 결정](h54_cluster_approved_content_slice.md)을 적용하여 가문 표현 자체를 특정인의 입증된 직계 혈통으로 한정하지 않는다.
- H91은 성경의 아각 사람이라는 식별 경로를 보존하고 아가그 가문(家門) 사람이라는 전통적 풀이를 함께 두었다. 아가그는 기반 이름 H90의 표기이며 H91 전체 어형의 음역 아가기와 구분한다. 두 완전한 표현을 가운데점으로 묶고 가문의 한자 家門을 병기했다.
- Strong의 source-reference H91→H90과 semantic formation H90→H91을 구분한다. 승인 관계는 이름에서 소속형을 형성한 어휘 관계이며 하만의 족보를 입증하는 관계가 아니다. H89/H90의 uncertain derivation 및 compare를 확정 어원 관계로 승격하지 않았다.
- 사용자는 이 근거와 잔여 불확실성을 포함한 최신 추천을 최종 채택했다. 사용자가 말하지 않은 개인적 이유를 추정하지 않는다.

## 채택하지 않은 주요 대안

- **H89 도망자 추가**: 이름에 대한 참고자료 어원 풀이를 일반명사 의미로 승격할 근거가 없어 채택하지 않았다. 해당 참고 row의 삼하33:11은 실제 canonical 삼하23:11과 불일치하며 연구 자료에 오류로 기록했다.
- **H90 아각 (인)만 유지**: 전체 용례를 설명하는 유효한 대안이다. 이번에는 관용명·원문 기반 이름 대응을 함께 드러내는 병기를 선택했다.
- **H90 불꽃 추가 또는 왕들의 칭호만 저장**: 실제 이름 사용을 어원 풀이로 대체하거나 인명 식별을 약화하므로 채택하지 않는다. 출처의 설명은 비고에 보존했다.
- **H91 아각 사람만 유지**: 의미적으로 가능한 대안이며 오답이 아니다. 사용자는 기존 가문 소속형 결정과 기반 이름 병기를 함께 반영하는 최신안을 승인했다.
- **H91 아각 자손(子孫)만 저장**: 실제 혈통으로 범위를 좁힐 수 있어 별도 sense로 채택하지 않았다. Strong의 후손·소속자 풀이와 한계는 비고에 남긴다.
- **H91 아가그 가문 사람만 저장**: 성경 관용 표현으로 접근하는 식별 경로를 줄이므로 아각 사람도 함께 남겼다.
- **아각·아가기 가문 사람**: 기반 이름 아가그와 파생된 소속형 전체 음역 아가기를 혼동할 수 있어 채택하지 않는다.
- **H89–H90 확정 파생·동일어·공통 어근 관계**: 상호 compare는 이런 assertion의 근거가 아니므로 관계를 만들지 않는다.
- **단어 전체 hold**: 이름·소속형의 의미는 승인 가능한 범위에서 정리하고 역사적 대상·어원·전승 차이는 비고에 남긴다.

## 남은 불확실성 및 재검토 조건

H89/H90의 이름 어원, H90이 왕들 사이에 공유된 칭호인지 및 민24:7과 삼상15장의 인물 동일성은 미확정이다. H91은 사전상 H90과 연결되지만 사무엘이 죽인 아각 또는 동명이인에게 이어지는 실제 혈통이 입증된 것은 아니다. 문학적 호칭이나 다른 소속 해석도 논의되므로 가문 풀이의 근거 강도는 실제 가문 문맥이 있는 H3505 등과 구분한다.

참고 검토에서는 [BDB의 H91 항목](https://biblehub.com/hebrew/91.htm), [ISBE의 house of Agag 풀이](https://classic.net.bible.org/dictionary.php?word=Agagite), [Encyclopedia of the Bible의 문학적 호칭 해석](https://www.biblegateway.com/resources/encyclopedia-of-the-bible/Agagite)을 비교했다. 이 참고자료를 canonical semantic authority로 승격하지 않는다. Canonical Strong은 [고정 원문](https://raw.githubusercontent.com/openscriptures/HebrewLexicon/21c9add13bc727d3a951361778e97e3ff7afd1ce/HebrewStrong.xml)을 따른다.

로컬 LXX에는 삼하23:11의 다른 이름 형태, 민24:7의 γωγ, 에스더의 다른 소속명·생략이 있다. 판본·upstream provenance·license 미검증인 human-reference의 경계를 유지하며 자동 Hebrew↔Greek alignment·새 Strong 추론·canonical count 변경에 사용하지 않는다. 세 source의 x-pn과 현재 DB 언어 히브리어도 같은 검증 결과로 합치지 않는다.

검증된 비평판·새 언어학 자료·계통 증거가 이름 식별이나 형성 관계를 실질적으로 바꿀 때 사용자 판단으로 재검토한다. 단순 음역 차이·번역 다수결·같은 사전 반복·자동 graph edge 증가·progress 갱신만으로 재검토하거나 과거 승인값을 자동 변경하지 않는다.

공식 dry-run의 사본 적용·undo·원본 불변과 live apply가 성공했다. History group `1792115248248599`의 ID6089–6094는 active6행(word update5·relation create1), undone0이다. H89의 의미 유지 승인은 DB write/history를 추가하지 않는다. 독립 SQL47조회·48검증으로 전체13테이블·DDL·byte 백업·공식 snapshot을 비교했으며 승인2 meaning·3 note·1 relation 및 history/해당 sequence 외 차이가 없다. Work·seed·snapshot·byte 백업 integrity ok·FK0·sidecar0, seed 불변이며 기존 applicator 테스트31건이 통과했다.

공식 표준 progress JSON·CSV·Markdown을 함께 갱신했다. H89·H90·H91만 explicit_approved로 전환되어 승인286→289·미승인14,006→14,003·hold6·anomaly113이며 비대상 row와 anomaly는 불변이다. 원본 연구17개 파일은 적용 전 snapshot으로 보존하고 현재 적용값은 별도 외부 `00_applied_content.md/json`에 기록한다. 앱/UI 코드 변경이 없어 UI 수동 테스트·전체 앱 빌드는 N/A다.
