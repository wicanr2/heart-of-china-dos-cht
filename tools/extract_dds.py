#!/usr/bin/env python3
"""Parse DGDS DDS dialogue files (Heart of China, ver 1.216) and extract dialogue.
Faithful port of ScummVM engines/dgds/scene.cpp Scene::readDialogList + loadDialogData.

HoC stores player-facing dialogue in D<N>.DDS resources (not in the SDS scenes
like Rise of the Dragon 1.211). Each DDS has one packed `DDS:` chunk:
    magic(u32) + version(cstr) + id(cstr) + dialogList
The translation key is (ddsFileNum, dialogNum) — stable, matches the engine's
Dialog._fileNum / Dialog._num used at the draw point.
"""
import sys, os, io, struct, json, glob, re
sys.path.insert(0, os.path.dirname(__file__))
from dgds_chunks import iter_chunks, decompress_blob

class R:
    def __init__(self, data): self.d = data; self.p = 0
    def u16(self):
        v = struct.unpack_from('<H', self.d, self.p)[0]; self.p += 2; return v
    def u32(self):
        v = struct.unpack_from('<I', self.d, self.p)[0]; self.p += 4; return v
    def cstr(self):
        e = self.d.index(b'\0', self.p); s = self.d[self.p:e]; self.p = e + 1
        return s.decode('latin1')
    def fixedstr(self, n):
        raw = self.d[self.p:self.p + n]; self.p += n
        z = raw.find(b'\0')
        return (raw if z < 0 else raw[:z]).decode('cp437')
    def rem(self): return len(self.d) - self.p

# version comparison against the DDS file's own version string (HoC = " 1.216").
# strncmp(_version, arg, len(_version)) — both length 6 here, plain compare ok.
def over(ver, v):  return ver > v
def under(ver, v): return ver < v

def read_condlist(r):
    for _ in range(r.u16()):
        r.u16(); r.u16(); r.u16()  # cnum, cond, val(s16)

def read_oplist(r):
    n = r.u16()
    for _ in range(n):
        read_condlist(r)
        r.u16()                 # opCode
        nvals = r.u16()
        for _ in range(nvals // 2): r.u16()

def read_dialogactionlist(r):
    n = r.u16()
    for _ in range(n):
        r.u16(); r.u16()        # strStart, strEnd
        read_oplist(r)

def read_dialoglist(r, ver, out, filenum):
    nitems = r.u16()
    for _ in range(nitems):
        num = r.u16()
        rx, ry, rw, rh = r.u16(), r.u16(), r.u16(), r.u16()
        bg = r.u16(); fg = r.u16()
        if under(ver, " 1.209"):
            selbg, selfg = bg, fg
        else:
            selbg = r.u16(); selfg = r.u16()
        fontsize = r.u16()
        if under(ver, " 1.210"):
            flags = r.u16()
        else:
            flags = r.u32() & 0xffff
        frametype = r.u16(); time = r.u16()
        if over(ver, " 1.215"): nextfile = r.u16()
        if over(ver, " 1.207"): nextdlg = r.u16()
        if over(ver, " 1.216"):
            r.u16(); r.u16()    # talkDataNum, talkDataHeadNum (HoC 1.216 == not over)
        nbytes = r.u16()
        s = r.fixedstr(nbytes) if nbytes > 0 else ""
        read_dialogactionlist(r)
        if s:
            out.append(dict(file=filenum, num=num, rect=[rx, ry, rw, rh],
                            bg=bg, fg=fg, fontsize=fontsize, text=s))

def parse_dds(path):
    data = open(path, 'rb').read()
    m = re.search(r'd(\d+)\.dds$', os.path.basename(path).lower())
    filenum = int(m.group(1)) if m else 0
    dialogs = []
    ver = None
    for idstr, size, cont, start, payload in iter_chunks(data):
        if idstr == 'DDS:' and not cont:
            raw = decompress_blob(payload)
            r = R(raw)
            magic = r.u32()
            ver = r.cstr()
            fileid = r.cstr()
            read_dialoglist(r, ver, dialogs, filenum)
            return dialogs, ver, fileid
    return dialogs, ver, None

def main():
    indir = sys.argv[1]
    files = sorted(glob.glob(os.path.join(indir, 'd*.dds')),
                   key=lambda p: int(re.search(r'd(\d+)', os.path.basename(p)).group(1)))
    alldlg = []; bad = 0; vers = set()
    for f in files:
        try:
            dlg, ver, fid = parse_dds(f)
            vers.add(ver)
            alldlg += dlg
        except Exception as e:
            print(f"FAIL {os.path.basename(f)}: {e}", file=sys.stderr); bad += 1
    print(f"# {len(files)} dds files, {len(alldlg)} dialogs, {bad} failures, versions={vers}",
          file=sys.stderr)
    if len(sys.argv) > 2:
        json.dump(alldlg, open(sys.argv[2], 'w'), ensure_ascii=False, indent=1)
        print(f"# wrote {sys.argv[2]}", file=sys.stderr)

if __name__ == '__main__':
    main()
