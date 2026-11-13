# H442 알루스 지명 의미·비고 결정

- 상태: active
- 기록 성격: 결정 적용과 동시 작성
- 판단 근거 복원 수준: 높음
- 결정일: 2026-11-13 (Asia/Seoul)
- 대상: H0442 / H0442_0000
- 승인 manifest: [h442_cluster_approved_content_slice.json](../../tool/data_provenance/manifests/h442_cluster_approved_content_slice.json)
- 관련 hold ledger: [현행 ledger](../../tool/data_provenance/manifests/semantic_research_dispositions.json), 변경 없음
- 로컬 연구 산출물: reshet_research_output/H0442_cluster_20261113_3161ba62/ (R1)
- 적용 전 백업·승인 원문·독립 검증: data/backups/approved_content_batch/h442_approval_20261113/
- 공식 receipt·snapshot: data/backups/approved_content_batch/20261113T121606441734Z/

## 최종 결정

사용자는 R1 추천안을 채택하고 DB·문서·기타 필요 파일 반영과 검증, 커밋·작업 branch push·main ff-only 병합·push·이번 작업 branch의 로컬·원격 정리까지 승인했다.

H0442 meaning seq1을 `알루스 (지)`에서 **알루스·알루쉬 (지)**로 교체했다. 같은 지명의 관용명·교재식 근사를 병기한 한 sense다. 비고 NULL은 다음으로 교체했다.

> 출애굽 여정에서 돕가와 르비딤 사이에 머문 광야 야영지다(민 33:13–14). 알루스는 한국어 성경 관용명이고 알루쉬는 히브리어 표제 אָלוּשׁ의 교재식 읽기에 따른 한글 근사다. Strong은 어원을 미상으로 둔다. 참고 사전에는 ‘나는 (빵을) 반죽할 것이다’라는 풀이가 있고, Gesenius는 탈무드에 따른 ‘사람들의 무리’라는 해석을 소개하지만 어느 쪽도 이 지명의 확정된 본뜻으로 채택하지 않는다. 정확한 위치는 현재 자료로 확정할 수 없다.

관계 신규·교체·삭제 0건, 기존 관련 관계 0건, word-level hold 없음. 관계 category/type/status/direction은 N/A다. 원문·음역·발음·언어·schema·seed·앱/UI와 기존 승인들은 보존했다. 기존 결정을 대체하는 작업이 아니므로 supersession 없음.

## 핵심 판단 근거

Canonical HebrewStrong.xml은 n-pr-loc 지명이며 source는 `of uncertain derivation;`다. OSHB 민33:13·14의 두 token을 전량 검토했다. 한 절은 알루스에 도착해 야영하고 다음 절은 이곳을 떠나 르비딤으로 이동한다. 동일 지명 한 sense로 2/2 배정, 미검토·의미 배정 미해결·ambiguous·반례 0이다. 물 부족은 르비딤의 사정이므로 알루스의 meaning에 넣지 않는다.

HebGrkKo exact1, KJV·개역개정·개역한글·새번역·원전분해 각2절, LXX explicit2절을 전량 대조했다. LXX는 지명을 음역하며 human reference / provenance·license unverified 경계를 유지했다. 한국어 로컬33:13 일부 절 범위가 OSHB와 다른 점을 구별했고 H442 표적 자체는 일치했다. BDB 전재의 민23장 표기는 canonical33장과 혼동하지 않았다.

관용명 알루스와 기존 교재식 근사 알루쉬를 함께 보존했다. [표기 정책](../semantic_research/korean_lexical_notation_policy.md), [H325](h325_cluster_approved_content_slice.md)·[H163](h163_cluster_approved_content_slice.md)의 선택 이유와 실제 manifest·DB를 대조했다. 한자나 불확실한 합성 붙임표를 추가하지 않았다. 쉬 계열 근사는 정확한 고대 음성의 재구가 아니다. Source의 x-pn과 DB 언어·본문 사용을 구별한다.

반죽 풀이와 Gesenius의 탈무드에 따른 무리 풀이는 비고에 해석 전통으로 보존하고 어휘의 확정 본뜻으로 채택하지 않았다. 확인한 것은 해당 사전 항목이며 탈무드 원전은 직접 열람하지 않았다. Closure node1·edge0·frontier0, hub 예외 없음이다. 사용자는 이 근거에 따른 추천안을 최종 채택했다.

## 채택하지 않은 주요 대안

- 관용명만 유지: 이름 식별은 가능하지만 이번 기본 병기 기준의 원문 읽기 비교 정보가 빠진다.
- 알루쉬만 사용: 한국어 성경 관용명을 잃으므로 병기를 채택했다.
- 반죽하다·나는 빵을 반죽할 것이다·사람들의 무리: 이름 풀이를 지명의 독립 lexical sense로 승격할 근거가 부족하다. 풀이의 존재와 불확실성은 비고에 보존했다.
- 파생 관계 생성: canonical 참조가 없고 경쟁 이름 풀이를 확정할 근거가 부족하여 생성하지 않았다.
- Word hold: 지명 identity·일반 의미는 충분히 판단 가능하므로 어원·위치의 한계는 비고에 한정했다.

## 남은 불확실성 및 재검토 조건

이름의 어원·기원 언어·정확한 현대 위치·역사적 발음은 확정하지 않는다. 출처가 분명한 전문 어원·지리·비문·본문 근거가 identity나 의미 범위를 실질적으로 바꾸거나 사용자가 읽기 체계를 변경하면 해당 부분을 재검토한다. 번호 인접성·같은 자료 재집계·표기 취향만으로 자동 변경하지 않는다.

### 적용 검증

공식 dry-run·실제 undo·원본 SHA 불변과 적용기 테스트31개 통과 후 live apply1회가 성공했다. 이력 그룹1794572169352080의2행, 전체13테이블·DDL·적용 전 백업·공식 snapshot을 독립 대조했다. 승인 meaning·비고·해당 의미 행 재생성과 이력·기대 sequence 외 변경 없음. Integrity ok·FK0·sidecar0, seed 불변이다.

Work SHA `3161ba621e15c6417b0246e767aedeca5a580864bf53820fa05df5959227aa37` → `ed5789a8068ff1ace2987ba1ea57c8e14fd22bb36d72659248117b0a068c0ab5`.
Seed SHA `a7e0d6a50a3ab6b520c3bf7532b2780cfd6418709d9739a451eb4ce5493fbdb1` 불변.
Manifest SHA `e2c98513b179bff208091ef57dc587e608f67ea7c58e34b9a6ac9dcdfd06cab5`는 실제 적용 사본 및 Git stage 바이트와 일치한다. 해당 경로에 -text를 지정해 바이트를 보존한다.

표준 progress3종을 공식 CLI로 갱신했다. 승인968→969·미승인13324→13323·hold6·anomaly113, H0442 explicit_approved와 최종 의미·비고 일치, 비대상14297행·anomaly·relation index 불변을 확인했다. Snapshot identity `9d843806f7cb2af967bc29387fc477e7233aa54bcf79511061f024a610222484`다. UI 테스트·전체 앱 빌드·배포·seed 교체는 N/A다.
