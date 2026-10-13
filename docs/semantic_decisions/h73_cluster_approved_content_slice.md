# H73 클러스터 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정·DB 적용일: 2026-10-13
- 문서·Git 마무리일: 2026-10-14
- 대상: CORE1 `H0073`, word_id `H0073_0000`, אַבְנֵט
- 승인 manifest: [h73_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h73_cluster_approved_content_slice.json)
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 기존6건 유지·신규 hold 없음
- 로컬 연구 산출물: `C:/Users/kkiih/Documents/Workspace/FlutterWorkspace/reshet_research_output/H0073_cluster_20261013_69935b6e`
- 승인 원문·실행 로그·독립 검증: `data/backups/approved_content_batch/h73_approval_20261013/`
- 공식 적용 snapshot·result: `data/backups/approved_content_batch/20261013T111858887270Z/`
- 실제 적용 DB: `data/reshet_work.db`, history group `1791890340110875`

## 최종 결정

사용자는 착용 위치를 허리로만 한정할 수 있는지 재검토한 후의 최신 제안과 문서·DB·Git·작업 브랜치 정리까지 승인했다. 초기 연구의 `허리띠` 추천은 채택하지 않았다.

| 항목 | 적용 전 | 최종값 |
|---|---|---|
| meaning seq1 | 띠, 허리띠 | 띠 |
| word note | NULL | 아래 비고 |

> 옷 위로 몸통에 둘러매는 띠로, 제사장과 관리의 복장에 쓰인다. 요세푸스는 제사장의 띠를 가슴 부근에 둘러매는 것으로 설명하므로, 착용 위치를 허리로만 한정하지 않는다.

Meaning 교체1건·비고 교체1건을 적용했다. 기존 meaning은 쉼표를 포함한 한 행이었으므로 sense 두 개를 병합한 것은 아니다. 관계는 기존0건을 유지하고 신규 관계·word hold를 만들지 않았다. 표현 `אַבְנֵט`, 음역 `아브네트`, 발음·언어·품사와 다른 단어는 보존했다.

## 핵심 판단 근거

- Canonical OSHB의 전체9토큰/9절을 검토했다. 출28:4·28:39·28:40·29:9·39:29, 레8:7·8:13·16:4의 8회는 제사장 복장이고 사22:21의 1회는 관리의 복장이다. 모두 옷 위에 두르는 띠로 설명할 수 있지만 이 본문들만으로 착용 위치를 허리로 한정할 근거는 충분하지 않다.
- [BDB H73 항목](https://biblehub.com/bdb/73.htm)은 가슴 둘레에 여러 번 감는 sash를 설명하며 요세푸스 『유대 고대사』3.7.2를 인용한다. [요세푸스 해당 문맥](https://penelope.uchicago.edu/josephus/ant-3.html)은 제사장의 띠를 가슴 부근에 여러 번 두르고 끝을 아래로 늘어뜨리는 것으로 설명하며 Abaneth라는 이름과 연결한다. 따라서 허리 전용이라는 제한을 의미에 넣지 않고 `띠`와 기능·착용 범위 비고를 채택했다.
- Canonical HebrewStrong은 belt/girdle을 제시하고 어원을 불확실한 것으로 표시한다. Structured lexical reference가 없으며 양방향 관계 발견도0건이다. 인접 Strong 번호나 다른 띠와의 동시 출현만으로 관계를 생성하지 않는다.
- 레8:7의 에봇 장식띠 H2805는 H73과 같은 절에 별도로 나온다. 한국어 번역어가 같다는 이유로 같은 어휘로 합치지 않는다. 사22:21의 권한 이양은 문맥 기능이므로 `직책`·`권력`을 별도 meaning으로 추가하지 않는다.
- LXX는 수동 참고자료다. 출39:29에 해당하는 제작 문맥은 로컬36:36에서 대조했고 사22:21은 왕관 계열 표현 차이가 있다. 이를 H73의 새 의미나 자동 히브리어–헬라어 관계로 승격하지 않았다.
- 표기 검토: `띠`는 고유어여서 한자 병기 N/A다. 고유명사 병기·합성 붙임표·새 발음 표기 역시 N/A다. 의미는 한 행에, 착용 범위와 근거는 비고에 두었으며 기존 표현·셰와·발음값을 변경하지 않았다.

## 채택하지 않은 주요 대안

- `허리띠`: 익숙하고 구체적이지만 가슴 부근 착용 설명까지 포괄하는 표제 의미로는 좁다. 초기 추천을 철회했다.
- `띠, 허리띠`: 기존값 자체가 명백한 오류는 아니지만 같은 sense의 중복 gloss를 남기기보다 `띠`로 간결하게 정리했다.
- `제사장용 띠`: 사22:21의 관리 용례를 포괄하지 못한다. `수놓은 띠` 역시 모든 용례에 장식 조건을 부여하므로 채택하지 않았다.
- `허리띠·가슴띠`를 별도 의미로 분리: 착용 위치 차이만으로 독립 sense를 늘릴 근거가 부족하다. `띠`와 비고가 함께 범위를 설명한다.
- 초기 비고의 H2805 비교·어원 설명은 연구 근거에 보존하고, 승인된 앱 비고에는 최신 착용 범위 설명을 사용했다.

## 남은 불확실성 및 재검토 조건

- 요세푸스는 구약 본문보다 후대의 증언이다. 그의 설명을 구약9개 용례 각각의 정확한 착용 방식으로 소급 확정하지 않는다. 본문·고대 의복 자료가 특정 용례의 착용 위치를 더 명확히 밝혀 주면 비고를 재검토할 수 있다.
- 정확한 어원·차용 경로와 일부 참고사전의 원천 언어 추정은 미확정이다. 독립적인 형태·역사언어학 증거가 확보되면 관계 후보를 다시 검토한다. 현재의 의복 의미 승인을 막는 word hold 사유는 아니다.
- 로컬 번역본의 unverified versification profile, LXX의 미검증 provenance·license와 수동 대응 한계를 보존한다. 새 canonical source로 도입하지 않았다.
- 발견은 singleton closure1·frontier0·resume0이며 discovery/research_complete=true다. 이는 현행 structured source graph와 확보한 증거의 연구 완료이며 모든 역사적 어원 문제가 해결됐다는 뜻은 아니다.

### 적용 검증

공식 dry-run의 사본 적용·undo와 live apply가 성공했다. History2행은 H73 word update이며 undone0이다. 독립 SQL43조회·148검증으로 전체13테이블과 schema·snapshot·비대상 행을 대조했다. 승인된 meaning·비고와 history·관련 sequence 외 차이 없고 모든 표현·관계·기존 history를 보존했다. Work·seed·snapshot integrity ok·FK0·sidecar0, seed SHA 불변이다. 원천·기존 승인·machine evidence113파일도 불변이다. 기존 applicator Flutter 테스트29건이 통과했다.

공식 progress JSON·CSV·Markdown을 함께 갱신하고11항목으로 검증했다. 14,298행 중 H73만 explicit_approved로 바뀌어 승인260→261·hold6·미승인14,032→14,031·anomaly113이다. 모든 비대상 행 불변과 공식 CSV/Markdown 렌더 일치를 확인했다. Snapshot identity는 `c638d45450ed185786967956e30c6af6982ad86eb80b8b1b5146651859e4059f`다.

문서 영향은 이 결정 기록·색인·DATA_PROVENANCE와 외부 연구 요약에 한정한다. DB는 기존 정책에 따라 Git 미추적 로컬 자산이며 Git에는 승인 manifest와 관련 문서를 보존한다. 앱 코드·schema·seed 변경이 없어 UI 테스트·앱 빌드는 N/A다. 승인된 Git 공개는 main fast-forward 방식으로 진행하며 실제 커밋은 Git 이력에서 확인한다.
