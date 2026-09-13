#!/bin/sh
# Opt-in Dafny formal gate; ACT-POLYC2-DAFNY-PROOF-MVP01
# and -CORRECTION01. Single stable repo entrypoint.
# Invariants: I1/I2 toolchain identity fail-closed; I3
# ephemeral runtime dir (build/, never evidence/);
# I4 audit exit preserved; I5 exact-summary parse;
# I6 audit report empty. Not wired into gate-fast.
#
# Solver binding: the verify step passes
# --solver-path "$Z3" so the Z3 executable we
# mechanically checked is the EXACT solver process
# Dafny uses (not whatever happens to be first on
# PATH). See ACT-POLYC2-DAFNY-PROOF-MVP01-CORRECTION01
# D15.
set -eu
S=$(cd "$(dirname "$0")" && pwd); cd "$(cd "$S/../.." && pwd)"
DAFNY=tools/dafny/dafny-4.11.0/dafny/dafny
Z3=tools/dafny/dafny-4.11.0/dafny/z3/bin/z3-4.12.1
DFY=formal/dafny/identifier-scan.dfy
E_DAFNY=4.11.0+fcb2042d6d043a2634f0854338c08feeaaaf4ae2
E_Z3="Z3 version 4.12.1"
R=build/formal-dafny
[ -x "$DAFNY" ] && [ -x "$Z3" ] && [ -f "$DFY" ] \
  || { echo FATAL: dafny/z3/model missing >&2; exit 2; }
A_DAFNY=$("$DAFNY" --version 2>/dev/null || true)
A_Z3=$("$Z3" -version 2>/dev/null || true)
[ "$A_DAFNY" = "$E_DAFNY" ] \
  || { echo FATAL: dafny version mismatch expected=$E_DAFNY actual=${A_DAFNY:-empty} >&2; exit 3; }
case "$A_Z3" in "$E_Z3"*) ;; *) echo FATAL: z3 version mismatch actual=${A_Z3:-empty} >&2; exit 3 ;; esac
export PATH="$(dirname "$Z3"):$PATH"; mkdir -p "$R"
RV=$R/verify.txt; RA=$R/audit.txt; RAS=$R/audit-stdout.txt; RAE=$R/audit-stderr.txt
echo POLYC_GATE=formal-dafny DAFNY_VERSION="$A_DAFNY" Z3_VERSION="$A_Z3" RUNTIME_DIR="$R"
set +e
"$DAFNY" verify --solver-path "$Z3" --warn-redundant-assumptions --warn-contradictory-assumptions "$DFY" >"$RV" 2>&1
VRC=$?
set -e
cat "$RV"
[ "$VRC" -eq 0 ] || { echo FATAL: verify non-zero >&2; exit 1; }
set +e; "$DAFNY" audit --report-file "$RA" --report-format txt "$DFY" >"$RAS" 2>"$RAE"; ARC=$?; set -e
echo AUDIT_RC=$ARC
[ "$ARC" -eq 0 ] || { echo FATAL: audit non-zero exit=$ARC >&2; exit 1; }
SL=$(grep -E '^Dafny auditor completed with [0-9]+ findings$' "$RAS" || true)
[ -n "$SL" ] || { echo FATAL: audit summary not found >&2; cat "$RAS" >&2; exit 1; }
N=$(printf '%s\n' "$SL" | sed -E 's/^Dafny auditor completed with ([0-9]+) findings$/\1/')
echo AUDIT_SUMMARY_N=$N
[ "$N" = 0 ] || { echo FATAL: auditor reported $N findings >&2; cat "$RA" >&2; exit 1; }
[ ! -s "$RA" ] || { echo FATAL: audit report non-empty >&2; cat "$RA" >&2; exit 1; }
echo AUDIT_FINDINGS=0 AUDIT_GATE=PASS
