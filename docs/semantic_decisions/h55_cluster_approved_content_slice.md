# H55 클러스터 결정

- 상태: `active`
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-10-13
- 대상: CORE 1개 `H0055` (`H0055_0000`)의 meaning·비고
- 승인 manifest: [h55_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h55_cluster_approved_content_slice.json)
- 표기 authority: [한국어 어휘 표기 정책](../semantic_research/korean_lexical_notation_policy.md)
- 로컬 연구 산출물: `C:\Users\kkiih\Documents\Workspace\FlutterWorkspace\reshet_research_output\H55_cluster_20261013_16eca623`의 cluster summary, H55 Packet/Review·관계 증거 및 수동 참고자료 보충 Review
- 최종 승인 발췌와 정확한 값: `data/backups/approved_content_batch/h55_approval_20261013/00_approved_content.md`
- 실제 적용 DB: `C:\Users\kkiih\Documents\Workspace\FlutterWorkspace\reshet_app\data\reshet_work.db`
- DB history group: `1791821611143860`

## 최종 결정

사용자는 연구 추천 내용을 승인하고 DB·문서·Git 완료를 지시했다. H55의 meaning seq 1을 ‘휘감아 올라가게 하다’에서 **‘휘돌며 올라가다’**로 교체하며, sense는 1개로 둔다. 비고는 `NULL`에서 다음 정확한 문장으로 바꾼다.

> 이사야 9:18(히브리어 절 번호 9:17)의 히트파엘형으로 한 번만 나타난다. 불타는 수풀이 연기와 함께 휘돌며 올라가는 모습으로 이해되며, 기본 어근의 정확한 뜻은 확정적이지 않다.

새 관계를 생성하지 않고 기존 관계도 교체하지 않는다. H55의 기존 관계는 0건이다. 신규 hold는 없으며 기존 hold ledger는 유지한다. 원문 표현 `אָבַךְ`, 음역 ‘아바크’와 발음·언어는 유지한다.

공식 applicator로 meaning 1건·비고 1건을 적용했다. 독립 전체 13테이블 대조에서 이 두 변경과 history 2행·관련 sequence 증가만 확인했고, 적용 전 snapshot의 전체 projection과 DDL도 일치했다. 표준 progress에서 H55는 `unapproved`에서 `explicit_approved`로 바뀌었다.

## 핵심 판단 근거

- Canonical Strong은 기본 어근이라고만 하며 뜻을 `probably to coil upward`, 용법을 `mount up`으로 제시한다. ‘휘돌며 올라가다’는 회전·말림과 상승을 한 표현에 담고, 확정적이지 않은 기본 어근의 뜻은 비고로 제한한다.
- OSHB 전체 확인에서 유일한 용례는 `Isa.9.17`의 `וַ/יִּֽתְאַבְּכ֖וּ`, lemma `c/55`, morphology `HC/Vtw3mp`다. 히트파엘형과 불타는 수풀·연기의 문맥을 함께 고려하여 외부 사역자를 의미의 필수 요소로 추가하지 않는다. 1/1 용례를 검토했으며 별도 sense를 세울 근거가 없다.
- 적용되는 로컬 참고자료 6종을 모두 확인했다. KJV의 상승 표현, 한국어 번역의 휘돌며 올라가는 표현, BDB의 물음표가 붙은 어근 설명과 연기가 말려 올라가는 해석, NET의 연기와 함께 소용돌이치는 설명은 현재 선택을 지지한다. 사전이나 번역 하나의 표현을 단독 정답으로 취급하지 않는다.
- OSHB는 히브리어 9:17과 KJV 9:18의 대응을 명시한다. 이번 용례에 대해서는 로컬 성경 참고자료 5종의 9:17·9:18을 직접 대조해 화재 문맥을 확인했다. 전체 versification profile의 `unverified` 상태와 자동 도구의 수동 검토 표시는 보존했다.
- Canonical 양방향 lexical index에서 H55의 발견 관계는 0건이고 frontier도 0이다. LXX의 대응 문장 후반은 표현이 달라 H55와 특정 헬라어 어휘를 직접 정렬하지 못했다. 참고 비교어나 문장 단위 유사성을 파생·어근 공유·신약 관계로 확정하지 않는다.

## 채택하지 않은 주요 대안

- **‘휘감아 올라가게 하다’ 유지**: 일부 한국어 참고자료의 문장 번역과 연결되지만, 외부 사역을 기본 의미로 고정한다. 문장 번역의 가능성을 부정하지 않으면서 Strong의 상승·말림과 실제 히트파엘 용례를 포괄하는 현재 표현을 택했다.
- **‘올라가다’**: 여전히 가능한 보수적 표현이고 KJV·Strong의 용법과도 맞는다. 다만 말려 올라가거나 휘도는 양상을 덜 드러내므로, 그 양상을 포함하되 어근의 불확실성을 비고로 밝히는 안을 채택했다.
- **‘돌다 / 회전하다(回轉하다)’를 별도 sense로 추가**: 회전 양상의 해석은 가능하지만 실제 용례의 상승 문맥을 충분히 담지 못한다. 독립된 다른 용례도 없어 별도 sense로 분리하지 않는다.

## 남은 불확실성 및 재검토 조건

기본 어근의 정확한 뜻과 휘돎·말림의 세부 양상은 단일 용례만으로 확정할 수 없다. LXX 문장 차이의 원인과 직접 대응 헬라어도 미확인이다. 이는 현재 의미를 뒤집는 반례로 확인된 상태는 아니므로 신규 hold 대신 비고와 이 기록에 보존한다. 확신도는 중간이다.

신뢰할 원문·본문비평·동족어 연구가 다른 lexical sense나 해당 용례의 다른 분석을 강하게 입증하면 재검토한다. 단순 절 번호·표기 차이, 번역 문체 선호 또는 인접 Strong 번호만으로 자동 변경·관계 생성·hold를 수행하지 않는다. 이 결정은 H55 한 단어에 한정하며 다른 어휘의 기존 승인을 변경하지 않는다.
