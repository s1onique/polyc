#!/usr/bin/env python3
"""Build the differential TSV tables (existing / adversarial /
special) from raw/ + polyc-raw/.
"""
import hashlib, os

HERE = os.path.dirname(os.path.abspath(__file__))
PY_RAW = os.path.join(HERE, "raw")
PO_RAW = os.path.join(HERE, "polyc-raw")

def sha(p):
    return hashlib.sha256(open(p, "rb").read()).hexdigest()

def triple(dir_, name):
    o = sha(os.path.join(dir_, f"{name}.stdout"))
    e = sha(os.path.join(dir_, f"{name}.stderr"))
    rc = open(os.path.join(dir_, f"{name}.rc"), "rb").read().decode().strip()
    return o, e, rc

FIX = [f"R{i}" for i in range(1, 13)]
ADV = [f"D{i:02d}" for i in range(1, 25)]
SPE = ["USAGE", "MISSING_FILE", "MATRIX"]

def emit(path, ids, label):
    n_pass = 0
    with open(path, "w") as f:
        f.write(f"{label}_id\tpython_rc\tpolyc_rc\tpython_stdout_sha256\tpolyc_stdout_sha256\tstdout_eq\tpython_stderr_sha256\tpolyc_stderr_sha256\tstderr_eq\trc_eq\tresult\n")
        for fid in ids:
            py_o, py_e, py_rc = triple(PY_RAW, fid)
            po_o, po_e, po_rc = triple(PO_RAW, fid)
            so = py_o == po_o; se = py_e == po_e; rc = py_rc == po_rc
            ok = so and se and rc
            if ok: n_pass += 1
            f.write(f"{fid}\t{py_rc}\t{po_rc}\tsha256:{py_o}\tsha256:{po_o}\t{'EQ' if so else 'NE'}\t"
                    f"sha256:{py_e}\tsha256:{po_e}\t{'EQ' if se else 'NE'}\t{'EQ' if rc else 'NE'}\t"
                    f"{'PASS' if ok else 'FAIL'}\n")
    print(f"{path}: {n_pass}/{len(ids)} PASS")

emit(os.path.join(HERE, "existing-fixtures-differential.tsv"), FIX, "fixture_id")
emit(os.path.join(HERE, "adversarial-differential.tsv"),       ADV, "fixture_id")
emit(os.path.join(HERE, "special-modes-differential.tsv"),      SPE, "case")
