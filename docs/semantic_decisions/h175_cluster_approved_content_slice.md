# H175·G2 아론 이름 의미·비고·음역 관계 승인 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-22 (Asia/Seoul)
- 대상: H0175·G0002
- 승인 manifest: [h175_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h175_cluster_approved_content_slice.json)
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음
- 로컬 연구 산출물: `reshet_research_output/H0175_cluster_20261022_c7c39c98/`
- 최신 승인 원문·byte 백업·독립 검증: `data/backups/approved_content_batch/h175_approval_20261022/`
- 공식 snapshot·result·manifest 사본: `data/backups/approved_content_batch/20261022T051143422930Z/`

## 최종 결정

사용자는 두 단어의 의미·비고와 기존 관계 교체를 승인하고, 안전 검증 뒤 DB·문서·필요 파일 반영, 커밋·작업 브랜치 push·main fast-forward 병합·main push와 이번 로컬·원격 작업 브랜치 정리까지 승인했다.

| Strong | 최종 meaning | sense 수 | 현재 음역란 |
|---|---|---:|---|
| H0175 | 아론·아하론 (인) | 1 | 아하론 유지 |
| G0002 | 아론·아하론 (인) | 1 | 아아론 유지 |

가운데점은 동일 인명의 표기 병기다. 두 word_id는 별도로 유지하며 expression·transliteration·pronunciation·언어를 변경하지 않았다. 두 단어 모두 신규 hold 없이 의미 승인했다. 기존 hold 6건과 schema·seed·앱 코드 및 비대상 데이터는 유지했다.

H0175 비고:

> ‘아론’은 한국어 성경의 관용 표기이고 ‘아하론’은 אַהֲרוֹן과 사전 음역을 반영한 원문 기반 근사 표기이다. 모세의 형을 가리키며, 일부 문맥에서는 그 이름으로 제사장 가계를 나타낸다. 이름의 어원은 불확실하다.

G0002 비고:

> 히브리어 인명 H175 אַהֲרוֹן의 헬라어 음역이다. 의미란의 ‘아론’은 한국어 성경의 관용 표기이고 ‘아하론’은 원천인 히브리어 이름을 반영한다. 헬라어 자체의 교재식 음역은 ‘아아론’이다. 자손·반차 문맥에서는 아론의 제사장 계통을 나타낸다.

기존 관계 ID 3을 같은 ID·pair·created_at을 보존하여 다음과 같이 교체했다. 새 관계를 중복 생성하지 않았다.

| 항목 | 변경 전 | 최종값 |
|---|---|---|
| stored pair | G0002_0000 / H0175_0000 | 동일 |
| category_code | unspecified | transliteration |
| relation_type | related | direct_transliteration |
| status_code | inferred | asserted |
| direction_code | unknown | w2_to_w1 |
| source | WORD_TABLE.관련1 | RESHET-EC-H175-CLUSTER-H0175-G0002 |
| description / relation_group_id | NULL / NULL | 동일 |

의미 방향은 **H0175 → G0002**다. 저장 순서는 `G0002_0000 < H0175_0000`이므로 `w2_to_w1`로 나타낸다.

관계 비고:

> Strong G2는 H175의 Hebrew origin을 명시하며 두 항목은 모세의 형 아론을 가리킨다. 방향은 히브리어 이름에서 헬라어 음역으로 향한다. 이름 자체의 더 이른 어원은 이 관계로 확정하지 않는다.

Meaning replacement 2·word note replacement 2·relation replacement 1, 총 5건을 적용했다. Relation create·delete와 hold 변경은 없다.

## 핵심 판단 근거

고정 Strong H175는 모세의 형 Aharon을 뜻하고 어원을 `of uncertain derivation`으로 기록한다. G2는 `of Hebrew origin (H0175)`을 명시한다. OSHB H175 347 token·328절과 TAGNT NA27/28 G2 5 token·5절은 같은 인명과 그 이름으로 표시하는 가계를 한 meaning과 비고로 설명할 수 있다.

H175 전량 문맥 분류는 아들·자손·씨와 결합한 구성 68, 아론의 집 구성 4, 이름만으로 가계를 나타낸 용법 2, 그 밖의 인명 용법 273이다. 대상 12:27(한국어/KJV; OSHB 12:28)·27:17의 가계 용법을 개인 이름과 완전히 분리된 새 meaning으로 늘리지 않고 비고에 보존했다. G2의 눅 1:5 자손, 행 7:40 금송아지 사건, 히 5:4 부르심, 히 7:11 반차, 히 9:4 지팡이도 동일한 이름으로 설명한다.

사용자는 G2 meaning에도 원천 이름인 아하론을 병기하는 것이 기존 방식과 더 일관적이라고 지적했고, 설명을 확인한 뒤 최신안을 승인했다. 따라서 두 meaning을 `아론·아하론 (인)`으로 맞추고 헬라어 자체의 교재식 음역 `아아론`은 기존 음역란에 보존했다. [G1158 등의 전승 이름 표기 결정](h0022_h1841_g1158_analytic_name_notation_approved_content_slice.md)은 전승된 이름에도 원천 이름의 분석 표기를 둘 수 있다는 선례이며, 합성 경계를 다룬 그 결정을 모든 인명의 음역 통일 규칙으로 확대하지 않는다.

관계 방향은 source-reference G2 → H175를 복사하지 않고 이름의 전승 방향 H175 → G2로 판단했다. 동일 인명의 명시적 원천 참조와 현행 인명 관계 분류를 따라 직접 음역으로 승인했다. 이 분류는 모든 음운의 일대일 동일성이나 중간 언어를 배제한 역사적 차용 경로를 새로 입증하는 주장이 아니다.

## 채택하지 않은 주요 대안

- G2 meaning `아론·아아론 (인)`: 헬라어 철자를 보여 주는 타당한 대안이나, 사용자는 의미란에서 원천 이름의 일관된 병기를 선택했다. 아아론은 음역란과 비고에 보존한다.
- 두 meaning을 `아론 (인)`으로만 유지: 인명 식별에는 충분하지만 사용자가 승인한 원천 이름 병기를 반영하지 못한다.
- H175에 아론 가문을 별도 meaning으로 추가: 집·아들·자손 구성과 이름의 생략·환유 용법을 비고로 설명할 수 있어 독립 sense를 늘리지 않았다.
- 총명한을 meaning이나 확정 어원으로 채택: HebGrkKo G2의 어원 풀이를 canonical Strong의 불확실한 어원보다 강한 주장으로 올릴 수 없고, 실제 용례는 인명이다.
- 기존 일반 관련 inferred/unknown 유지 또는 같은 pair에 새 관계 추가: 명시적 원천 이름과 방향을 확인했으므로 기존 한 건을 구체적인 음역 관계로 교체했다. 별도의 root_shared·derived 관계를 생성하지 않았다.

## 남은 불확실성 및 재검토 조건

H175 이름의 더 이른 어원과 역사적 발음은 미확정이다. 아하론·아아론은 원문·사전 또는 교재식 읽기의 한글 근사이며 특정 시대의 실제 발음이나 IPA 재구가 아니다. 합성 구조를 확정할 근거가 없어 이름에 붙임표를 넣지 않았다.

Strong H175의 언어 코드 x-pn과 DB의 히브리어 값은 각각 보존했다. x-pn을 별도의 semantic hold로 바꾸지 않았다. Local 번역·형태 자료의 profile unverified와 LXX Human Reference의 upstream provenance·license 미검증 경계도 유지했다.

LXX는 H175 328절에 대해 369회 명시절 조회와 내용 대조를 수행했다. 최종 323절을 문맥 참고로 사용할 수 있었고, 출 38:21·39:1·39:27·39:41·40:31은 대응 미확정 또는 구절 부재로 제외했다. 레 6:11(OSHB)·민 26:1·수 24:5의 이 참고파일에는 아론 명시가 없는 차이를 보존한다. 이 자료를 canonical occurrence나 자동 Hebrew–Greek alignment authority로 삼지 않았다. 원본 Review의 한국어 자료 34 token·33절 수동 검토 표시는 별도 explicit 조회로 보완했으며 전역 mapping을 확정하지 않았다.

새 원전이 인명 식별·어원·가계의 독립 의미 또는 이름 전승 관계를 실질적으로 바꾸거나 canonical token 오류가 확인될 때 해당 쟁점만 재검토할 수 있다. 번역 문체·대명사·생략·표지 수 차이만으로 현재 결정을 자동 폐기하지 않는다.

## 적용 검증

공식 dry-run은 5건의 사본 적용·undo와 실제 work DB 불변을 확인했다. Applicator 기존 테스트 31건을 통과한 뒤 공식 live apply를 실행했다. 초기 테스트 런타임의 분석 옵션 위치 오류는 옵션을 Flutter 실행기 인자로 옮겨 해소했고 두 실행 로그를 보존했다.

History group `1792645904728292`, ID 6586–6590은 word update 4·relation update 1, undone 0이다. 독립 SQL 53조회·79검증으로 전체 13테이블(사용자 테이블 12개와 내부 sqlite_sequence), DDL·인덱스·byte 백업·공식 snapshot을 대조했다. 승인된 의미·비고·관계·history 및 history sequence 외 변화 없음, integrity ok·FK 0·sidecar 없음이다. 보호 입력 160파일과 원본 연구 22파일은 불변이다. 공식 snapshot의 schema cookie 1368→1369는 VACUUM INTO 계약에 따른 것으로 실제 DDL·적용 전 데이터는 동일하다.

Work SHA `c7c39c98739337dfa6caec01b52d59d5c81504bc07384b802c07d7e269505359` → `64a943b21162e7a216d181af6ae6dcb07a8a6accae2bc025b6ea32d238cfe019`. Seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1` 불변이다. Manifest SHA `dd625aa9d2709f5b509f1b2696bb386ea2fba18af429a3238f971780f0212d47`, 승인 원문 SHA `b427c3d9be6df8a2e2483ef55033d80070920dc0aaf74643b14f8c14b831eabe`이며 신규 manifest의 LF bytes를 보존한다.

표준 semantic_progress JSON·CSV·Markdown 공식 생성과 독립 23검증·renderer bytes 대조가 통과했다. H175·G2만 승인됐고 비대상 14,296행·anomaly·canonical lexical index는 exact 불변이다. Explicit approved 487→489·unapproved 13,805→13,803·hold 6·anomaly 113·전체 14,298이며 snapshot identity는 `e525b334edc0d94da6a9d70a66f624e97043478f51ebe84aa0434066b9e7996a`다.

원본 연구의 최초 G2 아론·아아론 추천은 당시의 연구 이력으로 보존하며, 최종 projection은 이 결정과 승인 manifest를 따른다. Work DB는 Git 미추적 로컬 자산이며 승인 manifest·결정 문서·provenance·색인을 Git으로 게시한다. Seed 교체·앱 배포·전체 빌드·사용자 UX 수동 테스트는 N/A다.
