"""공개 RMAC 설명을 대조하고 seed 전용 번역 목록을 만든다. DB에는 쓰지 않는다."""
import concurrent.futures
import hashlib
import html
import json
import pathlib
import re
import sqlite3
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
BASE = 'https://www.modernliteralversion.org/K4-5/RMAC/'
COLS = ['Part_of_Speech', 'Tense', 'Voice', 'Mood', 'Person', 'Case',
        'Number', 'Gender', 'Degree', 'Form']
# 기존 한글 표를 입력으로 사용하지 않고 공개 영문 설명에서 작성한 번역.
TRANSLATIONS = {'Part_of_Speech': {'ARAMaic transliterated word (indeclinable)': '아람어를 음역한 불변화 단어',
                    'Adjective': '형용사',
                    'Adverb': '부사',
                    'Adverb or adverb and particle combined': '부사 또는 부사와 소사의 결합',
                    'CONDitional particle or conjunction': '조건을 나타내는 소사 또는 접속사',
                    'CONJunction': '접속사',
                    'CONJunction or conjunctive particle': '접속사 또는 연결 소사',
                    'CONJunction or conjunctive particle Negative': '부정을 나타내는 접속사 또는 연결 소사',
                    'Demonstrative pronoun': '지시 대명사',
                    'HEBrew transliterated word (indeclinable)': '히브리어를 음역한 불변화 단어',
                    'INterJection': '감탄사',
                    'Indeclinable NUmeral (Adjective)': '불변화 수사(형용사)',
                    'Indeclinable Noun of Other type': '기타 불변화 명사',
                    'Indeclinable PRoper Noun': '불변화 고유명사',
                    'Interrogative PaRTicle': '의문 소사',
                    'Interrogative pronoun': '의문 대명사',
                    'Negative PaRTicle': '부정 소사',
                    'Noun': '명사',
                    'Noun, Indeclinable Letter': '문자 이름을 나타내는 불변화 명사',
                    'PREPosition': '전치사',
                    'Personal pronoun': '인칭 대명사',
                    'Relative pronoun': '관계 대명사',
                    'Verb': '동사',
                    'correlative or interrogative pronoun': '상관 또는 의문 대명사',
                    'correlative pronoun': '상관 대명사',
                    'definite article': '정관사',
                    'disjunctive PaRTicle': '선택을 나타내는 소사',
                    'disjunctive PaRTicle with “kai”': 'kai가 결합한 선택 소사',
                    'indefinite pronoun': '부정 대명사',
                    'poSsessive pronoun': '소유 대명사',
                    'reCiprocal pronoun': '상호 대명사',
                    'reFlexive pronoun': '재귀 대명사'},
 'Tense': {'Aorist G5777': '부정과거 G5777',
           'Future G5776': '미래 G5776',
           'Imperfect G5775': '미완료 G5775',
           'Present G5774': '현재 G5774',
           'Second Aorist G5780': '제2부정과거 G5780',
           'Second Future G5781': '제2미래 G5781',
           'Second pLuperfect G5783': '제2과거완료 G5783',
           'Second peRfect G5782': '제2완료 G5782',
           'no tense stated (adverbial imperative)': '시제 표시 없음(부사적 명령 표현)',
           'no tense stated (adverbial imperative) (denoted by X) G5799': '시제 표시 없음(부사적 명령 표현, X) G5799',
           'pLuperfect G5779': '과거완료 G5779',
           'peRfect G5778': '완료 G5778'},
 'Voice': {'Active G5784': '능동태 G5784',
           'Either Middle or Passive G5787': '중간태 또는 수동태 G5787',
           'Middle G5785': '중간태 G5785',
           'Passive G5786': '수동태 G5786',
           'impersonal active (denoted by Q) G5905': '비인칭 능동태(Q) G5905',
           'middle Deponent': '중간태 형식의 디포넌트',
           'middle Deponent G5788': '중간태 형식의 디포넌트 G5788',
           'middle or passive depoNent G5790': '중간태 또는 수동태 형식의 디포넌트 G5790',
           'no voice stated (denoted by X) G5799': '태 표시 없음(X) G5799',
           'passive depOnent G5789': '수동태 형식의 디포넌트 G5789'},
 'Mood': {'Indicative G5791': '직설법 G5791',
          'Optative G5793': '희구법 G5793',
          'Participle G5796': '분사 G5796',
          'Subjunctive G5792': '접속법 G5792',
          'iMperative G5794': '명령법 G5794',
          'iNfinitive G5795': '부정사 G5795'},
 'Person': {'First (I)': '제1인칭(나)',
            'First (we)': '제1인칭(우리)',
            'Second (you)': '제2인칭(너)',
            'Second (you)w': '제2인칭(너)',
            'Second (you*)': '제2인칭(너희)',
            'Third (he/she/it)': '제3인칭(그·그녀·그것)',
            'Third (they)': '제3인칭(그들)'},
 'Case': {'Accusative (direct object; motion towar d; time: "how long")': '대격: 직접 목적어·방향·시간의 길이',
          'Accusative (direct object; motion toward)': '대격: 직접 목적어·방향',
          'Accusative (direct object; motion toward; time: "how long")': '대격: 직접 목적어·방향·시간의 길이',
          'Dative (indirect object, "to"; also location "in", (rarely): "at"; instrument, "with")': '여격: 간접 '
                                                                                                    '목적어·위치(드물게 '
                                                                                                    'at)·도구',
          'Dative (indirect object, "to"; also location "in", (rarely): "at”; instrument, "with")': '여격: 간접 '
                                                                                                    '목적어·위치(드물게 '
                                                                                                    'at)·도구',
          'Genitive (possession, "of"; also origin or separation, "from")': '속격: 소유·기원·분리',
          'Nominative (subject; predicate nominative)': '주격: 주어·주격 보어',
          'Vocative (direct address)': '호격: 부르는 대상'},
 'Number': {'Plural': '복수',
            'Plural Aeolic': '복수(아이올리스 방언)',
            'Singular': '단수',
            'Singular IRRegular or inpure form': '단수(불규칙 또는 혼합 형태)',
            'Singular Middle significance': '단수(중간태 의미)'},
 'Gender': {'Feminine': '여성',
            'Masculine': '남성',
            'Masculine Particle attached': '남성(소사 결합)',
            'Neuter': '중성',
            'Neuter As Noun: ±thing': '중성의 명사적 용법: ±thing',
            'Neuter As Noun: ±things': '중성의 명사적 용법: ±things'},
 'Degree': {'Comparative': '비교급', 'Negative': '부정', 'Superlative': '최상급'},
 'Form': {'ABBrevieated': '줄임 형태',
          'ATTic': '아티케 방언',
          'Apocopated': '말끝이 탈락한 형태',
          'Comparative': '비교급',
          'Contracted': '축약형',
          'Contracted with ‘kai’': 'kai와 축약된 형태',
          'Contracted with ‘kai’ (kai = and or also)': 'kai와 축약된 형태(kai: 그리고·또한)',
          'Interrogative': '의문형'}}


def text(fragment):
    return ' '.join(html.unescape(re.sub(r'<[^>]+>', ' ', fragment)).split())


def normalize(value):
    # 페이지의 문장 마침표·따옴표·HTML 줄바꿈 차이만 비교에서 정규화한다.
    value = value.lower().replace('towar d', 'toward')
    value = value.replace('“', '"').replace('”', '"').replace('‘', "'").replace('’', "'")
    return re.sub(r'[\s.]', '', value)


def fetch(code):
    url = BASE + code + '.htm'
    request = urllib.request.Request(url, headers={'User-Agent': 'ReshetSourceReview/1.0'})
    raw = urllib.request.urlopen(request, timeout=20).read()
    page = raw.decode('utf-8')
    note = re.search(r'<p[^>]*rmac-note[^>]*>(.*?)</p>', page, re.S)
    if not note or 'These are Public Domain.' not in text(note[1]):
        raise ValueError('RMAC 공개 조건을 확인할 수 없음: ' + code)
    table = re.search(r'<table class="entry-table">(.*?)</table>', page, re.S)
    more = re.search(r'<div class="entry-more">(.*?)</div>', page, re.S)
    if table is None:
        raise ValueError('문법 설명표 없음: ' + code)
    return code, raw, text(table[1] + (more[1] if more else '')), text(note[1])


def main():
    work = ROOT / 'data/reshet_work.db'
    before = hashlib.sha256(work.read_bytes()).hexdigest()
    db = sqlite3.connect(work.as_uri() + '?mode=ro', uri=True)
    db.execute('PRAGMA query_only=ON')
    rows = list(db.execute('SELECT * FROM RMAC_TABLE ORDER BY RMAC'))
    values = [sorted({r[i] for r in rows if r[i] is not None}) for i in range(1, 11)]
    remaining = {(i, v) for i, vals in enumerate(values, 1) for v in vals}
    chosen = []
    while remaining:
        row = max(rows, key=lambda r: len({(i, v) for i, v in enumerate(r[1:], 1)
                                          if v is not None} & remaining))
        chosen.append(row)
        remaining -= {(i, v) for i, v in enumerate(row[1:], 1) if v is not None}
    cache = ROOT / 'build/play_release/rmac_sources'
    cache.mkdir(parents=True, exist_ok=True)
    sources = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        for code, raw, body, note in pool.map(fetch, [r[0] for r in chosen]):
            (cache / (code + '.htm')).write_bytes(raw)
            sources[code] = (body, note, hashlib.sha256(raw).hexdigest())
    replacements = []
    missing = []
    for i, (column, vals, translations) in enumerate(zip(COLS, values, [TRANSLATIONS[c] for c in COLS]), 1):
        if set(vals) != set(translations):
            raise ValueError('번역 대상 개수가 변경됨: ' + column)
        for value in vals:
            korean = translations[value]
            matches = [r[0] for r in chosen if r[i] == value
                       and normalize(value) in normalize(sources[r[0]][0])]
            if not matches:
                missing.append((column, value, [(r[0], sources[r[0]][0])
                                                for r in chosen if r[i] == value]))
                continue
            code = matches[0]
            # 원천의 원래 문법 설명 범위를 유지한다. 기존 영어 표는 수정하지 않는다.
            replacements.append({'column': column, 'english': value, 'korean': korean,
                                 'source_url': BASE + code + '.htm',
                                 'source_sha256': sources[code][2]})
    if missing:
        print(json.dumps({'unmatched': missing}, ensure_ascii=False, indent=2))
        raise ValueError('공개 원문과 일치하지 않은 설명은 자동 채택하지 않음')
    manifest = {'format': 1, 'source': 'MLV Teams RMAC', 'license': 'Public Domain',
                'checked_at': '2026-10-02', 'scope': 'seed_only_korean_retranslation',
                'source_note': sources[chosen[0][0]][1],
                'translations': replacements}
    target = ROOT / 'tool/data_provenance/manifests/seed_rmac_translations.json'
    target.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')
    db.close()
    assert hashlib.sha256(work.read_bytes()).hexdigest() == before
    print(json.dumps({'english_values': len(replacements), 'source_pages': len(chosen),
                      'korean_values': sum(len(set(v.values())) for v in TRANSLATIONS.values()),
                      'work_sha256_unchanged': before}, ensure_ascii=False))


if __name__ == '__main__':
    main()
