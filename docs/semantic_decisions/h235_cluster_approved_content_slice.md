# H235 이동·염소·아사셀 클러스터 의미·비고·관계 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-27 (Asia/Seoul)
- 대상: H0235, H0236, H0237, H5795, H5796, H5799
- 승인 manifest: [h235_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h235_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음·신규 hold 없음
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 로컬 연구 산출물: `reshet_research_output/H0235_cluster_20261027_5cad2469/`, 최신 판단 `H0235-r2-20261027`
- 승인 원문·적용 전 byte 사본·독립 검증: `data/backups/approved_content_batch/h235_approval_20261027/`
- 공식 receipt: `data/backups/approved_content_batch/20261027T071119708514Z/result.json`

## 최종 결정

사용자는 H5799를 hold로 표시하지 않고 비고로 불확실성을 설명하며 `아사셀·아자젤`을 승인했다. H5795의 긴 괄호 풀이 대신 기본 의미를 보존하는 최신 추천과 같은 원칙의 H5796 유지안을 제시한 뒤, 수정안 반영·DB·문서·기타 필요 파일·검증·Git·이번 브랜치 정리까지 승인했다. 이 승인에 최신 r2 수정과 나머지 r1 추천을 포함했다. 사용자의 별도 개인적 판단 이유를 추정하지 않는다.

|Strong|최종 ordered meaning|sense|조치|
|---|---|---:|---|
|H0235|가다 / 다하다|2|meaning 교체|
|H0236|가다|1|meaning 교체|
|H0237|에셀·에젤 (지)|1|meaning 교체|
|H5795|암염소 / 염소털|2|meaning 교체|
|H5796|암염소|1|현행 meaning 유지 승인|
|H5799|아사셀·아자젤|1|meaning 교체|

의미 교체5건(최종7행), 현행 meaning 유지 승인1건, 비고6건, 관계 생성3건이다. 대상 전체의 최종 meaning은8행이다. 새 hold·기존 hold 변경·supersession·관계 교체·삭제는 없다.

### 최종 비고

**H0235**

> 히브리어 이동 동사로, 떠나가거나 이리저리 다니는 용법과 힘·양식·물 등이 다하여 없어지는 용법이 있다. 겔 27:19의 형태를 Strong의 usage와 일부 참고자료는 H235에 연결하지만, OSHB는 H187 우살로 분석한다. 이 구절의 ‘길쌈하는 실’ 독법을 H235의 확정 의미나 여섯 번째 정본 용례로 추가하지 않는다.

**H0236**

> H235와 대응하는 아람어 이동 동사다. 문맥에 따라 가다·떠나다·돌아가다로 옮기며, 여행 자체를 별도 의미로 나누지 않는다. 단 6:19–20은 OSHB의 절 번호이고 한국어 성경·KJV의 6:18–19에 해당한다.

**H0237**

> 에셀은 한국어 성경 관용 표기이고 에젤은 표제어의 교재식 한글 근사다. 삼상 20:19에서 다윗이 머물도록 지정된 바위의 명칭으로 읽는다. Strong은 H235에서 나온 ‘떠남’으로 풀이하지만, 지시 표현이나 다른 본문으로 읽는 견해도 있어 명칭과 어원을 확정하지 않는다.

**H5795**

> 기본적으로 암염소를 가리키는 여성명사다. 복수형은 문맥에 따라 염소류를 묶어 가리키며, 숫염소·새끼 염소 구문에서는 다른 구성어가 성별·나이를 나타낸다. 재료 문맥에서는 염소털을 뜻한다. Strong의 H5810 파생 설명은 비교 셈어의 염소 어휘와 구별한다.

**H5796**

> H5795에 대응하는 아람어 여성명사다. 스 6:17에서 숫염소를 나타내는 말과 결합한다. 구문 전체가 수컷을 가리킨다는 사실만으로 이 단어 자체의 암염소 의미가 사라진다고 단정하지 않는다.

**H5799**

> 아사셀은 한국어 성경 관용 표기이고 아자젤은 원문 형태의 교재식 한글 근사다. 레 16장에서 죄를 지운 염소를 광야로 보내는 의식과 관련된다. 그 지시 대상과 어원에는 견해 차이가 있으며, 광야의 존재를 가리키는 이름·장소·제거 개념 등으로 해석된다. Strong의 ‘염소(H5795)+가다(H235)’ 분석도 확정된 어원으로 취급하지 않는다.

### 최종 관계

|ID|semantic 관계|canonical 저장 pair|category/type/status/direction|
|---|---|---|---|
|8143|H0235 ↔ H0236|H0235_0000 < H0236_0000|etymological/root_shared/asserted/undirected|
|8144|H0235 → H0237|H0235_0000 < H0237_0000|morphological/derived/hypothesized/w1_to_w2|
|8145|H5795 ↔ H5796|H5795_0000 < H5796_0000|etymological/root_shared/asserted/undirected|

H235·H5795→H5799의 합성 관계와 H5810→H5795의 파생 관계는 생성하지 않는다. H235–H187, H236–H230의 기존 비생성 결정도 유지한다. CONTEXT H5810의 기존 meaning·비고와 기존4관계는 그대로다. 원문·음역·발음·언어·Strong identity·비대상·schema·seed·앱 코드·기존 hold는 보존했다.

## 핵심 판단 근거

- CORE6의 Strong 원 entry와 OSHB 전체92토큰을 대조했다. 로컬5종의 번역·분해 및 HebGrkKo를 전량 비교하고, 절 번호 충돌12개 절·자료 쌍은 수동 보충했다. LXX는 explicit human reference이며 자동 lexical alignment나 canonical 집계 근거로 사용하지 않았다.
- H235는 이동2토큰과 힘·양식·물의 소진3토큰을 `가다 / 다하다`로 보존한다. 겔27:19의 다른 독법은 OSHB H187과 구별하며 여섯 번째 H235 occurrence나 실을 잣는다는 확정 의미로 추가하지 않는다.
- H236의7토큰은 이동이다. 목적지·귀환·급함·여행 문체와 활용 차이만으로 sense를 늘리지 않는다. H235와의 언어별 대응은 공통 어근으로 표현하고 차용 방향은 확정하지 않는다.
- H237은 채택한 정본에서 특정 바위의 명칭으로 읽는다. 에셀은 관용 표기, 에젤은 교재식 근사이며 한 sense로 병기한다. Strong의 떠남 파생과 다른 본문·지시 표현 분석을 구별해 파생 관계는 가설 상태로 한정했다.
- H5795는 기본 풀이 암염소를 의미에 짧게 보존하고 범주적 복수형·숫염소/새끼 구문은 비고에 둔다. 동물65토큰과 염소털 재료9토큰은 구별한다. 이 집계가 동물65마리 모두의 생물학적 성별을 암컷으로 확정한다는 뜻은 아니다. H5796도 숫염소 구문 전체의 지시만으로 뒤 명사의 암염소 의미를 제거하지 않고 현행 meaning을 유지 승인했다.
- H5799는 사용자가 명칭을 승인하고 지시 대상·어원은 비고로 설명하도록 선택했다. 이름형 승인과 특정 영적 존재·장소·제거 개념 또는 Strong의 염소+가다 어원 확정은 별개다. 이 불확실성을 별도 word hold로 설정하지 않았다.
- 관용명·교재식 근사·source spelling/발음 필드를 구별했다. 두 고유명에 불확실한 분석적 붙임표나 한자를 만들지 않고 가운데점으로 병기한다. 일반 뜻풀이는 고유어여서 한자 병기가 필요하지 않다. [H186](h186_cluster_approved_content_slice.md)·[H187](h187_cluster_approved_content_slice.md)·[H230](h230_cluster_approved_content_slice.md) 결정을 대조하여 문맥 차이의 과도한 sense 분리와 경쟁 독법의 자동 관계화를 피했다.

## 채택하지 않은 주요 대안

|대안|채택하지 않은 이유·보존 위치|
|---|---|
|H235 돌아다니다·고갈되다만 유지|일회적 이동과 소진의 공통 범위를 표현하기 위해 가다·다하다를 선택했다. 돌아다님과 소진의 구체적 번역은 비고에 보존한다.|
|H5795 염소만을 대표어로 선택|기본 암염소 풀이를 지우지 않는다. 범주적 쓰임은 비고에 두며 모든 복수형이 성별 중립이라고 일반화하지 않는다.|
|암염소[문맥에 따라 염소류]라는 긴 meaning|필요한 설명을 meaning에 괄호로 누적하기보다 짧은 대표어와 비고로 나눈다.|
|암염소·염소·숫염소·새끼 염소를 모두 독립 sense로 분리|구문 구성어·문법적 수·문맥상의 성별과 나이를 어휘 자체의 독립 meaning으로 과도하게 나누지 않는다.|
|H5799 새 hold 설정|사용자가 채택하지 않았다. 명칭을 승인하고 정확한 지시 대상·어원은 비고로 설명한다.|
|H5799를 떠나는 염소·악령·특정 장소로 확정|경쟁하는 의미·어원·대상 분석 중 하나를 명칭 승인에 자동 포함하지 않는다.|
|H235→H237을 asserted로 생성|전통적 파생 설명은 보존하되 명칭·본문 분석의 경쟁을 반영해 hypothesized로 한정한다.|
|Strong의 모든 from을 관계로 생성|H5795 비교 어원 및 H5799 경쟁 분석을 함께 고려했다. reference 화살표와 의미 방향도 구별했다.|

## 남은 불확실성 및 재검토 조건

H235 겔27:19의 독법, H236 단2:24의 분사/완료 형태 분석 차이, H237의 명칭·지시 표현/다른 본문·파생, H5795의 비교 어원 및 삼상19:13·16의 LXX 간/MT 털 읽기는 남겨 둔다. H5799의4토큰에 명칭을 배정한 것은 어원과 지시 대상4건의 해석이 새로 해결됐다는 뜻이 아니다. 명칭 승인과 불확실성 설명을 함께 보존한다.

전역 재귀 discovery는 발견28·관계27·frontier12·research_complete=false로 남아 있다. H5810의 강함/인명군과 H3050 신명 hub를 경계로 CORE6·CONTEXT1·허브 제외21을 구별했고 이번 승인은 CORE6에 한정한다. 원본 state·packet·Review를 수정하거나 전역 closure 완료로 표시하지 않았다.

새 원문·본문비평·사전·비교언어 자료가 현재 어휘 식별·일반 의미·관계 강도를 실질적으로 바꿀 때 해당 쟁점을 재검토한다. 단순 번호 인접성·번역 문체·표기 취향만으로 승인값이나 기존 비생성 결정을 자동 변경하지 않는다.

## 적용 및 검증 근거

- 공식 dry-run: 사본 적용14건·undo 성공·원본 work/seed 불변, 유지 승인1건 확인. 기존 applicator 테스트31개 통과. sandbox 임시 경로와 flutter.bat 초기화 문제는 필요한 접근 권한과 동일 공식 Flutter snapshot runner로 해결했으며 테스트 구현은 변경하지 않았다.
- 공식 live apply1회 성공. History group `1793085083840651`, ID7062–7075, word update11·relation create3·undone0.
- 독립 SQL49조회·339검증: 전체13테이블·DDL·byte 백업·공식 snapshot 대조, 승인 projection·history·필요한 sequence 외 변화 없음. integrity ok·FK0·sidecar 없음·seed 불변. 신규 relation history에 SQL DEFAULT created_at이 포함되지 않는 현행 계약을 구별해 검증했다.
- 보호 입력196개 중 승인 work DB 외 불변, 신규 LF 속성 확인, 원본 연구35파일 불변.
- Work SHA `5cad2469e7a2947a09b2bb3d71dd5577b3202dca4e2f3be79fed06ff93c6bf7a` → `15cf33252266e35704b5a6c5188c5724fe50b2c171b0728ae2036e09e280bca4`.
- Seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1` 불변. Manifest SHA `aac744dd8f0a744b806ee8165924217b819d8a0643943ed0af7ff59fe7cfd63b`는 적용 사본과 현재 LF bytes가 일치한다.
- 표준 progress JSON·CSV·Markdown: 승인670→676·미승인13622→13616·hold6·anomaly113·전체14298. 대상6개와 비대상14292행, 기존119개 승인 authority, lexical index·anomaly를 대조했다. 공식 renderer3종 exact 일치 및 독립42검증 통과.
- Snapshot identity: `91b970fb63b126994f5f616b73306b18024db0f8ae8a3bddba2f2475581fe882`.
- Work DB는 Git 미추적 로컬 자산이며 seed 교체·앱 배포·전체 빌드·사용자 UI 테스트는 N/A다. 이 기록과 README 색인은 같은 승인 manifest의 결정 근거로 함께 보존한다.
