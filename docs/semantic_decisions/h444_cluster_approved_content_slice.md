# H444 도덕적 타락 의미 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-11-13
- 대상: H0444
- 승인 manifest: [h444_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h444_cluster_approved_content_slice.json)
- 로컬 연구 산출물: `reshet_research_output/H0444_cluster_20261113_df8d473e/`, 추천 revision H0444-R1-2026-11-13

## 최종 결정

사용자는 추천 보고에 대해 “내용 승인, DB·문서·Git 실행 승인”으로 최종 채택과 실행을 승인했다.

- Ordered meaning: `타락하다(墮落하다)` 1개.
- Word note:

> 성경의 세 용례는 모두 니팔형으로, 사람이 도덕적으로 부패하거나 더러워진 상태를 나타낸다. 시편 14:3과 53:3(히브리어 절 번호 53:4)은 선을 행하지 않는 사람들의 상태를, 욥기 15:16은 악을 물 마시듯 행하는 사람을 묘사한다. BDB는 우유가 시어지는 아랍어 표현을 비교하지만, 성경 히브리어에서 음식이 시어지거나 썩는 별도 용례가 확인된 것은 아니다.

- 신규 relation 없음. H444–G889와 H444–G169는 번역 비교로 보존하고 DB 관계로 생성하지 않는다.
- Word-level hold 없음. 기존 원문·발음·음역·언어·schema·seed는 유지한다.

## 핵심 판단 근거

정본 OSHB의 욥15:16·시14:3·시53:4(한국어53:3) 3토큰을 전량 검토했다. 모두 니팔형이며 사람의 도덕적 부패·더러워진 상태를 나타낸다. Strong의 도덕적 부패 풀이와 BDB의 해당 entry, 확보한 한국어·영어 번역 및 형태 자료가 이를 지지한다. 기존 타락하다가 전체 의미를 설명하므로 유지하면서 정책에 따라 한자와 -하다를 병기했다. 시53편의 절 번호 차이는 네 한국어 자료에서 별도로 수동 확인했다.

LXX 시편의 표현과 롬3:12 G889, 욥기의 G169를 비교했으나 개별 번역 대응을 어원·완전 동의 관계로 확대하지 않았다. 사용자가 이 추천의 근거와 처리 방식을 채택했다.

## 채택하지 않은 주요 대안

- `부패하다(腐敗하다)`: 세 문맥을 설명하는 유효한 대안이다. 기존 meaning으로 충분하므로 교체하거나 독립 sense를 추가하지 않고 비고에 의미를 보존했다.
- `더러워지다`·`썩다`: 문맥 번역과 비유로 유효하나 신체·위생·음식 부패의 별도 성경 용례를 확정할 근거가 없어 별도 meaning으로 추가하지 않았다.
- Strong의 muddle과 BDB의 아랍어 우유 비교를 별도 히브리어 sense·확정 어원 관계로 저장: 실제 성경 용법과 비교어원의 층위를 혼합하므로 채택하지 않았다.

## 남은 불확실성 및 재검토 조건

3/3 용례를 한 sense에 배정했으며 미검토·의미 배정 미해결·확인된 반례는0이다. 이는 최초 어원과 물리적 의미의 역사가 완전히 밝혀졌다는 뜻은 아니다. LXX 참고자료의 upstream provenance·license와 일부 번역 자료의 versification profile은 unverified로 유지한다. LXX 시13:3의 긴 추가를 히브리어 H444의 추가 출현으로 세지 않는다.

새로운 성경 히브리어 용례나 본문·Strong 배정 근거가 현재 의미를 설명하지 못하거나 신뢰할 만한 비교어원 근거가 비고를 실질적으로 바꿀 때 재검토한다. 단순 번역어 차이만으로 자동 재연구하지 않는다.

## 적용 검증

공식 dry-run·실제 undo·원본 불변 및 적용기31테스트 통과 후 live apply1회. History group `1794578593809595`에 의미·비고 update2행을 확인했다. 전체13테이블·DDL·비대상·기존 이력 불변, byte backup과 공식 snapshot의 논리적 일치 및 receipt hash를 독립 확인했다. Snapshot의 schema cookie 차이는 공식 계약에 따른 것으로 원본 byte backup과 구별한다. Work·seed·백업·snapshot integrity ok·FK0·sidecar0. Progress 승인983→984·미승인13309→13308·hold6·anomaly113이다.

Work after SHA: `b1acda8d3e1b45d8f73e51be76e2150b05c907e0bbea2bcd2cf2e5ac76627504`. 적용 receipt: `data/backups/approved_content_batch/20261113T140311082895Z/result.json`. 독립 검증·승인 원문·byte backup: `data/backups/approved_content_batch/h444_approval_20261113/`. 앱·UX 변경이 없어 UI 테스트 N/A.
