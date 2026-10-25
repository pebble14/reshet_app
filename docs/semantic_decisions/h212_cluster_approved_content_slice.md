# H212 바퀴 의미 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-25 (Asia/Seoul)
- 대상: H0212
- 승인 manifest: [h212_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h212_cluster_approved_content_slice.json)
- 관련 hold ledger: [semantic_research_dispositions.json](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음·신규 hold 없음
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 로컬 연구 산출물: `reshet_research_output/H0212_cluster_20261025_f62903af/`; 전체 cluster summary, H212 Packet·Full Review·관계 evidence, 35토큰 분류, 21절 원문 및 로컬·LXX 비교
- 승인 원문·적용 전 byte 백업·독립 검증: `data/backups/approved_content_batch/h212_approval_20261025/`
- 공식 적용 receipt: `data/backups/approved_content_batch/20261025T000903559396Z/result.json`

## 최종 결정

사용자는 연구 추천안을 그대로 채택하고 DB·문서·기타 필요 파일 반영, Git 게시와 이번 작업 브랜치 정리까지 승인했다. 아래 값은 실제 적용과 독립 검증을 완료한 최종 상태다.

| Strong | 최종 ordered meaning | sense | word note | 처리 |
|---|---|---:|---|---|
| H0212 | 1. `바퀴` | 1 | NULL 유지 | meaning 한 행 교체·승인 |

기존 `바퀴, 수레바퀴`도 한 meaning 행이었다. 이번 결정은 여러 sense의 병합이 아니라 동일 기본 의미 안에서 번역어 중복을 줄이는 선택이다.

신규·교체·삭제 관계는 모두 0개다. Category/type/status/direction은 N/A이며 기존 관계와 hold ledger를 유지한다. H0212에 새 hold를 만들지 않는다. 동일 entry의 축약 표기 `אֹפָן`을 별도 단어 관계로 만들지 않고, 번호 없는 미사용 어근을 현존 Strong으로 추정하지 않는다. 겔10:13의 H1534와도 이번에 관계를 생성하지 않는다.

변경 범위는 `H0212_0000`의 meaning replacement 1건이다. NULL 비고, expression·음역·발음·언어, 비대상 어휘, schema, seed, 앱 코드를 유지한다. Work DB는 Git 미추적 로컬 자산이며 Git에는 승인 manifest·이 결정 기록·색인·provenance와 manifest의 LF byte 보존 속성을 게시한다.

공식 dry-run에서 의미 교체1·history1·undo·원본 DB 불변을 확인한 뒤 기존 applicator 테스트31개가 통과했다. 실제 적용은1회이며, 이후 독립 SQL53조회·53검증에서 전체13테이블을 적용 전 byte 백업 및 공식 snapshot과 대조했다. 승인 meaning·word history1·history sequence 외 데이터 변화는 없었다. History group `1792886944866467`, ID `6862`는 H0212의 word update1이며 undone은 없다. Integrity ok·FK0·sidecar 없음·seed 불변, 보호 입력202개·원본 연구15파일 불변을 확인했다.

표준 progress JSON·CSV·Markdown과 독립19검증·공식 renderer 대조에서 H0212만 신규 승인됐고 비대상14,297행·anomaly·lexical index는 exact 불변이다. 승인595→596·미승인13,697→13,696·hold6·anomaly113·전체14,298이며 snapshot identity는 `71898c3e93c5219ec485314579f3b43f9547b160ef16eb94cff031475e4e6c66`다. Flutter UI 코드 변경이 없으므로 앱 UI 테스트와 배포는 N/A다.

## 핵심 판단 근거

- Canonical Strong의 H212는 히브리어 남성명사 `אוֹפָן`, 정의는 `a wheel`, usage는 `wheel.`이다. 원문은 축약 표기 `אֹפָן`과 `from an unused root meaning to revolve`를 보존한다. 어원에서 회전을 언급한다고 동사 meaning이나 특정 Strong 관계를 추가하지 않는다.
- OSHB canonical 전체35토큰·21절을 검토했다. 전쟁 병거2, 성전 받침수레 문맥6(병거 바퀴 비교1 포함), 타작 문맥2, 에스겔 환상25이며 모두 `바퀴`로 설명된다. 미분류·의미상 ambiguous·추천을 뒤집는 lexical 반례는0이다. 수·연계형·관사·전치사·접속사·소유 접미사 차이는 별도 sense가 아니다.
- 병거·타작 기구·성전 기구·환상의 지시 대상과 기능 차이는 기본 명사 안에서 설명할 수 있다. 사28:27의 `수레`는 H5699이고 H212는 그 바퀴다. 잠20:26의 악인 심판은 바퀴 이미지의 문맥적 적용이며 독립 meaning을 심판이나 타작기 전체로 늘릴 근거로 삼지 않는다.
- 겔10:13에서 H212는 `그 바퀴들`, `도는 것`에 해당하는 별도 어휘는 H1534다. 겔10:6에서도 두 어휘의 token을 구별했다. 한국어 번역 표현이나 문맥상 명명만으로 H212에 별도 meaning 또는 두 단어 사이의 전면적 동의·파생 관계를 만들지 않는다.
- HebGrkKo exact1행 및 개역개정·개역한글·KJV·새번역·원전분해의 적용 가능35토큰·21절 전량을 비교했다. 한국어의 병거바퀴·타작하는 바퀴·대명사화, 영어의 관사·전치사 차이는 문맥 번역으로 구분했다. LXX21개 explicit 조회 중 문맥 일치18개를 제한적으로 활용하고 내용 불일치3개를 제외했다. Sampling이나 자동 Hebrew–Greek alignment는 사용하지 않았다.
- `바퀴`는 고유어이며 한자 병기·고유명사 병기·합성 붙임표는 N/A다. 의미가 충분하므로 용도 목록·어원·연구 판단을 반복하는 word note를 만들지 않고 NULL을 유지했다. Expression·발음 필드의 추가 정비는 승인 범위가 아니다.
- 사용자가 이 추천안과 그 근거를 최종 채택했다는 사실을 기록한다. 사용자가 말하지 않은 개인적 판단 이유를 부여하지 않는다.

## 채택하지 않은 주요 대안

- 기존 `바퀴, 수레바퀴` 유지: 전체 용례를 설명하는 수용 가능한 대안이며 오류로 판정하지 않는다. 다만 수레바퀴가 같은 기본 의미의 구체화이므로 대표 의미를 더 간결한 `바퀴`로 선택했다.
- `수레바퀴`만 사용: 병거·타작·성전 받침수레에는 직관적이지만 에스겔 환상25회를 구체적인 수레 부품으로 과도하게 제한할 수 있어 단독 대표 meaning으로 채택하지 않았다.
- 환상용·타작용 바퀴를 별도 sense로 분리하거나 `수레·타작기·심판` 추가: 용도·담화 기능·주변 어휘를 H212 자체의 독립 의미로 승격할 필요가 확인되지 않았다. 문맥 차이는 상세 연구에 보존했다.
- word note에 용도·어원 목록 추가: 기존 기본 의미로 포괄되며 반복 가치가 낮아 채택하지 않았다. 특정 본문 및 자료의 제한은 아래와 원본 연구에 보존한다.
- H1534와 동의어·어근 관계 생성: 겔10:13의 지시·명명 대응만으로 전면적 관계를 확정하지 않는다. 미사용 어근에 임의 Strong을 연결하는 대안도 채택하지 않았다.
- word 전체 hold: 의미와 품사는 충분히 명확하고 남은 제한이 단일 meaning을 막지 않아 설정하지 않았다.

## 남은 불확실성 및 재검토 조건

미사용 회전 어근의 실제 identity, 잠20:26의 타작·형벌 이미지 세부 해석, 에스겔 환상 기구의 세부 구조는 이번 의미 승인으로 확정하지 않는다. 의미상 ambiguous0은 이 모든 본문 해석이 해결됐다는 뜻이 아니다.

LXXStp는 upstream provenance·license가 미검증인 human-reference다. 같은 숫자의 왕상7:30·32·33은 대상 히브리어 문맥과 내용이 달라 제외했고 자동 절 재대응을 하지 않았다. 출14:25의 차축 결박 표현은 사건 문맥 참고에 한정하며 H212의 직접 바퀴 어휘 대응으로 세지 않았다. 21조회 중 바퀴 표현 비교17절·출애굽기 표현 차이1절·내용 불일치3절을 구분한다. 로컬 한국어 및 원전분해의 전체 versification profile도 미검증 상태를 유지한다.

HebGrkKo의 잠28:27 인용에는 실제 OSHB H212 token이 없어 reference 오류 가능성으로 남겼다. 이를 조용히 보정하거나 canonical 출현 수를 늘리지 않았다. 원본 Packet·Review·research summary는 승인 후에도 수정하지 않는다.

새 원문·사전·본문비평 자료가 `바퀴`로 포괄되지 않는 독립 lexical sense를 입증하거나 특정 어근·관계를 직접 확인할 때 재검토한다. 번역 표현·단복수·기물 용도·환상 묘사의 차이만으로 sense를 자동 분리하거나 승인값을 변경하지 않는다. 제외한 LXX3절의 mapping 해결은 현재 H212 의미 결정을 바꿀 이득이 낮으므로 별도 필요가 생길 때 다룬다.
