# H323 태수 관직명 연결군 의미·비고·관계 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-11-01 (Asia/Seoul)
- 대상: H0323·H0324
- 승인 manifest: [h323_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h323_cluster_approved_content_slice.json)
- 관련 hold ledger: [현행 ledger](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음
- 로컬 연구 산출물: reshet_research_output/H323_cluster_20261101_2ddb474a/00_cluster_summary.md 및 CORE별 Full Review
- 승인·백업·독립 검증: data/backups/approved_content_batch/h323_approval_20261101/
- 공식 receipt: data/backups/approved_content_batch/20261101T095307100991Z/result.json

## 최종 결정

사용자는 태수 선택과 충분한 비고 설명을 요청한 뒤 DB·문서·필요 파일 반영과 검증, 커밋·작업 branch push·main ff-only 병합·push 및 이번 branch 로컬/원격 정리를 승인했다. 직전 비고안 두 개를 최종 적용했다.

H323·H324 각각 seq1의 총독, 태수를 **태수(太守)**로 교체했다. 원래도 각 한 meaning 행이었으며 sense 수는 각각1이다.

### 적용 비고 전문

**H0323_0000**

> 왕을 대신해 지방을 다스리는 페르시아계 관직명인 사트라프를 가리킨다. 태수는 이 관직의 한국어 대응어이며, 한국어 성경에서는 문맥과 번역본에 따라 총독·대신·관원 등으로 옮긴다. ‘나라를 지키는 자’라는 고대 이란계 어원 풀이는 관직명의 배경 설명이다. 아람어 H324와 같은 관직명의 언어별 대응형이지만 직접 차용 방향은 확정하지 않는다.

**H0324_0000**

> 히브리어 H323과 같은 페르시아계 관직명의 아람어 대응형으로, 왕을 대신해 지방을 다스리는 관원을 가리킨다. 다니엘에서는 총독·고관·방백 등으로 옮기며, 느부갓네살과 다리오 통치 문맥에 쓰인다. 문맥마다 구체적인 관할 규모와 서열이 같다고 단정하지 않는다. Strong의 prince는 여기서 지방 통치 관원을 가리키며 왕자라는 의미로 해석하지 않는다. ‘나라를 지키는 자’라는 고대 이란계 어원 풀이는 관직명의 배경 설명이다.

신규 관계 ID8285: H0323_0000 ↔ H0324_0000, etymological / root_shared / asserted / undirected. description·relation_group_id NULL. 다음 비고와 원자료 source를 manifest·DB에 함께 저장했다.

> 같은 페르시아계 관직명(사트라프)의 히브리어·아람어 대응형이다. Strong H324의 corresponding to H323과 두 언어의 표제·문맥이 대응을 뒷받침한다. root_shared는 공통 어휘 기원을 나타내며 생산적인 히브리어 어근이나 두 언어 사이의 직접 차용·파생 방향을 확정하지 않는다.

source: `Open Scriptures HebrewLexicon, HebrewStrong.xml, H323 source/meaning; H324 source; commit 21c9add13bc727d3a951361778e97e3ff7afd1ce`

신규 hold 없음, 기존 ledger 불변. 기존 relation 교체·삭제 없음. 원문·음역·발음·언어·schema·seed·앱 구현은 유지했다. supersession 없음.

## 핵심 판단 근거

H323은 히브리어, H324는 같은 사트라프 관직명의 아람어 대응이다. Strong의 Persian derivation 및 corresponding to 설명과 정본13용례(4+9) 전체가 지방 통치 관직 의미를 뒷받침한다. 미검토·sense 모호·의미 배정 미해결·실제 반례0이다. HebGrkKo2행, 다섯 reference65건(자동41·수동24), LXX 명시적15절을 검토했다. 한국어 자료 profile·LXX provenance/license의 미검증 경계를 유지한다.

사용자는 총독과 태수의 비교 설명을 들은 뒤 태수를 선택했다. 태수는 특정 관직명 사트라프의 한국어 대응을 드러내는 선택이다. 총독이 의미상 틀리거나 태수만 원뜻을 포괄한다는 결론은 아니다. 국립국어원 온용어의 [사트라프 항목](https://kli.korean.go.kr/term/trgtWord/indexTrgtWord.do?trgtWordNo=2240538)에서 태수(太守) 대응을 확인했다. 동일 절의 peḥā 계열과 원어 관직명 차이를 드러내는 이점은 보조 근거이며 배타적인 서열을 확정하지 않는다.

‘나라를 지키는 자’는 고대 이란계 어원 배경으로 비고에 보존했다. [Schmitt의 관련 설명](https://www.iranicaonline.org/articles/achaemenid-dynasty/achaemenid-dynasty-ii-the-empire/) 일부와 사전 해당 항목을 확인했으며 전문 전체를 열람한 것은 아니다. 무방향 root_shared는 [H104/H107](h104_cluster_approved_content_slice.md)·[H143/H144](h143_cluster_approved_content_slice.md)의 공통 어휘 기원 대응 관례를 따른다. 직접 차용 방향은 확정하지 않는다.

보통명사 관직명이므로 고유명사 병기·발음 근사·분석적 붙임표는 N/A다. 현행 한국어 표기 정책의 의미·비고 구별과 한자 병기를 적용했다.

## 채택하지 않은 주요 대안

- 총독(總督): 여전히 유효한 대안이다. 사용자는 특정 관직명의 대응을 드러내는 태수를 선택했으며 총독 등 실제 번역어는 비고에 보존했다.
- 총독·태수 병기 또는 대신·고관·방백 별도 sense: 하나의 관직명 의미를 번역 표현별로 늘리지 않았다.
- 왕자·중위·일반적인 수호자 의미 추가: 영어 usage나 어원을 현재 문맥과 분리한 뜻이므로 채택하지 않았다.
- 방향 있는 derived·borrowed_from: 직접 전승 경로를 입증하지 못해 무방향 대응을 택했다.
- word hold: 일반 의미·identity는 충분하며 남은 문제를 비고와 연구 한계로 분리했다.

## 남은 불확실성 및 재검토 조건

직접 차용 경로, 문맥별 관할 규모·서열, 역사적 발음은 미확정이다. OSHB 단6:4 singular morphology tag와 복수 표면형의 차이를 보존했다. 확보 LXX의 120/127명·에8:9 달 이름·관직 목록 및 서사 차이와 저본·recension 문제도 남아 있다. 새로운 원문·어원·비문·본문비평 자료가 일반 의미나 대응을 실질적으로 바꾸면 재검토한다. 단순 번역 차이·표기 취향·동일 자료 재집계만으로 자동 변경하지 않는다.

### 적용 검증

공식 dry-run·실제 undo·원본 SHA 불변, 적용기 테스트31개 통과 뒤 live apply1회. 전체13테이블·DDL 독립 대조에서 승인 meaning2·비고2·신규관계1·history5행 및 해당 sequence 외 변경 없음. Expression·기존 relation·기존 history·비대상 불변, integrity ok·FK0·sidecar0·seed 불변이다. Snapshot도 integrity ok·FK0이다. History group1793526788520437, ID7514–7518, undone 없음.

Work SHA 2ddb474aa9814e10ffc8d5b00610bfe4a228cbe69fe95dc2407b4a59da6fc3ce → d66371088c9a7db92275d3db0e5536eddc9c9764f5095df827e2cd990e2a5f25. Seed SHA a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1 불변. 기존 입력191개 hash 불변이다.

표준 progress JSON·CSV·Markdown 생성 완료. H323·H324의 승인·meaning·비고 exact 검증, 승인826→828·미승인13466→13464·hold6·anomaly113 유지. 앱 UI·UX·schema·seed 배포 변경이 없어 수동 UI 테스트와 전체 빌드는 N/A다.
