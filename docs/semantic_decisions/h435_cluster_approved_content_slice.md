# H435 엘룰월 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-11-13
- 대상: H0435
- 승인 manifest: [h435_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h435_cluster_approved_content_slice.json)
- 관련 hold ledger: 변경 없음, 신규 hold 없음
- 로컬 연구 산출물: reshet_research_output/H0435_cluster_20261113_6a8f9726, 추천 revision 1

## 최종 결정

사용자는 추천안과 DB·문서 반영·검증·커밋·push·main ff-only 병합·이번 작업 브랜치 정리를 승인했다.

- H0435 meaning seq1: 엘룰 (월), sense 1개
- 기존 엘룰월의 뜻을 보존하면서 이름과 분류 기호를 구별한다.
- 비고: ‘엘룰’은 한국어 성경의 관용 표기이자 히브리어 אֱלוּל의 교재식 읽기를 옮긴 한글 근사다. 니산월을 첫째로 세는 달력의 여섯째 달이며, 양력으로 대체로 8~9월 무렵에 해당한다. 느헤미야 6:15에서는 성벽 공사를 마친 달이다. 아카드어 월명 Elūlu 계열과 연결되지만, 궁극적 어원 뜻과 정확한 차용 경로는 확정하지 않는다. 예레미야 14:14의 H0434 ‘헛된 것’과 구별한다.
- 기존 관계 0개, 신규 관계 비생성. 신규 hold 없음.
- 원문·음역·발음·언어·schema·seed 및 관련 다른 단어의 기존 승인값은 변경하지 않았다.

## 핵심 판단 근거

Canonical Strong H435 entry와 OSHB 느헤미야 6:15의 전체 1회 용례는 달의 고유명을 지지한다. 전치사+월명이 완공 날짜를 지정하며 25일은 날짜, 52일은 공사 기간이다. 로컬 참고자료 6종과 LXX 해당 절 전체를 대조했다. LXX ελουλ도 월명이며 human_reference·provenance/license 미검증 경계를 유지한다.

관용명과 히브리어 교재식 한글 근사가 모두 엘룰이므로 중복 병기하지 않는다. H143·H144의 아달·아다르 (월) 형식을 따르며, (월)은 분류 기호라 한자를 기계적으로 추가하지 않는다. 합성 경계 근거가 없어 붙임표를 넣지 않는다. H434 헛된 것과는 다른 어휘로 구별한다. 사용자는 이 추천을 채택했다.

BDB H435는 여섯째 달·8~9월 대응과 Assyrian Ululu를 대조한다. American Heritage 공식 Elul entry는 아카드어 elūlu 월명과 연결하며 그 이전의 정결·거룩 계열 어원은 추정이다. 궁극적 어원 뜻을 별도 의미로 만들지 않았다.

- https://bibeltext.com/bdb/435.htm
- https://ahdictionary.com/word/search.html?q=elul
- [표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- [월명 선례](h143_cluster_approved_content_slice.md)
- [H434 구별](h408_cluster_approved_content_slice.md)

## 채택하지 않은 주요 대안

- 엘룰월 유지: 의미상 가능한 대안이나 이번에는 월명+분류 형식을 택했다.
- 엘룰월(月): H24 아빕월(月) 선례에 맞는 유효한 대안이다. 이번에는 H143의 분류 형식을 채택하며 기존 H24를 수정하지 않는다.
- 여섯째 달만 기록: 월명 식별이 사라지고 양력 6월로 오해할 수 있어 비고에 둔다.
- 헛됨·정화 등 독립 sense: 동일 철자의 다른 어휘 또는 추정 어원과 혼합되며 해당 월명의 실제 용례가 지지하지 않는다.
- H434 관계·아카드어 차용 관계 생성: 동철자를 파생 관계로 승격하지 않으며 원천 DB identity와 정확한 차용 경로가 미확정이다.
- 단어 전체 hold: 월명 identity는 충분히 명확하여 어원·발음의 한계를 비고에 한정한다.

## 남은 불확실성 및 재검토 조건

궁극적 어원·중개 언어·차용 경로와 고대 세부 발음은 미확정이다. 원자료 x-pn metadata를 실제 히브리어 용례와 구별하여 보존한다. HebGrkKo의 9월 초순~10월 초순 설명은 BDB의 8~9월·새번역 각주와 다르다. 비고의 8~9월은 대략적 대응이며 특정 연도의 정확한 날짜 환산이 아니다.

미검토 canonical 용례 0, 의미 배정 미해결 0, 실제 반례 0이다. 새로운 독립 용례·identity 충돌·검증된 반대 어휘 근거 또는 사용자의 표기 변경이 재검토 조건이다. 번호 인접성·철자 일치·새 근거 없는 어원 추측만으로 자동 재검토하지 않는다.

### 적용 검증

공식 dry-run·사본 적용·undo·원본 불변과 기존 적용기 31테스트를 통과했다. Live apply 1회 후 13테이블·DDL을 원본 백업과 대조하여 의미1·비고1·history2행 및 해당 sequence 외 데이터 보존을 확인했다. 관계·기존 history·원문 표현·언어·seed 불변이다. Work·seed·snapshot integrity ok·FK0·sidecar0.

이력 그룹: 1794558498634059. 공식 receipt: data/backups/approved_content_batch/20261113T082817101033Z/result.json. 백업·승인 원문·독립 검증: data/backups/approved_content_batch/h435_approval_20261113/.

Work SHA: 6a8f972655b7d33b0e5a89a78363934faea6b64a21f933badc00a010689e8e79 → aae14d19c2c673e07ae43cd13e4bfeba0b248e516df42274c0acbb15783afcf5. Seed SHA: a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1 불변.

Progress 승인960→961·미승인13332→13331·hold6·anomaly113. 비대상14,297행 불변 및 JSON/CSV/Markdown renderer 일치를 확인했다. 앱·UX 변경이 없어 UI 테스트·앱 배포는 N/A다. 상세 raw evidence는 외부 연구 산출물에 보존한다.
