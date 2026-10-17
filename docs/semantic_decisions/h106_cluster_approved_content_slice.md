# H106 주먹·휩쓸어감·흙덩어리 어휘군 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-17 (Asia/Seoul)
- 대상: H0106, H1640, H4053
- 승인 manifest: [h106_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h106_cluster_approved_content_slice.json)
- 관련 hold ledger: 기존6건 유지; 신규 hold·해제 없음
- 로컬 연구 산출물: 외부 reshet_research_output/H0106_cluster_20261017_a4820f7d/
- 승인 원문·byte 백업·검증: data/backups/approved_content_batch/h106_approval_20261017/
- 공식 snapshot·result: data/backups/approved_content_batch/20261017T091321073304Z/

## 최종 결정

사용자는 완료된 Codex 추천안을 채택하고 DB·문서·필요 파일 반영, 이상 없는 경우 Git 완료와 이번 작업 브랜치 정리까지 승인했다. 단일 meaning3개는 현재 값을 그대로 승인하고 비고3·파생 관계2, 총5 write를 공식 도구로 적용했다.

| Strong | 최종 meaning | 순서 / sense | canonical 출현 |
|---|---|---|---:|
| H0106 | 주먹 | seq1 / 1 | 2 |
| H1640 | 휩쓸어가다 | seq1 / 1 | 1 |
| H4053 | 흙 덩어리 | seq1 / 1 | 1 |

최종 비고 전문:

**H0106**

> 사 58:4의 '악한 주먹'에서 '악한'은 뒤따르는 רֶשַׁע가 더하는 문맥 의미이며, 이 단어 자체의 별도 의미가 아니다. BDB가 소개하는 '몽둥이·막대기' 대안은 남아 있지만, 확보된 용례와 그리스어 참고 본문은 '주먹' 해석을 지지한다. Strong의 '붙잡다' 설명은 H1640과 연결하는 어원적 풀이로 구분한다.

**H1640**

> 성경의 유일한 용례인 삿 5:21에서는 강물이 사람들을 휩쓸어 가는 데 쓰인다. 관련 명사의 어원 풀이에 나오는 '붙잡다·떠내다'를 별도 성경 의미로 확정하지 않으며, 로컬 사전의 '파악하다·이해하다'도 확보된 성경 용례에서 입증되지 않는다.

**H4053**

> 욜 1:17에만 나오며, 본문의 대상과 해석에는 불확실성이 있다. Strong과 여러 번역은 '흙 덩어리'로 풀이하지만, BDB·NET은 '삽' 풀이를 제시하고, 확보된 LXX 참고 본문은 암소와 구유를 말하는 다른 문장을 전한다. '삽'이나 '구유'를 별도 확정 의미로 추가하지 않고, 현행 의미를 대표 해석으로 유지한다.

| ID | semantic 방향 | 저장 pair | category / type / status / direction |
|---|---|---|---|
| 7884 | H1640 → H0106 | H0106_0000 < H1640_0000 | morphological / derived / asserted / w2_to_w1 |
| 7885 | H1640 → H4053 | H1640_0000 < H4053_0000 | morphological / derived / asserted / w1_to_w2 |

관계별 정확한 비고·source·NULL 필드는 manifest와 DB에 보존한다. H106–H4053 직접 관계·자동 LXX 번역 관계·H1640의 이해하다 meaning은 생성하지 않았다. 신규 hold와 기존 결정의 supersession은 없다. Expression·음역·발음·언어·Strong identity·schema·seed·앱 코드는 유지했다.

## 핵심 판단 근거

H106의 출21:18·사58:4는 움켜쥔 손으로 사람을 치는 문맥이다. 사58:4의 악함은 뒤 명사의 수식이고 주먹질은 동작 중심 번역이므로 별도 sense를 늘리지 않았다. H1640의 삿5:21은 기손 강이 사람들을 휩쓸어 가는 유일한 용례이며, 로컬 사전의 추상적 파악하다·이해하다는 입증되지 않는다.

H4053의 유일한 출현 욜1:17은 Strong과 확보 로컬 자료가 흙덩이 해석을 지지하고 농경 재난 문맥에도 맞는다. BDB·NET의 삽 풀이와 확보 LXX의 암소·구유 문장은 경쟁 근거로 남긴다. 현재 값을 대표 해석으로 유지하며 해석 미해결을 비고에 명시했다. 사용자는 이 evidence에 기초한 Codex 추천을 채택했다.

두 명사 항목은 qualifier 없는 from H1640으로 연결한다. 어근·명사 형성·전체 문맥을 검토하여 파생2건을 승인했다. Source-reference 방향과 semantic 파생 방향은 반대이며 H106의 grasping 어원 풀이를 H1640의 독립 성경 sense로 승격하지 않았다. H4053의 정확한 사물 식별과 어근 연결도 구분했다.

정상 CORE3 closure·frontier0이며 canonical4 token 전량을 검토했다. H106 2개와 H1640 1개는 확정 분류, H4053 1개는 잠정 분류이자 해석 미해결이다. 로컬 사전 exact3행, 5종 절 자료20/20 join, LXX explicit4절을 비교했다. 원본18개 연구 파일은 보존한다.

## 채택하지 않은 주요 대안

| 대안 | 채택하지 않은 이유와 보존 |
|---|---|
| H106 철권 | 로컬 사전에 있으나 폭력성·강경 지배를 독립 meaning으로 부각할 성경 근거가 없어 추가하지 않았다. |
| H106 몽둥이·막대기 | BDB가 소개한 고대 번역 대안이며 오답으로 폐기하지 않았다. 확보 문맥·그리스어 참고 본문을 우선해 주먹을 유지하고 비고에 대안을 보존했다. |
| H1640 표류시키다 | 유효한 문맥 번역이지만 강물의 작용보다 결과에 초점이 있어 대표 meaning으로 덜 적절하다. |
| H1640 파악하다·이해하다 | Canonical 용례로 입증되지 않아 어원적 grasping과 구분하는 제한을 비고에 남겼다. |
| H4053 삽 | BDB·NET의 유효한 경쟁 해석이나 배타적으로 확정하기 어려워 비고에 보존했다. |
| H4053 구유 | 같은 히브리어 표제어의 sense인지 다른 본문 독법인지 미확정이므로 추가 의미로 만들지 않았다. |
| H4053 신규 hold | 대표 해석 유지와 명시적 비고로 현재 판단을 보존할 수 있어 채택하지 않았다. 본문 문제가 해결됐다는 결정은 아니다. |

## 남은 불확실성 및 재검토 조건

H4053의 정확한 대상과 욜1:17의 해석은 미해결이다. BDB가 인용한 고대 번역 원문이나 NET 주석이 언급한 사해 사본 자체는 이번에 직접 확인하지 않았다. LXX upstream provenance·license와 한국어 참고자료 reference profile은 미확인 경계를 유지한다. 사전적 파생 승인이 모든 역사적 중간 어형을 새로 입증했다는 뜻은 아니다.

실제 초기 히브리어 사본·비평 판본 대조, 도구명과 흙덩이 해석을 구별하는 직접 증거, H106 어원·고대 번역 관계를 바꿀 자료가 나오면 재검토한다. 같은 번역의 반복 확인·번호 인접성·발음 유사성만으로 자동 재검토하지 않는다.

### 적용·검증

공식 dry-run에서 사본 적용·실제 undo·원본 불변을 확인한 뒤 live apply했다. History group1792228402244877, ID6179–6183은 active5행(word update3·relation create2), undone0이다. 독립 SQL50조회·59검증으로 전체13테이블·DDL·byte 백업·공식 snapshot을 대조했다. 비고3·관계2와 관련 history/sequence 외 변경이 없다. Integrity ok·FK0·sidecar0, seed 및 보호 입력153개 불변, applicator 테스트31건 통과다.

Work SHA a4820f7deb562e0b472fafd7478710a92feb77634047b4f19079e7cd39e127f0 → d4ac11bc06a35e8e1558a1f61567e2aab4faf70838a1db7126dcef22fd2c089b. Seed SHA a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1 불변이다.

승인 원문 SHA b2af076572eafbaa2a84e243d95117495b5a7c6b93aabb7700a59989d31ebf1a, manifest SHA 9fdc2a60095b45c2f61d0a094d8ecab2fbe3f8f83239ff43908c882f99a023fa이며 신규 manifest의 text eol=lf 지정으로 실제 적용 bytes를 Git에서도 보존한다.

공식 표준 progress3종과31검증에서 대상3개만 승인 전환됐다. 승인323→326·미승인13,969→13,966·hold6·anomaly113·분모14,298이며 snapshot identity는 8702e666fa9da96670b55a320ffb87ea425805322fe6741b7541210108b95e08다. 비대상 row·원천 fingerprint·canonical relation index 불변 및 공식 JSON/CSV/Markdown render 일치를 확인했다.

DB는 Git 미추적 로컬 자산이며 설치 DB 교체·앱 배포는 수행하지 않았다. 앱/UI·UX 변경이 없어 수동 UI 테스트·전체 앱 빌드는 N/A다.
