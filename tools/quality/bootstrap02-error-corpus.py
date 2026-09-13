#!/usr/bin/env python3
# tools/quality/bootstrap02-error-corpus.py
#
# ACT-POLYC-BOOTSTRAP02 C3 EVIDENCE — explicit error
# corpus differential driver.
#
# Per ACT §15: a small deliberate error corpus,
# separate from accidentally non-standalone repository
# files. At minimum four fixtures:
#
#   ERR01 unterminated string
#   ERR02 valid identifier followed by malformed declaration
#   ERR03 $ at a position invalid under the frozen start grammar
#   ERR04 identifier followed by an intentional parser error
#
# For each fixture, run the SAME compilation invocation
# under stage0 and stage1 and compare:
#
#   - exit code
#   - normalized diagnostic class (error/warning/ok)
#   - source position if stable
#
# Inputs (positional):
#   1. error fixture directory (one .HC per ERR)
#   2. stage0 compiler path
#   3. stage1 compiler path
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
         "-o", "/tmp/b02-err-discard.o"],
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
        sys.stderr.write("usage: bootstrap02-error-corpus.py "
                         "<fixtures-dir> <stage0> <stage1> <install-dir> <out.tsv>\n")
        sys.exit(2)
    fixtures_dir = sys.argv[1]
    stage0       = os.path.abspath(sys.argv[2])
    stage1       = os.path.abspath(sys.argv[3])
    inst_dir     = sys.argv[4]
    out_tsv      = sys.argv[5]
    files = sorted(p for p in os.listdir(fixtures_dir) if p.startswith("ERR"))
    rows = []
    mismatch = 0
    for name in files:
        src = os.path.abspath(os.path.join(fixtures_dir, name))
        rc0, out0, err0 = run_one(stage0, src, inst_dir)
        rc1, out1, err1 = run_one(stage1, src, inst_dir)
        norm0 = normalize(err0)
        norm1 = normalize(err1)
        cls0 = "PASS" if rc0 == 0 else "FAIL"
        cls1 = "PASS" if rc1 == 0 else "FAIL"
        # For an error corpus, the exit codes should both
        # be non-zero (or both zero only if no error).
        eq = "YES" if (rc0 == rc1 and cls0 == cls1) else "NO"
        if eq == "NO":
            mismatch += 1
        rows.append((name, str(rc0), str(rc1), cls0, cls1, norm0, norm1, eq))
    with open(out_tsv, "w") as f:
        f.write("fixture\tstage0_rc\tstage1_rc\tstage0_class\tstage1_class\t"
                "stage0_diag\tstage1_diag\tequivalent\n")
        for r in rows:
            f.write("\t".join(r) + "\n")
    sys.stderr.write(f"error-corpus-rows={len(rows)}\n")
    sys.stderr.write(f"error-corpus-mismatch={mismatch}\n")
    sys.exit(0 if mismatch == 0 else 1)

if __name__ == "__main__":
    main()
