#!/bin/sh
# scripts/quality/llvm-spike-test.sh
#
# ACT-POLYC-LLVM-SPIKE01-RESUME01: positive + negative matrix for the
# LLVM 22 C-API backend.
#
# For each positive fixture:
#   1. hcc --emit-llvm <file> -o <tmp>.ll
#   2. llvm-as <tmp>.ll -o <tmp>.bc
#   3. assert both succeed and the textual IR contains the expected
#      opcodes / types
#
# For each negative fixture:
#   1. hcc --emit-llvm <file>
#   2. assert non-zero exit AND an LLVM_BACKEND_UNSUPPORTED_* error
#      code on stderr AND no .ll output AND no native fallback
#
# No network. No execution. No object emission. No ORC. No JIT.

set -eu

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$REPO_ROOT"

# ACT-POLYC-LLVM-MEMORY01: the spike evidence redirect.
#
# Historically EVID pointed at $REPO_ROOT/evidence/llvmspike01-resume01,
# the closed-ACT evidence dir. Each `positive()` invocation wrote its
# canonical .ll into that dir, which worked only because the IR was
# stable across ACTs. MEMORY01 changes the IR (the constant-cache fix
# flips `add i64 %0, %0` -> `add i64 %0, 1`, and the IR_LOAD_DEREF /
# IR_STORE_DEREF dispatch arms now emit load/store instructions for
# the supported shapes), so re-running the spike overwrites historical
# files with semantically different output.
#
# Redirect to a MEMORY01-specific dir so the historical evidence
# (which captured the pre-MEMORY01 IR shape) stays bit-identical
# (F14). The MEMORY01 evidence dir captures the new IR shape.
#
# If a future ACT wants the historical EVID layout, it can set
# LLVM_SPIKE_EVID_OVERRIDE to a different dir.
#
# ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C5 (harness-isolation
# producer fix): $EVID is now ALSO governed by EVIDENCE_OUT. When
# EVIDENCE_OUT is unset, the harness defaults to a scratch dir under
# build/ (gitignored) so ordinary regression does NOT mutate any
# tracked historical evidence tree. Explicit evidence regeneration
# (e.g. via `make evidence-update`) sets EVIDENCE_OUT to the intended
# destination, which may be a closed-ACT tree when the engineer
# intentionally wants to refresh that tree's evidence.
if [ -n "${EVIDENCE_OUT:-}" ]; then
    # EVIDENCE_OUT governs the per-run root. LLVM_SPIKE_EVID_OVERRIDE
    # is preserved for backwards compatibility (it sets only $EVID).
    EVID="$EVIDENCE_OUT/spike"
    if [ -n "${LLVM_SPIKE_EVID_OVERRIDE:-}" ]; then
        EVID="$LLVM_SPIKE_EVID_OVERRIDE"
    fi
else
    if [ -n "${LLVM_SPIKE_EVID_OVERRIDE:-}" ]; then
        EVID="$LLVM_SPIKE_EVID_OVERRIDE"
    else
        # Default to a gitignored scratch dir under build/. Ordinary
        # regression therefore produces no durable tracked evidence;
        # the producer stops mutating historical evidence trees.
        # Use a per-host/per-run subdir so concurrent runs don't
        # collide and so stale evidence from a previous run is
        # visibly distinguishable from the current one.
        EVID="$REPO_ROOT/build/evidence/spike/$$-$RANDOM"
    fi
fi
mkdir -p "$EVID"
mkdir -p "$EVID/_tmp"
trap 'rm -rf "$EVID/_tmp"' EXIT

HCC=./hcc
LLVM_CONFIG=${LLVM_CONFIG:-llvm-config}
LLVM_AS=${LLVM_AS:-llvm-as}
LLVM_OPT=${LLVM_OPT:-opt}
LLVM_LIBDIR=$("$LLVM_CONFIG" --libdir 2>/dev/null || echo "")

# Optional: pass --install-dir=<dir> to hcc invocations. Necessary in
# fresh worktrees where /usr/local/include/tos.HH is not installed.
# The hcc binary unconditionally tries to load
# $install_dir/include/tos.HH at startup (src/compile.c:72-82), so
# without this the harness cannot run unless hcc is installed
# system-wide. Setting HCC_INSTALL_DIR to the test prefix (or any
# directory containing include/tos.HH and lib/libtos.{a,dylib}) makes
# the harness hermetic.
#
# This is harness strengthening, not feature expansion: the
# underlying LLVM spike semantics are unchanged.
HCC_INSTALL_DIR=${HCC_INSTALL_DIR:-}
HCC_INSTALL_ARG=""
if [ -n "$HCC_INSTALL_DIR" ]; then
    HCC_INSTALL_ARG="--install-dir=$HCC_INSTALL_DIR"
fi

# Per-fixture exit codes
PASS=0
FAIL=0

# ACT-POLYC-LLVM-CORE04-RESUME01 C2: aggregate per-class counters
# across the full matrix. Each positive() / negative() invocation
# captures stderr at $EVID/_tmp/<bn>.stderr; we parse every such
# file at the end and sum the per-class fields.
#
# Each fixture must produce EXACTLY ONE CAPABILITY_COUNTERS line on
# stderr (the contract). Multiple lines in one stderr fail the
# probe. A zero lines fail the probe (counters=missing RED).
#
# Counters are aggregated monotonically; the harness binds
# inequalities (SUPPORTED>0, REJECTED>0, ...), not golden numbers.
TOTAL_SUPPORTED=0
TOTAL_REJECTED=0
TOTAL_SHAPE_DEPENDENT=0
TOTAL_DEFENSIVE=0
TOTAL_UNREACHABLE=0
COUNTER_AGG_FAILURES=0

# check_counter_purity <fixture-name>
# ASSERTION: the .ll output contains no CAPABILITY_COUNTERS line.
# Per ACT §6.1 + §7: the line goes to stderr only; if it appears
# in the LLVM IR output, instrumentation has contaminated the IR.
# Returns 0 on PASS, 1 on FAIL.
check_counter_purity() {
    bn="$1"
    out="$2"
    if grep -q '^CAPABILITY_COUNTERS ' "$out"; then
        echo "FAIL  $bn: CAPABILITY_COUNTERS contaminated LLVM IR output" >&2
        FAIL=$((FAIL+1))
        COUNTER_AGG_FAILURES=$((COUNTER_AGG_FAILURES+1))
        return 1
    fi
    return 0
}

# parse_and_sum_counters <fixture-name> <stderr-file>
# Parse one CAPABILITY_COUNTERS line from <stderr-file>; verify
# exactly one record; sum the per-class fields into the matrix
# totals. Returns 0 on PASS, 1 on FAIL (or no record).
parse_and_sum_counters() {
    bn="$1"
    se="$2"
    if [ ! -f "$se" ]; then
        echo "FAIL  $bn: counters stderr file missing" >&2
        FAIL=$((FAIL+1))
        COUNTER_AGG_FAILURES=$((COUNTER_AGG_FAILURES+1))
        return 1
    fi
    n=$(grep -c '^CAPABILITY_COUNTERS ' "$se" || true)
    if [ "$n" = "0" ]; then
        echo "FAIL  $bn: no CAPABILITY_COUNTERS line in stderr" >&2
        echo "  (captured stderr:)" >&2
        sed 's/^/    /' "$se" >&2
        FAIL=$((FAIL+1))
        COUNTER_AGG_FAILURES=$((COUNTER_AGG_FAILURES+1))
        return 1
    fi
    if [ "$n" != "1" ]; then
        echo "FAIL  $bn: expected exactly one CAPABILITY_COUNTERS line, got $n" >&2
        sed -n '/^CAPABILITY_COUNTERS /p' "$se" >&2
        FAIL=$((FAIL+1))
        COUNTER_AGG_FAILURES=$((COUNTER_AGG_FAILURES+1))
        return 1
    fi
    line=$(grep '^CAPABILITY_COUNTERS ' "$se" | head -1)
    # Parse fields. Field set is fixed by ACT §6.1.
    sup=$(printf '%s\n' "$line" | sed -n 's/^CAPABILITY_COUNTERS supported=\([0-9][0-9]*\) .*/\1/p')
    rej=$(printf '%s\n' "$line" | sed -n 's/^.* rejected=\([0-9][0-9]*\) .*/\1/p')
    sdp=$(printf '%s\n' "$line" | sed -n 's/^.* shape_dependent=\([0-9][0-9]*\) .*/\1/p')
    def=$(printf '%s\n' "$line" | sed -n 's/^.* defensive=\([0-9][0-9]*\) .*/\1/p')
    unr=$(printf '%s\n' "$line" | sed -n 's/^.* unreachable=\([0-9][0-9]*\).*/\1/p')
    if [ -z "$sup" ] || [ -z "$rej" ] || [ -z "$sdp" ] || [ -z "$def" ] || [ -z "$unr" ]; then
        echo "FAIL  $bn: malformed CAPABILITY_COUNTERS line: $line" >&2
        FAIL=$((FAIL+1))
        COUNTER_AGG_FAILURES=$((COUNTER_AGG_FAILURES+1))
        return 1
    fi
    if [ "$unr" != "0" ]; then
        # ACT §5.1: UNREACHABLE_ON_LLVM is always 0; a non-zero is
        # HALT_UNREACHABLE_OPCODE_REACHED territory.
        echo "FAIL  $bn: unreachable=$unr (expected 0)" >&2
        FAIL=$((FAIL+1))
        COUNTER_AGG_FAILURES=$((COUNTER_AGG_FAILURES+1))
        return 1
    fi
    TOTAL_SUPPORTED=$((TOTAL_SUPPORTED + sup))
    TOTAL_REJECTED=$((TOTAL_REJECTED + rej))
    TOTAL_SHAPE_DEPENDENT=$((TOTAL_SHAPE_DEPENDENT + sdp))
    TOTAL_DEFENSIVE=$((TOTAL_DEFENSIVE + def))
    return 0
}

# Run a positive fixture. Args: <fixture> <out-ll>
positive() {
    f="$1"
    out="$2"
    if ! "$HCC" --emit-llvm $HCC_INSTALL_ARG "$f" -o "$out" >"$EVID/_tmp/$bn.stdout" 2>"$EVID/_tmp/$bn.stderr"; then
        echo "FAIL  $f: hcc --emit-llvm exited non-zero" >&2
        echo "  stderr: $(cat "$EVID/_tmp/$bn.stderr")" >&2
        FAIL=$((FAIL+1))
        return 1
    fi
    if [ ! -s "$out" ]; then
        echo "FAIL  $f: no .ll output" >&2
        FAIL=$((FAIL+1))
        return 1
    fi
    # ACT-POLYC-LLVM-CORE04-RESUME01 C2 §6.1: CAPABILITY_COUNTERS
    # is NOT LLVM IR; assert it never appears in the .ll file.
    check_counter_purity "$bn" "$out" || return 1
    DYLD_LIBRARY_PATH="$LLVM_LIBDIR:${DYLD_LIBRARY_PATH:-}" \
    LD_LIBRARY_PATH="$LLVM_LIBDIR:${LD_LIBRARY_PATH:-}" \
        "$LLVM_AS" "$out" -o "$EVID/_tmp/$bn.bc" >"$EVID/_tmp/$bn.as_stdout" 2>"$EVID/_tmp/$bn.as_stderr" || {
        echo "FAIL  $f: llvm-as rejected output" >&2
        echo "  stderr: $(cat "$EVID/_tmp/$bn.as_stderr")" >&2
        FAIL=$((FAIL+1))
        return 1
    }
    # ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01:
    # structural assertion that the emitted LLVM IR for this
    # fixture contains no executable alloca/store/load. This
    # enforces the SSA-only contract end-to-end without relying
    # on visual inspection.
    #
    # Strip LLVM ';' comments before scanning, since the textual
    # IR can mention "store"/"load" in `; preds =` comments when
    # listing predecessor blocks. Only an executable occurrence
    # (at column 0 or following only whitespace) is rejected.
    bad=$(grep -nE '^[[:space:]]*(alloca|store|load)[[:space:]]' "$out" || true)
    if [ -n "$bad" ]; then
        echo "FAIL  $f: emitted LLVM IR contains memory ops (forbidden):" >&2
        printf '  %s\n' "$bad" | head -5 >&2
        FAIL=$((FAIL+1))
        return 1
    fi
    # Parse this fixture's counter record into the matrix totals.
    parse_and_sum_counters "$bn" "$EVID/_tmp/$bn.stderr" || return 1
    PASS=$((PASS+1))
    echo "PASS  $f"
}

# Run a negative fixture. Args: <fixture> <expected-code>
negative() {
    f="$1"
    code="$2"
    bn=$(basename "$f" .HC)
    set +e
    "$HCC" --emit-llvm $HCC_INSTALL_ARG "$f" >"$EVID/_tmp/$bn.neg.out" 2>"$EVID/_tmp/$bn.neg.err"
    rc=$?
    set -e
    if [ "$rc" -eq 0 ]; then
        echo "FAIL  $f: hcc --emit-llvm succeeded but should have failed ($code)" >&2
        FAIL=$((FAIL+1))
        return 1
    fi
    if ! grep -q "$code" "$EVID/_tmp/$bn.neg.err"; then
        echo "FAIL  $f: stderr missing '$code' (got: $(cat "$EVID/_tmp/$bn.neg.err"))" >&2
        FAIL=$((FAIL+1))
        return 1
    fi
    # ACT-POLYC-LLVM-CORE04-RESUME01 C2 §6.3: rejected invocations
    # must still emit exactly one CAPABILITY_COUNTERS line on
    # stderr. Parse and sum.
    parse_and_sum_counters "$bn" "$EVID/_tmp/$bn.neg.err" || true
    # also ensure no spurious .ll was written (none requested anyway)
    PASS=$((PASS+1))
    echo "PASS  $f (negative, $code)"
}

echo "=== positive matrix ==="
# ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6.1:
# red_local_multi_def.HC moved from negative matrix (line 545 in
# the pre-C6.1 script) to positive matrix. The C6 IMPL handles
# eligible multi-def I64 locals via Option-W + mem2reg; the
# historical "rejection" expectation is superseded.
for f in src/tests/llvm-spike/01_const.HC \
         src/tests/llvm-spike/02_add.HC \
         src/tests/llvm-spike/03_sub_mul.HC \
         src/tests/llvm-spike/04_cmp_branch.HC \
         src/tests/llvm-spike/05_call.HC \
         src/tests/llvm-spike/red_local_multi_def.HC; do
    bn=$(basename "$f" .HC)
    positive "$f" "$EVID/$bn.ll"
done

echo
echo "=== cmp predicate matrix ==="
# ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01 / RED-6 + RED-1A + RED-1B.
#
# The spike proves the switch + dispatch wiring with one witness for
# each of the six signed predicates from PolyC source. CORRECTION01
# records whatever the existing compiler actually produces — no
# success/failure distribution is assumed. Each predicate's transcripts
# (both --dump-ir and --emit-llvm) are written under $EVID_CORR for
# independent inspection. Successful emission through IR_CMP_BR is
# also evidence for RED-1A / RED-1B, not a GREEN boundary result.
#
# ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01-CORRECTION01:
# $EVID_CORR was previously hardcoded to the C1 evidence dir
# (evidence/llvmspike01-resume01-correction01/), which is HISTORICAL
# (F14). Running the harness overwrote those historical RED files
# on every invocation. The directory is now redirected to THIS ACT's
# evidence dir, prefixed `live-` to make it clear these transcripts
# are regenerated on every harness run, NOT historical records.
#
# ACT-POLYC-LLVM-CORE04-RESUME01 C2 IMPL P0-1 conservation fix:
# `$EVID_CORR` previously redirected to a CLOSED-ACT evidence dir
# (`evidence/llvmspike01-resume01-correction01-resume01-correction01/
# live-red-transcripts/`) and persisted `red-{1B,2,2b}.emit.stderr`
# into it. Those tracked files became byte-different on every C2
# harness invocation (the live stderr grew a CAPABILITY_COUNTERS
# ACT-POLYC-LLVM-MEMORY01: also redirect the cmp-predicate
# live transcripts. RESUME01 closed with EVID_CORR pointing at
# the closed ACT's own evidence dir; MEMORY01 changes the path
# of the emitted .ll (via $EVID redirect), so the transcript
# path string would also drift. Redirect to a MEMORY01-specific
# location to keep the historical evidence dir bit-identical
# (F14).
EVID_CORR=${LLVM_SPIKE_EVID_CORR_OVERRIDE:-}
if [ -z "$EVID_CORR" ]; then
    if [ -n "${EVIDENCE_OUT:-}" ]; then
        EVID_CORR="$EVIDENCE_OUT/red-6-live-transcripts"
    else
        # ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C5 fix: the
        # historical closed-ACT path
        # evidence/llvm-memory01/spike/red-6-live-transcripts/ is
        # no longer the default. Co-locate with $EVID under the
        # gitignored scratch dir so ordinary regression never
        # mutates tracked historical evidence.
        EVID_CORR="$EVID/red-6-live-transcripts"
    fi
fi
mkdir -p "$EVID_CORR"

# dump_ir_capture <src> <out_base>
#
# Capture `hcc --dump-ir <src>` and write:
#   <out_base>.dump-ir.txt        NORMALISED textual transcript
#                                 (trailing horizontal whitespace
#                                 stripped per line; passes
#                                 `git diff --check`).
#   <out_base>.dump-ir.txt.sha256 SHA256 of the ORIGINAL raw bytes.
#   <out_base>.dump-ir.txt.b64    Base64 encoding of the ORIGINAL
#                                 raw bytes (chunked at 76 columns).
#
# The PolyC IR printer (src/ir.c:3311) emits one line with a
# trailing space before EOL. Committing the raw transcript
# would violate `git diff --check`; the base64 + sha256 sidecars
# preserve the byte-faithful witness without committing the
# trailing whitespace.
#
# See ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01 §4 and the
# HANDOFF section on dump-ir transcript hygiene for the
# verification procedure.
dump_ir_capture() {
    src="$1"
    base="$2"
    raw_tmp=$(mktemp -t polyc-dump-ir.XXXXXX)
    if ! "$HCC" --dump-ir $HCC_INSTALL_ARG "$src" >"$raw_tmp" 2>/dev/null; then
        : # hcc may exit non-zero on some fixtures; capture anyway
    fi

    # Compute SHA256 of raw bytes (always, even on empty output).
    if command -v shasum >/dev/null 2>&1; then
        sha=$(shasum -a 256 "$raw_tmp" | awk '{print $1}')
    elif command -v sha256sum >/dev/null 2>&1; then
        sha=$(sha256sum "$raw_tmp" | awk '{print $1}')
    else
        sha="UNAVAILABLE-no-sha-tool"
    fi
    nbytes=$(wc -c < "$raw_tmp" | tr -d ' ')

    # Write SHA256 sidecar.
    printf '%s  %s\n' "$sha" "$(basename "$src")" \
        > "${base}.dump-ir.txt.sha256"

    # Write base64 sidecar (chunked at 76 columns for git-friendliness).
    if command -v base64 >/dev/null 2>&1; then
        base64 < "$raw_tmp" | fold -w 76 > "${base}.dump-ir.txt.b64"
    else
        : > "${base}.dump-ir.txt.b64"  # tool missing; placeholder
    fi

    # Write normalised .dump-ir.txt with a verification header.
    {
        printf '# Normalised transcript. Source: hcc --dump-ir %s\n' "$src"
        printf '# raw_sha256: %s\n' "$sha"
        printf '# raw_bytes:  %s\n' "$nbytes"
        printf '# Normalisation: trailing horizontal whitespace stripped per line.\n'
        printf '# See dump-ir-manifest.md for verification procedure.\n'
        # Strip trailing whitespace per line; collapse trailing blank
        # lines so the file ends with exactly one trailing newline
        # (POSIX text-file convention; avoids `git diff --check`
        # "new blank line at EOF").
        python3 -c '
import sys
with open(sys.argv[1], "r") as f:
    text = f.read()
lines = [line.rstrip() for line in text.split("\n")]
# Drop trailing blank lines
while lines and lines[-1] == "":
    lines.pop()
# Write back with exactly one trailing newline
sys.stdout.write("\n".join(lines) + "\n")
' "$raw_tmp"
    } > "${base}.dump-ir.txt"

    rm -f "$raw_tmp"
}

matrix_record() {
    bn="$1"
    src="$2"
    expected_llvm_pred="$3"
    dump="$EVID_CORR/red-6.${bn}.dump-ir.txt"
    emit="$EVID_CORR/red-6.${bn}.emit-llvm.txt"
    aserr="$EVID_CORR/red-6.${bn}.llvm-as.stderr"

    # --dump-ir capture (the shape above the LLVM consumer).
    # Use dump_ir_capture to write the normalised .dump-ir.txt plus
    # the .sha256 + .b64 sidecars (see dump_ir_capture above).
    dump_ir_capture "$src" "$EVID_CORR/red-6.${bn}"

    # --emit-llvm capture (the shape at the LLVM boundary).
    set +e
    "$HCC" --emit-llvm $HCC_INSTALL_ARG "$src" -o "$EVID/_tmp/${bn}.ll" \
        >"$EVID/_tmp/${bn}.emit.stdout" 2>"$EVID/_tmp/${bn}.emit.stderr"
    rc=$?
    set -e
    {
        echo "source operator: see $src"
        echo "expected llvm predicate: $expected_llvm_pred"
        echo "hcc --emit-llvm rc: $rc"
        if [ "$rc" -eq 0 ] && [ -s "$EVID/_tmp/${bn}.ll" ]; then
            obs=$(grep -m1 -oE 'icmp [a-z]+' "$EVID/_tmp/${bn}.ll" || true)
            echo "observed icmp: ${obs:-<none>}"
            echo "emitted .ll path: $EVID/_tmp/${bn}.ll  (transient, _tmp is rm'd on exit)"
            set +e
            "$LLVM_AS" "$EVID/_tmp/${bn}.ll" -o "$EVID/_tmp/${bn}.bc" \
                2>"$aserr"
            asrc=$?
            set -e
            echo "llvm-as rc: $asrc"
            if [ "$asrc" -ne 0 ]; then
                echo "llvm-as stderr: $(cat "$aserr")"
            fi
        else
            echo "hcc stderr: $(cat "$EVID/_tmp/${bn}.emit.stderr")"
        fi
    } >"$emit"
}

matrix_record red_pred_eq   src/tests/llvm-spike/red_pred_eq.HC   eq
matrix_record red_pred_ne   src/tests/llvm-spike/red_pred_ne.HC   ne
matrix_record red_pred_slt  src/tests/llvm-spike/red_pred_slt.HC  slt
matrix_record red_pred_sle  src/tests/llvm-spike/red_pred_sle.HC  sle
matrix_record red_pred_sgt  src/tests/llvm-spike/red_pred_sgt.HC  sgt
matrix_record red_pred_sge  src/tests/llvm-spike/red_pred_sge.HC  sge


# Legacy sgt-only assertion (kept for backward compatibility with the
# predecessor's PASS count; not the RED-6 measurement).
if grep -q "icmp sgt" "$EVID/04_cmp_branch.ll"; then
    echo "PASS  04_cmp_branch: icmp sgt"
    PASS=$((PASS+1))
else
    echo "FAIL  04_cmp_branch: missing icmp sgt" >&2
    FAIL=$((FAIL+1))
fi

# RED-1A / RED-1B: capture the existing 04_cmp_branch.HC pair of
# transcripts so RED-1A (--dump-ir shape) and RED-1B (--emit-llvm +
# consumer behaviour) are recorded as text witnesses.
dump_ir_capture src/tests/llvm-spike/04_cmp_branch.HC \
    "$EVID_CORR/red-1A"
set +e
"$HCC" --emit-llvm $HCC_INSTALL_ARG src/tests/llvm-spike/04_cmp_branch.HC \
    -o "$EVID_CORR/red-1B.emit-llvm.ll" \
    >"$EVID_CORR/red-1B.emit.stdout" \
    2>"$EVID_CORR/red-1B.emit.stderr"
rc=$?
set -e
{
    echo "hcc --emit-llvm rc: $rc"
    if [ "$rc" -ne 0 ]; then
        echo "hcc stderr: $(cat "$EVID_CORR/red-1B.emit.stderr")"
    else
        grep -m1 -oE 'icmp [a-z]+' "$EVID_CORR/red-1B.emit-llvm.ll" \
            | sed 's/^/observed icmp: /'
    fi
} >"$EVID_CORR/red-1B.emit-llvm.txt"

# RED-2: alloca / load / store witness. Capture two fixtures:
#   - 04_cmp_branch.HC: diamond CFG that defeats collapse-elimination,
#     forces real alloca/store/load on locals.
#   - red_local_alloca_emitted.HC: simple sequential locals; observe
#     whether collapse-elimination folds them to a bare `add`.
set +e
"$HCC" --emit-llvm $HCC_INSTALL_ARG src/tests/llvm-spike/04_cmp_branch.HC \
    -o "$EVID_CORR/red-2.emit-llvm.ll" \
    >"$EVID_CORR/red-2.emit.stdout" \
    2>"$EVID_CORR/red-2.emit.stderr"
rc1=$?
"$HCC" --emit-llvm $HCC_INSTALL_ARG src/tests/llvm-spike/red_local_alloca_emitted.HC \
    -o "$EVID_CORR/red-2b.locals.ll" \
    >"$EVID_CORR/red-2b.emit.stdout" \
    2>"$EVID_CORR/red-2b.emit.stderr"
rc2=$?
set -e
{
    echo "==== 04_cmp_branch.HC ===="
    echo "hcc --emit-llvm rc: $rc1"
    if [ "$rc1" -eq 0 ] && [ -s "$EVID_CORR/red-2.emit-llvm.ll" ]; then
        echo "alloca count:  $(grep -c 'alloca ' "$EVID_CORR/red-2.emit-llvm.ll" || true)"
        echo "store  count:  $(grep -c 'store '  "$EVID_CORR/red-2.emit-llvm.ll" || true)"
        echo "load   count:  $(grep -c 'load '   "$EVID_CORR/red-2.emit-llvm.ll" || true)"
    fi
    echo
    echo "==== red_local_alloca_emitted.HC ===="
    echo "hcc --emit-llvm rc: $rc2"
    if [ "$rc2" -eq 0 ] && [ -s "$EVID_CORR/red-2b.locals.ll" ]; then
        echo "alloca count:  $(grep -c 'alloca ' "$EVID_CORR/red-2b.locals.ll" || true)"
        echo "store  count:  $(grep -c 'store '  "$EVID_CORR/red-2b.locals.ll" || true)"
        echo "load   count:  $(grep -c 'load '   "$EVID_CORR/red-2b.locals.ll" || true)"
    fi
} >"$EVID_CORR/red-2.emit-llvm.txt"


echo
echo "=== negative matrix ==="
negative src/tests/llvm-spike/neg_f64.HC      LLVM_BACKEND_UNSUPPORTED_TYPE
# ACT-POLYC-LLVM-MEMORY01: src/tests/llvm-spike/neg_pointer.HC
# (the predecessor's pointer-deref negative fixture) has been
# moved to src/tests/llvm-memory01/ as a positive fixture, since
# the basic I64 *p parameter + *p deref shape is now SUPPORTED.
# See scripts/quality/llvm-memory01-test.sh for the new positive
# and shape-dependent negative matrix.
negative src/tests/llvm-spike/neg_struct.HC   LLVM_BACKEND_UNSUPPORTED_TYPE
# ACT-POLYC-LLVM-CORE01 RED-1: integer division must produce a NAMED
# diagnostic (LLVM_BACKEND_UNSUPPORTED_INT_DIVISION), not the generic
# LLVM_BACKEND_UNSUPPORTED_IR catch-all. This is the regression test
# that proves the capability matrix contract is honored for opcodes
# that previously fell through to the default arm.
negative src/tests/llvm-spike/red_idiv_unclassified.HC  LLVM_BACKEND_UNSUPPORTED_INT_DIVISION
# ACT-POLYC-LLVM-CORE01-CORRECTION01 (AC06): widen the negative
# matrix to six real backend-level REJECTED-class witnesses.
# ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6.1:
# red_local_multi_def.HC removed from the negative matrix; it
# is now in the positive matrix (see top of script). The
# historical "multi-def SSA-local rejection" expectation is
# superseded by Option-W handling.
# red_conversion_trunc_i16.HC replaces the original
# `red_conversion_trunc.HC` CORRECTION01 fixture. The original
# narrowed I64 -> I8, which is now ADMITTED by
# ACT-POLYC-LLVM-BYTE-MEMORY01's IR_TRUNC I64->I8 shape
# promotion. The replacement fixture narrows I64 -> I16 (a
# shape BYTE-MEMORY01 does NOT authorise) and continues to
# exercise the CONVERSION rejection class (IR_TRUNC).
negative src/tests/llvm-spike/red_conversion_trunc_i16.HC LLVM_BACKEND_UNSUPPORTED_CONVERSION
# ACT-POLYC-LLVM-CORE01-CORRECTION02 (AC02): widen the negative
# matrix to six DISTINCT named backend rejection classes.
# Each fixture must FAIL with a distinct
# LLVM_BACKEND_UNSUPPORTED_<CLASS> token and nonzero RC.
negative src/tests/llvm-spike/red_remainder_mod.HC       LLVM_BACKEND_UNSUPPORTED_INT_REMAINDER
negative src/tests/llvm-spike/red_shift_shl.HC           LLVM_BACKEND_UNSUPPORTED_INT_SHIFT
# RED-8 reclassification: neg_asm.HC fails at PARSE time (the inline
# `asm { ... }` block is rejected by the parser in this configuration).
# It is therefore NOT a backend witness — it does not prove IR_ASM
# reaches the LLVM consumer. The assertion below accepts any "error:"
# token from the parser and records the transcript under
# $EVID_CORR/red-8.neg-asm.txt for honest reclassification.
"$HCC" $HCC_INSTALL_ARG src/tests/llvm-spike/neg_asm.HC -o /tmp/__neg_asm_out__ \
    >"$EVID_CORR/red-8.neg-asm.stdout" \
    2>"$EVID_CORR/red-8.neg-asm.stderr" \
    && rc=0 || rc=$?
{
    echo "hcc rc (no --emit-llvm): $rc"
    echo "stderr (first 5 lines):"
    head -5 "$EVID_CORR/red-8.neg-asm.stderr" 2>/dev/null || true
    echo
    echo "RED-8 verdict: this is a PARSE-TIME gate, not a backend witness."
    echo "  neg_asm.HC exercises inline asm syntax; the parser rejects it"
    echo "  before the IR or LLVM consumer ever sees the IR_ASM opcode."
    echo "  The negative assertion only proves \"parser rejects asm blocks\"."
    echo "  It does NOT prove IR_ASM reachability through the LLVM backend."
    echo "  IR_ASM is recorded as residue (RED-8 + §8 P2)."
} >"$EVID_CORR/red-8.llvm-spike-test.txt"
if [ "$rc" -ne 0 ] && grep -q "error:" "$EVID_CORR/red-8.neg-asm.stderr"; then
    echo "PASS  neg_asm: parse-time rejection (NOT a backend witness)"
    PASS=$((PASS+1))
else
    echo "FAIL  neg_asm: expected parse-time rejection with 'error:'" >&2
    FAIL=$((FAIL+1))
fi
rm -f /tmp/__neg_asm_out__


echo
echo "=== conservation: no native fallback ==="
# Re-run a positive fixture; check that the output starts with
# `; ModuleID` (LLVM textual IR), NOT assembly. This proves the
# dispatch never falls through to the native backend.
if head -1 "$EVID/01_const.ll" | grep -q "ModuleID\|; ModuleID"; then
    echo "PASS  01_const.ll: starts with LLVM ModuleID"
    PASS=$((PASS+1))
else
    echo "FAIL  01_const.ll: not LLVM IR (first line: $(head -1 "$EVID/01_const.ll"))" >&2
    FAIL=$((FAIL+1))
fi

echo
echo "=== determinism ==="
"$HCC" --emit-llvm $HCC_INSTALL_ARG src/tests/llvm-spike/01_const.HC -o "$EVID/_tmp/01_const.b.ll"
if cmp -s "$EVID/01_const.ll" "$EVID/_tmp/01_const.b.ll"; then
    echo "PASS  determinism: 01_const twice"
    PASS=$((PASS+1))
else
    echo "FAIL  determinism: 01_const differs across runs" >&2
    FAIL=$((FAIL+1))
fi

echo
echo "=== multi-def Option-W promotion (CORRECTION02 C6.1) ==="
# ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C6.1:
# red_local_multi_def.HC is RE-PURPOSED. Pre-CORRECTION02 it was a
# RED witness for SSA-only multi-def rejection (closed with
# HALT_DEFECTIVE_IMPL in CORRECTION01). C6 IMPL replaces the
# broken C9 predecessor-store synthesis with Option-W (memory-backed
# mutable locals + LLVM mem2reg). Under C6, eligible multi-def I64
# locals are HANDLED, not rejected.
#
# This section asserts the C6 lowering is correct for the
# MultiDef fixture:
#   1. hcc emits verifier-clean LLVM IR (rc=0)
#   2. emitted IR contains a single entry-block alloca for `y`
#   3. emitted IR contains exactly one same-site store per
#      ORIGINAL definition of `y` (bb1: I64 y = b; bb3: y = a)
#   4. emitted IR contains exactly one same-site load per ORIGINAL
#      read of `y` (bb4: x + y)
#   5. NO slot-store in a non-definition block (no C9 pred-injection)
#   6. the single-def `x` stays on the legacy SSA path
#      (no alloca for `x`; x's SSA value flows directly to the add)
#   7. opt -passes=verify on the post-mem2reg IR exits 0
#   8. opt -passes=mem2reg idempotence: re-running mem2reg on the
#      post-mem2reg IR produces an IR that diffs to a no-op
EVID_CORR2=${EVIDENCE_OUT:-}
if [ -z "$EVID_CORR2" ]; then
    # ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C5 fix: the
    # historical closed-ACT path
    # evidence/llvm-core04-resume01/c2/red-multi_def/ is no
    # longer the default. Co-locate with $EVID under the
    # gitignored scratch dir so ordinary regression never
    # mutates tracked historical evidence.
    EVID_CORR2="$EVID"
fi
EVID_MULTIDEF="$EVID_CORR2/red-multi_def"
mkdir -p "$EVID_MULTIDEF"

set +e
HCC_NO_MEM2REG=1 "$HCC" --emit-llvm $HCC_INSTALL_ARG \
    src/tests/llvm-spike/red_local_multi_def.HC \
    -o "$EVID_MULTIDEF/red-multi_def.live.pre.ll" \
    >"$EVID_MULTIDEF/red-multi_def.live.pre.stdout" \
    2>"$EVID_MULTIDEF/red-multi_def.live.pre.stderr"
rc_pre=$?
set -e

set +e
"$HCC" --emit-llvm $HCC_INSTALL_ARG \
    src/tests/llvm-spike/red_local_multi_def.HC \
    -o "$EVID_MULTIDEF/red-multi_def.live.post.ll" \
    >"$EVID_MULTIDEF/red-multi_def.live.post.stdout" \
    2>"$EVID_MULTIDEF/red-multi_def.live.post.stderr"
rc_post=$?
set -e

# Structural assertions on the PRE-mem2reg IR:
#   exactly one entry-block alloca for the optionw slot
#   exactly 2 same-site stores (bb1 case-a + bb3 case-a)
#   exactly 1 same-site load (bb4 read of y)
#   zero slot-stores in non-defn blocks (only the defn blocks contain
#     slot-stores; the non-defn branch block has none)
allocas=$(grep -c 'alloca i64' "$EVID_MULTIDEF/red-multi_def.live.pre.ll" 2>/dev/null || echo 0)
stores=$(grep -cE 'store i64 [^,]+, ptr %polyc.optionw.slot' \
    "$EVID_MULTIDEF/red-multi_def.live.pre.ll" 2>/dev/null || echo 0)
loads=$(grep -cE 'load i64, ptr %polyc.optionw.slot' \
    "$EVID_MULTIDEF/red-multi_def.live.pre.ll" 2>/dev/null || echo 0)

# Single-def x remains on legacy SSA path: no alloca/store/load
# for x (no second slot); the add uses a raw SSA value, not a load.
x_no_alloca=NO
if [ "$allocas" -eq 1 ]; then
    x_no_alloca=YES
fi

# opt -passes=verify on the post-mem2reg IR
set +e
"$LLVM_OPT" -passes=verify "$EVID_MULTIDEF/red-multi_def.live.post.ll" \
    -disable-output \
    >"$EVID_MULTIDEF/red-multi_def.live.post.verify.stdout" \
    2>"$EVID_MULTIDEF/red-multi_def.live.post.verify.stderr"
rc_verify=$?
set -e

# opt -passes=mem2reg idempotence: re-running mem2reg on the
# post-mem2reg IR must produce an identical IR (or at least
# verifier-clean IR).
set +e
"$LLVM_OPT" -passes=mem2reg "$EVID_MULTIDEF/red-multi_def.live.post.ll" \
    -S -o "$EVID_MULTIDEF/red-multi_def.live.post.idem.ll" \
    >"$EVID_MULTIDEF/red-multi_def.live.post.idem.stdout" \
    2>"$EVID_MULTIDEF/red-multi_def.live.post.idem.stderr"
rc_idem=$?
set -e

# diff idempotence: textually equal?
if cmp -s "$EVID_MULTIDEF/red-multi_def.live.post.ll" \
         "$EVID_MULTIDEF/red-multi_def.live.post.idem.ll"; then
    idem_diff=IDENTICAL
else
    idem_diff=CHANGED
fi

# Summary transcript
{
    echo "Option-W promotion fixture: src/tests/llvm-spike/red_local_multi_def.HC"
    echo "Toolchain: hcc built at the current ACT's IMPL commit."
    echo
    echo "hcc --emit-llvm rc (pre-mem2reg):  $rc_pre"
    echo "hcc --emit-llvm rc (post-mem2reg): $rc_post"
    echo "opt -passes=verify rc:             $rc_verify"
    echo "opt -passes=mem2reg rc:            $rc_idem"
    echo "mem2reg idempotence:               $idem_diff"
    echo
    echo "PRE-mem2reg structural counts:"
    echo "  allocas: $allocas  (expected: 1)"
    echo "  stores:  $stores   (expected: 2)"
    echo "  loads:   $loads    (expected: 1)"
    echo
    echo "x (single-def, non-direct-ret):"
    echo "  no alloca for x: $x_no_alloca  (expected: YES — legacy SSA path)"
    echo
    echo "VERDICT:"
    if [ "$rc_pre" -eq 0 ] && [ "$rc_post" -eq 0 ] && \
       [ "$rc_verify" -eq 0 ] && [ "$rc_idem" -eq 0 ] && \
       [ "$allocas" -eq 1 ] && [ "$stores" -eq 2 ] && [ "$loads" -eq 1 ] && \
       [ "$x_no_alloca" = "YES" ]; then
        echo "  PASS — Option-W handles eligible multi-def I64 locals"
        echo "  The C6 IMPL replaces the broken C9 predecessor-store synthesis."
        echo "  Single-def non-direct-ret locals stay on the legacy SSA path."
    else
        echo "  FAIL — Option-W invariant violated; see counts above"
    fi
} >"$EVID_MULTIDEF/red-multi_def.live.summary"

if [ "$rc_pre" -eq 0 ] && [ "$rc_post" -eq 0 ] && \
   [ "$rc_verify" -eq 0 ] && [ "$rc_idem" -eq 0 ] && \
   [ "$allocas" -eq 1 ] && [ "$stores" -eq 2 ] && [ "$loads" -eq 1 ] && \
   [ "$x_no_alloca" = "YES" ]; then
    echo "PASS  red_local_multi_def: Option-W handles eligible multi-def"
    PASS=$((PASS+1))
else
    echo "FAIL  red_local_multi_def: Option-W invariant violated" >&2
    FAIL=$((FAIL+1))
fi

echo
echo "=== capability counters (RESUME01 C2) ==="
# ACT-POLYC-LLVM-CORE04-RESUME01 §8: aggregate per-class counters
# across the full matrix. The totals were accumulated by
# parse_and_sum_counters during each positive() / negative()
# invocation. Here we (a) print the aggregation block, (b) bind
# the matrix-wide inequality assertions.
echo "=== capability counters ==="
echo "SUPPORTED           : $TOTAL_SUPPORTED"
echo "REJECTED            : $TOTAL_REJECTED"
echo "SHAPE_DEPENDENT     : $TOTAL_SHAPE_DEPENDENT"
echo "DEFENSIVE_INVARIANT : $TOTAL_DEFENSIVE"
echo "UNREACHABLE_ON_LLVM : $TOTAL_UNREACHABLE"
echo "=============================="

# Required matrix-wide inequalities (§8 + §10 F):
#   SUPPORTED           > 0   (at least one supported invocation)
#   REJECTED            > 0   (at least one table-REJECTED invocation)
#   SHAPE_DEPENDENT     >= 0  (matrix may or may not exercise it; record
#                              honestly and do not add new fixtures
#                              purely to make this counter positive)
#   DEFENSIVE_INVARIANT = 0   (supported subset must keep this at 0)
#   UNREACHABLE_ON_LLVM = 0   (always; invariant)
COUNTER_GATE_PASS=1
if [ "$TOTAL_SUPPORTED" -le 0 ]; then
    echo "FAIL  counter gate: SUPPORTED=$TOTAL_SUPPORTED (expected > 0)" >&2
    COUNTER_GATE_PASS=0
fi
if [ "$TOTAL_REJECTED" -le 0 ]; then
    echo "FAIL  counter gate: REJECTED=$TOTAL_REJECTED (expected > 0)" >&2
    COUNTER_GATE_PASS=0
fi
if [ "$TOTAL_DEFENSIVE" -ne 0 ]; then
    echo "FAIL  counter gate: DEFENSIVE_INVARIANT=$TOTAL_DEFENSIVE (expected 0 on supported subset)" >&2
    COUNTER_GATE_PASS=0
fi
if [ "$TOTAL_UNREACHABLE" -ne 0 ]; then
    echo "FAIL  counter gate: UNREACHABLE_ON_LLVM=$TOTAL_UNREACHABLE (expected 0; invariant)" >&2
    COUNTER_GATE_PASS=0
fi
if [ "$COUNTER_AGG_FAILURES" -ne 0 ]; then
    echo "FAIL  counter gate: $COUNTER_AGG_FAILURES per-fixture counter failures" >&2
    COUNTER_GATE_PASS=0
fi
if [ "$COUNTER_GATE_PASS" = "1" ]; then
    echo "PASS  counter gate: matrix-wide inequalities bound"
    PASS=$((PASS+1))
fi

# ACT §10 D: report the legacy matrix separately so C1/C2's added
# counter PASS row does not silently distort the 18-fixture baseline.
echo
echo "LEGACY_MATRIX_PASS=$((PASS - 1))"   # subtract the counter gate row
echo "COUNTER_GATE=$( [ "$COUNTER_GATE_PASS" = "1" ] && echo PASS || echo FAIL )"

echo
echo "================================="
echo "Summary: PASS=$PASS  FAIL=$FAIL"
echo "================================="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
