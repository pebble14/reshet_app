# relation_default_pilot_manual_checklist

## 목적
- 이번 파일럿은 DB 정제가 아니라 "검증 가능한 분류 기준"을 확인하는 단계다.
- 아래 체크는 `draft_update_word_relation_pilot.sql`을 실행하기 위한 것이 아니라, 초안의 타당성을 사람이 다시 검토하기 위한 절차다.

## 대표 후보 10건
- 대표 10건 id: `3, 4, 5, 10, 28, 48, 5369, 5371, 7482, 7488`

```sql
SELECT wr.id,
       wr.word_id_1,
       wr.word_id_2,
       wr.category_code,
       wr.relation_type,
       wr.direction_code,
       wr.source,
       w1."언어" AS lang1,
       w1."표기1" AS form1,
       w1."음역1" AS trans1,
       w1."의미1" AS meaning1,
       w2."언어" AS lang2,
       w2."표기1" AS form2,
       w2."음역1" AS trans2,
       w2."의미1" AS meaning2
FROM WORD_RELATION wr
JOIN WORD_TABLE w1 ON w1.id = wr.word_id_1
JOIN WORD_TABLE w2 ON w2.id = wr.word_id_2
WHERE wr.id IN (3, 4, 5, 10, 28, 48, 5369, 5371, 7482, 7488)
ORDER BY wr.id;
```

## direction 제안 건 전용 조회
- 아래 15건만 SQL 초안에 포함됐다.
- 각 행은 `direction_code`가 실제로 `word_id_1`/`word_id_2` 기준과 맞는지 따로 본다.

```sql
SELECT wr.id,
       wr.word_id_1,
       wr.word_id_2,
       wr.category_code,
       wr.relation_type,
       wr.direction_code,
       wr.source,
       w1."언어" AS lang1,
       w1."표기1" AS form1,
       w2."언어" AS lang2,
       w2."표기1" AS form2
FROM WORD_RELATION wr
JOIN WORD_TABLE w1 ON w1.id = wr.word_id_1
JOIN WORD_TABLE w2 ON w2.id = wr.word_id_2
WHERE wr.id IN (
  3, 4, 5, 10, 13, 23, 28, 32, 48,
  5369, 5371, 5382, 5383, 7482, 7488
)
ORDER BY wr.id;
```

## 검증 항목
1. Wiktionary entry가 실제 row의 표제어와 일치하는지 확인한다.
2. 기록한 section 이름이 실제 근거 위치와 맞는지 확인한다.
3. word1/word2 의미가 Wiktionary 설명과 대응되는지 확인한다.
4. 동일 철자라도 sense mismatch가 없는지 확인한다.
5. 이름/음차 계열은 "의미"보다 "원어에서 옮겨온 경로"를 우선 본다.

## direction 검증
1. `w1_to_w2`는 "word_id_1 쪽이 source, word_id_2 쪽이 target"인지 다시 읽는다.
2. `w2_to_w1`는 반대로 읽어도 근거가 유지되는지 확인한다.
3. compound/derived 계열은 "기저어 -> 파생어" 방향으로 읽히는지 다시 본다.
4. transliteration 계열은 "원어 -> 옮겨진 표기" 방향인지 다시 본다.
5. 애매하면 `unknown` 유지로 되돌리고 SQL 후보에서 제외한다.

## SQL 검증
1. 각 `UPDATE`에 기존값 가드(`unspecified/related/unknown`)가 모두 들어 있는지 확인한다.
2. `confidence=낮음` 행이 SQL 초안에 들어가지 않았는지 확인한다.
3. `sql_ready=no` 행이 실수로 SQL에 들어가지 않았는지 확인한다.
4. category/type 조합이 실제 lookup 체계와 일치하는지 확인한다.
5. `loan_translation`, `borrowed_from`, `direct_transliteration`, `derived`, `variant`, `compound`가 category와 맞게 들어갔는지 확인한다.

## 안전성 검증
1. DB 직접 수정이 없었는지 확인한다.
2. `.db` 파일이 바뀌지 않았는지 확인한다.
3. SQL 초안 파일만 생성되었고 실제 실행 로그는 없는지 확인한다.
4. `git status --short`에 `data/reshet_work.db`가 나타나지 않는지 확인한다.
5. 필요하면 아래 읽기 전용 확인을 다시 실행한다.

```powershell
git status --short
git diff --name-only
Get-Item data\reshet_work.db | Select-Object FullName, Length, LastWriteTime
```

## 우선 수동 검토 5건
- `19`: 이름 음차 패턴은 강하지만 Greek lemma etymology 확보가 부족하다.
- `97`: Greek -> Latin 차용으로 보이나 Latin 쪽 직접 근거를 한 번 더 닫는 편이 안전하다.
- `5368`: transliteration / calque / semantic matching이 섞여 code 선택이 가장 위험하다.
- `7480`: 개명(아브람 -> 아브라함)을 lexical variant로 넣을지 정책 확인이 필요하다.
- `7543`: 단일 lemma와 전체 구문을 연결한 row라 현재 code 체계와 가장 잘 충돌한다.
