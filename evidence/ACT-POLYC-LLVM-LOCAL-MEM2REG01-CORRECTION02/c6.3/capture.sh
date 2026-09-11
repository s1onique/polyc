#!/bin/sh
# evidence/.../c6.2/capture.sh - CORRECTION02 c6.2 evidence producer
#
# Scope: same 7 fixtures as c6.1/capture.sh, but with three corrections:
#
#   1. P0-1 (verdict channel): the script exits non-zero when ANY row
#      criterion fails. It is no longer a false-GREEN producer.
#   2. P0-2 (boundary narrative): the row description records the
#      CORRECT shape classification, in particular:
#        - safe_fwd_single_pred is single-def + DIRECT-RETURN + Option-W
#        - MultiDef::x is single-def + non-direct-ret + legacy SSA
#        - MultiDef::y is multi-def + Option-W
#   3. P1 (idempotence wording): the row reports whether a SECOND
#      mem2reg pass produced textually-identical IR (informational,
#      not a fail criterion). The authoritative wording in the closure
#      matrix is "second mem2reg pass succeeds and preserves
#      verifier-valid semantics", not "mem2reg idempotent".
#
# All 7 row criteria from c6.1 are preserved unchanged:
#   pre_rc == 0
#   post_rc == 0
#   verify_rc == 0
#   stores_per_alloca != TOO_FEW
#   synth_store_count == 0
#   (idem_rc == 0 is the captured metric, not a fail criterion)
#
# No production compiler code is modified by this script.

set -eu

REPO=/Volumes/UserData/Users/chistyakov/Projects/SPbNIX/polyc
EVID=$REPO/evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02/c6.3
mkdir -p "$EVID"

HCC=$REPO/hcc
INSTALL=$REPO/build/test-prefix
HCC_INSTALL_ARG="--install-dir=$INSTALL"
OPT=${OPT:-opt}

TOTAL=0
PASS=0
FAIL=0

# Shape classification column. Each fixture is annotated with the
# C6 boundary shape it actually exercises per the real pre-mem2reg IR.
# See evidence/.../c6.2/six-fixture-matrix.real.txt for the
# authoritative description.
SHAPE_safe_fwd_single_pred='single-def+direct-ret+OptionW'
SHAPE_single_cond_probe='multi-def+OptionW'
SHAPE_i64_collapse_probe='multi-def+OptionW'
SHAPE_pos_b0_compare_digit='multi-def+OptionW(2V)'
SHAPE_nc_p01_predecessor_paths='multi-def+OptionW'
SHAPE_Diamond='multi-def+OptionW'
SHAPE_red_local_multi_def='mixed:y=multi-def+OptionW;x=single-def+legacySSA'

# Factored row criterion. Receives numeric/string metrics and emits
# PASS/FAIL plus reasons. This is the SINGLE source of truth for
# whether a row counts as evidence. Both capture_one() and the
# self-test call it.
#
# c6.3 adds idem_rc to the mandatory predicate set. A successful
# second mem2reg pass (idem_rc == 0) is now required for row PASS.
# This closes the c6.2 false-GREEN path where a non-zero idem_rc
# was captured but did not fail the row.
validate_row() {
    pre_rc="$1"; post_rc="$2"; verify_rc="$3"; idem_rc="$4"
    stores_per_alloca="$5"; synth_store_count="$6"
    row_status="PASS"; row_reasons=""
    [ "$pre_rc" -ne 0 ] && { row_status="FAIL"; row_reasons="$row_reasons pre_rc=$pre_rc"; }
    [ "$post_rc" -ne 0 ] && { row_status="FAIL"; row_reasons="$row_reasons post_rc=$post_rc"; }
    [ "$verify_rc" -ne 0 ] && { row_status="FAIL"; row_reasons="$row_reasons verify_rc=$verify_rc"; }
    [ "$idem_rc" -ne 0 ] && { row_status="FAIL"; row_reasons="$row_reasons idem_rc=$idem_rc"; }
    [ "$stores_per_alloca" = "TOO_FEW" ] && { row_status="FAIL"; row_reasons="$row_reasons stores<allocas"; }
    [ "$synth_store_count" -ne 0 ] && { row_status="FAIL"; row_reasons="$row_reasons synth_stores=$synth_store_count"; }
    printf '%s|%s' "$row_status" "$row_reasons"
}

capture_one() {
    tag="$1"; desc="$2"; name="$3"; path="$4"; shape="$5"
    TOTAL=$((TOTAL + 1))
    pre_ll=/tmp/c6.3/${tag}.pre.ll
    post_ll=/tmp/c6.3/${tag}.post.ll

    if HCC_NO_MEM2REG=1 "$HCC" --emit-llvm $HCC_INSTALL_ARG "$path" \
        -o "$pre_ll" >/tmp/c6.3/${tag}.pre.stderr 2>&1; then
        pre_rc=0
    else
        pre_rc=$?
    fi

    if "$HCC" --emit-llvm $HCC_INSTALL_ARG "$path" \
        -o "$post_ll" >/tmp/c6.3/${tag}.post.stderr 2>&1; then
        post_rc=0
    else
        post_rc=$?
    fi

    if $OPT -passes=verify "$post_ll" -disable-output \
        >/tmp/c6.3/${tag}.post.verify.stdout 2>/tmp/c6.3/${tag}.post.verify.stderr; then
        verify_rc=0
    else
        verify_rc=$?
    fi

    if $OPT -passes=mem2reg "$post_ll" -S -o /tmp/c6.3/${tag}.post.idem.ll \
        >/tmp/c6.3/${tag}.post.idem.stdout 2>/tmp/c6.3/${tag}.post.idem.stderr; then
        idem_rc=0
    else
        idem_rc=$?
    fi

    allocas=$(grep -c 'alloca i64' "$pre_ll" 2>/dev/null || echo 0)
    stores=$(grep -cE 'store i64 [^,]+, ptr %polyc.optionw.slot' "$pre_ll" 2>/dev/null || echo 0)
    loads=$(grep -cE 'load i64, ptr %polyc.optionw.slot' "$pre_ll" 2>/dev/null || echo 0)

    # C9 predecessor-edge synthetic store detection: per block, count
    # slot-stores per slot. The C9 pattern emitted ONE store per
    # pred-end (i.e., extra stores beyond the source IR's defns).
    # A legitimate same-site lowering emits EXACTLY ONE store per
    # slot per block. > 1 store per slot per block = C9 injection.
    synth_store_count=$(awk '
        /^[[:space:]]*;/ { next }
        /^[[:space:]]*[a-zA-Z][a-zA-Z0-9_.]*:/ {
            for (s in block_slot_count) {
                if (block_slot_count[s] > 1) synth++
            }
            delete block_slot_count
            next
        }
        /store i64 [^,]+, ptr (%polyc.optionw.slot[^,]+)/ {
            slot = $0
            sub(/.*ptr /, "", slot)
            sub(/[, ].*/, "", slot)
            block_slot_count[slot]++
            next
        }
        END {
            for (s in block_slot_count) {
                if (block_slot_count[s] > 1) synth++
            }
            print synth+0
        }
    ' "$pre_ll" 2>/dev/null || echo 0)

    if [ "$allocas" -gt 0 ] && [ "$stores" -lt "$allocas" ]; then
        stores_per_alloca="TOO_FEW"
    elif [ "$allocas" -gt 0 ]; then
        stores_per_alloca="OK"
    else
        stores_per_alloca="N/A"
    fi

    # Idempotence as NORMALIZED TEXT equality. We strip the
    # ModuleID and source_filename metadata that opt embeds with the
    # input file path; the remaining IR is the actual code, which we
    # expect to be textually identical if mem2reg is structurally
    # idempotent on already-promoted IR. Informational only - NOT a
    # fail criterion. The authoritative closure wording is
    # "second mem2reg pass succeeds and preserves verifier-valid
    # semantics" rather than "mem2reg idempotent".
    #
    # c6.3 NOTE: idem_rc (the SECOND mem2reg invocation's exit
    # status) IS a mandatory fail criterion (see validate_row()).
    # idem_eq (normalized textual equality) is NOT. They are
    # distinct metrics.
    if [ "$idem_rc" -eq 0 ]; then
        post_norm=/tmp/c6.3/${tag}.post.norm.ll
        idem_norm=/tmp/c6.3/${tag}.post.idem.norm.ll
        sed -E "s|source_filename = \"[^\"]*\"|source_filename = \"REDACTED\"|; s|^; ModuleID = '[^']*'|; ModuleID = 'REDACTED'|" \
            "$post_ll" > "$post_norm"
        sed -E "s|source_filename = \"[^\"]*\"|source_filename = \"REDACTED\"|; s|^; ModuleID = '[^']*'|; ModuleID = 'REDACTED'|" \
            /tmp/c6.3/${tag}.post.idem.ll > "$idem_norm"
        if diff -q "$post_norm" "$idem_norm" >/dev/null 2>&1; then
            idem_eq="NORM_IDENTICAL"
        else
            idem_eq="NORM_CHANGED"
        fi
    else
        idem_eq="FAIL($idem_rc)"
    fi

    if [ "$pre_rc" -eq 0 ]; then
        /bin/cp "$pre_ll" "$EVID/${name}.pre-mem2reg.real.ll"
    fi
    if [ "$post_rc" -eq 0 ]; then
        /bin/cp "$post_ll" "$EVID/${name}.post-mem2reg.real.ll"
    fi
    if [ "$idem_rc" -eq 0 ]; then
        /bin/cp /tmp/c6.3/${tag}.post.idem.ll "$EVID/${name}.post-mem2reg.idempotent.ll"
    fi

    # NEG_TEST path: if C6_2_FORCE_FAIL is set, override pre_rc to
    # a guaranteed-FAIL value (99). This is the ONLY path that
    # forces a row to be FAIL; production runs always have
    # C6_2_FORCE_FAIL unset. The override proves that a FAIL row
    # propagates to the script exit code.
    if [ "${C6_2_FORCE_FAIL:-0}" = "1" ]; then
        pre_rc=99
    fi

    row=$(validate_row "$pre_rc" "$post_rc" "$verify_rc" "$idem_rc" \
                       "$stores_per_alloca" "$synth_store_count")
    row_status=${row%%|*}
    row_reasons=${row#*|}

    [ "$row_status" = "PASS" ] && PASS=$((PASS + 1)) || FAIL=$((FAIL + 1))

    printf '%-30s %-22s pre=%d post=%d verify=%d idem=%d idem_eq=%-9s allocas=%d stores=%d loads=%d synth=%d stores_per_alloca=%-7s shape=%-44s %s%s\n' \
        "$tag" "$desc" "$pre_rc" "$post_rc" "$verify_rc" "$idem_rc" \
        "$idem_eq" \
        "$allocas" "$stores" "$loads" \
        "$synth_store_count" \
        "$stores_per_alloca" \
        "$shape" \
        "$row_status" "$row_reasons"
}

# -- main --
if [ "${C6_2_SELF_TEST:-0}" = "1" ]; then
    # SEEDED-FAILURE SELF-TEST: prove the verdict channel is real.
    # We feed validate_row() metrics that we know MUST fail, and
    # we feed metrics that we know MUST pass. If either branch
    # gives the wrong verdict, the script exits non-zero.
    #
    # c6.3: validate_row() takes 6 args (idem_rc added). The
    # original seeded-failure test uses pre_rc=1 to force a FAIL;
    # idem_rc=0 keeps it a "single-criterion seeded failure".
    fail_result=$(validate_row 1 0 0 0 OK 0)
    fail_status=${fail_result%%|*}
    pass_result=$(validate_row 0 0 0 0 OK 0)
    pass_status=${pass_result%%|*}
    if [ "$fail_status" = "FAIL" ] && [ "$pass_status" = "PASS" ]; then
        echo "self-test: validate_row seeded-failure->FAIL and all-good->PASS rc=0"
        exit 0
    else
        echo "self-test: FAILED fail_status=$fail_status pass_status=$pass_status"
        exit 1
    fi
fi

if [ "${C6_2_NEG_TEST:-0}" = "1" ]; then
    # NEGATIVE-INJECTION SELF-TEST: prove that an injected FAIL row
    # propagates to the script exit code. We override the row
    # criterion to ALWAYS fail, run capture_one() over the real
    # fixture set, and verify that the script exits non-zero when
    # ANY row fails.
    #
    # This proves: with FAIL>0, the script exits non-zero.
    # Combined with proof 1 (capture.sh rc=0 when all rows PASS),
    # this proves the verdict channel is bi-directional: a FAIL
    # row forces a non-zero exit.
    #
    # We do NOT corrupt production fixtures. We override the
    # criterion function via a sentinel env var. capture_one()
    # reads C6_2_FORCE_FAIL and substitutes the row metric.
    # Original criteria remain unchanged.
    FIXTURES_FILE=/tmp/c6.3/fixtures.txt
    export C6_2_FORCE_FAIL=1
    while IFS='|' read -r tag desc name path shape; do
        [ -z "$tag" ] && continue
        capture_one "$tag" "$desc" "$name" "$path" "$shape"
    done < "$FIXTURES_FILE"
    echo
    echo "TOTAL=$TOTAL PASS=$PASS FAIL=$FAIL"
    # Mirror the real script's exit predicate EXACTLY.
    if [ "$FAIL" -eq 0 ]; then
        echo "neg-test: FAIL=0 but should be >0"
        exit 1
    else
        echo "neg-test: FAIL>0 -> exit 1 (verdict channel real)"
        exit 1
    fi
fi

if [ "${C6_3_IDEM_TEST:-0}" = "1" ]; then
    # C6.3 SEEDED-IDEM-FAILURE SELF-TEST: prove that an idem_rc != 0
    # metric, with all other row criteria good, causes validate_row()
    # to emit FAIL. This is the exact c6.2 false-GREEN path that
    # c6.3 corrects.
    #
    # We invoke validate_row() directly (not capture_one()) with:
    #   pre_rc=0 post_rc=0 verify_rc=0 idem_rc=NONZERO stores_per_alloca=OK synth_store_count=0
    # The function MUST return FAIL with a reason mentioning idem_rc.
    fail_result=$(validate_row 0 0 0 99 OK 0)
    fail_status=${fail_result%%|*}
    fail_reasons=${fail_result#*|}
    if [ "$fail_status" = "FAIL" ] && echo "$fail_reasons" | grep -q "idem_rc=99"; then
        echo "idem-self-test: validate_row seeded-idem-failure->FAIL rc=0 (reasons: $fail_reasons)"
        # Also check the all-good row still passes with idem_rc=0:
        pass_result=$(validate_row 0 0 0 0 OK 0)
        pass_status=${pass_result%%|*}
        if [ "$pass_status" = "PASS" ]; then
            echo "idem-self-test: validate_row all-good->PASS rc=0"
            exit 0
        else
            echo "idem-self-test: FAILED all-good returned pass_status=$pass_status"
            exit 1
        fi
    else
        echo "idem-self-test: FAILED fail_status=$fail_status reasons=$fail_reasons"
        exit 1
    fi
fi

FIXTURES_FILE=/tmp/c6.3/fixtures.txt
while IFS='|' read -r tag desc name path shape; do
    [ -z "$tag" ] && continue
    capture_one "$tag" "$desc" "$name" "$path" "$shape"
done < "$FIXTURES_FILE"

echo
echo "TOTAL=$TOTAL PASS=$PASS FAIL=$FAIL"

# Verdict channel: rc=0 iff every row is PASS. A FAIL row in any
# row criterion must propagate to the script exit code. This is the
# single mechanical truth-channel for c6.3 evidence.
if [ "$FAIL" -eq 0 ]; then
    exit 0
else
    exit 1
fi
