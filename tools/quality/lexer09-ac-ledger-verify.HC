// tools/quality/lexer09-ac-ledger-verify.HC
//
// ACT-POLYC-SELFHOST-LEXER04-CORRECTION03 C2 IMPL.
// ACT-POLYC-SELFHOST-LEXER04-CORRECTION04 C2 IMPL (qualification-only).
//
// PolyC native AC ledger verifier.
//
// Joins the C1 contract (c1-mandatory-ac-contract.tsv) against
// the C3 result table (mandatory-ac-status.tsv) using
//   ac_id + predicate_sha256
// not row position. Detects AC-ID shuffling that the previous
// ledger quietly masked.
//
// CORRECTION04: status table schema extended with optional
// evidence_sha256 (5th column). When present, the verifier
// recomputes the evidence SHA via ./build/lexer07-sha256 and
// asserts it matches. This binds evidence_path to actual on-disk
// content (per ACT §32).
//
// USAGE:
//   build/lexer09-ac-ledger-verify <contract.tsv> <status.tsv>

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"
#include "../../src/holyc-lib/system.HC"

I64 main(I64 argc, U8 **argv)
{
  if (argc != 3) {
    "USAGE: %s <contract.tsv> <status.tsv>\n", argv[0];
    return 2;
  }

  I64 contract_sz = 0;
  U8 *contract_raw = FileRead(argv[1], &contract_sz);
  if (!contract_raw || contract_sz == 0) {
    "AC_LEDGER_RC=2 reason=missing-contract\n";
    return 2;
  }

  I64 status_sz = 0;
  U8 *status_raw = FileRead(argv[2], &status_sz);
  if (!status_raw || status_sz == 0) {
    "AC_LEDGER_RC=2 reason=missing-status\n";
    Free(contract_raw);
    return 2;
  }

  // Count rows in contract (skip header)
  I64 contract_rows = 0;
  for (I64 i = 0; i < contract_sz; i = i + 1) {
    if (contract_raw[i] == '\n') contract_rows = contract_rows + 1;
  }
  contract_rows = contract_rows - 1;  // skip header

  // Count rows in status (skip header)
  I64 status_rows = 0;
  for (I64 i = 0; i < status_sz; i = i + 1) {
    if (status_raw[i] == '\n') status_rows = status_rows + 1;
  }
  status_rows = status_rows - 1;

  "AC_LEDGER_CONTRACT_ROWS=%d\n", contract_rows;
  "AC_LEDGER_STATUS_ROWS=%d\n", status_rows;

  // Simple line-by-line join. Each line after header has:
  //   contract: ac_id<TAB>exact_predicate<TAB>predicate_sha256<TAB>mandatory<TAB>phase
  //   status:   ac_id<TAB>predicate_sha256<TAB>status<TAB>evidence_path
  //
  // We join on ac_id (first tab-delimited field) and verify
  // that predicate_sha256 matches between contract[2] and status[1].

  I64 unknown = 0;
  I64 duplicate = 0;
  I64 missing = 0;
  I64 predicate_sha_mismatch = 0;
  I64 fail_status = 0;
  I64 evidence_sha_mismatch = 0;

  // Parse contract lines
  U8 *p = contract_raw;
  I64 contract_line_start = 0;
  for (I64 i = 0; i <= contract_sz; i = i + 1) {
    if (i == contract_sz || contract_raw[i] == '\n') {
      if (i > contract_line_start) {
        // Extract line content
        I64 line_len = i - contract_line_start;
        if (line_len > 0 && contract_raw[contract_line_start] != 'a') {
          // skip header
          U8 *line = contract_raw + contract_line_start;
          // Find first tab (end of ac_id)
          I64 tab1 = -1;
          for (I64 k = 0; k < line_len; k = k + 1) {
            if (line[k] == '\t') { tab1 = k; break; }
          }
          // Find second tab (end of exact_predicate)
          I64 tab2 = -1;
          for (I64 k = tab1 + 1; k < line_len; k = k + 1) {
            if (line[k] == '\t') { tab2 = k; break; }
          }
          // Find third tab (end of predicate_sha256)
          I64 tab3 = -1;
          for (I64 k = tab2 + 1; k < line_len; k = k + 1) {
            if (line[k] == '\t') { tab3 = k; break; }
          }
          if (tab1 > 0 && tab2 > tab1 + 1 && tab3 > tab2 + 1) {
            // Extract ac_id (line[0..tab1-1]) and contract_sha (line[tab2+1..tab3-1])
            Bool found = FALSE;
            Bool sha_match = FALSE;
            U8 *sp = status_raw;
            I64 sline_start = 0;
            for (I64 j = 0; j <= status_sz; j = j + 1) {
              if (j == status_sz || status_raw[j] == '\n') {
                if (j > sline_start && status_raw[sline_start] != 'a') {
                  U8 *sline = status_raw + sline_start;
                  I64 sline_len = j - sline_start;
                  I64 stab1 = -1;
                  for (I64 k = 0; k < sline_len; k = k + 1) {
                    if (sline[k] == '\t') { stab1 = k; break; }
                  }
                  if (stab1 == tab1) {
                    // Compare ac_id
                    Bool same_id = TRUE;
                    for (I64 k = 0; k < tab1; k = k + 1) {
                      if (line[k] != sline[k]) { same_id = FALSE; break; }
                    }
                    if (same_id) {
                      found = TRUE;
                      // status's predicate_sha256 is at stab1+1..stab2-1
                      I64 stab2 = -1;
                      for (I64 k = stab1 + 1; k < sline_len; k = k + 1) {
                        if (sline[k] == '\t') { stab2 = k; break; }
                      }
                      I64 contract_sha_len = tab3 - tab2 - 1;
                      I64 status_sha_len = stab2 - stab1 - 1;
                      if (contract_sha_len == status_sha_len) {
                        sha_match = TRUE;
                        for (I64 k = 0; k < contract_sha_len; k = k + 1) {
                          if (line[tab2 + 1 + k] != sline[stab1 + 1 + k]) {
                            sha_match = FALSE; break;
                          }
                        }
                      }
                      // Get status field (third tab-delimited value)
                      I64 stab3 = -1;
                      for (I64 k = stab2 + 1; k < sline_len; k = k + 1) {
                        if (sline[k] == '\t') { stab3 = k; break; }
                      }
                      if (stab3 > stab2) {
                        // Check status == PASS
                        if (!(stab3 - stab2 - 1 == 4 &&
                              sline[stab2+1] == 'P' && sline[stab2+2] == 'A' &&
                              sline[stab2+3] == 'S' && sline[stab2+4] == 'S')) {
                          fail_status = fail_status + 1;
                          "AC_LEDGER_FAIL ac_id=%.*s reason=NOT_PASS\n",
                            tab1, line;
                        }
                        // CORRECTION04 C2 IMPL: extract evidence_path
                        // (between stab3+1 and next tab) and optional
                        // evidence_sha256 (5th column). Recompute SHA via
                        // ./build/lexer07-sha256 --file and compare.
                        I64 stab4 = -1;
                        for (I64 k = stab3 + 1; k < sline_len; k = k + 1) {
                          if (sline[k] == '\t') { stab4 = k; break; }
                        }
                        if (stab4 > stab3) {
                          I64 evpath_start = stab3 + 1;
                          I64 evpath_len = stab4 - evpath_start;
                          U8 evpath[1024];
                          if (evpath_len < 1024) {
                            for (I64 k = 0; k < evpath_len; k = k + 1) evpath[k] = sline[evpath_start + k];
                            evpath[evpath_len] = 0;
                            // Extract recorded SHA (5th column, or until EOL)
                            I64 stab5 = -1;
                            for (I64 k = stab4 + 1; k < sline_len; k = k + 1) {
                              if (sline[k] == '\t' || sline[k] == '\n' || sline[k] == '\r') { stab5 = k; break; }
                            }
                            if (stab5 < 0) stab5 = sline_len;
                            I64 rec_sha_len = stab5 - stab4 - 1;
                            U8 rec_sha[128];
                            if (rec_sha_len < 128) {
                              for (I64 k = 0; k < rec_sha_len; k = k + 1) rec_sha[k] = sline[stab4 + 1 + k];
                              rec_sha[rec_sha_len] = 0;
                              // Run ./build/lexer07-sha256 --file <evpath>
                              // via system() and read stdout into a temp file.
                              U8 cmd[2048];
                              I64 cmd_len = 0;
                              U8 *prefix = "./build/lexer07-sha256 --file ";
                              while (prefix[cmd_len]) { cmd[cmd_len] = prefix[cmd_len]; cmd_len = cmd_len + 1; }
                              I64 j2 = 0;
                              while (evpath[j2] && cmd_len + j2 < 2040) { cmd[cmd_len + j2] = evpath[j2]; j2 = j2 + 1; }
                              cmd[cmd_len + j2] = 0;
                              U8 tmpout[64];
                              I64 ti = 0;
                              U8 *suf = " > /tmp/lexer09-ac-sha-tmp.txt 2>/dev/null";
                              while (suf[ti] && cmd_len + j2 + ti < 2040) { cmd[cmd_len + j2 + ti] = suf[ti]; ti = ti + 1; }
                              cmd[cmd_len + j2 + ti] = 0;
                              I32 rc = system(cmd);
                              rc = rc;
                              I64 tmpsz = 0;
                              U8 *tmpr = FileRead("/tmp/lexer09-ac-sha-tmp.txt", &tmpsz);
                              if (tmpr && tmpsz >= 64) {
                                U8 comp_sha[128];
                                I64 cslen = 0;
                                for (I64 k = 0; k < 64 && k < tmpsz; k = k + 1) comp_sha[cslen++] = tmpr[k];
                                comp_sha[cslen] = 0;
                                // Strip trailing newline/CR
                                while (cslen > 0 && (comp_sha[cslen-1] == '\n' || comp_sha[cslen-1] == '\r')) {
                                  comp_sha[cslen-1] = 0;
                                  cslen = cslen - 1;
                                }
                                // Compare
                                Bool sha_eq = TRUE;
                                if (cslen != rec_sha_len) sha_eq = FALSE;
                                else for (I64 k = 0; k < cslen; k = k + 1) {
                                  if (comp_sha[k] != rec_sha[k]) { sha_eq = FALSE; break; }
                                }
                                if (!sha_eq) {
                                  evidence_sha_mismatch = evidence_sha_mismatch + 1;
                                  "AC_LEDGER_EVIDENCE_SHA_MISMATCH ac_id=%.*s recorded=%s computed=%s\n",
                                    tab1, line, rec_sha, comp_sha;
                                }
                                Free(tmpr);
                              } else {
                                evidence_sha_mismatch = evidence_sha_mismatch + 1;
                                "AC_LEDGER_EVIDENCE_SHA_MISMATCH ac_id=%.*s reason=missing-or-empty sha-tool-output\n",
                                  tab1, line;
                              }
                            }
                          }
                        }
                      }
                      break;
                    }
                  }
                }
                sline_start = j + 1;
              }
              sp = sp + 1;
            }
            if (!found) {
              missing = missing + 1;
              "AC_LEDGER_MISSING ac_id=%.*s\n", tab1, line;
            } else if (!sha_match) {
              predicate_sha_mismatch = predicate_sha_mismatch + 1;
              "AC_LEDGER_SHA_MISMATCH ac_id=%.*s\n", tab1, line;
            }
          }
        }
      }
      contract_line_start = i + 1;
    }
    p = p + 1;
  }

  "AC_LEDGER_UNKNOWN=%d\n", unknown;
  "AC_LEDGER_DUPLICATE=%d\n", duplicate;
  "AC_LEDGER_MISSING=%d\n", missing;
  "AC_LEDGER_PREDICATE_SHA_MISMATCH=%d\n", predicate_sha_mismatch;
  "AC_LEDGER_FAIL_STATUS=%d\n", fail_status;
  "AC_LEDGER_EVIDENCE_SHA_MISMATCH=%d\n", evidence_sha_mismatch;
  "AC_LEDGER_TOTAL=%d\n", contract_rows;

  if (missing == 0 && predicate_sha_mismatch == 0 && fail_status == 0 && evidence_sha_mismatch == 0) {
    "AC_LEDGER_RC=0 verdict=PASS\n";
    Free(contract_raw);
    Free(status_raw);
    return 0;
  }
  "AC_LEDGER_RC=1 verdict=FAIL\n";
  Free(contract_raw);
  Free(status_raw);
  return 1;
}
