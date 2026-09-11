#!/bin/sh
# /tmp/c6.1/capture.sh - real-compiler capture for the 6 CORRECTION02
# frozen fixtures plus the reclassified red_local_multi_def.
set -eu

REPO=/Volumes/UserData/Users/chistyakov/Projects/SPbNIX/polyc
EVID=$REPO/evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02/c6.1
mkdir -p "$EVID"

HCC=$REPO/hcc
INSTALL=$REPO/build/test-prefix
HCC_INSTALL_ARG="--install-dir=$INSTALL"
OPT=${OPT:-opt}

TOTAL=0
PASS=0
FAIL=0

capture_one() {
    tag="$1"; desc="$2"; name="$3"; path="$4"
    TOTAL=$((TOTAL + 1))
    pre_ll=/tmp/c6.1/${tag}.pre.ll
    post_ll=/tmp/c6.1/${tag}.post.ll

    if HCC_NO_MEM2REG=1 "$HCC" --emit-llvm $HCC_INSTALL_ARG "$path" \
        -o "$pre_ll" >/tmp/c6.1/${tag}.pre.stderr 2>&1; then
        pre_rc=0
    else
        pre_rc=$?
    fi

    if "$HCC" --emit-llvm $HCC_INSTALL_ARG "$path" \
        -o "$post_ll" >/tmp/c6.1/${tag}.post.stderr 2>&1; then
        post_rc=0
    else
        post_rc=$?
    fi

    if $OPT -passes=verify "$post_ll" -disable-output \
        >/tmp/c6.1/${tag}.post.verify.stdout 2>/tmp/c6.1/${tag}.post.verify.stderr; then
        verify_rc=0
    else
        verify_rc=$?
    fi

    if $OPT -passes=mem2reg "$post_ll" -S -o /tmp/c6.1/${tag}.post.idem.ll \
        >/tmp/c6.1/${tag}.post.idem.stdout 2>/tmp/c6.1/${tag}.post.idem.stderr; then
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
    # This is the C9 detection heuristic; case-a defns that emit a
    # bare "store %param, slot[V]" are correctly counted as 1 store.
    synth_store_count=$(awk '
        /^[[:space:]]*;/ { next }
        /^[[:space:]]*[a-zA-Z][a-zA-Z0-9_.]*:/ {
            # new block - check previous block for duplicates
            for (s in block_slot_count) {
                if (block_slot_count[s] > 1) {
                    synth++
                }
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
                if (block_slot_count[s] > 1) {
                    synth++
                }
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

    if [ "$pre_rc" -eq 0 ]; then
        /bin/cp "$pre_ll" "$EVID/${name}.pre-mem2reg.real.ll"
    fi
    if [ "$post_rc" -eq 0 ]; then
        /bin/cp "$post_ll" "$EVID/${name}.post-mem2reg.real.ll"
    fi
    if [ "$idem_rc" -eq 0 ]; then
        /bin/cp /tmp/c6.1/${tag}.post.idem.ll "$EVID/${name}.post-mem2reg.idempotent.ll"
    fi

    row_status="PASS"
    row_reasons=""
    [ "$pre_rc" -ne 0 ] && { row_status="FAIL"; row_reasons="$row_reasons pre_rc=$pre_rc"; }
    [ "$post_rc" -ne 0 ] && { row_status="FAIL"; row_reasons="$row_reasons post_rc=$post_rc"; }
    [ "$verify_rc" -ne 0 ] && { row_status="FAIL"; row_reasons="$row_reasons verify_rc=$verify_rc"; }
    [ "$stores_per_alloca" = "TOO_FEW" ] && { row_status="FAIL"; row_reasons="$row_reasons stores<allocas"; }
    [ "$synth_store_count" -ne 0 ] && { row_status="FAIL"; row_reasons="$row_reasons synth_stores=$synth_store_count"; }

    [ "$row_status" = "PASS" ] && PASS=$((PASS + 1)) || FAIL=$((FAIL + 1))

    printf '%-30s %-22s pre=%d post=%d verify=%d idem=%d allocas=%d stores=%d loads=%d synth=%d stores_per_alloca=%s  %s  %s\n' \
        "$tag" "$desc" "$pre_rc" "$post_rc" "$verify_rc" "$idem_rc" \
        "$allocas" "$stores" "$loads" \
        "$synth_store_count" \
        "$stores_per_alloca" \
        "$row_status" "$row_reasons"
}

FIXTURES_FILE=/tmp/c6.1/fixtures.txt
while IFS='|' read -r tag desc name path; do
    [ -z "$tag" ] && continue
    capture_one "$tag" "$desc" "$name" "$path"
done < "$FIXTURES_FILE"

echo
echo "TOTAL=$TOTAL PASS=$PASS FAIL=$FAIL"
exit 0
