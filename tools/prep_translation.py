#!/usr/bin/env python3
"""Turn dialogs_en.json into translatable units for the translation workflow.

Mirrors engine draw behaviour (dialog.cpp drawType2):
  - frametype==2 AND `_str` has a colon immediately followed by CR ("NAME:\\rbody")
    -> nameplate is drawn separately via drawHeader (lookupUI "UI:NAME"); the body
       (after ':' + the leading CR) is drawn via drawForeground (lookupDialog).
    => translate body under key "file:num"; register nameplate under key "UI:NAME".
  - otherwise the whole `_str` is drawn -> translate full string under key "file:num".

Dedups identical source strings into units (one translation, consistent + less volume).
Outputs:
  i18n/src_units.json : {"<uid>": {"src": "...", "kind": "dialog|name"}}
  i18n/key_map.json   : {"<engine key>": "<uid>"}   (engine key = "file:num" or "UI:NAME")
"""
import json, os, sys, re

def split_unit(text, frametype):
    """Return (nameplate_or_None, body) matching dialog.cpp drawType2."""
    colon = text.find(':')
    cr = text.find('\r')
    if frametype == 2 and colon != -1 and cr == colon + 1:
        name = text[:colon]
        body = text[colon + 2:]   # skip ':' and the immediate '\r'
        return name, body
    return None, text

def main():
    src = sys.argv[1] if len(sys.argv) > 1 else 'dialogs_en.json'
    outdir = sys.argv[2] if len(sys.argv) > 2 else 'i18n'
    os.makedirs(outdir, exist_ok=True)
    dlgs = json.load(open(src, encoding='utf-8'))

    units = {}          # src_text -> uid
    unit_meta = {}      # uid -> {"src","kind"}
    key_map = {}        # engine key -> uid
    def unit_for(text, kind):
        key = (kind, text)
        if key not in units:
            uid = f"u{len(units)}"
            units[key] = uid
            unit_meta[uid] = {"src": text, "kind": kind}
        return units[key]

    n_name = 0
    for d in dlgs:
        name, body = split_unit(d['text'], d.get('frametype', 0))
        if name is not None and name.strip():
            key_map[f"UI:{name}"] = unit_for(name, 'name'); n_name += 1
        if body.strip():
            key_map[f"{d['file']}:{d['num']}"] = unit_for(body, 'dialog')

    json.dump(unit_meta, open(os.path.join(outdir, 'src_units.json'), 'w'),
              ensure_ascii=False, indent=1)
    json.dump(key_map, open(os.path.join(outdir, 'key_map.json'), 'w'),
              ensure_ascii=False, indent=1)
    nplate = sorted({m['src'] for m in unit_meta.values() if m['kind'] == 'name'})
    print(f"# {len(dlgs)} dialogs -> {len(key_map)} keys, {len(unit_meta)} unique units "
          f"({sum(1 for m in unit_meta.values() if m['kind']=='name')} nameplates, "
          f"{sum(1 for m in unit_meta.values() if m['kind']=='dialog')} dialog)", file=sys.stderr)
    print(f"# nameplates: {nplate}", file=sys.stderr)

if __name__ == '__main__':
    main()
