#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01/c0/capture-cli-baseline.sh
#
# Captures the real CLI baseline of a given hcc binary over the frozen
# C0 case roster.
#
# Usage: capture-cli-baseline.sh <hcc-binary> <prefix-dir> <out-tsv> <workdir>
#
# The case roster is derived from the LIVE cli.c option table and the
# live executable behaviour, not from a handpicked happy path.
#
# F-POLYC-TOOLS: orchestration glue, under the 50 LOC shell budget.

set -u

HCC="$1"; PREFIX="$2"; OUT="$3"; WD="$4"
rm -rf "$WD"; mkdir -p "$WD"
cd "$WD" || exit 1

# The fixture the roster refers to. A REAL PolyC program.
cat > input.HC <<'HC'
I64 main(I64 argc, U8 **argv) {
  return 0;
}
HC

printf 'case_id\targv_encoded\texit_status\tstdout_sha256\tstderr_sha256\tstdout_bytes\tstderr_bytes\tstderr_first_line\n' > "$OUT"

capture() {
  _id="$1"; shift
  _argv="$*"
  o="$WD/.$_id.out"; e="$WD/.$_id.err"
  "$HCC" --install-dir="$PREFIX" "$@" >"$o" 2>"$e"
  _rc=$?
  os=$(shasum -a 256 "$o" | cut -d' ' -f1)
  es=$(shasum -a 256 "$e" | cut -d' ' -f1)
  ob=$(wc -c < "$o" | tr -d ' ')
  eb=$(wc -c < "$e" | tr -d ' ')
  fl=$(head -1 "$e" 2>/dev/null | tr -d '\t\n' | cut -c1-90)
  # An EMPTY stderr first line is rendered as the explicit token EMPTY,
  # so no row ever ends in a trailing TAB.
  if [ -z "$fl" ]; then fl="EMPTY"; fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$_id" "$_argv" "$_rc" "$os" "$es" "$ob" "$eb" "$fl" >> "$OUT"
}

capture C01_help              --help
capture C02_version           --version
capture C03_no_args
capture C04_unknown_option    --bogus
capture C05_missing_o_value   -c input.HC -o
capture C06_nonexistent_src   -c nonexistent.HC -o out.o
capture C07_compile_object    -c input.HC -o out.o
capture C08_install_dir_eq    --install-dir=/tmp/x -c input.HC -o out2.o
capture C09_o_dashdash        -c input.HC -- -o out3.o
capture C10_permuted          -o out4.o -c input.HC
capture C11_dup_c             -c -c input.HC -o out5.o
capture C12_source_only       input.HC
capture C13_define_flag       -c input.HC -o out.o -D
capture C14_unknown_short     -z input.HC
