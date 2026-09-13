#!/usr/bin/env python3
"""Capture PolyC outputs for every frozen input.

For each fixture (R1..R12 + D01..D24 + USAGE/MISSING_FILE/MATRIX)
this writes:
  <dir>/polyc-raw/<name>.stdout
  <dir>/polyc-raw/<name>.stderr
  <dir>/polyc-raw/<name>.rc

Used by capture-and-diff.sh / make_diff_tsvs.sh to materialise
the polyc-side evidence before byte-comparison.
"""
import os, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
POLY = os.path.join(REPO, "build", "factory-halt-classification")
OUT  = os.path.join(HERE, "polyc-raw")
os.makedirs(OUT, exist_ok=True)

# Load the Python oracle and reuse its _FIXTURES + adversarial inputs
# so we test the same bytes on both sides.
sys.path.insert(0, os.path.join(REPO, "scripts", "quality"))
import importlib.util
spec = importlib.util.spec_from_file_location(
    "fhc",
    os.path.join(REPO, "scripts", "quality", "factory-halt-classification.py"))
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

# Same adversarial matrix as freeze-oracle.py / differential.py.
ADV = {
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

def write_triple(name, out, err, rc):
    open(os.path.join(OUT, f"{name}.stdout"), "wb").write(out)
    open(os.path.join(OUT, f"{name}.stderr"), "wb").write(err)
    open(os.path.join(OUT, f"{name}.rc"), "w").write(f"{rc}\n")

# Per-fixture inputs (12 + 24 = 36).
for name, _want_rc, msg in mod._FIXTURES:
    base = name.split()[0]
    tf = tempfile.NamedTemporaryFile(mode="w", delete=False, suffix=".txt")
    tf.write(msg); tf.close()
    p = subprocess.run([POLY, tf.name], capture_output=True, timeout=10)
    write_triple(base, p.stdout, p.stderr, p.returncode)
    os.unlink(tf.name)

for k, msg in ADV.items():
    tf = tempfile.NamedTemporaryFile(mode="w", delete=False, suffix=".txt")
    tf.write(msg); tf.close()
    p = subprocess.run([POLY, tf.name], capture_output=True, timeout=10)
    write_triple(k, p.stdout, p.stderr, p.returncode)
    os.unlink(tf.name)

# USAGE
p = subprocess.run([POLY], capture_output=True, timeout=10)
write_triple("USAGE", p.stdout, p.stderr, p.returncode)

# MATRIX
p = subprocess.run([POLY, "--matrix"], capture_output=True, timeout=10)
write_triple("MATRIX", p.stdout, p.stderr, p.returncode)

# MISSING_FILE — use the same synthetic path the differential driver
# uses, so byte parity is achievable.
MISS = "/tmp/this_file_definitely_does_not_exist_for_differential_test.txt"
p = subprocess.run([POLY, MISS], capture_output=True, timeout=10)
write_triple("MISSING_FILE", p.stdout, p.stderr, p.returncode)

print(f"Wrote {len(mod._FIXTURES) + len(ADV) + 3} polyc captures under {OUT}")
