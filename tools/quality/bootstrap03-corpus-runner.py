#!/usr/bin/env python3
# tools/quality/bootstrap03-corpus-runner.py
#
# ACT-POLYC-BOOTSTRAP03 C3 EVIDENCE — broad-corpus
# stage1 ↔ stage2 differential driver.
#
# Per ACT §20: mechanically enumerates all .HC sources
# under src/holyc-lib and src/tests, compiles each one
# with stage1 (./build/hcc-bootstrap02) and stage2
# (./build/hcc-bootstrap03) using the same flags and
# the same environment, and compares the resulting
# objects. Produces a TSV row per source.
#
# Scope contract (ACT §26):
#   - test-only
#   - deterministic (no timestamps in output)
#   - bounded output (one row per source)
#   - no compiler semantic changes (does not touch
#     src/ or tools/bootstrap/)
#
# Inputs (positional):
#   1. inventory file (one path per line)
#   2. stage1 compiler path
#   3. stage2 compiler path
#   4. install-dir
#   5. stage1 output directory
#   6. stage2 output directory
#   7. output TSV path
#
# The output TSV schema is the B2 analog of the B1 schema
# (compare tools/quality/bootstrap02-corpus-runner.py):
#
#   path
#   has_dollar_identifier
#   stage1_rc
#   stage2_rc
#   stage1_class
#   stage2_class
#   stage1_artifact
#   stage2_artifact
#   byte_equal
#   verdict
#   reason
import hashlib
import os
import re
import subprocess
import sys
import tempfile


DOLLAR_RE = re.compile(rb"[A-Za-z_][A-Za-z0-9_]*\$[A-Za-z0-9_$]*")

C_OK         = "PASS"
C_COMPILE    = "COMPILE_FAIL"
C_BUILDFAIL  = "BUILD_FAIL"
C_MISSING    = "MISSING_FILE"

VERDICT_PASS = "STAGE1_PASS_STAGE2_PASS"
VERDICT_FAIL = "STAGE1_FAIL_STAGE2_FAIL"
VERDICT_DIV  = "STAGE1_FAIL_STAGE2_PASS"
VERDICT_INV  = "STAGE1_PASS_STAGE2_FAIL"


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def run_compile(compiler, src, install_dir, outdir, idx, cwd_root):
    base = os.path.basename(src)
    stem = os.path.splitext(base)[0]
    abs_out = os.path.abspath(os.path.join(outdir, f"{idx}_{stem}.o"))
    out = abs_out
    if os.path.exists(out):
        os.remove(out)
    rel_out = os.path.relpath(abs_out, cwd_root)
    rel_src = src if os.path.isabs(src) else os.path.relpath(src, cwd_root)
    try:
        proc = subprocess.run(
            [compiler, "--install-dir", install_dir,
             "-c", rel_src, "-o", rel_out],
            cwd=cwd_root,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=60,
        )
    except subprocess.TimeoutExpired:
        return C_COMPILE, -1, None, "TIMEOUT"
    if proc.returncode != 0:
        if not os.path.exists(out):
            return C_COMPILE, proc.returncode, None, "NO_OUTPUT"
        return C_COMPILE, proc.returncode, None, "OUTPUT_PRESENT"
    if not os.path.exists(out):
        return C_BUILDFAIL, proc.returncode, None, "MISSING_ARTIFACT"
    return C_OK, proc.returncode, out, "OK"


def classify(src, rc):
    if not os.path.isfile(src):
        return C_MISSING
    if rc != 0:
        return C_COMPILE
    return C_OK


def main():
    if len(sys.argv) != 8:
        sys.stderr.write("usage: bootstrap03-corpus-runner.py "
                         "<inventory> <stage1> <stage2> <install-dir> "
                         "<stage1-outdir> <stage2-outdir> <out.tsv>\n")
        sys.exit(2)
    inv_path  = sys.argv[1]
    stage1    = os.path.abspath(sys.argv[2])
    stage2    = os.path.abspath(sys.argv[3])
    inst_dir  = sys.argv[4]
    outdir1   = os.path.abspath(sys.argv[5])
    outdir2   = os.path.abspath(sys.argv[6])
    out_tsv   = sys.argv[7]
    cwd_root  = os.path.abspath(".")
    with open(inv_path) as f:
        sources = [l.strip() for l in f if l.strip()]
    os.makedirs(outdir1, exist_ok=True)
    os.makedirs(outdir2, exist_ok=True)
    rows = []
    counts = {VERDICT_PASS: 0, VERDICT_FAIL: 0, VERDICT_DIV: 0, VERDICT_INV: 0}
    div_rows = []
    for idx, src in enumerate(sources):
        try:
            with open(src, "rb") as f:
                content = f.read(1 << 20)
        except OSError:
            content = b""
        has_dollar = "1" if DOLLAR_RE.search(content) else "0"
        c1, rc1, art1, reason1 = run_compile(stage1, src, inst_dir, outdir1, idx, cwd_root)
        c2, rc2, art2, reason2 = run_compile(stage2, src, inst_dir, outdir2, idx, cwd_root)
        byte_equal = "N/A"
        if c1 == C_OK and c2 == C_OK:
            try:
                byte_equal = "YES" if sha256(art1) == sha256(art2) else "NO"
            except OSError:
                byte_equal = "ERR"
        if c1 == C_OK and c2 == C_OK:
            verdict = VERDICT_PASS
            reason  = byte_equal
        elif c1 != C_OK and c2 != C_OK:
            verdict = VERDICT_FAIL
            reason  = f"S1={reason1};S2={reason2}"
        elif c1 != C_OK and c2 == C_OK:
            verdict = VERDICT_DIV
            reason  = f"ONLY_STAGE2:{reason1}"
        else:
            verdict = VERDICT_INV
            reason  = f"ONLY_STAGE1:{reason2}"
        counts[verdict] = counts.get(verdict, 0) + 1
        if verdict in (VERDICT_DIV, VERDICT_INV):
            div_rows.append((src, verdict, reason))
        rows.append((src, has_dollar, str(rc1), str(rc2), c1, c2,
                     art1 or "", art2 or "", byte_equal, verdict, reason))
    with open(out_tsv, "w") as f:
        f.write("path\thas_dollar_identifier\tstage1_rc\tstage2_rc\t"
                "stage1_class\tstage2_class\tstage1_artifact\t"
                "stage2_artifact\tbyte_equal\tverdict\treason\n")
        for r in rows:
            f.write("\t".join(r) + "\n")
    sys.stderr.write(f"corpus-rows={len(rows)}\n")
    for k in (VERDICT_PASS, VERDICT_FAIL, VERDICT_DIV, VERDICT_INV):
        sys.stderr.write(f"{k}={counts.get(k, 0)}\n")
    if div_rows:
        sys.stderr.write("DIVERGENCES:\n")
        for src, v, r in div_rows:
            sys.stderr.write(f"  {v}\t{src}\t{r}\n")
    sys.exit(0)


if __name__ == "__main__":
    main()
