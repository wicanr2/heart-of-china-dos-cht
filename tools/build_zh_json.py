#!/usr/bin/env python3
"""Merge per-batch unit translations into translations/zh.json (engine keys).

Inputs:
  i18n/key_map.json      : {engine_key -> uid}   (from prep_translation.py)
  i18n/out/b*.json       : {uid -> 繁體中文}      (from the translation workflow)
Output:
  translations/zh.json   : {engine_key -> 繁體中文}  (key = "file:num" or "UI:NAME")

Also: enforces canonical nameplates (CONTEXT.md 譯名表) for consistency,
reports missing units (so failed batches can be re-run) and any non-Big5 chars.
"""
import json, glob, os, sys, re

# Official 軟體世界 (1990s) 譯名 — restored from the manual (攻略/珍108). These OVERRIDE the
# machine-translation drafts everywhere. 賽奇 = the named 中國忍者 (Zhao Chi). See CONTEXT.md.
RENAME = [  # (machine draft, 官方軟體世界) — value-only replace, longest/compound first
    ("傑克·馬斯特斯", "傑克馬斯特斯"), ("傑克·馬斯特", "傑克馬斯特斯"),
    ("老馬", "來福"), ("趙奇", "齊豪"), ("凱特", "凱蒂"),
    ("李鄧", "鄧利"), ("羅麥斯", "羅梅士"),
    # fix earlier OCR-misreads already shipped:
    ("鄧立", "鄧利"), ("羅麥士", "羅梅士"), ("賽奇", "齊豪"), ("凱茶", "凱蒂"),
]
# 官方手冊（故事大綱）：來福(Lucky)、齊豪(中國忍者 Zhao Chi)、凱蒂(Kate)、羅梅士(Lomax)、鄧利(軍閥 Li Deng)。
def apply_rename(s):
    for a, b in RENAME:
        if a in s:
            s = s.replace(a, b)
    return s

# Canonical nameplates / recurring proper nouns — override agent output for 100% consistency.
CANON = {
    "UI:LUCKY": "來福", "UI:CHI": "齊豪", "UI:KATE": "凱蒂", "UI:LOMAX": "羅梅士",
    "UI:LI DENG": "鄧利", "UI:DENG": "鄧利", "UI:Li Deng": "鄧利",
    "UI:SARDAR": "薩達爾", "UI:AMA": "阿瑪", "UI:WU": "吳", "UI:HO": "何",
    "UI:LAMA": "喇嘛", "UI:KUBLA": "忽必", "UI:BIJAYA": "比賈亞", "UI:NALINI": "娜里妮",
    "UI:HAKIM": "哈金", "UI:KASIM": "卡辛", "UI:ALMIRA": "艾米拉",
    "UI:MOHMAR": "莫瑪", "UI:MOMAR": "莫瑪", "UI:HOJI": "霍吉", "UI:BOJON": "波瓊",
    "UI:ACAYIB": "阿賈伊", "UI:GUARD": "守衛", "UI:Guard": "守衛",
    "UI:PEASANT": "農夫", "UI:Peasant": "農夫", "UI:GOON": "打手", "UI:OLD WOMAN": "老婦",
    "UI:KATE, LUCKY": "凱特、老馬", "UI:LUCKY & CHI": "老馬與趙奇",
    "UI:LUCKY, KATE, CHI": "老馬、凱特、趙奇", "UI:PEASANT (CHI)": "農夫（趙奇）",
}

# Agent-noise / typographic chars not in Big5 -> Big5-safe equivalents.
NORMALIZE = {
    '‧': '·',  # ‧ hyphenation point -> · middle dot (name separator)
    '・': '·',  # ・ katakana middle dot -> ·
    '–': '—',  # – en dash -> — em dash (Big5 A15A)
    '‘': "'", '’': "'",  # ‘ ’ -> '
    '“': '「', '”': '」',  # “ ” -> 「 」
    '﹕': '：', '；': '；',
    '\t': ' ',  # tabs render undefined in the CJK path -> space
}

# Hand corrections for specific dialog keys (survive rebuilds; applied last).
POST_FIX = {
    "28:218": "我這人，本來就『來福』啊。",  # pun: "I already am Lucky" -> his name 來福 = 福來/走運
}
def normalize(s):
    for a, b in NORMALIZE.items():
        if a in s:
            s = s.replace(a, b)
    return s

_OPT_RE = re.compile(r'(?:^|\r)\s*\d+[.．]')
def collapse_options(s):
    """Numbered-option choice lists ('1. .. \\r\\r 2. ..') overflow the dialog box at
    24px CJK because each \\r\\r adds a blank line. Tighten \\r\\r->\\r for option lists
    (>=2 numbered markers). Leaves narration paragraph breaks alone."""
    if '\r\r' in s and len(_OPT_RE.findall(s)) >= 2:
        s = s.replace('\r\r', '\r')
    return s

def load_units():
    """Base = machine translation (i18n/out/); overlay = 文案 review refinements (i18n/review/)."""
    units = {}
    n_rev = 0
    for src_glob, tag in (('i18n/out/b*.json', 'out'), ('i18n/review/b*.json', 'review')):
        for f in sorted(glob.glob(src_glob)):
            try:
                d = json.load(open(f, encoding='utf-8'))
            except Exception as e:
                print(f"  BAD {tag} file {f}: {e}", file=sys.stderr); continue
            for uid, zh in d.items():
                if isinstance(zh, str) and zh.strip():
                    units[uid] = normalize(zh)
                    if tag == 'review':
                        n_rev += 1
    if n_rev:
        print(f"# overlaid {n_rev} 文案-reviewed unit translations", file=sys.stderr)
    return units

def main():
    key_map = json.load(open('i18n/key_map.json', encoding='utf-8'))
    units = load_units()
    zh = {}
    missing = []
    for k, uid in key_map.items():
        if uid in units:
            zh[k] = units[uid]
        else:
            missing.append((k, uid))
    # enforce canonical nameplates
    for k, v in CANON.items():
        if k in key_map:
            zh[k] = v
    # merge hand-authored UI / system-menu / TTM supplement (lookupUI keys)
    sup_path = 'translations/ui_supplement.json'
    if os.path.exists(sup_path):
        sup = json.load(open(sup_path, encoding='utf-8'))
        for k, v in sup.items():
            if not k.startswith('_'):
                zh[k] = normalize(v)
    # apply official 軟體世界 譯名 (老馬→來福, 趙奇→賽奇, 李鄧→鄧立, 羅麥斯→羅麥士) everywhere
    n_ren = 0
    for k in list(zh.keys()):
        nv = apply_rename(zh[k])
        if nv != zh[k]:
            zh[k] = nv; n_ren += 1
    # tighten numbered-option choice lists so they fit the dialog box at 24px CJK
    n_opt = 0
    for k in list(zh.keys()):
        if not k.startswith('UI:'):
            nv = collapse_options(zh[k])
            if nv != zh[k]:
                zh[k] = nv; n_opt += 1
    print(f"# renamed {n_ren} values to official 譯名, collapsed {n_opt} option lists", file=sys.stderr)
    # hand corrections (last word)
    for k, v in POST_FIX.items():
        if k in zh:
            zh[k] = v
    # Big5 check
    bad = []
    for k, v in zh.items():
        try:
            v.encode('big5')
        except UnicodeEncodeError as e:
            bad.append((k, v[e.start:e.end]))
    os.makedirs('translations', exist_ok=True)
    json.dump(zh, open('translations/zh.json', 'w', encoding='utf-8'),
              ensure_ascii=False, indent=1)
    print(f"# zh.json: {len(zh)}/{len(key_map)} keys translated, "
          f"{len(missing)} missing, {len(bad)} non-Big5", file=sys.stderr)
    if missing[:10]:
        miss_uids = sorted({u for _, u in missing})
        print(f"# missing uids ({len(miss_uids)}): {miss_uids[:20]}", file=sys.stderr)
    if bad[:10]:
        print(f"# non-Big5 sample: {bad[:10]}", file=sys.stderr)

if __name__ == '__main__':
    main()
