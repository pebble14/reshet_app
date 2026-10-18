# H109 슬프게 하다·H110 아드베엘 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-18 (Asia/Seoul)
- 대상: H0109, H0110
- 승인 manifest: [h109_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h109_cluster_approved_content_slice.json)
- 표기 기준: [한국어 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 로컬 연구: 외부 reshet_research_output/H0109_cluster_20261018_a09d3545/
- 승인 원문·byte 백업·독립 SQL·progress 검증: data/backups/approved_content_batch/h109_approval_20261018/
- 공식 snapshot·result: data/backups/approved_content_batch/20261018T010158019515Z/

## 최종 결정

사용자는 H110에 붙임표를 넣지 않는 최종안과 나머지 의미·비고 추천, DB·문서·필요 파일 및 이상 없는 경우 Git 완료와 이번 작업 브랜치 정리를 승인했다.

|Strong|최종 meaning|처리|canonical 출현|
|---|---|---|---:|
|H0109|슬프게 하다|기존 의미 유지 승인, 비고 추가|1|
|H0110|앗브엘·아드베엘 (인)|동일 인명 표기 병기, 비고 추가|2|

각각 seq1의 단일 의미다. H109 meaning approval1은 데이터 쓰기 없이 기존 값을 검증하며, H110 meaning replacement1·word note replacement2의 총3 write를 적용했다. H110의 가운데점은 동일 이름의 두 표기이며 별도 sense 구분이 아니다.

최종 비고 전문:

**H0109**

> Strong의 기본 풀이는 ‘쇠약해지다’이며, 성경의 유일한 용례(삼상 2:33)는 마음을 슬프게 하는 히필형이다. 어근을 דוב로 달리 분석하는 견해도 있으나, 현행 Strong·OSHB의 H109 분류를 따른다.

**H0110**

> 이스마엘의 아들로, 창 25:13과 대상 1:29에 나온다. ‘앗브엘’은 한국어 성경의 관용 표기이고 ‘아드베엘’은 마소라 표기와 Strong 음역을 참고한 읽기 표기이며, 고대의 실제 발음을 확정한 것은 아니다. Strong은 H109와 H410에서 온 이름으로 추정하여 ‘하나님께 징계받은’으로 풀이하지만, 어원이 확정된 것은 아니다.

H109→H110과 H410→H110은 관계로 생성하지 않았다. Strong의 probably를 제거해 확정 구성 관계로 저장하지 않으며 추정 어원은 비고에 보존한다. 관계 생성·교체·삭제0, 신규 word hold0, 기존 hold ledger6건 유지다. CONTEXT H410과 HUB-EXCLUDED159개는 변경·추가 승인하지 않았다. 원어·음역·발음·언어·Strong identity·schema·seed·앱 코드는 유지하며 이전 active 결정의 supersession은 없다.

## 핵심 판단 근거

- H109의 유일한 삼상2:33 용례는 히필 부정사 연계형으로 마음을 슬프게 하는 문맥이다. Strong의 기본 어근 풀이 to languish와 실제 사역형의 기능을 구분해 ‘슬프게 하다’를 유지한다. BDB가 소개하는 דוב 어근 분석 대안은 비고에 남기되 현행 Strong·OSHB 분류를 교체하지 않는다.
- H110은 창25:13·대상1:29에서 이스마엘의 아들을 가리킨다. 한국어 성경의 ‘앗브엘’을 보존하고 마소라 표기·Strong 음역을 참고한 ‘아드베엘’을 병기한다. 고대 실제 발음의 확정이나 새로운 발음 필드 교정이 아니다.
- Strong은 H109와 H410에서 온 이름이라는 설명 전체에 probably를 붙인다. 현재 확인한 자료만으로 합성 경계를 충분히 확정할 수 없어 ‘아드베-엘’을 채택하지 않는다. 붙임표를 단순 읽기 보조로 쓰지 않는 표기 정책과 일치한다. 합성 분석이 뒷받침된 다른 이름의 표기를 기계적으로 일반화하지 않는다.
- 인물 식별과 실제 용례는 명확하다. 어원·발음의 불확실성은 비고로 한정할 수 있으므로 word hold를 새로 만들지 않는다. Strong의 x-pn/unresolved 표시는 현재 DB 언어를 자동 교체하거나 의미 승인 전체를 보류할 근거로 취급하지 않는다.

CORE2의 정본 용례3회 전량을 검토했고 미분류0이다. 확보된 로컬 참고자료 및 명시적 LXX3절은 reference-only다. LXX 삼상2:33은 마음과 소유대명사에 다른 독해를 전하며, H110 두 용례는 이름 Ναβδεηλ 계열로 나타난다. 이를 자동 cross-language 관계나 역사적 히브리어 발음 확정으로 바꾸지 않는다. 사해문서 관련 번역 주석은 참고했으나 해당 사본을 직접 확인했다고 주장하지 않는다.

탐색은 max_nodes_reached에서 중단된 162노드·161간선·frontier158이며 전역 research_complete=false를 보존한다. CORE2·CONTEXT1·HUB-EXCLUDED159의 범위 판단에 따른 한정 승인이다. H410의 245회 전체를 연구 완료한 것으로 표시하지 않으며 관련 문맥3절만 참고했다. CORE에 접한 근거를 검토했다는 사실과 전체 그래프 closure를 구분한다.

## 채택하지 않은 주요 대안

|대안|채택하지 않은 이유와 보존|
|---|---|
|H110 앗브엘·아드베-엘 (인)|불확실한 구성 경계를 붙임표로 단정할 수 있다. 근거 수준에 맞춰 붙임표 없이 병기한다.|
|H110 앗브엘만 유지 또는 아드베엘만 사용|관용 표기와 원문 참고 읽기를 함께 보여 주는 승인안을 채택했다. 기존 관용 표기를 버리지 않는다.|
|H110 하나님께 징계받은을 별도 meaning으로 추가|이름의 추정 어원 풀이이지 본문에서 독립적으로 쓰이는 일반 의미가 아니다. 출처·한계와 함께 비고에 둔다.|
|H109 쇠약해지다로 교체|Strong의 어근 설명을 보존할 가치는 있으나 유일한 사역형 문맥을 대표하기에는 부족하다. 비고로 보존한다.|
|H109 마음을 괴롭게 하다로 교체|문맥상 가능한 표현이지만 기존 ‘슬프게 하다’로 충분하며 교체 이득이 낮다.|
|H109 징계하다를 추가|H110의 추정 어원에서 역추론한 의미를 독립 성경 용례의 확정 의미로 만들지 않는다.|
|두 구성 관계 생성 또는 신규 hold|추정 관계는 생성하지 않되 인물 식별·대표 의미를 승인할 수 있어 비고와 관계 비생성으로 처리한다.|

## 남은 불확실성과 재검토 조건

H109의 어근 분석과 삼상2:33 본문 차이, H110의 정확한 어원·내부 경계·역사적 발음은 미확정이다. 이번 승인이 이 문제들의 해결을 뜻하지 않는다. LXX upstream provenance·license와 한국어 참고자료의 전역 reference profile은 기존 미확인 경계를 유지하며 원천 본문을 앱에 새로 import하지 않았다.

비교셈어·비문·비판본 등에서 어원과 경계를 실제로 판별할 새 근거가 확보되거나 canonical 용례 분류를 바꿀 근거가 나오면 재검토한다. 단순히 다른 이름과 시각적으로 맞추려는 이유만으로 붙임표나 관계를 추가하지 않는다. 후속 변경은 별도 semantic 승인을 따른다.

## 적용·검증

공식 dry-run의 사본 적용·실제 undo·원본 byte 불변을 확인한 뒤 live apply했다. History group1792285319242569, ID6193–6195는 active word update3행·undone0이다. 독립 SQL45조회로 전체13테이블·DDL·byte 백업·공식 snapshot을 대조하여 승인 의미1·비고2와 history/해당 sequence 외 차이가 없음을 확인했다. Integrity ok·FK0·sidecar0이며 seed·원본 연구·기존 manifest를 포함한 보호 파일106개 불변, 기존 applicator 테스트31건 통과다.

Work SHA a09d3545e97ef60ae8b0bf111f6edaa842fa0ffbf857e808ec50ca21970ab0ce → 650608e83efc61131f491d1a82c0df118226f657793ddfae848f2f0428409dc7. Seed SHA a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1 불변이다. 승인 원문 SHA ff7bf3d7d288fe9b9d1f6265cc2a48301491324c94f27348760591ebe82d04c8, manifest SHA 4e7fae58238701ae2f65e988b2d90498f5ff63e4c0f8b73e8dc59d3c083c29a9이며 신규 manifest만 text eol=lf로 지정한다.

공식 표준 semantic_progress JSON·CSV·Markdown을 함께 갱신했다. 전체14,298개 중 H109·H110만 explicit_approved로 전환돼 승인331→333·미승인13,961→13,959·hold6·anomaly113이다. Snapshot identity 48eafc01d9da3eb76f30e473ad30eb9fd8181421214fe35b471342227e0a82e6이며 비대상 row·anomaly·canonical relation index 불변과 CSV/Markdown 공식 render 일치를 확인했다.

원본 연구 control/Review는 유지하고 외부 00_applied_content.md/json에 적용 결과를 별도로 기록한다. DB는 Git 미추적 로컬 자산이며 앱 배포·설치 DB 교체는 수행하지 않았다. 앱/UI·UX 변경이 없어 수동 UI 테스트와 전체 앱 빌드는 N/A다.
