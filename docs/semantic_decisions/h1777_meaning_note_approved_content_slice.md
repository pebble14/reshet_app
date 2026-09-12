# H1777 의미·비고 결정

- 상태: `active`
- 기록 성격: 승인 시점 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-09-12
- 대상: H1777 meaning·note와 hold 해제
- 승인 manifest: [h1777_meaning_note_approved_content_slice.json](../../tool/data_provenance/manifests/h1777_meaning_note_approved_content_slice.json)
- 이전 결정: [H27 클러스터 결정](h27_cluster_approved_content_slice.md)
- 로컬 연구 산출물: `H27_cluster_20260911_427a6c2f/H1777_review.md`
- DB 적용: history group `1789179579102751`

## 마감 검증

- semantic progress: canonical 14,298건, `explicit_approved` 94건, `hold` 2건, `unapproved` 14,202건, anomaly 113건
- 최종 checkout snapshot identity: `e494d25f2b7b46edd84e05a4c1bc731e7c64b1432f48c8c34a6225df5d97af0f`
- 최종 checkout 산출물 SHA-256: JSON `9ee7ac16e0575f7a5ca5ed47f55653dca721ffa847509e9099822d9d134c2861`, CSV `da814995cd7a61aead28ed697810c350b97e40900417eb9e01de3c45a0186c22`, Markdown `7dee2b271a904c1ba0ada9b60f44ffcdfc4891fb4eeba8a20083616da4a86a9e`
- 적용 manifest SHA-256: `64d226f777e35f2f99cce15d187aa965ec9cade0c512086c96468ee2eb1f377e`; `core.autocrlf`가 적용된 최종 checkout 파일 SHA-256: `76a96b50dce8a51197a2319080eca4be9f67397d49c4b71841bccbb8e612004f`
- DB SHA-256: work `fc77559add7ccdd64af1360db1673287cd40dadae0eed5adc16f102f418ae0d7`, seed `e2e356c0f9a5d0d86c059da77c59815521e2abc410b3c4aa69b1ab6e55ff9a67`
- 적용량: meaning replacement 1건, word note replacement 1건, relation 변경 0건
- live history: word update 2행, 모두 active; 자동 restore 없음
- SQLite: `integrity_check=ok`, foreign key violation 0건, `user_version=0`, sidecar 없음
- 회귀 검증: semantic progress 18개 테스트, approved-content applicator 29개 테스트 통과

최초 적용 시 H27 manifest의 H1777 승인을 supersede한다고 잘못 선언한 metadata를 공식 progress가 거부했다. H27에서는 H1777 meaning을 승인하지 않고 hold만 기록했으므로 supersession 대상이 아니다. 최초 history group `1789179237857983`의 2행은 Repository의 `undoLastChange()`로 즉시 복원해 inactive 상태로 남겼다. corrected manifest는 `supersedes: []`이고, 위 마감 검증은 corrected live apply만을 기준으로 한다.

## 최종 결정

H1777의 ordered meaning projection을 다음과 같이 승인했다.

1. `심판하다(審判하다)`
2. `변호하다(辯護하다)`
3. `다투다`
4. `다스리다`

비고는 다음 문장으로 승인했다.

> 창세기 6:3의 יָדוֹן(야돈)은 형태와 어원 해석에 논쟁이 있다. ‘다투다’로 풀이하기도 하며, 칠십인역은 ‘머무르다’로 옮긴다. ‘머무르다’로 읽으면 하나님의 영이 인간의 생명을 끝없이 유지하지는 않겠다는 뜻으로 이해할 수 있다. 다만 이 용례의 분석이 확정되지 않았으므로 ‘머무르다’는 해석 가능성으로 제시한다.

H1777을 semantic hold ledger에서 제거한다. 기존 H1777 관계는 이번 결정의 대상이 아니며 변경하지 않는다.

## 핵심 판단 근거

H1777의 일반적인 용례는 재판과 판결, 당사자의 권리 옹호, 다툼, 통치의 범위로 설명된다. `심판하다(審判하다)`와 `변호하다(辯護하다)`를 구분하면 불리한 판결뿐 아니라 정당함을 인정하고 송사를 맡는 기능까지 나타낼 수 있다. `다투다`와 `다스리다`는 실제 용례의 별도 기능을 보존한다.

창세기 6:3의 יָדוֹן은 일반적인 H1777 미완료형에서 기대되는 형태와 다르고, ‘다투다’ 계열 분석과 ‘머무르다’ 계열 분석이 수렴하지 않는다. 그러나 이 불확실성은 H1777의 나머지 23개 canonical token에서 확인되는 일반 의미를 승인하지 못하게 할 정도는 아니다. `머무르다`를 일반 meaning으로 확정하지 않고, 칠십인역과 문맥에 근거한 해석 가능성으로 비고에 한정하면 확인된 의미 범위와 미해결 용례를 함께 보존할 수 있다.

## 채택하지 않은 주요 대안

- `머무르다`를 다섯 번째 일반 meaning으로 추가: 창세기 6:3 한 용례의 형태·어원 분석이 확정되지 않았으므로 채택하지 않았다.
- 창세기 6:3이 해결될 때까지 H1777 전체를 hold로 유지: 일반 의미 범위는 충분히 확인되었고, 남은 불확실성을 비고에서 정확히 구분할 수 있으므로 hold를 해제했다.
- `억울함을 풀어주다`를 별도 meaning으로 추가: 유리한 심판 또는 변호의 문맥적 결과이므로 독립 lexical sense로 늘리지 않았다.

## 남은 불확실성 및 재검토 조건

창세기 6:3의 יָדוֹן이 H1777의 특이형인지, ‘머무르다’ 또는 다른 어근에 속하는지는 확정하지 않는다. 새로운 본문비평·비교언어학 근거가 어느 분석을 충분히 지지하면 비고의 표현과 H1777 귀속을 재검토한다. 이 불확실성은 비고에 명시되어 있으므로 현재 meaning 승인과 hold 해제는 유지된다.
