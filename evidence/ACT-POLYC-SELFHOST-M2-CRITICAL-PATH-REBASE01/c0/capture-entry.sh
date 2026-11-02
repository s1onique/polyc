#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/c0/capture-entry.sh
#
# ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01 C0 RED.
#
# Captures the ENTRY IDENTITY AND HISTORY evidence file by actually
# running the §2.1 commands, recording for each one:
#
#   the command, its exit code, the UTC and local timestamps with
#   offsets, the SHA-256 of the captured output, and the output
#   itself (base64 for multi-line payloads so the TSV stays
#   parseable).
#
# Nothing here is hand-authored: every row is produced by the run.
#
# F-POLYC-TOOLS: this is ≤50-LOC-equivalent bootstrap glue that only
# captures command output. It computes no conclusion. All substantive
# verification lives in the compiled PolyC verifier
# tools/quality/m2-critical-path-rebase01-verify.HC.

set -u

OUT="evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/c0/entry-identity-and-history.tsv"
TMP=$(mktemp -t m2rebase-capture.XXXXXX)
trap 'rm -f "$TMP"' EXIT INT TERM

{
  echo '# ACT_ID=ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01'
  echo '# ACT_PHASE=C0-RED'
  echo '# EVIDENCE_KIND=entry-identity-and-history'
  echo '#'
  echo '# Every row below was produced by actually running the command'
  echo '# against the canonical checkout at the pinned entry. The output'
  echo '# column is base64 of the captured stdout+stderr so the TSV is'
  echo '# single-field parseable; the sha256 column is the digest of the'
  echo '# SAME captured bytes.'
  echo '#'
  printf 'command\texit_code\tutc_timestamp\tlocal_timestamp\tsha256_of_output\toutput_b64\n'
} > "$OUT"

run() {
  _label="$1"
  shift
  _utc=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  _loc=$(date '+%Y-%m-%dT%H:%M:%S%z')
  "$@" > "$TMP" 2>&1
  _rc=$?
  _sha=$(shasum -a 256 "$TMP" | awk '{print $1}')
  _b64=$(base64 < "$TMP" | tr -d '\n')
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$_label" "$_rc" "$_utc" "$_loc" "$_sha" "$_b64" >> "$OUT"
  return 0
}

run "git_branch_show_current" git branch --show-current
run "git_rev_parse_HEAD" git rev-parse HEAD
run "git_rev_parse_HEAD_tree" git rev-parse 'HEAD^{tree}'
run "git_status_porcelain_v1" git status --porcelain=v1
run "git_replace_l" git replace -l
run "git_worktree_list_porcelain" git worktree list --porcelain
run "git_log_40_full" git log --format=%H%x09%P%x09%s%n%b -40
run "git_log_1_oneline_HEAD" git log -1 --format=%H%x09%s HEAD
run "git_remote_v" git remote -v
run "git_reflog_5" git reflog -5
run "git_describe_all_heads" git show-ref --heads
run "git_stash_list" git stash list

# The predecessor's ACT trailers, one commit at a time, in reverse
# chronological order, so the four-commit chronology is independently
# derivable from Git object history alone.
for _c in $(git log --format=%H -4); do
  run "predecessor_trailers_$_c" git log -1 --format=%B "$_c"
  run "predecessor_files_$_c" git show --stat --format= "$_c"
done

# The canonical Factory-v2 range check over the predecessor.
run "factory_v2_range_check_predecessor" \
  ./scripts/quality/factory-v2-range-check.sh \
  ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02-CORRECTED01 \
  9ba4ba5ddbbfacb10393514874c829c9f21d5ea4

# The predecessor CLOSE cardinality, derived exactly as DOCTRINE §21
# prescribes (--oneline, not --pretty=format).
run "predecessor_close_cardinality" \
  sh -c "git log --all-match --grep='^ACT: ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02-CORRECTED01\$' --grep='^ACT-Phase: CLOSE\$' --oneline | wc -l"

# The predecessor's own evidence tree, frozen by path/OID/SHA-256.
run "predecessor_evidence_tree" \
  sh -c "git ls-tree -r --long HEAD evidence/ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02-CORRECTED01"

# The CENSUS01 evidence tree, frozen the same way.
run "census01_evidence_tree" \
  sh -c "git ls-tree -r --long HEAD evidence/ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01"

# The production link line and the subject manifest of the current build.
run "production_link_line" cat build/CMakeFiles/hcc.dir/link.txt
run "production_hcc_sha256" sh -c "shasum -a 256 build/hcc 2>/dev/null || echo UNAVAILABLE"

echo "CAPTURE_WRITTEN=$OUT"
echo "CAPTURE_ROWS=$(($(wc -l < "$OUT") - 10))"
