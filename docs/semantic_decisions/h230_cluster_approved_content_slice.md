# H230 확고함 의미·비고 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-26 (Asia/Seoul)
- 대상: H0230_0000, 아람어 אֲזָד
- 승인 manifest: [h230_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h230_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 로컬 연구 산출물: `reshet_research_output/H0230_cluster_20261026_98bd347f/`, 추천 revision `H0230-r1-20261026`; Full Review·cluster summary·보충 assessment
- 승인 원문·적용 전 byte 백업·독립 검증: `data/backups/approved_content_batch/h230_approval_20261026/`
- 공식 적용 receipt: `data/backups/approved_content_batch/20261026T124931534739Z/result.json`

## 최종 결정

사용자는 직전 Codex r1 추천안에 이어 DB·문서·기타 파일 반영과 검증, Git 작업 및 이번 작업 브랜치 정리까지 지시했다. 추천한 meaning1·비고1, 관계 생성 없음·hold 없음 안을 승인 범위로 고정하여 적용했다. 사용자 개인의 별도 선택 이유를 추정하지 않는다.

|Strong|변경 전 meaning|최종 ordered meaning|sense|hold|
|---|---|---|---:|---|
|H0230|가버리다, 떠나다|seq1 `확고하다(確固하다)`|1|없음|

최종 비고 전문:

> 아람어 형용사로, 단 2:5·8에서는 왕의 말이나 결정이 확고히 정해져 있음을 나타낸다. ‘명령을 내리다’는 구문 전체의 번역이다. KJV와 일부 고대 번역은 ‘떠났다’로 옮기며, ‘이미 공표되어 알려졌다’라는 대안 분석도 있다. 이 단어만으로 왕이 꿈을 잊었다고 단정하지 않는다. Strong은 어원을 불확실하다고 하며, 페르시아어 차용설도 확정하지 않는다.

신규·교체·삭제 관계0, 새 hold·hold 해제·supersession0이다. 기존 relation도0이며 새 category/type/status/direction 값을 만들지 않는다. 원문 expression·음역·발음·언어·Strong identity·비대상 어휘·기존 관계·hold ledger·schema·seed·앱 코드는 보존했다. 어휘 meaning의 승인은 원자료 필드 변경이나 seed 배포 승인을 뜻하지 않는다.

## 핵심 판단 근거

- Canonical Strong XML의 H230 entry는 아람어 형용사로 분류하고 meaning `firm`, usage `be gone.`, source `of uncertain derivation`을 구분한다. Usage에 보존된 번역 표현을 lexical definition과 동일시하지 않았다.
- OSHB의 canonical2토큰은 단2:5·8이며 모두 `AAafsa`(아람어 형용사·여성·단수·절대형)다. 단2:1–13의 문맥을 확인했다. 두 절은 같은 표현의 반복이므로 서로 독립된 다양한 문맥의 증거로 과장하지 않는다.
- 왕이 처벌·보상 조건을 제시하고 이후 시간을 끄는 술사들에게 그 결정을 재확인하는 구문을 `확고하다` 한 meaning으로 설명한다. 말·명령은 H4406이 담당하며, 단2:8 도입의 분명히는 H3330이 담당한다. 문장 전체의 명령을 내리다·꿈을 잊다를 H230의 독립 뜻으로 옮기지 않는다.
- HebGrkKo exact1행과 KJV·개역개정·개역한글·새번역·원전분해의 각2절 전문·각주·형태 자료를 전량 비교했다. HebGrkKo의 이동 동사 설명 및 KJV의 떠남 독해를 반대 자료로 보존했다. 같은 두 token의 경쟁 독해를 입증된 복수 sense로 저장하지 않았다.
- LXXStp의 명시적 두 조회를 수동 비교했다. 단2:8에는 떠남 표현이 있지만, 그것만으로 꿈이 왕의 기억에서 사라졌다고 단정할 수 없다. 단2:5에서는 아람어 구문의 직접 대응 표현을 식별하지 못했으며 자동 Hebrew–Greek alignment·Strong·신약 연결을 만들지 않았다.
- [NET 단2:5 번역자 주석](https://classic.net.bible.org/passage.php?passage=Dan+2%3A5), [BDB 항목 재전재](https://biblehub.com/hebrew/230.htm), [Regalado 논문](https://publicaciones.uap.edu.ar/index.php/davarlogos/article/view/357)의 관련 부분은 확고함·공표 해석과 품사 분석의 차이를 보여 준다. 논문 전문 및 원파피루스를 직접 전량 읽은 것으로 기록하지 않는다. NET에 인용된 사전·문법 전문도 직접 열람한 것이 아니다.
- [국립국어원 한국어기초사전](https://krdict.korean.go.kr/eng/dicSearch/SearchView?ParaWordNo=87318&nation=eng)에서 확고하다의 형용사 품사와 確固를 확인했다. 원어와 한국어의 형용사 기능을 보존하며, 고유명사 표기·새 음역·발음 변경은 N/A다.
- [H108 결정](h108_cluster_approved_content_slice.md)의 경쟁 독해를 비고에 보존하는 원칙을 대조했다. 당시 특정 대표값의 선택을 복사하지 않고 H230 자체의 근거로 대표 의미를 선택했다. H236의 이동 동사와의 동일 어근, H3330과의 완전 동의, H4406과의 어휘 관계는 이번 근거만으로 새로 승인하지 않았다.

## 채택하지 않은 주요 대안

|대안|채택하지 않은 이유·보존|
|---|---|
|기존 가버리다, 떠나다 유지|번역 전통의 근거가 있으나 정본 definition·형태·왕의 결정 문맥을 충분히 반영하지 못한다. KJV·고대 번역의 대안은 비고에 보존했다.|
|확실하다(確實하다)|sure/assured와 겹치는 유효한 후보이나, 정보의 참/거짓보다 굳게 정해진 결정이 두 문맥에서 두드러져 확고하다를 선택했다.|
|공표되다·알려지다로 교체|명사·부사·형용사 분석 차이와 연결되는 진지한 대안이다. 배타적으로 기각하지 않고 비고에 보존했다.|
|확고함·떠남·공표의 여러 sense|같은 두 용례에 대한 경쟁 분석을 검증된 다의성처럼 저장할 수 있어 분리하지 않았다.|
|돌이킬 수 없다만 저장|왕의 결정 문맥에는 맞지만 어휘 전체를 불가역성으로 과도하게 한정할 수 있다. 확고히 정해짐을 비고에서 설명했다.|
|H230–H236 또는 Greek/Persian 항목 관계 생성|정본 structured reference0이며 실제 파생·동일 어근·정확한 차용·번역 pair를 승인할 충분한 근거가 없다.|
|word-level hold|Strong identity·일반적인 대표 의미를 선택할 수 있으며 구체적 통사·어원 불확실성은 비고에서 범위를 한정할 수 있다.|

## 남은 불확실성 및 재검토 조건

전체 canonical2회·검토2·미검토0이다. 추천 독해의 주 배정은 sense1=2·미배정0이며, 두 token 모두 대안 분석과 세부 문장 해석의 미해결 태그가 겹친다. 미배정0은 모든 문장 해석이 해결됐다는 뜻이 아니다. 확인한 범위에서 추천을 반드시 철회시킬 확정 반례는0이나 경쟁 해석은 존재한다.

정확한 품사·통사와 공표 독해, 페르시아어 차용의 형식·시기, 고대 번역의 해석 과정, 왕의 실제 기억 상태는 미확정이다. Strong의 uncertain derivation을 보존한다. 관련 자료의 명사·부사 분석을 숨기지 않으며 원파피루스나 모든 문헌을 검토했다고 주장하지 않는다. 원어·음역·발음에 관한 자동 교정도 하지 않는다.

LXXStp의 판본·upstream provenance·license와 일부 한국어 자료의 전역 reference profile은 미확인 경계를 유지한다. 자동 join 성공과 전역 profile 검증은 다르다. CAL의 exact target entry는 열람하지 못했으므로 그 검색 결과를 의미 근거로 사용하지 않았다.

새로운 비판 사전·문법·동시대 용례·판본 근거가 경쟁 분석을 실제로 판별하거나 사용자가 공표 독해를 대표로 선택할 때 재검토한다. 같은 번역 표현의 반복·번호 인접성·표기 유사성·일반 정책 변경만으로 의미 수나 관계를 자동 변경하지 않는다.

### 적용·검증

공식 dry-run 사본 적용2건·실제 undo·원본 DB byte 불변과 기존 applicator 회귀 테스트31개 통과 후 live apply를1회 수행했다. 제한 환경의 임시 사본 생성 권한 오류는 동일 공식 dry-run을 정상 환경에서 재실행하여 해결했으며 live apply 실패로 취급하지 않았다.

독립 SQL55조회·59검증·전체13테이블/DDL/byte 백업/공식 snapshot 대조에서 승인 meaning·비고·history2·history sequence 외 변화가 없다. History group `1793018972830628`, ID7008·7009는 word update2·undone0이다. Integrity ok·FK0·sidecar 없음·seed 불변·원본 연구9파일과 보호 입력222개 중 work 외 입력 불변을 확인했다.

Work SHA `98bd347fbf4bf0896c19196605f1cd3c41f8f666c37d3ec4fe4ad2cba7801bbf` → `2a48feb4e49908021380e1c874781618b6d721c295eba5175097a35ccdd09175`; seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1` 불변이다. Manifest SHA `7e862bfc678ded0faa03c93cf6ecab4dd7abede9176a97f88f195877b5a241b1`는 현재 파일·적용 사본·Git index가 일치한다. 해당 파일의 CRLF bytes를 Git에서도 그대로 보존하도록 파일별 `-text whitespace=cr-at-eol` 속성을 사용했다.

표준 progress JSON·CSV·Markdown은 공식 도구로 갱신했고 독립25검증·공식 renderer exact 대조를 통과했다. H0230만 새 승인되어650→651·미승인13642→13641·hold6·anomaly113·전체14298이다. 비대상14297행·기존 authority·lexical index·anomaly는 exact 불변이며 snapshot identity는 `a790930f1b937c197f0bff4cf7ddfd76ae5f4b5f1f6c440a79f56e2acea8a332`다.

Work DB는 Git 미추적 로컬 자산으로 유지한다. 앱 코드·UI·schema 변경, seed 교체·배포·전체 빌드·사용자 UI 테스트는 N/A다. 상세 evidence는 외부 연구 파일과 로컬 승인·검증 폴더에 보존한다.
