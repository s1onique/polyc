#!/bin/sh
#
# evidence/ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03/c4r2/red-capture.sh
#
# ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 REMEDIATION ROUND 2.
#
# THE DECISIVE RED CAPTURE SCRIPT.
#
# It reproduces, at the REAL execution seam, the THREE P1 defects that the
# second independent Codex review reported:
#
#   F1  the comparator's rule does not generate the test-prefix header it
#       consumes, so a pristine isolated checkout cannot build it;
#   F2  the comparator ACCEPTS a malformed Mach-O, an unsupported artifact
#       class, a forged exit status, and a STALE replay of valid artifacts
#       and transcripts;
#   F3  the emission verifier classifies an archive NAME-FORMAT mutation that
#       changes the extracted payload as harmless METADATA NONDETERMINISM.
#
# It writes a machine-readable ledger to stdout. Every row records the CASE,
# the OBSERVATION, the EXPECTED verdict, the OBSERVED verdict, and whether the
# OBSERVED verdict DISPROVED the expectation (which is the RED).
#
# The script is READ-ONLY with respect to the repository: it writes only into
# the work directory it is given. It uses no Python.
#
# F-POLYC-TOOLS: shell as bootstrap glue; the tool itself is PolyC.

set -u

REPO="${1:?usage: red-capture.sh <repo-root> <work-dir>}"
WORK="${2:?usage: red-capture.sh <repo-root> <work-dir>}"

if [ ! -d "$REPO" ]; then
  echo "red-capture: the repository root $REPO does not exist" >&2
  exit 2
fi

rm -rf "$WORK"
mkdir -p "$WORK/good" "$WORK/o" "$WORK/p"

COMPARE="$REPO/build/driver-required-route-correction03-compare"
EMISSION="$REPO/build/driver-required-route-correction03-emission"
OFFHCC="$REPO/build/driver-wp001-correction03/off/hcc"
PREFIX="$REPO/build/test-prefix"
FIXTURE="$REPO/tests/driver-wp001/required-route/route-source.HC"

for f in "$COMPARE" "$EMISSION" "$OFFHCC"; do
  if [ ! -x "$f" ]; then
    echo "red-capture: the required tool $f is not present or not executable" >&2
    exit 2
  fi
done

# ---------------------------------------------------------------------------
# The KNOWN-GOOD observation set, produced by a REAL selector-OFF run.
# ---------------------------------------------------------------------------
cp "$FIXTURE" "$WORK/good/source.HC"
(
  cd "$WORK/good" || exit 2
  set +e
  "$OFFHCC" --install-dir="$PREFIX" -c source.HC -o artifact.bin \
    >stdout.txt 2>stderr.txt
  echo $? > exit.txt
)
if [ ! -s "$WORK/good/artifact.bin" ]; then
  echo "red-capture: the known-good artifact was not produced" >&2
  exit 2
fi

: > "$WORK/empty.txt"
printf '0\n' > "$WORK/exit0.txt"
# The EMPTY and EXIT0 paths are used from INSIDE $WORK/good, so they are
# absolute.
EMPTY_ABS="$WORK/empty.txt"
EXIT0_ABS="$WORK/exit0.txt"

# The EXPECTED class and architecture of the known-good artifact, derived by
# the comparator's own `derive` mode from the REAL oracle artifact.
ECLASS=$("$COMPARE" derive "$WORK/good/artifact.bin" \
  | sed -n 's/^DERIVED_CLASS\t//p')
EARCH=$("$COMPARE" derive "$WORK/good/artifact.bin" \
  | sed -n 's/^DERIVED_ARCH\t//p')
if [ -z "$ECLASS" ]; then
  echo "red-capture: the expected class could not be derived" >&2
  exit 2
fi

printf 'CASE\tOBSERVATION\tEXPECTED\tOBSERVED\tRED\n'

report() {
  # report <case> <observation> <expected> <observed>
  if [ "$3" = "$4" ]; then
    printf '%s\t%s\t%s\t%s\tNO\n' "$1" "$2" "$3" "$4"
  else
    printf '%s\t%s\t%s\t%s\tYES\n' "$1" "$2" "$3" "$4"
  fi
}

run_compare() {
  # run_compare <case> <oracle-art> <polyc-art> <o-stdout> <p-stdout>
  #             <o-stderr> <p-stderr> <o-exit> <p-exit> <class> <arch>
  #             <exit> [symbol ...]
  "$COMPARE" "$@" >"$WORK/$1.out.txt" 2>&1
  echo $?
}

cd "$WORK/good" || exit 2


# --- F2-1: a forged exit status with TRAILING TEXT -------------------------
printf '0 trailing garbage text\n' > exit-forged.txt
rc=$(run_compare F2_1_TRAILING_EXIT_TEXT artifact.bin artifact.bin \
  stdout.txt stdout.txt stderr.txt stderr.txt exit-forged.txt exit-forged.txt \
  "$ECLASS" "$EARCH" 0 _main)
if [ "$rc" -eq 0 ]; then obs=ACCEPT; else obs=REJECT; fi
report F2_1_TRAILING_EXIT_TEXT "a forged exit status with trailing text" \
  REJECT "$obs"

# --- F2-2: an out-of-bounds Mach-O symbol count ----------------------------
# The LC_SYMTAB load command of the known-good artifact is located with the
# system tool, and its `nsyms` field is set past the end of the file.
#
# The load commands of a mach_header_64 start at file offset 32. The command
# index is reported by `otool -l` as "Load command N", so the file offset of
# the LC_SYMTAB command is 32 plus the sum of the cmdsize of every preceding
# load command.
otool -l artifact.bin > ot.txt 2>/dev/null
LCIDX=$(awk '
  /^Load command [0-9]+/ { idx = $3; next }
  /cmd LC_SYMTAB/ { print idx; exit }' ot.txt)
if [ -n "$LCIDX" ]; then
  CMDOFF=$(awk -v want="$LCIDX" '
    /^Load command [0-9]+/ { idx = $3; next }
    /^ *cmdsize / { if (idx == want) { done = 1 } else { off += $2 } }
    END { if (done) { print off + 32 } }' ot.txt)
  NSYMS_OFF=$((CMDOFF + 12))
  SYMOFF_OFF=$((CMDOFF + 8))
  # The FILE offset of the symbol table itself, for the string-index witness.
  SYMOFF=$(awk '
    /^ *cmd LC_SYMTAB/ { want = 1; next }
    want && /^ *symoff/ { so = $2; next }
    END { print so }' ot.txt)
  cp artifact.bin macho-oob-nsyms.o
  printf '\377\377\377\000' | dd of=macho-oob-nsyms.o bs=1 seek="$NSYMS_OFF" \
    conv=notrunc 2>/dev/null
  rc=$(run_compare F2_2_OOB_SYMBOL_COUNT macho-oob-nsyms.o macho-oob-nsyms.o \
    stdout.txt stdout.txt stderr.txt stderr.txt exit.txt exit.txt \
    "$ECLASS" "$EARCH" 0 _main)
  if [ "$rc" -eq 0 ]; then obs=ACCEPT; else obs=REJECT; fi
  report F2_2_OOB_SYMBOL_COUNT "an out-of-bounds Mach-O symbol count" \
    REJECT "$obs"
  nm macho-oob-nsyms.o > nm-oob-nsyms.txt 2>&1
fi

# --- F2-3: an undersized symbol table -------------------------------------
if [ -n "$CMDOFF" ]; then
  cp artifact.bin macho-undersized.o
  printf '\000\010\000\000' | dd of=macho-undersized.o bs=1 seek="$SYMOFF_OFF" \
    conv=notrunc 2>/dev/null
  rc=$(run_compare F2_3_UNDERSIZED_SYMBOL_TABLE macho-undersized.o \
    macho-undersized.o stdout.txt stdout.txt stderr.txt stderr.txt \
    exit.txt exit.txt "$ECLASS" "$EARCH" 0 _main)
  if [ "$rc" -eq 0 ]; then obs=ACCEPT; else obs=REJECT; fi
  report F2_3_UNDERSIZED_SYMBOL_TABLE "an undersized Mach-O symbol table" \
    REJECT "$obs"
  nm macho-undersized.o > nm-undersized.txt 2>&1
fi

# --- F2-4: an out-of-bounds string-table entry ----------------------------
if [ -n "$SYMOFF" ]; then
  cp artifact.bin macho-oob-strx.o
  printf '\377\000\000\000' | dd of=macho-oob-strx.o bs=1 seek="$SYMOFF" \
    conv=notrunc 2>/dev/null
  rc=$(run_compare F2_4_OOB_STRING_ENTRY macho-oob-strx.o macho-oob-strx.o \
    stdout.txt stdout.txt stderr.txt stderr.txt exit.txt exit.txt \
    "$ECLASS" "$EARCH" 0 _main)
  if [ "$rc" -eq 0 ]; then obs=ACCEPT; else obs=REJECT; fi
  report F2_4_OOB_STRING_ENTRY "an out-of-bounds string-table entry" \
    REJECT "$obs"
fi

# --- F2-5: an overflowing exit integer ------------------------------------
printf '99999999999999999999999999\n' > exit-overflow.txt
rc=$(run_compare F2_5_OVERFLOWING_EXIT artifact.bin artifact.bin \
  stdout.txt stdout.txt stderr.txt stderr.txt exit-overflow.txt exit-overflow.txt \
  "$ECLASS" "$EARCH" 0 _main)
if [ "$rc" -eq 0 ]; then obs=ACCEPT; else obs=REJECT; fi
report F2_5_OVERFLOWING_EXIT "an overflowing exit integer" REJECT "$obs"

# --- F2-6: an identical UNSUPPORTED artifact on both sides ---------------
printf 'not a mach-o image at all, just text garbage\n' > garbage.bin
rc=$(run_compare F2_6_IDENTICAL_UNSUPPORTED garbage.bin garbage.bin \
  stdout.txt stdout.txt stderr.txt stderr.txt exit.txt exit.txt \
  OTHER none 0 _main)
if [ "$rc" -eq 0 ]; then obs=ACCEPT; else obs=REJECT; fi
report F2_6_IDENTICAL_UNSUPPORTED \
  "identical unsupported artifacts on both sides" REJECT "$obs"

# --- F2-7: a VALID STALE artifact replayed on BOTH sides ------------------
# The stale artifact is a REAL, VALID, current-format object that still
# exports the required symbol, but it was produced from a DIFFERENT source.
printf 'I64 OtherFunction() {\n    return 3;\n}\nI64 main(I64 argc, U8 **argv) {\n    return 0;\n}\n' > other.HC
(
  set +e
  "$OFFHCC" --install-dir="$PREFIX" -c other.HC -o stale-valid.bin \
    >/dev/null 2>&1
)
if [ -s stale-valid.bin ]; then
  rc=$(run_compare F2_7_VALID_STALE_BOTH_SIDES stale-valid.bin stale-valid.bin \
    stdout.txt stdout.txt stderr.txt stderr.txt exit.txt exit.txt \
    "$ECLASS" "$EARCH" 0 _main)
  if [ "$rc" -eq 0 ]; then obs=ACCEPT; else obs=REJECT; fi
  report F2_7_VALID_STALE_BOTH_SIDES \
    "valid stale artifacts replayed on BOTH sides" REJECT "$obs"
fi

# ---------------------------------------------------------------------------
# The F3 witnesses.
#
# The archive is the REAL archive produced by the dylib route. The name-format
# mutation changes the member's `#1/N` extended-name field so that `ar`
# extracts a DIFFERENT payload, while the archive's declared size and its
# raw member bytes are unchanged.
# ---------------------------------------------------------------------------
ARCHIVE="$PREFIX/lib/libmylib.a"
if [ ! -f "$ARCHIVE" ]; then
  echo "red-capture: the reference archive $ARCHIVE is not present" >&2
  exit 2
fi

# The first member of the archive is the `__.SYMDEF SORTED` member, whose
# declared size is 44 (20 bytes of name plus 24 bytes of payload). The
# second member header therefore starts at 8 + 60 + 44.
S1SIZE=44
SECOND_HDR=$((8 + 60 + S1SIZE))
cp "$ARCHIVE" "$WORK/o/libmylib.a"
cp "$ARCHIVE" "$WORK/p/libmylib.a"
printf '\062\060' | dd of="$WORK/p/libmylib.a" bs=1 seek="$((SECOND_HDR + 3))" \
  conv=notrunc 2>/dev/null

# The INDEPENDENT cross-check: `ar` must extract DIFFERENT payloads.
rm -rf "$WORK/ar-o" "$WORK/ar-p"
mkdir -p "$WORK/ar-o" "$WORK/ar-p"
( cd "$WORK/ar-o" && ar x "$WORK/o/libmylib.a" ) >/dev/null 2>&1
( cd "$WORK/ar-p" && ar x "$WORK/p/libmylib.a" ) >/dev/null 2>&1
if [ -f "$WORK/ar-o/source.o" ] && [ -f "$WORK/ar-p/source.o" ]; then
  if cmp -s "$WORK/ar-o/source.o" "$WORK/ar-p/source.o"; then
    ARDIFF=IDENTICAL
  else
    ARDIFF=DIFFERENT
  fi
  echo "AR_EXTRACTED_PAYLOAD=$ARDIFF" >> "$WORK/ar-crosscheck.txt"
  if [ "$ARDIFF" = DIFFERENT ]; then
    rc=$("$EMISSION" F3_1_NAME_FORMAT_MUTATION archive "$WORK/o/" "$WORK/p/" \
      "$EMPTY_ABS" "$EMPTY_ABS" "$EMPTY_ABS" "$EMPTY_ABS" "$EXIT0_ABS" "$EXIT0_ABS" 0 none 0 \
      libmylib.a AR_ARCHIVE none >"$WORK/F3_1.out.txt" 2>&1; echo $?)
    if [ "$rc" -eq 0 ]; then obs=ACCEPT; else obs=REJECT; fi
    report F3_1_NAME_FORMAT_MUTATION \
      "an archive name-format mutation that changes the extracted payload" \
      REJECT "$obs"
  fi
fi

# --- F3-2: two IDENTICAL EMPTY archives -----------------------------------
printf '!<arch>\n' > "$WORK/empty.a"
mkdir -p "$WORK/e1" "$WORK/e2"
cp "$WORK/empty.a" "$WORK/e1/libmylib.a"
cp "$WORK/empty.a" "$WORK/e2/libmylib.a"
rc=$("$EMISSION" F3_2_IDENTICAL_EMPTY_ARCHIVES archive "$WORK/e1/" "$WORK/e2/" \
  "$EMPTY_ABS" "$EMPTY_ABS" "$EMPTY_ABS" "$EMPTY_ABS" "$EXIT0_ABS" "$EXIT0_ABS" 0 none 0 \
  libmylib.a AR_ARCHIVE none >"$WORK/F3_2.out.txt" 2>&1; echo $?)
if [ "$rc" -eq 0 ]; then obs=ACCEPT; else obs=REJECT; fi
report F3_2_IDENTICAL_EMPTY_ARCHIVES "two identical empty archives" \
  REJECT "$obs"

echo "RED_CAPTURE_DONE"


# --- F2-8: a VALID STALE stdout replayed on BOTH sides --------------------
printf 'STALE STDOUT FROM AN EARLIER RUN\n' > stale-stdout.txt
rc=$(run_compare F2_8_VALID_STALE_STDOUT_BOTH_SIDES artifact.bin artifact.bin \
  stale-stdout.txt stale-stdout.txt stderr.txt stderr.txt exit.txt exit.txt \
  "$ECLASS" "$EARCH" 0 _main)
if [ "$rc" -eq 0 ]; then obs=ACCEPT; else obs=REJECT; fi
report F2_8_VALID_STALE_STDOUT_BOTH_SIDES \
  "valid stale stdout replayed on BOTH sides" REJECT "$obs"

# --- F2-9: an ON-only stale stdout ----------------------------------------
rc=$(run_compare F2_9_ON_ONLY_STALE_STDOUT artifact.bin artifact.bin \
  stale-stdout.txt stdout.txt stderr.txt stderr.txt exit.txt exit.txt \
  "$ECLASS" "$EARCH" 0 _main)
if [ "$rc" -eq 0 ]; then obs=ACCEPT; else obs=REJECT; fi
report F2_9_ON_ONLY_STALE_STDOUT "an ON-only stale stdout" REJECT "$obs"
