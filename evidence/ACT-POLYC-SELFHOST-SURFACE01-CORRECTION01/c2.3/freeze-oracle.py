#!/usr/bin/env python3
"""Capture Python oracle outputs for C2.3 RED."""
import io, os, sys, contextlib, importlib.util, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
PY   = os.path.normpath(os.path.join(HERE, "..", "..", "..",
                                     "scripts", "quality",
                                     "factory-halt-classification.py"))
OUT  = os.path.join(HERE, "raw")
os.makedirs(OUT, exist_ok=True)

spec = importlib.util.spec_from_file_location("fhc", PY)
mod  = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

def run_classify(msg):
    buf_out = io.StringIO()
    with contextlib.redirect_stdout(buf_out):
        v = mod.classify(msg)
        mod._emit(v)
    rc = 0 if v.status == "PASS" else 1
    return buf_out.getvalue(), "", rc

def write_triple(name, out, err, rc):
    open(os.path.join(OUT, f"{name}.stdout"), "w").write(out)
    open(os.path.join(OUT, f"{name}.stderr"), "w").write(err)
    open(os.path.join(OUT, f"{name}.rc"),     "w").write(f"{rc}\n")

for name, want_rc, msg in mod._FIXTURES:
    base = name.split()[0]
    out, err, rc = run_classify(msg)
    write_triple(base, out, err, rc)

# usage error
buf = io.StringIO()
with contextlib.redirect_stdout(buf):
    rc = mod.main(["fhc.py"])
write_triple("USAGE", buf.getvalue(), "", rc)

# missing file
tmpdir = tempfile.mkdtemp()
miss = os.path.join(tmpdir, "no-such-file")
buf = io.StringIO()
with contextlib.redirect_stdout(buf):
    rc = mod.main(["fhc.py", miss])
write_triple("MISSING_FILE", buf.getvalue(), "", rc)

# adversarial differential matrix (ACT §15)
D = {
  "D01": ("subject\n\nbody\n\n"
          "ACT: ACT-POLYC-D01\nACT-Phase: CLOSE\nACT-Verdict: PASS\n"),
  "D02": ("subject\n\nbody\n\n"
          "ACT: ACT-POLYC-D02\nACT-Phase: CLOSE\nACT-Verdict: PASS\n"
          "HALT_CLASS: GOVERNANCE\n"),
  "D03": ("subject\n\nbody\n\n"
          "ACT: ACT-POLYC-D03\nACT-Phase: CLOSE\nACT-Verdict: PASS\n"
          "BLOCKS_NEXT: NO\n"),
  "D04": ("subject\n\nbody\n\n"
          "ACT: ACT-POLYC-D04\nACT-Phase: CLOSE\n"
          "ACT-Verdict: HALT_GOVERNANCE_HALT\n"
          "HALT_CLASS: GOVERNANCE\nBLOCKS_NEXT: NO\n"),
  "D05": ("subject\n\nbody\n\n"
          "ACT: ACT-POLYC-D05\nACT-Phase: CLOSE\n"
          "ACT-Verdict: HALT_PRODUCTION_DEFECT\n"
          "HALT_CLASS: PRODUCTION\nBLOCKS_NEXT: YES\n"),
  "D06": ("subject\n\nbody\n\n"
          "ACT: ACT-POLYC-D06\nACT-Phase: CLOSE\n"
          "ACT-Verdict: HALT_PRODUCTION_DEFECT\n"
          "BLOCKS_NEXT: YES\n"),
  "D07": ("subject\n\nbody\n\n"
          "ACT: ACT-POLYC-D07\nACT-Phase: CLOSE\n"
          "ACT-Verdict: HALT_PRODUCTION_DEFECT\n"
          "HALT_CLASS: PRODUCTION\n"),
  "D08": ("subject\n\nbody\n\n"
          "ACT: ACT-POLYC-D08\nACT-Phase: CLOSE\n"
          "ACT-Verdict: HALT_GOVERNANCE_HALT\n"
          "ACT-Verdict: HALT_PRODUCTION_DEFECT\n"
          "HALT_CLASS: GOVERNANCE\nBLOCKS_NEXT: NO\n"),
  "D09": ("subject\n\nbody\n\n"
          "ACT: ACT-POLYC-D09\nACT-Phase: CLOSE\n"
          "ACT-Verdict: HALT_PRODUCTION_DEFECT\n"
          "HALT_CLASS: PRODUCTION\nHALT_CLASS: SAFETY\n"
          "BLOCKS_NEXT: YES\n"),
  "D10": ("subject\n\nbody\n\n"
          "ACT: ACT-POLYC-D10\nACT-Phase: CLOSE\n"
          "ACT-Verdict: HALT_PRODUCTION_DEFECT\n"
          "HALT_CLASS: PRODUCTION\n"
          "BLOCKS_NEXT: YES\nBLOCKS_NEXT: NO\n"),
  "D11": ("subject\n\nbody\n\n"
          "ACT: ACT-POLYC-D11\nACT-Phase: CLOSE\n"
          "ACT-Verdict: HALT_PRODUCTION_DEFECT\n"
          "HALT_CLASS: BOGUS\nBLOCKS_NEXT: YES\n"),
  "D12": ("subject\n\nbody\n\n"
          "ACT: ACT-POLYC-D12\nACT-Phase: CLOSE\n"
          "ACT-Verdict: HALT_PRODUCTION_DEFECT\n"
          "HALT_CLASS: PRODUCTION\nBLOCKS_NEXT: MAYBE\n"),
  "D13": ("subject\n\nbody\n\n"
          "ACT: ACT-POLYC-D13\nACT-Phase: CLOSE\n"
          "ACT-Verdict: HALT_PRODUCTION_DEFECT\n"
          "HALT_CLASS: PRODUCTION\nBLOCKS_NEXT: yes\n"),
  "D14": ("subject\n\nbody\n\n"
          "ACT: ACT-POLYC-D14\nACT-Phase: CLOSE\n"
          "ACT-Verdict: HALT_PRODUCTION_DEFECT\n"
          " HALT_CLASS: PRODUCTION\n"
          "BLOCKS_NEXT: YES\n"),
  "D15": ("subject\n\nbody\n\n"
          "ACT-Verdict: HALT_PRODUCTION_DEFECT\n"
          "ACT-Phase: CLOSE\n"
          "ACT: ACT-POLYC-D15\n"
          "HALT_CLASS: PRODUCTION\n"
          "BLOCKS_NEXT: YES\n"),
  "D16": ("subject\n\n"
          "ACT: ACT-POLYC-D16\nACT-Phase: CLOSE\n"
          "ACT-Verdict: HALT_PRODUCTION_DEFECT\n"
          "ACT-Verdict: HALT_GOVERNANCE_HALT\n"
          "HALT_CLASS: GOVERNANCE\nBLOCKS_NEXT: NO\n"),
  "D17": (""),
  "D18": ("\n"),
  "D19": ("subject\n\nbody\n\n"
          "ACT: ACT-POLYC-D19\nACT-Phase: CLOSE\n"
          "ACT-Verdict: HALT_PRODUCTION_DEFECT\n"
          "HALT_CLASS: PRODUCTION\nBLOCKS_NEXT: YES\n"
          + ("X" * 5000)),
  "D20": ("subject\n\nbody\n\n"
          "ACT: ACT-POLYC-D20\nACT-Phase: CLOSE\n"
          "ACT-Verdict: HALT_PRODUCTION_DEFECT\n"
          "HALT_CLASS: PRODUCTION\nBLOCKS_NEXT: YES"),
  "D21": ("subject\r\n\r\nbody\r\n\r\n"
          "ACT: ACT-POLYC-D21\r\nACT-Phase: CLOSE\r\n"
          "ACT-Verdict: HALT_PRODUCTION_DEFECT\r\n"
          "HALT_CLASS: PRODUCTION\r\nBLOCKS_NEXT: YES\r\n"),
  "D22": ("subject\n\nbody\n\n"
          "ACT: ACT-POLYC-D22\nACT-Phase: CLOSE\n"
          "ACT-Verdict: HALT_PRODUCTION_DEFECT\n"
          "HALT_CLASS: PRODUCTION\n"
          "BLOCKS_NEXT: YES: extra\n"),
  "D23": ("subject\n\nbody\n\n\n\n\n"
          "ACT: ACT-POLYC-D23\nACT-Phase: CLOSE\n"
          "ACT-Verdict: HALT_PRODUCTION_DEFECT\n"
          "HALT_CLASS: PRODUCTION\nBLOCKS_NEXT: YES\n"),
  "D24": ("subject\n\nbody\n\n"
          "ACT: ACT-POLYC-D24\nACT-Phase: CLOSE\n"
          "ACT-Verdict: HALT_PRODUCTION_DEFECT\n"
          "BAD KEY NO COLON\n"
          "HALT_CLASS: PRODUCTION\nBLOCKS_NEXT: YES\n"),
}
for k, msg in D.items():
    out, err, rc = run_classify(msg)
    write_triple(k, out, err, rc)

# matrix-mode
buf = io.StringIO()
with contextlib.redirect_stdout(buf):
    rc = mod.run_matrix()
write_triple("MATRIX", buf.getvalue(), "", rc)

print("Captured fixtures + adversarial into", OUT)
print("Existing fixtures:", len(mod._FIXTURES))
print("Adversarial D    :", len(D))
print("Specials         : USAGE, MISSING_FILE, MATRIX")
print("Total captures   :", len(mod._FIXTURES) + len(D) + 3)
