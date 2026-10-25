# H213 재촉·서두름과 좁음 의미 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-25 (Asia/Seoul)
- 대상: H0213 / H0213_0000
- 승인 manifest: [h213_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h213_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음·신규 hold 없음
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 로컬 연구 산출물: `reshet_research_output/H0213_cluster_20261025_c87e45ee/`; 전체 요약, H213 Packet·Full Review·관계 evidence, canonical 10토큰의 판단, `01_lexicon_etymology_addendum.md`
- 승인 원문·적용 전 byte 백업·독립 검증: `data/backups/approved_content_batch/h213_approval_20261025/`
- 공식 적용 receipt: `data/backups/approved_content_batch/20261025T005547618824Z/result.json`

## 최종 결정

사용자는 최초 연구에 이어 사전·어원 보충 설명과 추천안을 채택하고, DB·문서·필요 metadata 반영, commit·작업 branch push·main ff-only 병합과 push·로컬/원격 작업 branch 정리까지 승인했다. 아래 값은 공식 applicator 적용과 독립 DB 검증을 완료한 상태다.

| Strong | 최종 ordered meaning | sense 수 | 처리 |
|---|---|---:|---|
| H0213 אוּץ | 1. `재촉하다, 서두르다` / 2. `좁다` | 2 | 기존 첫째 meaning 유지·둘째 meaning 추가, word note 추가 |

첫째 meaning 안의 쉼표는 재촉과 서두름의 밀접한 범위를 묶는다. 칼/히필이나 분사 번역을 이유로 별도 meaning을 추가하지 않는다. 원어 품사는 동사 v이며 한국어 ‘좁다’의 문법 분류로 원어를 재분류하지 않는다. Meaning은 고유어이므로 한자 병기는 N/A다.

**최종 비고**

> 타인을 몰아붙이거나 재촉하는 뜻과 스스로 서두르는 뜻으로 쓰인다. 사 22:4에서는 위로하려고 애쓰거나 몰아붙이는 문맥이다. מִן과 결합하면 서둘러 떠나다·물러나다로 풀이되며, 렘 17:16은 이 구문으로 설명되기도 한다. 이 구절에는 뒤따르는 말의 모음 읽기를 달리하여 재앙을 재촉하지 않았다고 옮기는 해석도 있다. ‘물러나다’는 별도 의미로 분리하지 않고 이 구문과 문장 해석의 차이로 보존한다.

신규·교체·삭제 relation은 0개이며 category/type/status/direction은 N/A다. 기존 관계와 hold ledger를 그대로 두며 H0213에 새 hold를 만들지 않는다. 원어 expression·음역·발음·언어·비대상 어휘·schema·seed·앱 코드는 변경하지 않았다.

적용 범위는 meaning replacement1·word note replacement1이다. 공식 dry-run·undo·원본 불변과 기존 applicator 테스트31개를 통과한 뒤 실제 적용을1회 수행했다. 독립 검증 56건·SQL 51조회·13테이블의 byte 백업/공식 snapshot 대조에서 승인 projection·history2·history sequence 외 변화가 없었다. History group `1792889748937287`, ID `6863·6864`, undone0이며 integrity ok·FK0·sidecar 없음이다. 보호 입력170개와 원본 연구11파일은 불변이다.

표준 progress JSON·CSV·Markdown 및 독립20검증에서 H0213만 신규 승인됐고 비대상14,297행·anomaly·lexical index는 exact 불변이다. 승인596→597·미승인13,696→13,695·hold6·anomaly113·전체14,298이다. Work DB는 Git 미추적 로컬 자산이며 seed 교체·앱 배포·UI 테스트는 N/A다.

## 핵심 판단 근거

- Canonical Strong은 압박·서두름·좁음·물러남의 범위를 제시하고 기본 어근으로 분류한다. 현행 양방향 lexical index에서 직접 참조0·정상 단일-node closure·frontier0이므로 임의로 인접 Strong을 관계 대상으로 편입하지 않았다.
- OSHB 전체10토큰을 분석했다. 재촉·서두름 계열9회와 수17:15의 비좁은 거주 공간1회를 구분한다. 렘17:16의 문장 해석 ambiguity1은 첫째 의미에 포함하면서 비고에 남겼다.
- 두 meaning은 번역 표현만으로 만든 구분이 아니다. [BDB](https://www.sefaria.org/BDB%2C_%D7%90%D7%95%D6%BC%D7%A5)와 [Gesenius 재수록](https://www.studylight.org/lexicons/rus/hebrew/213.html)도 타인을 몰아붙이거나 재촉함, 스스로 서두름, 비좁음을 구별한다. 재촉과 서두름은 하나의 meaning에 묶되 공간 상태는 별도 meaning으로 보존했다.
- Gesenius·Ben-Yehuda가 인정하는 אוץ + מִן의 ‘서둘러 떠나다·물러나다’를 비고에 명시한다. 렘17:16의 단순한 번역 차이로만 축소하지 않으며 [NET 주석](https://classic.net.bible.org/verse.php?book=Jer&chapter=17&verse=16)이 설명하는 목자/재앙 읽기의 차이도 보존한다.
- [Klein 어원사전](https://www.sefaria.org/Klein_Dictionary%2C_%D7%90%D7%95%D7%A5)의 아랍어 관련 가능성은 유보를 유지한다. 압박·재촉·좁음의 개념적 관계를 역사적으로 입증된 의미 발달 순서나 확정 파생 관계로 바꾸지 않는다.
- 한국어 로컬 사전 exact1행과 성경 참고자료5종의 모든10절을 대조했다. LXX는 명시적10절 중8절의 human-reference 문장 비교에 한정하며 자동 정렬·Greek lemma/관계 추론에 사용하지 않았다.
- 사용자는 용례 중심 판단인지 추가 확인을 요청했고, 위 사전·어원 설명과 비고 보완안을 최종 채택했다. 사용자가 말하지 않은 개인적 이유를 덧붙이지 않는다.

## 채택하지 않은 주요 대안

- 기존 ‘재촉하다, 서두르다’ 한 meaning만 유지: 수17:15의 공간 상태를 설명하지 못하므로 채택하지 않았다.
- ‘누르다’ 또는 ‘몰아붙이다’ 하나로 모든 용례를 통합: 압박의 개념적 연관은 설명할 수 있지만 스스로 서두름과 비좁은 공간을 자연스럽게 대표하지 못한다. 몰아붙임은 첫째 meaning의 범위를 설명하는 비고에 보존한다.
- ‘조급하다·힘쓰다’를 별도 meaning으로 추가: 분사와 특정 문맥의 번역을 과분리하지 않고 첫째 의미와 비고에서 설명한다.
- ‘물러나다’를 단독 셋째 meaning으로 추가: 사전 근거가 있는 가능한 대안이지만 מִן 결합 구문과 렘17:16의 해석 차이를 비고에 명시하는 방식을 채택했다. 오답으로 기각한 것은 아니다.
- 현대 히브리어의 가속 의미 추가: Klein의 NH 표지를 성경 어휘 의미로 자동 확장하지 않는다.
- 어원 relation 또는 word 전체 hold: 확정된 Strong 연결은 없으며 핵심 두 의미를 승인할 근거는 충분하다. 비교어원의 불확실성은 비고·연구 자료로 보존한다.

## 남은 불확실성 및 재검토 조건

확정된 선행 어근·차용 경로와 최초 의미 또는 의미 발달의 시간 순서는 제시하지 않는다. Klein의 아랍어 비교는 가능성이고 Jastrow의 물리적 밀착 용법은 후대 자료다. HALOT·DCH 전문 항목은 직접 확인하지 못했으므로 그 사전들의 일치를 주장하지 않는다.

렘17:16의 목자/재앙 모음 읽기와 정확한 문장 해석은 미확정이다. 새로운 critical apparatus·직접 역본·사전 연구가 독립된 의미 구분을 정당화할 때 재검토한다. Canonical 표기·Strong 부착을 자동 교정하거나 다른 독법을 현재 DB 원문으로 바꾸지 않는다.

HebGrkKo의 창9:15 표기는 canonical 창19:15와 어긋나므로 오기 가능성을 기록했다. 한국어 자료의 전체 versification profile 및 LXXStp의 upstream provenance·license는 미검증이다. 현재10절의 matched 결과로 자료 전체를 검증했다고 하지 않는다. 원본 Packet·Review·연구 summary는 덮어쓰지 않았다.

번역 표현의 차이, 동일 사전의 재수록 사이트 증가, 일반적인 압박 이미지 또는 후대 용법만으로 의미·관계·hold를 자동 변경하지 않는다.
