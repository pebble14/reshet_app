# Semantic 결정 기록

이 디렉터리는 Reshet 어휘 연구에서 사용자가 최종 승인한 의미·비고·관계와 그 판단 근거를 단어 또는 논리적 클러스터 단위로 기록한다. 전체 조사 일지를 복제하지 않고, 나중에 프로젝트 열람자·사용자·Codex가 **무엇을 왜 선택했는지** 빠르게 확인하는 것이 목적이다.

## 문서의 역할

- 승인 manifest는 정확히 적용되거나 승인된 값과 provenance를 기록한다.
- work DB는 현재 projection을 기록한다.
- Evidence Packet·Review·cluster summary는 상세 증거와 후보를 보존한다.
- 이 디렉터리의 기록은 증거에서 최종 선택으로 이어진 판단을 간결하게 설명한다.

값이 충돌하면 현재 사용자 지시, 현재 DB와 active 승인 manifest를 우선한다. 이 기록만으로 DB나 manifest를 수정해서는 안 된다. 과거 판단을 변경할 때는 기존 기록을 덮어써서 이력을 지우지 말고 새 승인 manifest와 결정 기록을 추가한 뒤 이전 기록을 `superseded` 또는 `partially_superseded`로 표시한다.

## 상태와 복원 수준

- `active`: 현재 결정이 그대로 유효하다.
- `partially_superseded`: 일부 의미나 관계가 후속 승인으로 대체되었고 나머지는 유효하다.
- `superseded`: 전체 결정이 후속 승인으로 대체되었다.
- 복원 수준 `높음`: 연구 산출물, 사용자 판단 대화, manifest와 Git 이력이 함께 남아 있다.
- 복원 수준 `중간`: 연구 산출물과 적용 기록은 있으나 당시의 대안 토론 일부가 남아 있지 않다.
- 복원 수준 `제한적`: manifest와 provenance로 최종값은 확인되지만 당시의 선택 이유는 최소한만 복원할 수 있다.

`소급 작성`은 이 문서가 결정 당시가 아니라 2026-08-28에 작성되었다는 뜻이다. 복원 수준이 낮은 항목에서는 확인되지 않은 이유를 추정해 채우지 않는다.

## 결정 색인

| 결정 단위 | 대상 | 상태 | 복원 수준 | 최초 적용일 | 기록 |
|---|---|---|---|---|---|
| P2 승인 배치 | H2020, H5005, H6306, H6772와 파생 관계 | `partially_superseded` | 제한적 | 2026-08-10 | [기록](p2_approved_content_slice.md) |
| H1672·H1674 | 걱정하다·걱정 | `active` | 중간 | 2026-08-13 | [기록](h1672_h1674_approved_content_slice.md) |
| 첫 5-Strong 배치 | H1618, H4200, H4461, H5807, H6378 | `partially_superseded` | 제한적 | 2026-08-13 | [기록](first_semantic_batch_approved_content_slice.md) |
| 두 번째 semantic 배치 | H1564, H2251, H3958, H5229; H1833 hold | `partially_superseded` | 중간 | 2026-08-14 | [기록](second_semantic_batch_approved_content_slice.md) |
| P1 historical 승인 복원 | H1653, H1655, H1656 | `partially_superseded` | 제한적 | 2026-08-14 | [기록](p1_historical_approval_approved_content_slice.md) |
| H2646 | 덮개·방 | `partially_superseded` | 중간 | 2026-08-14 | [기록](h2646_approved_content_slice.md) |
| 세 번째 semantic 배치 | H1563, H1652, H5228, H5229, H6770, H6772, H2645와 관계 | `active` | 중간 | 2026-08-14·20 | [기록](third_semantic_batch_approved_content_slice.md) |
| H1·H2·G5 | 아버지 계열과 G5 호격 | `partially_superseded` | 높음 | 2026-08-22 | [기록](h1_h2_g5_meaning_approval_approved_content_slice.md) |
| H3 클러스터 | H3, H4, H24와 합성 관계 | `active` | 높음 | 2026-08-22 | [기록](h3_cluster_approved_content_slice.md) |
| H5 인명 | 아박다·아바그타 | `active` | 높음 | 2026-08-25 | [기록](h5_name_approved_content_slice.md) |
| H6 클러스터 | 멸망·상실 계열과 아바돈 | `partially_superseded` | 높음 | 2026-08-25 | [기록](h6_cluster_approved_content_slice.md) |
| H14 클러스터 | 원함·갈망·적대 관련 14개 Strong | `partially_superseded` | 높음 | 2026-08-25 | [기록](h14_cluster_approved_content_slice.md) |
| H18 클러스터 | 구유·살찌우다·곡물 창고 | `active` | 높음 | 2026-08-27 | [기록](h18_cluster_approved_content_slice.md) |
| H19 | 칼의 번뜩임 | `active` | 높음 | 2026-08-27 | [기록](h19_cluster_approved_content_slice.md) |
| H20 | 수박 | `active` | 높음 | 2026-08-28 | [기록](h20_cluster_approved_content_slice.md) |
| H21 | 아비와 H1 파생 관계 | `active` | 높음 | 2026-08-28 | [기록](h21_cluster_approved_content_slice.md) |
| H22 | 아비엘과 H1·H410 합성 관계 | `partially_superseded` | 높음 | 2026-08-29 | [기록](h22_cluster_approved_content_slice.md) |
| H23 클러스터 | 아비아삽·아비-아사프와 에비아삽·에브야사프 | `active` | 높음 | 2026-08-30 | [기록](h23_cluster_approved_content_slice.md) |
| H25 | 기브온의 아버지와 H1·H1391 구성 관계 | `active` | 높음 | 2026-08-30 | [기록](h25_cluster_approved_content_slice.md) |
| H26 클러스터 | 아비가일·아비갈과 H1523–H1525 즐거움 계열 | `partially_superseded` | 높음 | 2026-08-31 | [기록](h26_cluster_approved_content_slice.md) |
| H27 클러스터 | 판단·송사·단·다니엘·미디안 계열 25개 승인과 H1777·H4092 hold | `partially_superseded` | 높음 | 2026-09-12 | [기록](h27_cluster_approved_content_slice.md) |
| H1777 | 심판·변호·다툼·다스림 의미와 창세기 6:3 해석 비고, hold 해제 | `active` | 높음 | 2026-09-12 | [기록](h1777_meaning_note_approved_content_slice.md) |
| 승인 meaning 표기 정책 정비 | 기존 승인 18개 Strong의 한국어 meaning 표기 | `active` | 높음 | 2026-09-12 | [기록](approved_meaning_notation_policy_correction.md) |
| H0026 분석 표기 | 아비가일·아비갈·아비-가일·아비-갈 | `active` | 높음 | 2026-09-12 | [기록](h0026_analytic_name_notation_approved_content_slice.md) |
| H0022·H1841·G1158 분석 표기 | 아비엘·아비-엘과 다니엘·다니-엘 | `active` | 높음 | 2026-09-13 | [기록](h0022_h1841_g1158_analytic_name_notation_approved_content_slice.md) |
| H28 클러스터 | 아비다·아비-다와 H0001·H3045 합성 관계 | `active` | 높음 | 2026-09-13 | [기록](h28_cluster_approved_content_slice.md) |
| H29 클러스터 | 아비야·아비-야와 H0001·H3050 합성 관계 및 G0007 음역 관계 | `active` | 높음 | 2026-09-14 | [기록](h29_cluster_approved_content_slice.md) |
| H30 클러스터 | 아비후·아비-후와 H0001·H1931 합성 관계 | `active` | 높음 | 2026-09-19 | [기록](h30_cluster_approved_content_slice.md) |
| H31 클러스터 | 아비훗·아비-후드와 H1·H1935 합성 및 G10 음역 관계 | `active` | 높음 | 2026-09-20 | [기록](h31_cluster_approved_content_slice.md) |
| H32 클러스터 | 아비하일·아비-하일과 H1·H2428 합성 관계 | `active` | 높음 | 2026-09-20 | [기록](h32_cluster_approved_content_slice.md) |
| H33 클러스터 | 아비에셀·이에셀 인명과 가문 소속형 4개, 파생·합성·가설 변이 관계 | `active` | 높음 | 2026-09-20 | [기록](h33_cluster_approved_content_slice.md) |
| H36 클러스터 | 아비둡·아비-투브와 H1·H2898 합성 관계 | `active` | 높음 | 2026-09-22 | [기록](h36_cluster_approved_content_slice.md) |
| H37 클러스터 | 아비달·아비-탈과 H1·H2919 합성 관계 | `active` | 높음 | 2026-09-22 | [기록](h37_cluster_approved_content_slice.md) |
| H38 클러스터 | 아비얌·아비-얌과 H1·H3220 합성 관계, H29·H8043 관계 비생성 | `active` | 높음 | 2026-09-23 | [기록](h38_cluster_approved_content_slice.md) |
| H39 클러스터 | 아비마엘·아비-마엘과 H1 합성 관계, H410 관계 비생성 | `active` | 높음 | 2026-09-24 | [기록](h39_cluster_approved_content_slice.md) |
| H40·H1125 클러스터 | 아비멜렉·아비-멜레크와 벤아비나답·벤-아비-나다브, 합성 관계 3건 | `active` | 높음 | 2026-09-27 | [기록](h40_cluster_approved_content_slice.md) |
| H41 클러스터 | 아비나답·아비-나다브와 H1·H5068 합성 관계, H1125 관계 보류 유지 | `active` | 높음 | 2026-09-27 | [기록](h41_cluster_approved_content_slice.md) |
| H42 클러스터 | 아비노암·아비-노암과 H1·H5278 합성 관계 | `active` | 높음 | 2026-09-28 | [기록](h42_cluster_approved_content_slice.md) |
| H45 클러스터 | 아비알본·아비-알본과 H1 합성 관계, H22 관계 비생성 | `active` | 높음 | 2026-10-03 | [기록](h45_cluster_approved_content_slice.md) |
| H46 클러스터 | 강하신 분·힘센·날개 어휘군과 세메벨 병기, 확정 3·가설 합성 2 관계 | `active` | 높음 | 2026-10-04 | [기록](h46_cluster_approved_content_slice.md) |
| H48 클러스터 | 아비람·아브람 인명 표기와 구성·단축형·개명 관계 6건 | `active` | 높음 | 2026-10-04 | [기록](h48_cluster_approved_content_slice.md) |
| H49 클러스터 | 아비삭·사게 인명과 빗나감·잘못·허물·식가욘, 확정 4·가설 1 관계 | `active` | 높음 | 2026-10-04 | [기록](h49_cluster_approved_content_slice.md) |
| H50 클러스터 | 아비수아·엘리사·밧세바 및 슈아 어휘군, 관계 18건·H7774 hold | `active` | 높음 | 2026-10-06 | [기록](h50_cluster_approved_content_slice.md) |
| H51 클러스터 | 아비술·아히살 및 담·이동·노래·소 어휘군, H7794/H8450 소·G5022 수소, 관계11건·H8284 hold | `active` | 높음 | 2026-10-06 | [기록](h51_cluster_approved_content_slice.md) |
| H52 클러스터 | 아비새·요사위야·이스위 표기와 같음·평원·예물 어휘군, 관계12건·어원 관계2개 보류 | `active` | 높음 | 2026-10-07 | [기록](h52_cluster_approved_content_slice.md) |
| H53 클러스터 | 압살롬·살렘·솔로몬과 평안·갚음·제사 어휘군, CORE31 승인·관계35건·H8003 hold | `active` | 높음 | 2026-10-07 | [기록](h53_cluster_approved_content_slice.md) |
| H54 클러스터 | 아비아달·남음·유익 어휘군, CORE19 승인·관계21건·H3491 hold | `active` | 높음 | 2026-10-12 | [기록](h54_cluster_approved_content_slice.md) |
| H55 클러스터 | 휘돌며 올라가다, 단일 용례의 의미·비고와 관계 비생성 | `active` | 높음 | 2026-10-13 | [기록](h55_cluster_approved_content_slice.md) |
| H56 클러스터 | 슬픔·애도(哀悼) 계열과 참으로·그러나·오빌, CORE5 승인·파생 관계2건·추정 관계2건 비생성 | `active` | 높음 | 2026-10-13 | [기록](h56_cluster_approved_content_slice.md) |
| H58 클러스터 | 풀밭·아벨 지명군·므홀랏 출신형·아빌레네, CORE12 승인·관계18건·본문2건 비고 보존 | `active` | 높음 | 2026-10-13 | [기록](h58_cluster_approved_content_slice.md) |
| H68 클러스터 | 돌·추·건축 어휘군, CORE25 승인·신규 관계26건·어원 관계4건 보류 | `active` | 높음 | 2026-10-13 | [기록](h68_cluster_approved_content_slice.md) |
| H73 클러스터 | 띠, 제사장·관리의 복장과 허리로 한정하지 않는 착용 범위, 관계 비생성 | `active` | 높음 | 2026-10-13 | [기록](h73_cluster_approved_content_slice.md) |
| H74 클러스터 | 아브넬·등불·농경·직조·화덕·네리야 이름군, CORE11 승인·관계8건·잠21:4 경쟁 독법 보존 | `active` | 높음 | 2026-10-15 | [기록](h74_cluster_approved_content_slice.md) |
| H76 확장 어휘군 | 물집·종기, 에베스·입산 이름군, 솟아나다·발하다와 샘, CORE6 승인·관계3건·비생성2건 | `active` | 높음 | 2026-10-15 | [기록](h76_cluster_approved_content_slice.md) |
| H79 클러스터 | 씨름하다·먼지·가루, CORE3 승인·여성명사 파생1건·H79–H80 관계 비생성 | `active` | 높음 | 2026-10-15 | [기록](h79_cluster_approved_content_slice.md) |
| H85·G11 이름군 | 아브라함·아브-라함, 의미·비고2건과 기존 관계3건 교체·H87/H48 승인 유지·어원 불확실성 보존 | `active` | 높음 | 2026-10-15 | [기록](h85_cluster_approved_content_slice.md) |
| H86 외침 어휘 | 무릎을 꿇다·불확실성 비고, 관계 비생성·신규 hold 없음 | `active` | 높음 | 2026-10-16 | [기록](h86_cluster_approved_content_slice.md) |
| H88·H178 어휘군 | 오봇 지명·신접한 자·가죽 부대·죽은 이의 영, CORE2 승인·파생1건·추정 어원 비생성 | `active` | 높음 | 2026-10-16 | [기록](h88_cluster_approved_content_slice.md) |
| H89·H90·H91 이름군 | 아게·아각·아가그 및 아각 사람·아가그 가문(家門) 사람, CORE3 승인·파생1건·비교 관계 비생성 | `active` | 높음 | 2026-10-16 | [기록](h89_cluster_approved_content_slice.md) |
| H92 묶음·결속 어휘 | 묶음·묶는 줄·무리·둥근 천장, 의미4·비고1·관계 비생성·아모스 불확실성 보존 | `active` | 높음 | 2026-10-16 | [기록](h92_cluster_approved_content_slice.md) |
| H93 호두 어휘 | 호두 의미1·집합적 호두나무 문맥 비고1, 일반 견과 대안과 수종 불확실성 보존·관계 비생성 | `active` | 높음 | 2026-10-16 | [기록](h93_cluster_approved_content_slice.md) |
| H94·H95·H103 어휘군 | 아굴·아구르, 삯, 거두어 모으다, 의미3·비고2·가설 파생1건·신규 hold 없음 | `active` | 높음 | 2026-10-16 | [기록](h94_cluster_approved_content_slice.md) |
| H96·H97 클러스터 | 방울·에글라임 및 가설 파생 관계 | `active` | 높음 | 2026-10-16 | [기록](h96_cluster_approved_content_slice.md) |
| H98·H99·H100 클러스터 | 못·늪, 슬픔, 갈대·밧줄 및 공통 어근2건(가설1 포함) | `active` | 높음 | 2026-10-16 | [기록](h98_cluster_approved_content_slice.md) |
| H101 클러스터 | 오목한 그릇·연주하다·음악·포도즙 틀 및 가트 이름군, CORE14 승인·관계13건·추정 어원2건 비생성 | `active` | 높음 | 2026-10-17 | [기록](h101_cluster_approved_content_slice.md) |
| H102 클러스터·H6211 수록 | 군사 집단·타격 계열 Strong6, 파생2, 아람어 풀 보충1 | active | 높음; Strong 표제와 보충 어휘 분리 | 2026-10-17 | [기록](h102_cluster_approved_content_slice.md) |
| H104 클러스터 | 편지 어휘2·강제 역무 G29, 의미3·비고3·공통어원 대응1·기존 비교 관계 유지 | `active` | 높음 | 2026-10-17 | [기록](h104_cluster_approved_content_slice.md) |
| H105 그릇 어휘 | 그릇 의미1·비고1, 형태·어원 불확실성 보존·관계 비생성 | `active` | 높음 | 2026-10-17 | [기록](h105_cluster_approved_content_slice.md) |
| H106 어휘군 | 주먹·휩쓸어가다·흙 덩어리 의미3 유지 승인·비고3·파생2, 욜1:17 해석 미해결 보존 | `active` | 높음 | 2026-10-17 | [기록](h106_cluster_approved_content_slice.md) |
| H108 클러스터 | 안개·불탄 나무·원인/관련 기능·재앙·정도/힘, meaning5·비고4·관계 비생성 | `active` | 높음 | 2026-10-17 | [기록](h108_cluster_approved_content_slice.md) |
| H109·H110 클러스터 | 슬프게 하다 유지 승인·앗브엘/아드베엘 병기·비고2, 붙임표 및 추정 구성 관계 비사용 | `active` | 높음 | 2026-10-18 | [기록](h109_cluster_approved_content_slice.md) |
| 헬라어 표현 정비 | 최초 6,106표현 검수와 승인 적용, G2458 Strong 악센트 일치·사용자 어형 미확인 비고, 현재 표현 보류6 | `active` | Strong 표제 선택과 역사적 인명 해석 구분 | 2026-10-11 | [기록](greek_expression_approved_content_slice.md) |
| 라틴어 표현 정비 | 최초 159단어·166표현 검수 후 유보5 정리, populus 분리로 현재 160단어·167표현, 역사적 독법 일부 미확정 | `active` | 사전 장단·교재식 독법·서로 다른 어휘 구분 | 2026-10-11 | [기록](latin_expression_approved_content_slice.md) |
| 영어·현대 외국어 표현 정비 | 영어 155단어·166표현 음역 NULL 유지, 독일어·러시아어·이탈리아어 4표현 교정·발음 보완 | `active` | 출처 확인·한글 근사·복수형 전사 구성 구분 | 2026-10-10 | [기록](modern_foreign_expression_approved_content_slice.md) |
| 기타 고대 언어 정비 | 고대 페르시아어·아카드어·우가릿어 전량 3단어의 표현·의미·비고 | `active` | 학술 읽기·재구 읽기·한정기호와 불확실성 구분, 상업 재배포 가능한 원천과 참고용 자료 분리 | 2026-10-10 | [기록](other_ancient_languages_approved_content_slice.md) |

## 열람 및 후속 판단 원칙

1. 새 제안을 만들기 전에 관련 Strong이 이 색인에 있는지 확인한다.
2. 관련 기록의 최종 결정·배제 대안·잔여 불확실성을 읽은 뒤 active manifest와 현재 DB projection을 대조한다.
3. 기존 결정을 단순히 다시 제안하지 않는다. 새 근거가 기존 판단을 실질적으로 바꿀 때만 재검토 후보로 보고한다.
4. 새 근거가 있어도 Codex가 기존 결정을 자동으로 폐기하지 않는다. 사용자가 최종 결정한다.
5. 로컬 연구 산출물 이름은 상세 근거를 찾기 위한 식별자다. 연구 산출물은 Git tracked authority가 아니며 다른 checkout에 존재하지 않을 수 있다.
