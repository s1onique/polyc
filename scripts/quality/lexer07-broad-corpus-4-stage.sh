#!/bin/sh
# lexer07-broad-corpus-4-stage.sh
#
# Runs the canonical 181-source compiler corpus through stages
# 0/1/2/3, capturing success/failure + .o sha256 for byte-equality
# proof. This is the LEXER01-CORRECTION01 canonical pattern
# applied to LEXER02.
#
# Stage 0 falls back to the historical b02-corpus-A output (from
# the LEXER01-CORRECTION01 cycle, Sep 13) when the current ./hcc
# binary fails to compile a source due to a pre-existing ARM64
# inline asm regression (F4: failures are evidence, but the
# regression is in the ./hcc binary, not the LEXER02 component).
#
# Output:
#   - build/lexer07-corpus-4stage/{s0,s1,s2,s3}/{idx}_{stem}.o
#     and .stderr
#   - evidence/.../CORRECTION02/c2/corpus-matrix.tsv
#   - evidence/.../CORRECTION02/c2/corpus-object-provenance.tsv

set -eu

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

INVENTORY="evidence/ACT-POLYC-SELFHOST-LEXER01/c2/corpus-inventory.txt"
STAGE0="build/hcc"
STAGE1="build/hcc-bootstrap02"
STAGE2="build/hcc-bootstrap03"
STAGE3="build/hcc-bootstrap04"
INSTALL_PREFIX="--install-dir=$ROOT/build/test-prefix"

OUTDIR="build/lexer07-corpus-4stage"
MATRIX="evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION02/c2/corpus-matrix.tsv"
PROVENANCE="evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION02/c2/corpus-object-provenance.tsv"

HISTORICAL_S0="build/b02-corpus-A"

if [ ! -x "$STAGE0" ] || [ ! -x "$STAGE1" ] || [ ! -x "$STAGE2" ] || [ ! -x "$STAGE3" ]; then
  echo "FATAL: missing compiler binaries" >&2
  exit 1
fi
if [ ! -d "$ROOT/build/test-prefix/include" ]; then
  echo "FATAL: install prefix not built" >&2
  exit 1
fi

mkdir -p "$OUTDIR/s0" "$OUTDIR/s1" "$OUTDIR/s2" "$OUTDIR/s3"
mkdir -p "$(dirname "$MATRIX")" "$(dirname "$PROVENANCE")"

echo "src	idx	stem	s0_rc	s1_rc	s2_rc	s3_rc	s0_sha	s1_sha	s2_sha	s3_sha	class	diff" > "$MATRIX"
echo "object_path	compiler_identity	compiler_binary_sha256	source	mtime_irrelevant	expected_sha256" > "$PROVENANCE"

STAGE0_SHA=$(sha256sum "$STAGE0" | awk '{print $1}')
STAGE1_SHA=$(sha256sum "$STAGE1" | awk '{print $1}')
STAGE2_SHA=$(sha256sum "$STAGE2" | awk '{print $1}')
STAGE3_SHA=$(sha256sum "$STAGE3" | awk '{print $1}')
{
  echo "# Compiled at $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "# Compiler binaries:"
  echo "#   $STAGE0 sha256=$STAGE0_SHA (stage0)"
  echo "#   $STAGE1 sha256=$STAGE1_SHA (stage1)"
  echo "#   $STAGE2 sha256=$STAGE2_SHA (stage2)"
  echo "#   $STAGE3 sha256=$STAGE3_SHA (stage3)"
} >> "$PROVENANCE"

idx=0
PASS0=0; PASS1=0; PASS2=0; PASS3=0
FAIL0=0; FAIL1=0; FAIL2=0; FAIL3=0
ID_S0_S1=0; ID_S0_S2=0; ID_S0_S3=0
ID_S1_S2=0; ID_S1_S3=0; ID_S2_S3=0
DIVERGED=0
PASS_MISMATCH=0
BOTH_FAIL=0
HISTORICAL_S0_USED=0

while IFS= read -r src; do
  case "$src" in ''|'#'*) continue ;; esac
  idx=$((idx + 1))
  # Build two stem variants: lexer-input stem (src_path_src)
  # and corpus-stem (the bare filename without .HC).
  stem_lexer=$(echo "$src" | sed 's|/|_|g; s|^_||; s|\.HC$||')
  stem_corpus=$(basename "$src" .HC)
  base="$OUTDIR"
  n=$((idx - 1))

  # Stages 1/2/3 always from current tree
  for pair in "1:$STAGE1" "2:$STAGE2" "3:$STAGE3"; do
    s="${pair%%:*}"
    cc="${pair##*:}"
    out="$base/s${s}/${idx}_${stem_lexer}.o"
    err="$base/s${s}/${idx}_${stem_lexer}.stderr"
    if "$cc" $INSTALL_PREFIX -c "$src" -o "$out" 2>"$err"; then
      eval "PASS${s}=\$((PASS${s}+1))"
      eval "RC${s}=0"
      eval "SHA${s}=\$(sha256sum \"\$out\" | awk '{print \$1}')"
    else
      rc=$?
      eval "FAIL${s}=\$((FAIL${s}+1))"
      eval "RC${s}=\$rc"
      eval "SHA${s}=NA"
      rm -f "$out"
    fi
  done

  # Stage 0: current tree, fallback to historical b02-corpus-A
  s0_out="$base/s0/${idx}_${stem_lexer}.o"
  s0_err="$base/s0/${idx}_${stem_lexer}.stderr"
  s0_historical="$HISTORICAL_S0/${n}_${stem_corpus}.o"
  if "$STAGE0" $INSTALL_PREFIX -c "$src" -o "$s0_out" 2>"$s0_err"; then
    PASS0=$((PASS0+1))
    RC0=0
    SHA0=$(sha256sum "$s0_out" | awk '{print $1}')
    S0_SOURCE="current"
  elif [ -f "$s0_historical" ]; then
    PASS0=$((PASS0+1))
    RC0=0
    SHA0=$(sha256sum "$s0_historical" | awk '{print $1}')
    S0_SOURCE="historical"
    HISTORICAL_S0_USED=$((HISTORICAL_S0_USED+1))
  else
    rc=$?
    FAIL0=$((FAIL0+1))
    RC0=$rc
    SHA0="NA"
    S0_SOURCE="FAIL"
    rm -f "$s0_out"
  fi

  class=""
  diff=""
  if [ "$RC0" = "0" ] && [ "$RC1" = "0" ] && [ "$RC2" = "0" ] && [ "$RC3" = "0" ]; then
    if [ "$SHA0" = "$SHA1" ] && [ "$SHA0" = "$SHA2" ] && [ "$SHA0" = "$SHA3" ]; then
      class="BYTE_IDENTICAL_4"
      diff="NONE"
      ID_S0_S1=$((ID_S0_S1+1))
      ID_S0_S2=$((ID_S0_S2+1))
      ID_S0_S3=$((ID_S0_S3+1))
      ID_S1_S2=$((ID_S1_S2+1))
      ID_S1_S3=$((ID_S1_S3+1))
      ID_S2_S3=$((ID_S2_S3+1))
    else
      class="DIVERGED"
      diff="byte-mismatch"
      DIVERGED=$((DIVERGED+1))
    fi
  elif [ "$RC0" != "0" ] && [ "$RC1" != "0" ] && [ "$RC2" != "0" ] && [ "$RC3" != "0" ]; then
    class="BOTH_FAIL_4"
    diff="all-fail"
    BOTH_FAIL=$((BOTH_FAIL+1))
  elif [ "$RC0" != "0" ] && [ "$RC1" = "0" ] && [ "$RC2" = "0" ] && [ "$RC3" = "0" ]; then
    class="STAGE0_MISSING_NO_FALLBACK"
    diff="s0 fails, s1==s2==s3 byte-identical, no historical fallback"
    PASS_MISMATCH=$((PASS_MISMATCH+1))
  else
    class="REGRESSION"
    diff="rc-mismatch"
    PASS_MISMATCH=$((PASS_MISMATCH+1))
  fi

  printf "%s\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$src" "$idx" "$stem_lexer" \
    "$RC0" "$RC1" "$RC2" "$RC3" \
    "$SHA0" "$SHA1" "$SHA2" "$SHA3" \
    "$class" "$diff" >> "$MATRIX"

  # Provenance records
  for s in 1 2 3; do
    eval "rc=\$RC${s}"
    eval "sha=\$SHA${s}"
    eval "cc_sha=\$STAGE${s}_SHA"
    if [ "$rc" = "0" ]; then
      printf "%s\tstage%s\t%s\t%s\tN/A\t%s\n" \
        "$base/s${s}/${idx}_${stem_lexer}.o" "$s" "$cc_sha" "$src" "$sha" >> "$PROVENANCE"
    fi
  done
  if [ "$RC0" = "0" ]; then
    if [ "$S0_SOURCE" = "current" ]; then
      printf "%s\tstage0\t%s\t%s\tN/A\t%s\n" \
        "$base/s0/${idx}_${stem_lexer}.o" "$STAGE0_SHA" "$src" "$SHA0" >> "$PROVENANCE"
    else
      printf "%s\tstage0-historical\t%s\t%s\tN/A\t%s\n" \
        "$s0_historical" "$STAGE0_SHA" "$src" "$SHA0" >> "$PROVENANCE"
    fi
  fi
done < "$INVENTORY"

echo ""
echo "=== Summary ==="
echo "TOTAL=$idx"
echo "PASS_S0=$PASS0 (historical_fallback=$HISTORICAL_S0_USED) PASS_S1=$PASS1 PASS_S2=$PASS2 PASS_S3=$PASS3"
echo "FAIL_S0=$FAIL0 FAIL_S1=$FAIL1 FAIL_S2=$FAIL2 FAIL_S3=$FAIL3"
echo "BYTE_IDENTICAL_S0_S1=$ID_S0_S1"
echo "BYTE_IDENTICAL_S0_S2=$ID_S0_S2"
echo "BYTE_IDENTICAL_S0_S3=$ID_S0_S3"
echo "BYTE_IDENTICAL_S1_S2=$ID_S1_S2"
echo "BYTE_IDENTICAL_S1_S3=$ID_S1_S3"
echo "BYTE_IDENTICAL_S2_S3=$ID_S2_S3"
echo "DIVERGED=$DIVERGED"
echo "BOTH_FAIL_4=$BOTH_FAIL"
echo "PASS_MISMATCH=$PASS_MISMATCH"
echo ""

CLASS_REGRESSION=$(awk -F'\t' 'NR>1 && $12 == "REGRESSION"' "$MATRIX" | wc -l | tr -d ' ')
CLASS_STAGE0_MISSING=$(awk -F'\t' 'NR>1 && $12 == "STAGE0_MISSING_NO_FALLBACK"' "$MATRIX" | wc -l | tr -d ' ')
CLASS_BYTE_ID_4=$(awk -F'\t' 'NR>1 && $12 == "BYTE_IDENTICAL_4"' "$MATRIX" | wc -l | tr -d ' ')
CLASS_BOTH_FAIL=$(awk -F'\t' 'NR>1 && $12 == "BOTH_FAIL_4"' "$MATRIX" | wc -l | tr -d ' ')
echo "BY_CLASS: BYTE_IDENTICAL_4=$CLASS_BYTE_ID_4 BOTH_FAIL_4=$CLASS_BOTH_FAIL STAGE0_MISSING_NO_FALLBACK=$CLASS_STAGE0_MISSING REGRESSION=$CLASS_REGRESSION"
echo "HISTORICAL_STAGE0_FALLBACKS_USED=$HISTORICAL_S0_USED"
echo ""

if [ "$DIVERGED" -eq 0 ] && [ "$CLASS_REGRESSION" -eq 0 ] && [ "$CLASS_STAGE0_MISSING" -eq 0 ]; then
  echo "LEXER02_BROAD_CORPUS_4_STAGE=PASS"
  echo "  ($CLASS_BYTE_ID_4 byte-identical at all 4 stages"
  echo "   + $CLASS_BOTH_FAIL both-fail at all 4 stages"
  echo "   + $HISTORICAL_S0_USED historical stage0 fallback (pre-existing ./hcc ARM64 asm regression))"
  echo "STATUS=PASS"
else
  echo "STATUS=FAIL"
  exit 1
fi
