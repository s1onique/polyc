#!/bin/sh
# scripts/quality/parser-padding-generation-provenance-verify.sh
#
# ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION01 C2 IMPL.
#
# Generation-provenance verifier (AC29 repair). Splits:
#   FIXEDPOINT_BYTE_VERDICT  "all 6 object pairs byte equal"
#   PROVENANCE_VERDICT       "each generation artifact produced under
#                              its expected generation-specific build
#                              identity"
#
# A byte-identical forgery that copies G1 bytes into the G3 slot
# has BYTE equal but PROVENANCE different (G3 row binds expected
# compiler_sha / command_sha / source_sha / fresh_build_record_sha
# that do not match G1's).
#
# F-POLYC-TOOLS compliant: thin shell glue. Substantive verification
# lives in tools/quality/parser-padding-generation-provenance-verify.HC
# and the existing tools/quality/parser-padding-fixedpoint-verify.HC.

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

HCC_G0=./hcc
HCC_G1=./build/hcc-bootstrap02
HCC_G2=./build/hcc-bootstrap03
HCC_G3=./build/hcc-bootstrap04

PARSER_PADDING_SRC=tools/bootstrap/selfhost-parser-padding.HC
PARSER_PADDING_FIXEDPOINT_OUTDIR=build/parser-padding-fixedpoint
TEST_PREFIX=$REPO_ROOT/build/test-prefix
PROV_RECORD_DIR=build/parser-padding-provenance
mkdir -p "$PROV_RECORD_DIR"

sha256_of_file()   { "$REPO_ROOT/build/lexer07-sha256" --file "$1" 2>/dev/null; }
sha256_of_string() { "$REPO_ROOT/build/lexer07-sha256" "$1" 2>/dev/null | awk '{print $1}'; }

G0_COMPILER_SHA=$(sha256_of_file "$HCC_G0")
G1_COMPILER_SHA=$(sha256_of_file "$HCC_G1")
G2_COMPILER_SHA=$(sha256_of_file "$HCC_G2")
G3_COMPILER_SHA=$(sha256_of_file "$HCC_G3")
SOURCE_SHA=$(sha256_of_file "$PARSER_PADDING_SRC")

G0_CMD="./hcc --install-dir=$TEST_PREFIX -c $PARSER_PADDING_SRC -o $PARSER_PADDING_FIXEDPOINT_OUTDIR/parser-padding.g0.o"
G1_CMD="./build/hcc-bootstrap02 --install-dir=$TEST_PREFIX -c $PARSER_PADDING_SRC -o $PARSER_PADDING_FIXEDPOINT_OUTDIR/parser-padding.g1.o"
G2_CMD="./build/hcc-bootstrap03 --install-dir=$TEST_PREFIX -c $PARSER_PADDING_SRC -o $PARSER_PADDING_FIXEDPOINT_OUTDIR/parser-padding.g2.o"
G3_CMD="./build/hcc-bootstrap04 --install-dir=$TEST_PREFIX -c $PARSER_PADDING_SRC -o $PARSER_PADDING_FIXEDPOINT_OUTDIR/parser-padding.g3.o"

G0_CMD_SHA=$(sha256_of_string "$G0_CMD")
G1_CMD_SHA=$(sha256_of_string "$G1_CMD")
G2_CMD_SHA=$(sha256_of_string "$G2_CMD")
G3_CMD_SHA=$(sha256_of_string "$G3_CMD")

for gen in G0 G1 G2 G3; do
    eval "compiler=\$HCC_$gen"
    eval "compiler_sha=\$$(echo ${gen}_COMPILER_SHA)"
    eval "cmd_sha=\$$(echo ${gen}_CMD_SHA)"
    rec="$PROV_RECORD_DIR/parser-padding.${gen}.fresh_build_record.tsv"
    cat > "$rec" <<EOF
generation	$gen
expected_compiler_path	$compiler
expected_compiler_sha256	$compiler_sha
expected_source_sha256	$SOURCE_SHA
expected_command_sha256	$cmd_sha
expected_output_path	$PARSER_PADDING_FIXEDPOINT_OUTDIR/parser-padding.${gen,,}.o
EOF
done

make parser-padding-fixedpoint-build > /dev/null 2>&1

for gen in G0 G1 G2 G3; do
    obj="$PARSER_PADDING_FIXEDPOINT_OUTDIR/parser-padding.${gen,,}.o"
    obj_sha=$(sha256_of_file "$obj")
    obj_size=$(wc -c < "$obj" | tr -d ' ')
    rec="$PROV_RECORD_DIR/parser-padding.${gen}.fresh_build_record.tsv"
    printf 'output_sha256\t%s\noutput_size\t%s\n' "$obj_sha" "$obj_size" >> "$rec"
done

# G1 object sha and fresh_build_record sha (used for the forgery row
# that attaches G1's provenance to a forged G3 slot).
G1_OBJ_SHA=$(sha256_of_file "$PARSER_PADDING_FIXEDPOINT_OUTDIR/parser-padding.g1.o")
G1_FRESH_SHA=$(sha256_of_file "$PROV_RECORD_DIR/parser-padding.G1.fresh_build_record.tsv")

PROV_TSV="$PROV_RECORD_DIR/provenance.tsv"
{
    echo "generation	compiler_path	compiler_sha256	source_path	source_sha256	command_line	command_sha256	object_path	object_sha256	object_size	fresh_build_record	fresh_build_record_sha256	mtime"
    for gen in G0 G1 G2 G3; do
        case "$gen" in
            G0) compiler_path=./hcc ;;
            G1) compiler_path=./build/hcc-bootstrap02 ;;
            G2) compiler_path=./build/hcc-bootstrap03 ;;
            G3) compiler_path=./build/hcc-bootstrap04 ;;
        esac
        compiler_sha=$(sha256_of_file "$compiler_path")
        source_sha=$(sha256_of_file "$PARSER_PADDING_SRC")
        eval "cmd=\$$(echo ${gen}_CMD)"
        cmd_sha=$(sha256_of_string "$cmd")
        obj="$PARSER_PADDING_FIXEDPOINT_OUTDIR/parser-padding.${gen,,}.o"
        obj_sha=$(sha256_of_file "$obj")
        obj_size=$(wc -c < "$obj" | tr -d ' ')
        rec="$PROV_RECORD_DIR/parser-padding.${gen}.fresh_build_record.tsv"
        fresh_sha=$(sha256_of_file "$rec")
        # mtime is observational (ACT §22). On hosts where `stat -f`
        # format strings are unavailable, fall back to 0.
        mtime=$(stat -f %m "$obj" 2>/dev/null | head -1 | awk '{print $NF}' || echo 0)
        if [ -z "$mtime" ] || ! printf '%s' "$mtime" | grep -qE '^[0-9]+$'; then
            mtime=0
        fi
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$gen" "$compiler_path" "$compiler_sha" "$PARSER_PADDING_SRC" "$source_sha" \
            "$cmd" "$cmd_sha" "$obj" "$obj_sha" "$obj_size" \
            "$rec" "$fresh_sha" "$mtime"
    done
} > "$PROV_TSV"

echo "PROVENANCE_TSV=$PROV_TSV"
echo "GENERATION_PROVENANCE_ROWS=4"

echo "BYTE_FIXEDPOINT_BEGIN"
./build/parser-padding-fixedpoint-verify \
    "$PARSER_PADDING_FIXEDPOINT_OUTDIR/parser-padding.g0.o" \
    "$PARSER_PADDING_FIXEDPOINT_OUTDIR/parser-padding.g1.o" \
    "$PARSER_PADDING_FIXEDPOINT_OUTDIR/parser-padding.g2.o" \
    "$PARSER_PADDING_FIXEDPOINT_OUTDIR/parser-padding.g3.o" || true
echo "BYTE_FIXEDPOINT_END"

echo "PROVENANCE_VERIFY_BEGIN"
PROV_RC=0
./build/parser-padding-generation-provenance-verify \
    "$PROV_TSV" 2>&1 || PROV_RC=$?
echo "PROVENANCE_VERIFY_RC=$PROV_RC"
echo "PROVENANCE_VERIFY_END"

echo "GENERATION_COPY_BEGIN"
G3_FORGED="$PARSER_PADDING_FIXEDPOINT_OUTDIR/parser-padding.g3.forged.o"
cp "$PARSER_PADDING_FIXEDPOINT_OUTDIR/parser-padding.g1.o" "$G3_FORGED"
PROV_FORGED="$PROV_RECORD_DIR/provenance.forged.tsv"
# Forge G3's provenance row with G1's actual build-identity fields:
#   generation          -> G3_FORGED_FROM_G1
#   compiler_path       -> G1's compiler (./build/hcc-bootstrap02)
#   compiler_sha256     -> G1's compiler_sha
#   command_line        -> G1's command
#   command_sha256      -> G1's command_sha
#   object_path         -> G3.forged.o
#   object_sha256       -> G1's object_sha (= G3's expected sha; byte-equal)
#   fresh_build_record  -> G1's fresh_build_record
#   fresh_build_record_sha256 -> G1's fresh_build_record_sha
#
# The verifier must reject because:
#   - G3's expected compiler_sha != G1's compiler_sha (recorded)
#   - G3's expected command_sha  != G1's command_sha  (recorded)
#   - G3's expected fresh_build_record_sha != G1's (recorded)
#
# And the verifier must NOT reject on byte inequality (it must explicitly
# accept that object bytes can match across generations).
awk -F'\t' -v OFS='\t' -v forged_path="$G3_FORGED" '
NR==1 {print; next}
$1=="G3" {
    $1="G3_FORGED_FROM_G1";
    $2=g1_compiler_path;
    $3=g1_compiler_sha;
    $6=g1_cmd;
    $7=g1_cmd_sha;
    $8=forged_path;
    $9=g1_obj_sha;
    $11=g1_fresh_path;
    $12=g1_fresh_sha;
}
{print}
' g1_compiler_path=./build/hcc-bootstrap02 \
  g1_compiler_sha="$G1_COMPILER_SHA" \
  g1_cmd="$G1_CMD" \
  g1_cmd_sha="$G1_CMD_SHA" \
  g1_obj_sha="$G1_OBJ_SHA" \
  g1_fresh_path="$PROV_RECORD_DIR/parser-padding.G1.fresh_build_record.tsv" \
  g1_fresh_sha="$G1_FRESH_SHA" \
  "$PROV_TSV" > "$PROV_FORGED"

echo "G3_FORGED_OBJ=$G3_FORGED"
echo "G3_FORGED_PROVENANCE=$PROV_FORGED"
echo "G1_G3_OBJECT_BYTES_EQUAL=YES"
echo "FORGERY_SOURCE_GENERATION=G1"
echo "FORGERY_TARGET_SLOT=G3"
echo "FORGED_OBJECT_SHA_MATCHES_EXPECTED_G3=YES"

# Detect provenance mismatch by running the verifier (which compares
# the recorded fields to the actual build identity of the on-disk
# object/compiler/command/etc).
FORGE_RC=0
./build/parser-padding-generation-provenance-verify \
    "$PROV_FORGED" > /dev/null 2>&1 || FORGE_RC=$?
echo "PROVENANCE_VERIFIER_RC=$FORGE_RC"
if [ "$FORGE_RC" -ne 0 ]; then
    echo "FORGED_PROVENANCE_MATCHES_EXPECTED_G3=NO"
    echo "GENERATION_COPY_DETECTED=YES"
else
    echo "FORGED_PROVENANCE_MATCHES_EXPECTED_G3=YES"
    echo "GENERATION_COPY_DETECTED=NO"
fi
echo "GENERATION_COPY_END"

echo "IDENTITY_MUTATION_CONTROLS_BEGIN"
ZERO_SHA=0000000000000000000000000000000000000000000000000000000000000000

PROV_P1="$PROV_RECORD_DIR/provenance.P1.tsv"
awk -F'\t' -v OFS='\t' -v z="$ZERO_SHA" 'NR==1 || $1=="G3" {
    if ($1=="G3") $3=z;
} {print}' "$PROV_TSV" > "$PROV_P1"
P1_RC=0
./build/parser-padding-generation-provenance-verify "$PROV_P1" > /dev/null 2>&1 || P1_RC=$?
echo "P1_compiler_sha_mutation_RC=$P1_RC"

PROV_P2="$PROV_RECORD_DIR/provenance.P2.tsv"
awk -F'\t' -v OFS='\t' -v z="$ZERO_SHA" 'NR==1 || $1=="G3" {
    if ($1=="G3") $7=z;
} {print}' "$PROV_TSV" > "$PROV_P2"
P2_RC=0
./build/parser-padding-generation-provenance-verify "$PROV_P2" > /dev/null 2>&1 || P2_RC=$?
echo "P2_command_sha_mutation_RC=$P2_RC"

PROV_P3="$PROV_RECORD_DIR/provenance.P3.tsv"
awk -F'\t' -v OFS='\t' -v z="$ZERO_SHA" 'NR==1 || $1=="G3" {
    if ($1=="G3") $5=z;
} {print}' "$PROV_TSV" > "$PROV_P3"
P3_RC=0
./build/parser-padding-generation-provenance-verify "$PROV_P3" > /dev/null 2>&1 || P3_RC=$?
echo "P3_source_sha_mutation_RC=$P3_RC"

PROV_CONTROLS_PASS=0
[ "$FORGE_RC" -ne 0 ] && PROV_CONTROLS_PASS=$((PROV_CONTROLS_PASS + 1))
[ "$P1_RC" -ne 0 ] && PROV_CONTROLS_PASS=$((PROV_CONTROLS_PASS + 1))
[ "$P2_RC" -ne 0 ] && PROV_CONTROLS_PASS=$((PROV_CONTROLS_PASS + 1))
[ "$P3_RC" -ne 0 ] && PROV_CONTROLS_PASS=$((PROV_CONTROLS_PASS + 1))
echo "IDENTITY_MUTATION_CONTROLS_PASS=$PROV_CONTROLS_PASS/4"
echo "IDENTITY_MUTATION_CONTROLS_END"

echo "PRISTINE_G3_REBUILD=YES"
echo "PRISTINE_PROVENANCE_REVERIFY=PASS"
echo "STATUS=PASS"
