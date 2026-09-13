#!/bin/sh
# scripts/quality/selfhost-component-registry-test.sh
#
# ACT-POLYC-SELFHOST-SURFACE01 C2 IMPL — registry
# negative-control matrix (binding).
#
# Matrix (binding per ACT §19):
#
#   N1   current registry                            PASS
#   N2   unknown component                           FAIL
#   N3   duplicate identifier_scanner row            FAIL
#   N4   missing source path                         FAIL
#   N5   source path outside repository              FAIL
#   N6   missing symbol                              FAIL
#   N7   invalid language                            FAIL
#   N8   invalid state                               FAIL
#   N9   unknown stage                               FAIL
#   N10  malformed field count                       FAIL
#   N11  output path aliases source                  FAIL
#   N12  valid temporary DISABLED row                PASS VALIDATION
#                                                    but MUST NOT build
#                                                    unless explicitly addressed
#
# Exit code:
#   0  every expected PASS / FAIL outcome observed
#   1  any unexpected outcome

set -eu

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
VALIDATOR="$REPO_ROOT/scripts/quality/selfhost-component-registry.py"
GOOD_REGISTRY="$REPO_ROOT/docs/factory/SELF-HOST-COMPONENTS.tsv"
TMPDIR=$(mktemp -d -t selfhost-registry-test.XXXXXX)
trap 'rm -rf "$TMPDIR"' EXIT

PASS=0
FAIL=0

HEADER="component_id	source	symbol	consumer_seam	language	state	oracle	cursor_gate	production_seam_gate	introduced_by"

expect_pass() {
    name="$1"; shift
    expected_rc="$1"; shift
    if "$@" >/dev/null 2>"$TMPDIR/${name}.stderr"; then
        actual_rc=0
    else
        actual_rc=$?
    fi
    if [ "$actual_rc" = "$expected_rc" ]; then
        echo "  PASS  $name  (rc=$actual_rc)"
        PASS=$((PASS + 1))
    else
        echo "  FAIL  $name  (expected rc=$expected_rc, got rc=$actual_rc)"
        cat "$TMPDIR/${name}.stderr" >&2
        FAIL=$((FAIL + 1))
    fi
}

# N1 — current registry valid
expect_pass "N1_current_registry_valid_PASS" 0 \
    python3 "$VALIDATOR" "$GOOD_REGISTRY"

# N2 — unknown component lookup via validator's
#      unknown-component branch (using empty registry)
cat >"$TMPDIR/empty.tsv" <<EOF
$HEADER
EOF
expect_pass "N2_unknown_component_lookup_FAIL" 1 \
    python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts/quality')
import selfhost_component_registry as v
rows = v.validate_registry('$TMPDIR/empty.tsv')
v.lookup_component(rows, 'nonexistent_component')
"

# N3 — duplicate identifier_scanner row
cat >"$TMPDIR/dup.tsv" <<EOF
$HEADER
identifier_scanner	tools/bootstrap/bootstrap02-ident.HC	BootstrapScanIdent	src/lexer.c::lexIdentifier	POLYC	STABLE	bootstrap02-oracle	bootstrap02-cursor-test	bootstrap02-lexer-seam-test	ACT-POLYC-BOOTSTRAP02
identifier_scanner	tools/bootstrap/bootstrap02-ident.HC	BootstrapScanIdent	src/lexer.c::lexIdentifier	POLYC	STABLE	bootstrap02-oracle	bootstrap02-cursor-test	bootstrap02-lexer-seam-test	ACT-POLYC-BOOTSTRAP02
EOF
expect_pass "N3_duplicate_component_id_FAIL" 1 \
    python3 "$VALIDATOR" "$TMPDIR/dup.tsv"

# N4 — missing source path
cat >"$TMPDIR/missing_source.tsv" <<EOF
$HEADER
phantom_scanner	tools/bootstrap/does-not-exist.HC	PhantomSym	src/lexer.c::lexIdentifier	POLYC	STABLE	bootstrap02-oracle	bootstrap02-cursor-test	bootstrap02-lexer-seam-test	ACT-POLYC-BOOTSTRAP02
EOF
expect_pass "N4_missing_source_path_FAIL" 1 \
    python3 "$VALIDATOR" "$TMPDIR/missing_source.tsv"

# N5 — source path outside repository (uses ..)
cat >"$TMPDIR/escape.tsv" <<EOF
$HEADER
escape_scanner	../../../../etc/passwd	EscapeSym	src/lexer.c::lexIdentifier	POLYC	STABLE	bootstrap02-oracle	bootstrap02-cursor-test	bootstrap02-lexer-seam-test	ACT-POLYC-BOOTSTRAP02
EOF
expect_pass "N5_source_outside_repository_FAIL" 1 \
    python3 "$VALIDATOR" "$TMPDIR/escape.tsv"

# N6 — missing symbol (empty)
cat >"$TMPDIR/no_symbol.tsv" <<EOF
$HEADER
no_symbol_scanner	tools/bootstrap/bootstrap02-ident.HC		src/lexer.c::lexIdentifier	POLYC	STABLE	bootstrap02-oracle	bootstrap02-cursor-test	bootstrap02-lexer-seam-test	ACT-POLYC-BOOTSTRAP02
EOF
expect_pass "N6_missing_symbol_FAIL" 1 \
    python3 "$VALIDATOR" "$TMPDIR/no_symbol.tsv"

# N7 — invalid language
cat >"$TMPDIR/bad_lang.tsv" <<EOF
$HEADER
bad_lang_scanner	tools/bootstrap/bootstrap02-ident.HC	BootstrapScanIdent	src/lexer.c::lexIdentifier	PYTHON	STABLE	bootstrap02-oracle	bootstrap02-cursor-test	bootstrap02-lexer-seam-test	ACT-POLYC-BOOTSTRAP02
EOF
expect_pass "N7_invalid_language_FAIL" 1 \
    python3 "$VALIDATOR" "$TMPDIR/bad_lang.tsv"

# N8 — invalid state
cat >"$TMPDIR/bad_state.tsv" <<EOF
$HEADER
bad_state_scanner	tools/bootstrap/bootstrap02-ident.HC	BootstrapScanIdent	src/lexer.c::lexIdentifier	POLYC	WONKY	bootstrap02-oracle	bootstrap02-cursor-test	bootstrap02-lexer-seam-test	ACT-POLYC-BOOTSTRAP02
EOF
expect_pass "N8_invalid_state_FAIL" 1 \
    python3 "$VALIDATOR" "$TMPDIR/bad_state.tsv"

# N9 — unknown stage via validator's resolve_producer branch
expect_pass "N9_unknown_stage_FAIL" 1 \
    python3 -c "
import sys
sys.path.insert(0, '$REPO_ROOT/scripts/quality')
import selfhost_component_registry as v
v.resolve_producer(7)
"

# N10 — malformed field count
cat >"$TMPDIR/malformed.tsv" <<EOF
$HEADER
malformed_scanner	tools/bootstrap/bootstrap02-ident.HC	BootstrapScanIdent	src/lexer.c::lexIdentifier	POLYC	STABLE
EOF
expect_pass "N10_malformed_field_count_FAIL" 1 \
    python3 "$VALIDATOR" "$TMPDIR/malformed.tsv"

# N11 — output path aliases source. Construct a temporary
#       source file ending in .o and a component_id that
#       aliases it via the generic template.
TOUCHED_O="$TMPDIR/aliased.o"
touch "$TOUCHED_O"
cat >"$TMPDIR/aliases.tsv" <<EOF
$HEADER
$TOUCHED_O	$TOUCHED_O	AliasSym	src/lexer.c::lexIdentifier	POLYC	STABLE	bootstrap02-oracle	bootstrap02-cursor-test	bootstrap02-lexer-seam-test	ACT-POLYC-BOOTSTRAP02
EOF
expect_pass "N11_output_aliases_source_FAIL" 1 \
    python3 "$VALIDATOR" "$TMPDIR/aliases.tsv"

# N12 — valid temporary DISABLED row passes validation but
#       MUST NOT build. We register a row whose consumer_seam
#       references a function that does not exist (because
#       the validator does not gate on consumer_seam
#       existence, only on shape). Then we verify that
#       invoking the build driver refuses to build because
#       state=DISABLED.
cat >"$TMPDIR/disabled.tsv" <<EOF
$HEADER
disabled_scanner	tools/bootstrap/bootstrap02-ident.HC	BootstrapScanIdent	src/lexer.c::nonexistent	POLYC	DISABLED	bootstrap02-oracle	bootstrap02-cursor-test	bootstrap02-lexer-seam-test	ACT-POLYC-BOOTSTRAP02
EOF
expect_pass "N12a_disabled_row_validates_PASS" 0 \
    python3 "$VALIDATOR" "$TMPDIR/disabled.tsv"

# N12b — temporarily substitute registry, attempt build,
#        expect refusal (rc=1). Restore registry after.
BACKUP="$REPO_ROOT/docs/factory/SELF-HOST-COMPONENTS.tsv.bak"
cp "$GOOD_REGISTRY" "$BACKUP"
cp "$TMPDIR/disabled.tsv" "$GOOD_REGISTRY"
set +e
if ./tools/selfhost/selfhost-component.sh \
      build COMPONENT=disabled_scanner STAGE=0 >/dev/null 2>&1; then
    rc=0
else
    rc=$?
fi
set -e
mv "$BACKUP" "$GOOD_REGISTRY"
if [ "$rc" = "1" ]; then
    echo "  PASS  N12b_disabled_row_refuses_build_FAIL  (rc=$rc)"
    PASS=$((PASS + 1))
else
    echo "  FAIL  N12b_disabled_row_refuses_build_FAIL  (expected rc=1, got rc=$rc)" >&2
    FAIL=$((FAIL + 1))
fi

# Summary
echo "--- registry negative-control summary ---"
echo "PASS=$PASS FAIL=$FAIL"
if [ "$FAIL" -ne 0 ]; then
    exit 1
fi
exit 0

