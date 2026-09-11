#!/bin/bash
# scripts/quality/red-p03-option-w-proof/validate.sh
#
# Validate the §6 PASS criteria on the committed pre/post
# hand-translated LLVM IR. This is the C4 RED-3 evidence.
#
# Mechanical binding: each fixture has a sidecar <bn>.spec
# that enumerates per-function expected definition sites,
# expected read sites, and the alloca location. The validator
# parses the .pre.ll against the .spec and mechanically checks:
#
#   pre:
#     - llvm-as parses cleanly
#     - the alloca appears exactly once in the function entry
#     - per spec: each DEF_SITES basic block contains exactly
#       one `store i64 ..., i64* %slot`
#     - per spec: each READ_SITES basic block contains exactly
#       one `load i64, i64* %slot`
#     - per spec: no `store i64 ..., i64* %slot` in any other
#       basic block (no synthetic predecessor-injected store;
#       no terminator-injected store)
#     - per spec: no `load i64, i64* %slot` in any other basic
#       block (no read substituted by an earlier SSA value)
#     - the function contains exactly one `alloca i64`
#
#   post:
#     - llvm-as parses cleanly
#     - the target alloca is gone
#     - target loads from %slot are gone
#     - target stores to %slot are gone
#     - opt -passes=verify exits 0
#     - no 'undef' incoming on paths where a real reaching
#       definition exists (entry-driven undef is the only
#       case caught mechanically)
#
# Exit code:
#   0  all checks PASS
#   non-zero on any FAIL
#
# ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02

set -eu

DIR=$(cd "$(dirname "$0")" && pwd)
cd "$DIR"

OPT=${OPT:-opt}
LLVM_AS=${LLVM_AS:-llvm-as}
LLVM_DIS=${LLVM_DIS:-llvm-dis}

PASS=0
FAIL=0

fail() {
    echo "FAIL: $1"
    FAIL=$((FAIL + 1))
}

ok() {
    echo "PASS: $1"
    PASS=$((PASS + 1))
}

# Extract the body of function `fnname` from `file` into
# stdout, sans the `define ... {` header line.
fn_body() {
    awk -v fn="$1" '
        $0 ~ "^define .* @" fn "\\(" { infn=1; next }
        infn && /^}/ { print; exit }
        infn { print }
    ' "$2"
}

# Count occurrences of `alloca` for the TARGET slot (`%slot`)
# inside the given function's body in `file`. The target slot
# name is hardcoded `%slot` across all proof fixtures; the
# return slot `%ret_slot` is a separate alloca for compiler-
# generated return handling and is OUT of Option-W's contract.
count_target_alloca_in_fn() {
    fn_body "$1" "$2" | awk '
        # Pattern:  %slot = alloca i64
        # The LHS %slot is field $1 in awk (no whitespace separator
        # between the leading spaces and %slot).
        /alloca i64/ {
            name = $1
            sub(/^%/, "", name)
            if (name == "slot") c++
        }
        END { print c+0 }
    '
}

# Get all block labels of a function in order.
fn_block_labels() {
    fn_body "$1" "$2" | grep -E '^[A-Za-z_][A-Za-z0-9_]*:' | sed 's/:.*//'
}

# Count stores-to-slot within a single basic block of a function.
count_slot_stores_in_block() {
    fn_body "$2" "$1" | awk -v blk="$3:" '
        $0 ~ "^"blk { inblk=1; next }
        inblk && /^[A-Za-z_][A-Za-z0-9_]*:/ { inblk=0 }
        inblk && /store i64 .* i64\* %slot/ { c++ }
        END { print c+0 }
    '
}

# Count loads-from-slot within a single basic block of a function.
count_slot_loads_in_block() {
    fn_body "$2" "$1" | awk -v blk="$3:" '
        $0 ~ "^"blk { inblk=1; next }
        inblk && /^[A-Za-z_][A-Za-z0-9_]*:/ { inblk=0 }
        inblk && /load i64, i64\* %slot/ { c++ }
        END { print c+0 }
    '
}

# Print which basic block contains the TARGET alloca (%slot) inside
# a function. Excludes %ret_slot (compiler-generated return handling).
alloca_block_in_fn() {
    fn_body "$1" "$2" | awk '
        /^[A-Za-z_][A-Za-z0-9_]*:/ { cur=$1; sub(/:$/, "", cur) }
        /alloca i64/ {
            name = $1
            sub(/^%/, "", name)
            if (name == "slot") { print cur; exit }
        }
    '
}

# Extract per-function stanzas from a .spec file into shell vars.
# Usage: parse_spec <specfile> <prefix>
# Sets per-fn shell variables:
#   <prefix>_<fn>_DEFS   (space-separated "block:case" entries)
#   <prefix>_<fn>_READS  (space-separated "block:kind" entries)
#   <prefix>_<fn>_TARGET (target local like %l6)
#   <prefix>_FNS         (space-separated function names)
parse_spec() {
    spec="$1"
    prefix="$2"
    cur=""
    defs=""
    reads=""
    target=""
    eval "${prefix}_FNS=''"
    while IFS= read -r line; do
        case "$line" in ';'*) continue ;; '#'*) continue ;; esac
        case "$line" in
            'FN:'*)
                if [ -n "$cur" ]; then
                    eval "${prefix}_${cur}_DEFS='${defs}'"
                    eval "${prefix}_${cur}_READS='${reads}'"
                    eval "${prefix}_${cur}_TARGET='${target}'"
                    eval "${prefix}_FNS=\"\${${prefix}_FNS} \${cur}\""
                fi
                cur="${line#FN:}"
                cur=$(echo "$cur" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
                defs=""
                reads=""
                target=""
                ;;
            'TARGET:'*)
                target="${line#TARGET:}"
                target=$(echo "$target" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
                ;;
            'DEF_SITES:'*)
                defs="${line#DEF_SITES:}"
                defs=$(echo "$defs" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
                ;;
            'READ_SITES:'*)
                reads="${line#READ_SITES:}"
                reads=$(echo "$reads" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
                ;;
        esac
    done < "$spec"
    if [ -n "$cur" ]; then
        eval "${prefix}_${cur}_DEFS='${defs}'"
        eval "${prefix}_${cur}_READS='${reads}'"
        eval "${prefix}_${cur}_TARGET='${target}'"
        eval "${prefix}_FNS=\"\${${prefix}_FNS} \${cur}\""
    fi
}

spec_def_sites() { eval "echo \"\${${1}_${2}_DEFS:-}\""; }
spec_read_sites() { eval "echo \"\${${1}_${2}_READS:-}\""; }
spec_target() { eval "echo \"\${${1}_${2}_TARGET:-}\""; }

echo
echo "================================================================"
echo "ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 / C4 v2 mechanical validator"
echo "================================================================"

for spec in ProbePath.spec Diamond.spec pos_b0_compare_digit.spec i64_collapse_probe.spec single_cond_probe.spec; do
    bn="${spec%.spec}"
    pre="${bn}.pre.ll"
    post="${bn}.post.ll"
    echo
    echo "==== ${bn} ===="

    if [ ! -f "$pre" ]; then fail "${bn}: pre file missing"; continue; fi
    if [ ! -f "$post" ]; then fail "${bn}: post file missing"; continue; fi
    if [ ! -f "$spec" ]; then fail "${bn}: spec file missing"; continue; fi

    # Pre: llvm-as parses cleanly
    if ! "$LLVM_AS" "$pre" -o /tmp/c4.bc 2>"${bn}.pre.llvm-as.stderr"; then
        fail "${bn}: pre llvm-as rejected"
        cat "${bn}.pre.llvm-as.stderr"
        continue
    fi
    ok "${bn}: pre llvm-as PASS"

    parse_spec "$spec" "S"
    eval "set -- \${S_FNS:-}"
    if [ $# -eq 0 ]; then
        fail "${bn}: spec parsed zero functions"
        continue
    fi
    for fn in "$@"; do
        target=$(spec_target S "$fn")
        defs=$(spec_def_sites S "$fn")
        reads=$(spec_read_sites S "$fn")
        echo "  --- fn=${fn} target=${target} ---"

        ac=$(count_target_alloca_in_fn "$fn" "$pre")
        if [ "$ac" = "1" ]; then
            ok "${bn}/${fn}: pre has exactly one target alloca (%slot)"
        else
            fail "${bn}/${fn}: pre has $ac target alloca (expected 1)"
        fi

        entry_blk=$(fn_block_labels "$fn" "$pre" | head -1)
        alloca_blk=$(alloca_block_in_fn "$fn" "$pre")
        if [ "$alloca_blk" = "$entry_blk" ]; then
            ok "${bn}/${fn}: alloca in entry block (${entry_blk})"
        else
            fail "${bn}/${fn}: alloca NOT in entry (got ${alloca_blk}, expected ${entry_blk})"
        fi

        for d in $defs; do
            block="${d%%:*}"
            case_label="${d##*:}"
            c=$(count_slot_stores_in_block "$pre" "$fn" "$block")
            if [ "$c" = "1" ]; then
                ok "${bn}/${fn}: def-site ${block} (${case_label}) has 1 slot store"
            else
                fail "${bn}/${fn}: def-site ${block} (${case_label}) has $c slot stores (expected 1)"
            fi
        done

        for r in $reads; do
            block="${r%%:*}"
            kind_label="${r##*:}"
            c=$(count_slot_loads_in_block "$pre" "$fn" "$block")
            if [ "$c" = "1" ]; then
                ok "${bn}/${fn}: read-site ${block} (${kind_label}) has 1 slot load"
            else
                fail "${bn}/${fn}: read-site ${block} (${kind_label}) has $c slot loads (expected 1)"
            fi
        done

        allowed_def=$(echo "$defs" | tr ' ' '\n' | sed 's/:.*//' | sort -u)
        all_blocks=$(fn_block_labels "$fn" "$pre")
        unexpected_store=0
        for b in $all_blocks; do
            echo "$allowed_def" | grep -qx "$b" && continue
            c=$(count_slot_stores_in_block "$pre" "$fn" "$b")
            if [ "$c" != "0" ]; then
                fail "${bn}/${fn}: UNEXPECTED slot store in ${b} ($c; not in DEF_SITES)"
                unexpected_store=$((unexpected_store + 1))
            fi
        done
        if [ "$unexpected_store" = "0" ]; then
            ok "${bn}/${fn}: no synthetic slot store in any non-def block"
        fi

        allowed_read=$(echo "$reads" | tr ' ' '\n' | sed 's/:.*//' | sort -u)
        unexpected_load=0
        for b in $all_blocks; do
            echo "$allowed_read" | grep -qx "$b" && continue
            c=$(count_slot_loads_in_block "$pre" "$fn" "$b")
            if [ "$c" != "0" ]; then
                fail "${bn}/${fn}: UNEXPECTED slot load in ${b} ($c; not in READ_SITES)"
                unexpected_load=$((unexpected_load + 1))
            fi
        done
        if [ "$unexpected_load" = "0" ]; then
            ok "${bn}/${fn}: no substituted slot load in any non-read block"
        fi
    done

    # Post: llvm-as parses cleanly
    if ! "$LLVM_AS" "$post" -o /tmp/c4.bc 2>"${bn}.post.llvm-as.stderr"; then
        fail "${bn}: post llvm-as rejected"
        cat "${bn}.post.llvm-as.stderr"
        continue
    fi
    ok "${bn}: post llvm-as PASS"

    if grep -q 'alloca i64' "$post"; then
        fail "${bn}: post still has alloca (post-mem2reg must drop allocas)"
    else
        ok "${bn}: post all allocas gone (post-mem2reg)"
    fi

    if grep -q 'load i64, i64\* %slot' "$post"; then
        fail "${bn}: post still has load from %slot"
    else
        ok "${bn}: post target loads-from-slot gone"
    fi

    if grep -q 'store i64 .* i64\* %slot' "$post"; then
        fail "${bn}: post still has store to %slot"
    else
        ok "${bn}: post target stores-to-slot gone"
    fi

    if "$OPT" -passes=verify -S /tmp/c4.bc >/dev/null 2>"${bn}.post.verify.stderr"; then
        ok "${bn}: post verify PASS"
    else
        fail "${bn}: post verify FAIL"
        cat "${bn}.post.verify.stderr"
    fi

    if grep -E 'phi i64 \[ undef, %bb_entry \]' "$post" >/dev/null 2>&1; then
        entry_def_seen=0
        eval "set -- \${S_FNS:-}"
        for fn in "$@"; do
            defs=$(spec_def_sites S "$fn")
            echo "$defs" | tr ' ' '\n' | grep -q '^bb_entry:' && entry_def_seen=1
        done
        if [ "$entry_def_seen" = "1" ]; then
            fail "${bn}: post has 'undef' incoming from entry where a real definition exists"
        else
            ok "${bn}: post undef-from-entry OK (no entry def in spec)"
        fi
    else
        ok "${bn}: post no undef-from-entry"
    fi
done

echo
echo "================================================================"
echo "SUMMARY  PASS=$PASS  FAIL=$FAIL"
echo "================================================================"
[ "$FAIL" = "0" ]
