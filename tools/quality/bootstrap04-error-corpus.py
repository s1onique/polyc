#!/usr/bin/env python3
# tools/quality/bootstrap04-error-corpus.py
#
# ACT-POLYC-BOOTSTRAP04 C3 EVIDENCE — explicit error
# corpus differential driver for stage2 ↔ stage3.
#
# Per ACT §28: reuse the C3 error corpus and verify
# that stage2 and stage3 produce equivalent exit
# classes and equivalent normalized diagnostics
# (path:line:col form, when stable).
#
# Inputs (positional):
#   1. error fixture directory (one .HC per ERR)
#   2. stage2 compiler path
#   3. stage3 compiler path
#   4. install-dir
#   5. output TSV path
import os
import re
import subprocess
import sys


ERR_LINE_RE = re.compile(rb"^(.*?\.HC):(\d+):(\d+):")


def run_one(compiler, src, install_dir):
    proc = subprocess.run(
        [compiler, "--install-dir", install_dir, "-c", src,
         "-o", "/tmp/b04-err-discard.o"],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30,
    )
    return proc.returncode, proc.stdout, proc.stderr


def normalize(stderr):
    if not stderr:
        return "OK"
    s = stderr.decode("utf-8", errors="replace")
    m = re.search(r"--> ([^:]+):(\d+):(\d+)", s)
    if not m:
        m = ERR_LINE_RE.search(stderr)
    if not m:
        return s.strip().split("\n")[0][:200]
    return f"{m.group(1)}:{m.group(2)}:{m.group(3)}"


def main():
    if len(sys.argv) != 6:
        sys.stderr.write("usage: bootstrap04-error-corpus.py "
                         "<fixtures-dir> <stage2> <stage3> "
                         "<install-dir> <out.tsv>\n")
        sys.exit(2)
    fixtures_dir = sys.argv[1]
    stage2       = os.path.abspath(sys.argv[2])
    stage3       = os.path.abspath(sys.argv[3])
    inst_dir     = sys.argv[4]
    out_tsv      = sys.argv[5]
    files = sorted(p for p in os.listdir(fixtures_dir) if p.startswith("ERR"))
    rows = []
    mismatch = 0
    for name in files:
        src = os.path.abspath(os.path.join(fixtures_dir, name))
        rc2, out2, err2 = run_one(stage2, src, inst_dir)
        rc3, out3, err3 = run_one(stage3, src, inst_dir)
        norm2 = normalize(err2)
        norm3 = normalize(err3)
        cls2 = "PASS" if rc2 == 0 else "FAIL"
        cls3 = "PASS" if rc3 == 0 else "FAIL"
        eq = "YES" if (rc2 == rc3 and cls2 == cls3) else "NO"
        if eq == "NO":
            mismatch += 1
        rows.append((name, str(rc2), str(rc3), cls2, cls3,
                     norm2, norm3, eq))
    with open(out_tsv, "w") as f:
        f.write("fixture\tstage2_rc\tstage3_rc\tstage2_class\tstage3_class\t"
                "stage2_diag\tstage3_diag\tequivalent\n")
        for r in rows:
            f.write("\t".join(r) + "\n")
    sys.stderr.write(f"error-corpus-rows={len(rows)}\n")
    sys.stderr.write(f"error-corpus-mismatch={mismatch}\n")
    sys.exit(0 if mismatch == 0 else 1)


if __name__ == "__main__":
    main()
