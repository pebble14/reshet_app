# H328 천천히·부드럽게·주술사 의미 결정

- 상태: active
- 결정일: 2026-11-01 (Asia/Seoul)
- 기록 성격: 결정 적용과 동시 작성 / 판단 근거 복원 수준: 높음
- 대상: H0328 (`H0328_0000`)
- 승인 manifest: [h328_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h328_cluster_approved_content_slice.json)
- Hold authority: [현행 ledger](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음
- 상세 연구: 로컬 reshet_research_output/H0328_cluster_20261101_29440547/00_cluster_summary.md (r1), H328_review.md, 00_manual_evidence.json
- 승인 원문·적용 전 byte 백업·독립 검증: data/backups/approved_content_batch/h328_approval_20261101/
- 공식 receipt: data/backups/approved_content_batch/20261101T125245257994Z/result.json

## 최종 결정

사용자는 r1 추천안과 DB·문서 반영, 검증 후 커밋·작업 브랜치 push·main ff-only 병합·push·이번 작업 브랜치의 로컬·원격 정리를 승인했다.

|seq|최종 meaning|
|---|---|
|1|천천히|
|2|부드럽게|
|3|주술사(呪術師)|

기존 seq1 `천천히, 부드럽게`를 위3행으로 교체했다. 기존 비고 NULL을 다음으로 교체했다.

> 움직임·흐름이 급하거나 거칠지 않은 모습과 사람·말을 부드럽게 대하는 태도를 나타낸다. 왕상 21:27의 ‘풀이 죽어’는 아합의 낮아진 행동을 문맥에서 풀어쓴 표현이다. 욥 15:11에는 ‘은밀하게’라는 해석도 있다. 사 19:3의 남성 복수형은 주문을 중얼거리는 주술사로 풀이하지만 ‘죽은 이의 영’으로 보는 견해도 있다. 작은 소리의 주문에서 주술사의 뜻이 생겼다는 설명은 추정 어원이며, H331에서 파생되었다는 설명도 확정하지 않는다.

관계 신규·교체·삭제0, word-level hold 없음. H0331→H0328 어원 관계는 보류·비생성이다. 후보 저장 pair H0328_0000/H0331_0000 및 방향 w2_to_w1은 미승인 후보 설명이며 실제 relation operation과 category/type/status는 N/A다. 기존 active 결정의 대체가 없어 supersession 없음. 원문·음역·발음·언어·schema·seed·앱 구현·기존 관계와 hold는 보존했다.

## 선택 이유와 기존 결정 대조

Canonical discovery node1·edge0·frontier0으로 closure를 마쳤고 hub 예외는 없다. Strong entry, canonical OSHB6/6회, 로컬 사전 exact row1개, 다섯 verse reference의30개 비교, 명시적 LXX7개 조회를 검토했다. LXX 왕상21:27 동일 번호는 다른 사건이므로 제외하고20:27의 아합 문맥을 직접 대조했다. 자동 장절 mapping·lemma alignment로 승격하지 않았다.

부사적 용법5회 중 Gen33:14는 형태상 명사 연계+접미사이지만 부사적으로 기능한다. 이동·물의 속도와 사람·말의 처우를 한국어 하나로 충분히 포괄하기 어려워 천천히와 부드럽게를 나눴다. 두 풀이의 문맥상 겹침은 인정하며 세 개의 확정 어원을 뜻하지 않는다.

사19:3의 남성복수 명사는 부사 meaning만으로 설명되지 않는다. Strong·BDB의 전통적 사람 독법과 확보 한국어/KJV를 근거로 주술사를 채택했다. 현대 한국어의 무대 기술로 오해할 가능성을 줄이는 표현이며, 마술사를 오답으로 배제한 결정은 아니다. 呪術師 표기는 국립국어원 발간물 해당 부분에서 확인했다. 일반 어휘이므로 고유명사 병기·분석 붙임표·새 발음 선택은 N/A다.

[H178 결정](h88_cluster_approved_content_slice.md)처럼 사람·영·추정 어원을 구별한다. 다만 H178에서 승인한 뜻을 H328에 자동 복사하지 않는다. [H309 관련 결정](h268_cluster_approved_content_slice.md)처럼 특정 문맥의 행위나 결과마다 독립 뜻을 만들지 않는다.

## 채택하지 않은 주요 대안

- 부드럽게 또는 천천히 하나만 유지: 속도 또는 대인 태도의 범위를 충분히 표현하지 못한다.
- 마술사(魔術師): 유효한 번역 대안이나 이번에는 주술사를 선택했다.
- 죽은 이의 영(靈): NET 사19:3과 Balogh2009 pp274–275가 지지하는 실제 경쟁 분석이다. 명사1 token의 판별은 미해결로 보존하며 사람과 영을 모두 별도 meaning으로 확정하지 않는다.
- 은밀하게: 욥15:11의 실제 경쟁 독법이며 제4 meaning 대신 비고에 보존한다.
- 흐르다·풀이 죽다·회개하다·중얼거림·탄식: 다른 token의 뜻, 문맥상의 태도 또는 추정 어원 설명을 독립 meaning으로 승격하지 않는다.
- H331 파생 관계: reference-only 사전은 단정하지만 Strong의 미확인 어근 추정과 BDB의 소리 어근 비교가 상충하므로 생성하지 않는다.
- 단어 전체 hold: 확실한 부사 일반 의미까지 보류하지 않고 명사·어원 불확실성을 비고에 남긴다.

## 남은 불확실성과 재검토 조건

검토6·미검토0. 확정 주배정은 천천히3·부드럽게2·의미 배정 미해결1이며 합계6이다. 채택한 추천 시나리오는3·2·1이지만 사19:3의 사람/죽은 영 판별을 해결한 것은 아니다. 왕상21:27과 욥15:11의 ambiguity2건은 별도 중복 태그다. 확정 반례0이 경쟁 분석의 부재를 뜻하지 않는다.

새 동시대·비교언어·본문·문법 근거가 사19:3의 대상 또는 H331 파생을 실질적으로 판별하면 재검토할 수 있다. 동일 번역 목록이나 옛 어원 설명의 반복만으로 자동 재검토하지 않는다. 고정 OSHB는 호11:4를 H5186으로 배정하므로 외부7회 집계를 H328 canonical6회에 합산하지 않았다.

## 적용 및 검증

공식 dry-run·undo에서 원본 SHA 불변, 적용기31개 테스트 통과 후 live apply1회. Meaning replacement1·note replacement1·history2행, history group1793537567218341. 전체13테이블·DDL 독립 대조에서 승인 대상 및 기대 history/sequence 외 불변을 확인했다. Integrity ok·FK0·sidecar0·seed 불변.

Work SHA before29440547a40f5db945471e1a3a2157546073bcf773b774fb2f226c0d7a5ae5aa → after a2d865cbc3aec0a672c8ee460f41635c9ec5077b11249b86ee1708ca3f039954. 진행표 승인831→832·미승인13461→13460, hold6·anomaly113 유지. 앱 UI·build·schema migration·seed 배포는 N/A다.
