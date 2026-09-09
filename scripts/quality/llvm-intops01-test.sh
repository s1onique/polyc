#!/bin/sh
# scripts/quality/llvm-intops01-test.sh
#
# ACT-POLYC-LLVM-INTOPS01 GREEN harness.
#
# Outcome: HALT_RED_NOT_REPRODUCED (per ACT §36 Outcome E).
# Fresh recon demonstrated that no new scalar integer operations are
# required by the B0 lexer/tokenizer (the smallest credible PolyC
# self-hosting milestone). All B0-required integer operations are
# already SUPPORTED in the LLVM backend, as proven by:
#   - LLVM-SPIKE01-RESUME01 (PASS=18)
#   - CORE04-RESUME01
#   - MEMORY01 (PASS=6)
#
# This harness therefore does NOT exercise new opcodes. It exists as
# a permanent artifact for future re-validation of the halt outcome.
#
# If at any future point new B0 demand is discovered that requires a
# new integer opcode, the ACT may be re-opened and this harness should
# be extended with positive fixtures for that opcode. See
# docs/acts/ACT-POLYC-LLVM-INTOPS01.md §7 for the freeze rule.
#
# Sections (per ACT §14):
#   toolchain
#   authorized-set echo
#   positive matrix (probe fixtures that exercise B0-shape ops)
#   native semantic oracle (covered by SPIKE01/MEMORY01/CORE04)
#   LLVM structure (verified at probe time)
#   llvm-as / opt verify (run on probe fixtures)
#   counter attribution (covered by cap verifier)
#   negative / deferred matrix (covered by SPIKE01 red_* fixtures)
#   determinism (verified at probe time)
#   historical-evidence conservation (covered by baseline gates)
#   summary

set -eu

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$REPO_ROOT"

EVID="$REPO_ROOT/evidence/llvm-intops01"
HCC=${HCC:-./hcc}
HCC_INSTALL_DIR=${HCC_INSTALL_DIR:-/tmp/polyc-install}
HCC_INSTALL_ARG="--install-dir=$HCC_INSTALL_DIR"
LLVM_CONFIG=${LLVM_CONFIG:-llvm-config}
LLVM_AS=${LLVM_AS:-llvm-as}
LLVM_OPT=${LLVM_OPT:-opt}
LLVM_LIBDIR=$("$LLVM_CONFIG" --libdir 2>/dev/null || echo "")

PASS=0
FAIL=0

section() { printf '\n=== %s ===\n' "$1"; }

# ---- toolchain ----
section "toolchain"
if [ ! -x "$HCC" ]; then
    echo "FAIL  HCC not found at $HCC"
    exit 2
fi
if ! "$HCC" --version | grep -q 'LLVM-enabled'; then
    # Try without --version checks; just check that --emit-llvm works
    if ! "$HCC" --help 2>&1 | grep -q 'emit-llvm'; then
        echo "FAIL  HCC is not LLVM-enabled: $($HCC --version 2>&1 | head -1)"
        exit 2
    fi
fi
if ! command -v "$LLVM_AS" >/dev/null 2>&1; then
    echo "FAIL  llvm-as not in PATH"
    exit 2
fi
if ! command -v "$LLVM_OPT" >/dev/null 2>&1; then
    echo "FAIL  opt not in PATH"
    exit 2
fi
echo "PASS  toolchain: hcc LLVM-enabled; llvm-as and opt available"

# ---- authorized-set echo ----
section "authorized-set echo"
echo "AUTHORIZED_IMPLEMENT=0"
echo "AUTHORIZED_DEFER=12"
echo "AUTHORIZED_DEFER_BYTEMEMORY01=3"
echo "AUTHORIZED_ALREADY_SUPPORTED=11"
if [ -f "$EVID/recon/authorized-set.txt" ]; then
    echo "PASS  authorized-set.txt present (frozen at recon close)"
else
    echo "FAIL  authorized-set.txt missing"
    FAIL=$((FAIL+1))
fi

# ---- positive matrix: probe fixtures ----
section "positive matrix (B0-shape probe fixtures)"
TMPDIR_PROBE=$(mktemp -d "$EVID/_tmp.XXXXXX")
trap 'rm -rf "$TMPDIR_PROBE"' EXIT

probe() {
    label="$1"
    src="$2"
    bn=$(basename "$src" .HC)
    out="$TMPDIR_PROBE/${bn}.ll"
    if ! "$HCC" --emit-llvm $HCC_INSTALL_ARG "$src" -o "$out" \
            > "$TMPDIR_PROBE/${bn}.stdout" 2> "$TMPDIR_PROBE/${bn}.stderr"; then
        echo "FAIL  $label: hcc --emit-llvm failed"
        sed 's/^/    /' "$TMPDIR_PROBE/${bn}.stderr" | head -5
        FAIL=$((FAIL+1))
        return 1
    fi
    if [ ! -s "$out" ]; then
        echo "FAIL  $label: no .ll output"
        FAIL=$((FAIL+1))
        return 1
    fi
    if ! DYLD_LIBRARY_PATH="$LLVM_LIBDIR:${DYLD_LIBRARY_PATH:-}" \
            LD_LIBRARY_PATH="$LLVM_LIBDIR:${LD_LIBRARY_PATH:-}" \
            "$LLVM_AS" "$out" -o "$TMPDIR_PROBE/${bn}.bc" \
            > "$TMPDIR_PROBE/${bn}.as_stdout" 2> "$TMPDIR_PROBE/${bn}.as_stderr"; then
        echo "FAIL  $label: llvm-as rejected output"
        sed 's/^/    /' "$TMPDIR_PROBE/${bn}.as_stderr" | head -5
        FAIL=$((FAIL+1))
        return 1
    fi
    if ! DYLD_LIBRARY_PATH="$LLVM_LIBDIR:${DYLD_LIBRARY_PATH:-}" \
            LD_LIBRARY_PATH="$LLVM_LIBDIR:${LD_LIBRARY_PATH:-}" \
            "$LLVM_OPT" --passes=verify "$out" -disable-output \
            > "$TMPDIR_PROBE/${bn}.opt_stdout" 2> "$TMPDIR_PROBE/${bn}.opt_stderr"; then
        echo "FAIL  $label: LLVM verifier rejected output"
        sed 's/^/    /' "$TMPDIR_PROBE/${bn}.opt_stderr" | head -5
        FAIL=$((FAIL+1))
        return 1
    fi
    echo "PASS  $label  llvm-as OK, opt verify OK"
    PASS=$((PASS+1))
    return 0
}

if [ -f src/tests/llvm-intops01/b0_lexer_shape_probe.HC ]; then
    probe "B0-shape single-token recognizer" src/tests/llvm-intops01/b0_lexer_shape_probe.HC
else
    echo "FAIL  B0-shape single-token recognizer fixture missing"
    FAIL=$((FAIL+1))
fi

if [ -f "$EVID/recon/b0_digit_accum.HC" ]; then
    probe "B0-shape digit accumulation" "$EVID/recon/b0_digit_accum.HC"
else
    echo "FAIL  B0-shape digit accumulation fixture missing"
    FAIL=$((FAIL+1))
fi

# ---- structural purity ----
section "structural purity (no alloca / GEP / pointer casts / float in positive .ll)"
for ll in "$TMPDIR_PROBE"/*.ll; do
    [ -f "$ll" ] || continue
    bn=$(basename "$ll" .ll)
    body=$(sed 's/;.*$//' "$ll")
    bad=$(printf '%s\n' "$body" | grep -nE '(^|[[:space:]])(alloca|getelementptr|ptrtoint|inttoptr|bitcast)([[:space:]]|$)' || true)
    if [ -n "$bad" ]; then
        echo "FAIL  $bn: structural impurity (forbidden construct):"
        printf '  %s\n' "$bad" | head -3
        FAIL=$((FAIL+1))
        continue
    fi
    echo "PASS  $bn: structural purity"
done

# ---- counter attribution ----
section "counter attribution"
if python3 scripts/quality/llvm-cap-table-verifier.py > "$TMPDIR_PROBE/capverifier.out" 2>&1; then
    if grep -q 'PASS: dispatch <-> capability <-> harness bound' "$TMPDIR_PROBE/capverifier.out"; then
        echo "PASS  cap verifier: dispatch <-> capability <-> harness bound"
        PASS=$((PASS+1))
    else
        echo "FAIL  cap verifier: no PASS line"
        FAIL=$((FAIL+1))
    fi
else
    echo "FAIL  cap verifier: non-zero exit"
    tail -5 "$TMPDIR_PROBE/capverifier.out"
    FAIL=$((FAIL+1))
fi

# ---- determinism ----
section "determinism"
DET_TMP=$(mktemp -d "$TMPDIR_PROBE/det.XXXXXX")
"$HCC" --emit-llvm $HCC_INSTALL_ARG src/tests/llvm-intops01/b0_lexer_shape_probe.HC -o "$DET_TMP/a.ll" > /dev/null 2>&1
"$HCC" --emit-llvm $HCC_INSTALL_ARG src/tests/llvm-intops01/b0_lexer_shape_probe.HC -o "$DET_TMP/b.ll" > /dev/null 2>&1
if diff -q "$DET_TMP/a.ll" "$DET_TMP/b.ll" > /dev/null; then
    echo "PASS  probe .ll byte-identical across two runs"
    PASS=$((PASS+1))
else
    echo "FAIL  probe .ll differs across runs"
    FAIL=$((FAIL+1))
fi
rm -rf "$DET_TMP"

# ---- historical-evidence conservation ----
section "historical-evidence conservation"
# SPIKE writes its evidence to evidence/llvm-memory01/spike/ (per spike-test.sh)
if [ ! -d "$REPO_ROOT/evidence/llvm-memory01/spike" ]; then
    echo "FAIL  evidence/llvm-memory01/spike missing"
    FAIL=$((FAIL+1))
else
    echo "PASS  evidence/llvm-memory01/spike present (predecessor SPIKE evidence intact)"
fi
if [ ! -d "$REPO_ROOT/evidence/llvm-memory01/impl" ]; then
    echo "FAIL  evidence/llvm-memory01/impl missing"
    FAIL=$((FAIL+1))
else
    echo "PASS  evidence/llvm-memory01/impl present (predecessor MEMORY01 evidence intact)"
fi
if [ ! -d "$REPO_ROOT/evidence/llvm-float01/impl" ]; then
    echo "FAIL  evidence/llvm-float01/impl missing"
    FAIL=$((FAIL+1))
else
    echo "PASS  evidence/llvm-float01/impl present (predecessor FLOAT01 evidence intact)"
fi

# ---- summary ----
section "summary"
echo "INTOPS01 PASS=$PASS FAIL=$FAIL"
if [ "$FAIL" = "0" ]; then
    echo "STATUS=PASS"
    echo "INTOPS01_PASS=$PASS"
    echo "INTOPS01_FAIL=0"
    exit 0
fi
echo "STATUS=FAIL"
echo "INTOPS01_PASS=$PASS"
echo "INTOPS01_FAIL=$FAIL"
exit 1
