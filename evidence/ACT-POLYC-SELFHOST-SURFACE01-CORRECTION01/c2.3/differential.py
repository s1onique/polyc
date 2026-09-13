#!/usr/bin/env python3
"""Differential driver for C2.3 — runs every frozen input through
both the Python oracle and the PolyC subject and compares stdout,
stderr, and exit code byte-for-byte.
"""
import os, subprocess, sys, tempfile, hashlib

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
PY  = os.path.join(REPO, "scripts", "quality", "factory-halt-classification.py")
POLY = os.path.join(REPO, "build", "factory-halt-classification")

if len(sys.argv) >= 3:
    PY, POLY = sys.argv[1], sys.argv[2]
elif len(sys.argv) == 2:
    PY = sys.argv[1]

PY = os.path.abspath(PY)
POLY = os.path.abspath(POLY)

def sha(b): return hashlib.sha256(b).hexdigest()

def run(cmd, stdin_data=None):
    p = subprocess.run(cmd, input=stdin_data, capture_output=True, timeout=10)
    return p.stdout, p.stderr, p.returncode

results = []

FIX = [
  ("R1",  "subject\n\nbody\n\nACT: ACT-POLYC-EXAMPLE01\nACT-Phase: CLOSE\nACT-Verdict: HALT_GOVERNANCE_HALT\nHALT_CLASS: GOVERNANCE\nBLOCKS_NEXT: NO"),
  ("R2",  "subject\n\nbody\n\nACT: ACT-POLYC-EXAMPLE02\nACT-Phase: CLOSE\nACT-Verdict: HALT_PRODUCTION_DEFECT\nHALT_CLASS: PRODUCTION\nBLOCKS_NEXT: YES"),
  ("R3",  "subject\n\nACT: ACT-POLYC-EXAMPLE03\nACT-Phase: CLOSE\nACT-Verdict: HALT_X\nBLOCKS_NEXT: YES"),
  ("R4",  "subject\n\nACT: ACT-POLYC-EXAMPLE04\nACT-Phase: CLOSE\nACT-Verdict: HALT_X\nHALT_CLASS: PRODUCTION"),
  ("R5",  "subject\n\nACT: ACT-POLYC-EXAMPLE05\nACT-Phase: CLOSE\nACT-Verdict: PASS\nBLOCKS_NEXT: YES"),
  ("R6",  "subject\n\nACT: ACT-POLYC-EXAMPLE06\nACT-Phase: CLOSE\nACT-Verdict: HALT_GOVERNANCE_HALT\nHALT_CLASS: GOVERNANCE\nBLOCKS_NEXT: YES"),
  ("R7",  "subject\n\nACT: ACT-POLYC-EXAMPLE07\nACT-Phase: CLOSE\nACT-Verdict: HALT_PRODUCTION_DEFECT\nHALT_CLASS: PRODUCTION\nBLOCKS_NEXT: NO"),
  ("R8",  "subject\n\nbody\n\nACT: ACT-POLYC-EXAMPLE08\nACT-Phase: CLOSE\nACT-Verdict: PASS"),
  ("R9",  "subject\n\nACT: ACT-POLYC-EXAMPLE09\nACT-Phase: CLOSE\nACT-Verdict: HALT_DEPENDENCY_HALT\nHALT_CLASS: DEPENDENCY\nBLOCKS_NEXT: YES"),
  ("R10", "subject\n\nACT: ACT-POLYC-EXAMPLE10\nACT-Phase: CLOSE\nACT-Verdict: HALT_DEPENDENCY_HALT\nHALT_CLASS: DEPENDENCY\nBLOCKS_NEXT: NO"),
  ("R11", "ordinary commit message\n\nno trailers here"),
  ("R12", "subject\n\nACT: ACT-POLYC-EXAMPLE12\nACT-Phase: RED\nACT-Verdict: HALT_DRAFT"),
]

D = {
  "D01": "subject\n\nbody\n\nACT: ACT-POLYC-D01\nACT-Phase: CLOSE\nACT-Verdict: PASS\n",
  "D02": "subject\n\nbody\n\nACT: ACT-POLYC-D02\nACT-Phase: CLOSE\nACT-Verdict: PASS\nHALT_CLASS: GOVERNANCE\n",
  "D03": "subject\n\nbody\n\nACT: ACT-POLYC-D03\nACT-Phase: CLOSE\nACT-Verdict: PASS\nBLOCKS_NEXT: NO\n",
  "D04": "subject\n\nbody\n\nACT: ACT-POLYC-D04\nACT-Phase: CLOSE\nACT-Verdict: HALT_GOVERNANCE_HALT\nHALT_CLASS: GOVERNANCE\nBLOCKS_NEXT: NO\n",
  "D05": "subject\n\nbody\n\nACT: ACT-POLYC-D05\nACT-Phase: CLOSE\nACT-Verdict: HALT_PRODUCTION_DEFECT\nHALT_CLASS: PRODUCTION\nBLOCKS_NEXT: YES\n",
  "D06": "subject\n\nbody\n\nACT: ACT-POLYC-D06\nACT-Phase: CLOSE\nACT-Verdict: HALT_PRODUCTION_DEFECT\nBLOCKS_NEXT: YES\n",
  "D07": "subject\n\nbody\n\nACT: ACT-POLYC-D07\nACT-Phase: CLOSE\nACT-Verdict: HALT_PRODUCTION_DEFECT\nHALT_CLASS: PRODUCTION\n",
  "D08": "subject\n\nbody\n\nACT: ACT-POLYC-D08\nACT-Phase: CLOSE\nACT-Verdict: HALT_GOVERNANCE_HALT\nACT-Verdict: HALT_PRODUCTION_DEFECT\nHALT_CLASS: GOVERNANCE\nBLOCKS_NEXT: NO\n",
  "D09": "subject\n\nbody\n\nACT: ACT-POLYC-D09\nACT-Phase: CLOSE\nACT-Verdict: HALT_PRODUCTION_DEFECT\nHALT_CLASS: PRODUCTION\nHALT_CLASS: SAFETY\nBLOCKS_NEXT: YES\n",
  "D10": "subject\n\nbody\n\nACT: ACT-POLYC-D10\nACT-Phase: CLOSE\nACT-Verdict: HALT_PRODUCTION_DEFECT\nHALT_CLASS: PRODUCTION\nBLOCKS_NEXT: YES\nBLOCKS_NEXT: NO\n",
  "D11": "subject\n\nbody\n\nACT: ACT-POLYC-D11\nACT-Phase: CLOSE\nACT-Verdict: HALT_PRODUCTION_DEFECT\nHALT_CLASS: BOGUS\nBLOCKS_NEXT: YES\n",
  "D12": "subject\n\nbody\n\nACT: ACT-POLYC-D12\nACT-Phase: CLOSE\nACT-Verdict: HALT_PRODUCTION_DEFECT\nHALT_CLASS: PRODUCTION\nBLOCKS_NEXT: MAYBE\n",
  "D13": "subject\n\nbody\n\nACT: ACT-POLYC-D13\nACT-Phase: CLOSE\nACT-Verdict: HALT_PRODUCTION_DEFECT\nHALT_CLASS: PRODUCTION\nBLOCKS_NEXT: yes\n",
  "D14": "subject\n\nbody\n\nACT: ACT-POLYC-D14\nACT-Phase: CLOSE\nACT-Verdict: HALT_PRODUCTION_DEFECT\n HALT_CLASS: PRODUCTION\nBLOCKS_NEXT: YES\n",
  "D15": "subject\n\nbody\n\nACT-Verdict: HALT_PRODUCTION_DEFECT\nACT-Phase: CLOSE\nACT: ACT-POLYC-D15\nHALT_CLASS: PRODUCTION\nBLOCKS_NEXT: YES\n",
  "D16": "subject\n\nACT: ACT-POLYC-D16\nACT-Phase: CLOSE\nACT-Verdict: HALT_PRODUCTION_DEFECT\nACT-Verdict: HALT_GOVERNANCE_HALT\nHALT_CLASS: GOVERNANCE\nBLOCKS_NEXT: NO\n",
  "D17": "",
  "D18": "\n",
  "D19": "subject\n\nbody\n\nACT: ACT-POLYC-D19\nACT-Phase: CLOSE\nACT-Verdict: HALT_PRODUCTION_DEFECT\nHALT_CLASS: PRODUCTION\nBLOCKS_NEXT: YES\n" + ("X" * 5000),
  "D20": "subject\n\nbody\n\nACT: ACT-POLYC-D20\nACT-Phase: CLOSE\nACT-Verdict: HALT_PRODUCTION_DEFECT\nHALT_CLASS: PRODUCTION\nBLOCKS_NEXT: YES",
  "D21": "subject\r\n\r\nbody\r\n\r\nACT: ACT-POLYC-D21\r\nACT-Phase: CLOSE\r\nACT-Verdict: HALT_PRODUCTION_DEFECT\r\nHALT_CLASS: PRODUCTION\r\nBLOCKS_NEXT: YES\r\n",
  "D22": "subject\n\nbody\n\nACT: ACT-POLYC-D22\nACT-Phase: CLOSE\nACT-Verdict: HALT_PRODUCTION_DEFECT\nHALT_CLASS: PRODUCTION\nBLOCKS_NEXT: YES: extra\n",
  "D23": "subject\n\nbody\n\n\n\n\nACT: ACT-POLYC-D23\nACT-Phase: CLOSE\nACT-Verdict: HALT_PRODUCTION_DEFECT\nHALT_CLASS: PRODUCTION\nBLOCKS_NEXT: YES\n",
  "D24": "subject\n\nbody\n\nACT: ACT-POLYC-D24\nACT-Phase: CLOSE\nACT-Verdict: HALT_PRODUCTION_DEFECT\nBAD KEY NO COLON\nHALT_CLASS: PRODUCTION\nBLOCKS_NEXT: YES\n",
}

all_ids = [r[0] for r in FIX] + list(D.keys())

for fid in all_ids:
    if fid.startswith("R"):
        msg = next(r[1] for r in FIX if r[0] == fid)
    else:
        msg = D[fid]
    tf = tempfile.NamedTemporaryFile(mode="w", delete=False, suffix=".txt")
    tf.write(msg); tf.close()
    path = tf.name
    try:
        po, pe, prc = run(["python3", PY, path])
        so, se, src = run([POLY, path])
        ok = (po == so) and (pe == se) and (prc == src)
        results.append((fid, ok, po == so, pe == se, prc == src,
                        prc, src, sha(po), sha(so)))
    finally:
        os.unlink(path)

# USAGE error (no args).
po, pe, prc = run(["python3", PY])
so, se, src = run([POLY])
results.append(("USAGE", po == so and pe == se and prc == src,
                po == so, pe == se, prc == src,
                prc, src, sha(po), sha(so)))

# MATRIX mode (--matrix).
po, pe, prc = run(["python3", PY, "--matrix"])
so, se, src = run([POLY, "--matrix"])
results.append(("MATRIX", po == so and pe == se and prc == src,
                po == so, pe == se, prc == src,
                prc, src, sha(po), sha(so)))

# MISSING_FILE: use same synthetic path for both.
MISS = "/tmp/this_file_definitely_does_not_exist_for_differential_test.txt"
po, pe, prc = run(["python3", PY, MISS])
so, se, src = run([POLY, MISS])
results.append(("MISSING_FILE", po == so and pe == se and prc == src,
                po == so, pe == se, prc == src,
                prc, src, sha(po), sha(so)))

print(f"{'ID':<14} {'OK':<5} {'STDOUT':<7} {'STDERR':<7} {'RC':<4} {'py_rc':<5} {'po_rc':<5}")
ok_count = 0
for fid, ok, so, se, src_eq, pyrc, polyc, _pysha, _polysha in results:
    print(f"{fid:<14} {'PASS' if ok else 'FAIL':<5} "
          f"{'EQ' if so else 'NE':<7} {'EQ' if se else 'NE':<7} "
          f"{'EQ' if src_eq else 'NE':<4} "
          f"{pyrc:<5} {polyc:<5}")
    if ok: ok_count += 1

print()
print(f"DIFFERENTIAL_PASS={ok_count}")
print(f"DIFFERENTIAL_TOTAL={len(results)}")
sys.exit(0 if ok_count == len(results) else 1)
