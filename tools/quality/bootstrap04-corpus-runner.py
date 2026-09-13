#!/usr/bin/env python3
# tools/quality/bootstrap04-corpus-runner.py
#
# ACT-POLYC-BOOTSTRAP04 C3 EVIDENCE — broad-corpus
# stage2 ↔ stage3 differential driver.
#
# Per ACT §26: mechanically enumerates all .HC sources
# under src/holyc-lib and src/tests, compiles each one
# with stage2 (./build/hcc-bootstrap03) and stage3
# (./build/hcc-bootstrap04) using the same flags and
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
#   2. stage2 compiler path
#   3. stage3 compiler path
#   4. install-dir
#   5. stage2 output directory
#   6. stage3 output directory
#   7. output TSV path
#
# The output TSV schema is the B3 analog of the B2 schema
# (compare tools/quality/bootstrap03-corpus-runner.py):
#
#   path
#   has_dollar_identifier
#   stage2_rc
#   stage3_rc
#   stage2_class
#   stage3_class
#   stage2_artifact
#   stage3_artifact
#   byte_equal
#   verdict
#   reason
import hashlib
import os
import re
import subprocess
import sys


DOLLAR_RE = re.compile(rb"[A-Za-z_][A-Za-z0-9_]*\$[A-Za-z0-9_$]*")

C_OK         = "PASS"
C_COMPILE    = "COMPILE_FAIL"
C_BUILDFAIL  = "BUILD_FAIL"
C_MISSING    = "MISSING_FILE"

VERDICT_PASS  = "STAGE2_PASS_STAGE3_PASS"
VERDICT_FAIL  = "STAGE2_FAIL_STAGE3_FAIL"
VERDICT_DIV   = "STAGE2_FAIL_STAGE3_PASS"
VERDICT_INV   = "STAGE2_PASS_STAGE3_FAIL"


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
            [compiler, "--install-dir", install_dir, "-c", rel_src, "-o", rel_out],
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


def main():
    if len(sys.argv) != 8:
        sys.stderr.write("usage: bootstrap04-corpus-runner.py "
                         "<inventory> <stage2> <stage3> <install-dir> "
                         "<stage2-outdir> <stage3-outdir> <out.tsv>\n")
        sys.exit(2)
    inv_path  = sys.argv[1]
    stage2    = os.path.abspath(sys.argv[2])
    stage3    = os.path.abspath(sys.argv[3])
    inst_dir  = sys.argv[4]
    outdir2   = os.path.abspath(sys.argv[5])
    outdir3   = os.path.abspath(sys.argv[6])
    out_tsv   = sys.argv[7]
    cwd_root  = os.path.abspath(".")
    with open(inv_path) as f:
        sources = [l.strip() for l in f if l.strip()]
    os.makedirs(outdir2, exist_ok=True)
    os.makedirs(outdir3, exist_ok=True)
    rows = []
    counts = {"STAGE2_PASS_STAGE3_PASS": 0, "STAGE2_FAIL_STAGE3_FAIL": 0,
              "STAGE2_FAIL_STAGE3_PASS": 0, "STAGE2_PASS_STAGE3_FAIL": 0}
    div_rows = []
    for idx, src in enumerate(sources):
        try:
            with open(src, "rb") as f:
                content = f.read(1 << 20)
        except OSError:
            content = b""
        has_dollar = "1" if DOLLAR_RE.search(content) else "0"
        c2, rc2, art2, reason2 = run_compile(stage2, src, inst_dir, outdir2, idx, cwd_root)
        c3, rc3, art3, reason3 = run_compile(stage3, src, inst_dir, outdir3, idx, cwd_root)
        byte_equal = "N/A"
        if c2 == C_OK and c3 == C_OK:
            try:
                byte_equal = "YES" if sha256(art2) == sha256(art3) else "NO"
            except OSError:
                byte_equal = "ERR"
        if c2 == C_OK and c3 == C_OK:
            verdict = VERDICT_PASS
            reason  = byte_equal
        elif c2 != C_OK and c3 != C_OK:
            verdict = VERDICT_FAIL
            reason  = f"S2={reason2};S3={reason3}"
        elif c2 != C_OK and c3 == C_OK:
            verdict = VERDICT_DIV
            reason  = f"ONLY_STAGE3:{reason2}"
        else:
            verdict = VERDICT_INV
            reason  = f"ONLY_STAGE2:{reason3}"
        counts[verdict] = counts.get(verdict, 0) + 1
        if verdict in (VERDICT_DIV, VERDICT_INV):
            div_rows.append((src, verdict, reason))
        rows.append((src, has_dollar, str(rc2), str(rc3), c2, c3,
                     art2 or "", art3 or "", byte_equal, verdict, reason))
    with open(out_tsv, "w") as f:
        f.write("path\thas_dollar_identifier\tstage2_rc\tstage3_rc\t"
                "stage2_class\tstage3_class\tstage2_artifact\t"
                "stage3_artifact\tbyte_equal\tverdict\treason\n")
        for r in rows:
            f.write("\t".join(r) + "\n")
    sys.stderr.write(f"corpus-rows={len(rows)}\n")
    for k in ("STAGE2_PASS_STAGE3_PASS", "STAGE2_FAIL_STAGE3_FAIL",
              "STAGE2_FAIL_STAGE3_PASS", "STAGE2_PASS_STAGE3_FAIL"):
        sys.stderr.write(f"{k}={counts.get(k, 0)}\n")
    if div_rows:
        sys.stderr.write("DIVERGENCES:\n")
        for src, v, r in div_rows:
            sys.stderr.write(f"  {v}\t{src}\t{r}\n")
    sys.exit(0)


if __name__ == "__main__":
    main()
