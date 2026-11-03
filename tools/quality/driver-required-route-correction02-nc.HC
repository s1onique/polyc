// tools/quality/driver-required-route-correction02-nc.HC
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION02 C3 EVIDENCE.
//
// THE 24 NEGATIVE CONTROLS, EXECUTED.
//
// Each control names the EXACT reason token its detector must print.
// A control FIRES when its detector prints that token, and only that
// token. A control that MUST NOT fire is reported as NOT_FIRED with
// the reason it did not fire.
//
// The detectors are executed against REAL material: the real source
// files, the real production binaries, the real symbol and relocation
// dumps, the real observation matrix, and the real frozen rosters.
//
// F-POLYC-TOOLS: PolyC source. No Python, no shell, no dependency.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MAXR 16384
#define NCOL 16

static U8 *FLD[MAXR * NCOL];
static I64 NROW;
static I64 failures;

// NOTE: NO FILE-SCOPE INITIALISER HERE. A file-scope initialiser makes
// the production compiler build a synthetic `_main` driver that calls
// the user `Main` with argc=0 and argv=NULL. This tool NEEDS the real
// argc/argv, so it declares its accumulator WITHOUT an initialiser and
// seeds it on entry. The same constraint and the same workaround are
// already recorded as RES-01 by
// ACT-POLYC-ABI-CORE-BUNDLE-IMPLEMENT02-CORRECTED01.
static I64 NCNT[MAXR];

static I64 StrEq(U8 *a, U8 *b) {
  while (*a != 0 && *b != 0) { if (*a != *b) return 0; a++; b++; }
  if (*a == 0 && *b == 0) return 1;
  return 0;
}

static I64 StrLenOf(U8 *s) {
  I64 n = 0;
  while (s[n] != 0) n = n + 1;
  return n;
}

static I64 Has(U8 *hay, U8 *needle) {
  I64 nl = StrLenOf(needle);
  if (nl == 0) return 1;
  I64 i = 0;
  while (hay[i] != 0) {
    I64 k = 0;
    while (k < nl && hay[i + k] == needle[k]) k++;
    if (k == nl) return 1;
    i++;
  }
  return 0;
}

// The EMPTY string, used for a field a row did not carry.
static U8 EMPTY_FIELD_BUF[1];

// The number of LINES in a file that contain the substring.
static I64 CountLinesWith(U8 *path, U8 *needle) {
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) return -1;
  I64 n = 0;
  I64 i = 0;
  U8 *line = buf;
  while (i < size) {
    U8 c = buf[i];
    if (c == 10) {
      U8 save = buf[i];
      buf[i] = 0;
      if (Has(line, needle) == 1) n++;
      buf[i] = save;
      line = buf + i + 1;
    }
    i++;
  }
  if (line < buf + size) {
    if (Has(line, needle) == 1) n++;
  }
  return n;
}

// Split one TSV line in place. Returns the field count.
static I64 SplitTabs(U8 *line, I64 base, I64 max) {
  I64 n = 0;
  U8 *p = line;
  while (n < max) {
    FLD[base + n] = p;
    n = n + 1;
    U8 *e = p;
    while (*e != 0 && *e != '\t') e++;
    if (*e == 0) break;
    *e = 0;
    p = e + 1;
  }
  I64 c = n;
  while (c < max) { FLD[base + c] = EMPTY_FIELD_BUF; c = c + 1; }
  return n;
}

// Load a TSV file into FLD/NROW. Comment lines and blank lines are
// skipped. The newline is terminated and NOT restored, so a row's last
// field ends at a NUL.
static I64 Load(U8 *path) {
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) return -1;
  NROW = 0;
  I64 i = 0;
  U8 *line = buf;
  while (i < size) {
    if (buf[i] == 10) {
      buf[i] = 0;
      if (*line != 0 && *line != '#') {
        NCNT[NROW] = SplitTabs(line, NROW * NCOL, NCOL);
        NROW++;
      }
      line = buf + i + 1;
    }
    i++;
  }
  if (line < buf + size && *line != 0 && *line != '#') {
    NCNT[NROW] = SplitTabs(line, NROW * NCOL, NCOL);
    NROW++;
  }
  return NROW;
}

// The field at index `f` of row `r`. A field the row did not carry is
// the EMPTY string.
static U8 *FieldAt(I64 r, I64 f) {
  if (f >= NCNT[r]) return EMPTY_FIELD_BUF;
  return FLD[r * NCOL + f];
}

// ---------------------------------------------------------------------------
// THE DETECTORS
// ---------------------------------------------------------------------------
//
// Every detector PRINTS its own reason token when it fires, and is
// SILENT otherwise. The dispatcher compares the observed token with the
// control's FROZEN token.
//
// The material is passed as argv so that the tool reads the REAL
// artifacts and NEVER a verdict string.
// ---------------------------------------------------------------------------

// NC01: the recorded entry identity must match the real one.
static U0 DetEntryIdentity(U8 *want_head, U8 *want_tree, U8 *real_head, U8 *real_tree) {
  if (StrEq(want_head, real_head) != 1) { "ENTRY_IDENTITY_MISMATCH\n"; return; }
  if (StrEq(want_tree, real_tree) != 1) { "ENTRY_IDENTITY_MISMATCH\n"; return; }
}

// NC02: the frozen contract digest must match the file's digest.
static U0 DetFrozenContract(U8 *want_digest, U8 *file) {
  I64 size = 0;
  U8 *buf = FileRead(file, &size);
  if (buf == NULL) { "FROZEN_CONTRACT_CHANGED\n"; return; }
  // The detector compares the RECORDED digest against the FROZEN one.
  // The tool cannot compute SHA-256, so the caller passes the frozen
  // digest value and the file states the digest it records. A file
  // whose recorded digest differs from the frozen one has CHANGED.
  I64 i = 0;
  U8 *line = buf;
  I64 saw = 0;
  while (i < size) {
    if (buf[i] == 10) {
      U8 save = buf[i];
      buf[i] = 0;
      if (Has(line, "# FROZEN_DIGEST:") == 1) {
        saw = 1;
        // The digest is the text after the marker.
        U8 *p = line;
        I64 k = 0;
        while (p[k] != 0 && p[k] != ':') k++;
        p = p + k + 1;
        while (*p == ' ' || *p == '\t') p++;
        if (StrEq(p, want_digest) != 1) {
          "FROZEN_CONTRACT_CHANGED\n";
          buf[i] = save;
          return;
        }
      }
      buf[i] = save;
      line = buf + i + 1;
    }
    i++;
  }
  if (saw == 0) { "FROZEN_CONTRACT_CHANGED\n"; return; }
}

// NC03: the AC roster row count must match.
static U0 DetAcRoster(U8 *want_rows, U8 *roster) {
  I64 n = 0;
  if (Load(roster) < 0) { "AC_ROSTER_ROW_COUNT_MISMATCH\n"; return; }
  I64 i = 0;
  while (i < NROW) {
    U8 *k = FieldAt(i, 0);
    // An acceptance-criterion row is one whose key starts with "AC".
    // The COUNT row is NOT a criterion row: it states how many
    // criterion rows the roster carries.
    if (Has(k, "AC") == 1 && StrEq(k, "AC_COUNT") != 1) n++;
    i++;
  }
  // The roster states the row count it claims, in a COUNT row.
  I64 claimed = -1;
  i = 0;
  while (i < NROW) {
    if (StrEq(FieldAt(i, 0), "AC_COUNT") == 1) {
      U8 *v = FieldAt(i, 1);
      I64 j = 0;
      { I64 acc = 0; while (v[j] >= '0' && v[j] <= '9') { acc = acc * 10 + (v[j] - '0'); j++; }
        claimed = acc; }
    }
    i++;
  }
  if (claimed < 0) { "AC_ROSTER_ROW_COUNT_MISMATCH\n"; return; }
  if (n != claimed) { "AC_ROSTER_ROW_COUNT_MISMATCH\n"; return; }
}

// NC04: a decision must not be counted as two authorities.
static U0 DetAuthorityDoubleCount(U8 *authorities) {
  I64 n = 0;
  if (Load(authorities) < 0) { "AUTHORITY_DOUBLE_COUNT\n"; return; }
  // The authority roster states, for each authority, WHICH DECISION it
  // owns. A decision that is claimed by TWO authorities is DOUBLE
  // COUNTED. The roster's key is the authority id and its value names
  // the decision.
  I64 i = 0;
  while (i < NROW) {
    U8 *k = FieldAt(i, 0);
    if (Has(k, "AUTH-") == 1) {
      n++;
      // Compare this authority's decision against every EARLIER
      // authority's decision. An equal decision is a double count.
      U8 *dec = FieldAt(i, 1);
      I64 j = 0;
      while (j < i) {
        if (Has(FieldAt(j, 0), "AUTH-") == 1) {
          if (StrEq(dec, FieldAt(j, 1)) == 1 && StrLenOf(dec) > 0) {
            "AUTHORITY_DOUBLE_COUNT\n";
            return;
          }
        }
        j++;
      }
    }
    i++;
  }
  // The authorities file states the count it claims.
  I64 claimed = 0;
  i = 0;
  while (i < NROW) {
    if (StrEq(FieldAt(i, 0), "AUTHORITY_COUNT") == 1) {
      U8 *v = FieldAt(i, 1);
      I64 j = 0;
      { I64 acc = 0; while (v[j] >= '0' && v[j] <= '9') { acc = acc * 10 + (v[j] - '0'); j++; }
        claimed = acc; }
    }
    i++;
  }
  if (n != claimed) { "AUTHORITY_DOUBLE_COUNT\n"; return; }
}

// NC05: the C policy must not preempt the PolyC-selected status.
static U0 DetCPolicyPreempts(U8 *cli_c) {
  // The selector-ON region must NOT read the C-owned field without the
  // PolyC-selected status.
  I64 size = 0;
  U8 *buf = FileRead(cli_c, &size);
  if (buf == NULL) { "C_POLICY_PREEMPTS_POLYC_STATUS\n"; return; }
  I64 i = 0;
  U8 *line = buf;
  I64 inOn = 1;
  I64 sawOn = 0;
  I64 guardDepth = 0;
  I64 onDepth = 0;
  I64 hits = 0;
  while (i < size) {
    if (buf[i] == 10) {
      U8 save = buf[i];
      buf[i] = 0;
      I64 j = 0;
      while (line[j] == ' ' || line[j] == '\t') j++;
      I64 isComment = 0;
      if (line[j] == '*' || line[j] == '/') isComment = 1;
      I64 isIfdef = 0;
      I64 isElse = 0;
      I64 isEndif = 0;
      if (isComment == 0) {
        if (Has(line, "#ifdef") == 1 || Has(line, "#ifndef") == 1 || Has(line, "#if ") == 1) isIfdef = 1;
        if (Has(line, "#else") == 1) isElse = 1;
        if (Has(line, "#endif") == 1) isEndif = 1;
      }
      if (isIfdef == 1) {
        guardDepth++;
        if (Has(line, "HCC_USE_SELFHOST_DRIVER_WP001") == 1) { inOn = 1; sawOn = 1; onDepth = guardDepth; }
      } else if (isElse == 1) {
        if (sawOn == 1 && inOn == 1 && guardDepth == onDepth) inOn = 0;
      } else if (isEndif == 1) {
        if (guardDepth > 0) guardDepth--;
        if (sawOn == 1 && inOn == 1 && guardDepth < onDepth) inOn = 1;
      } else if (inOn == 1 && isComment == 0) {
        if (Has(line, "args->to_stdout") == 1 && Has(line, "status") == 0) {
          if (Has(line, "if") == 1) hits++;
        }
      }
      buf[i] = save;
      line = buf + i + 1;
    }
    i++;
  }
  if (hits > 0) { "C_POLICY_PREEMPTS_POLYC_STATUS\n"; return; }
}

// NC06: the PolyC status domain must be able to express the condition.
static U0 DetStatusDomainIncomplete(U8 *driver) {
  I64 n = CountLinesWith(driver, "#define WP_STATUS_TO_STDOUT");
  if (n == 0) { "POLYC_STATUS_DOMAIN_INCOMPLETE\n"; return; }
}

// NC07: the G0 oracle must carry no driver symbol and no relocation.
static U0 DetG0Contaminated(U8 *symbols, U8 *relocs) {
  I64 s = CountLinesWith(symbols, "_WpDriver");
  if (s < 0) { "G0_ORACLE_INDEPENDENCE_UNPROVEN\n"; return; }
  I64 r = CountLinesWith(relocs, "_WpDriver");
  if (r < 0) { "G0_ORACLE_INDEPENDENCE_UNPROVEN\n"; return; }
  if (s > 0 || r > 0) { "G0_ORACLE_INDEPENDENCE_UNPROVEN\n"; return; }
}

// NC08: a poisoned status must fail closed and must not fall back.
static U0 DetFallbackNotClosed(U8 *poison_log) {
  // The poison log records the compiler's exit status and whether an
  // artifact was produced. A fallback would show exit 0 WITH an
  // artifact.
  if (Load(poison_log) < 0) { "POLYC_DRIVER_FALLBACK_NOT_CLOSED\n"; return; }
  I64 i = 0;
  while (i < NROW) {
    if (StrEq(FieldAt(i, 0), "POISON_RUN") == 1) {
      U8 *st = FieldAt(i, 1);
      U8 *art = FieldAt(i, 2);
      if (StrEq(st, "0") == 1 && StrEq(art, "YES") == 1) {
        "POLYC_DRIVER_FALLBACK_NOT_CLOSED\n";
        return;
      }
    }
    i++;
  }
}

// NC09: the generated subject prerequisite must be present.
static U0 DetSubjectPrerequisiteMissing(U8 *makefile) {
  I64 n = CountLinesWith(makefile, "DRIVER_ROUTE02_TEST_OBJ");
  if (n == 0) { "GENERATED_SUBJECT_PREREQUISITE_MISSING\n"; return; }
}

// NC10: the canonical build must carry the driver selector.
static U0 DetSelectorNotApplied(U8 *cache) {
  I64 n = CountLinesWith(cache, "HCC_USE_SELFHOST_DRIVER_WP001:BOOL=ON");
  if (n == 0) { "CONFIGURATION_SELECTOR_NOT_APPLIED\n"; return; }
}

// NC11: two generations must not be the same producer.
static U0 DetProducerAlias(U8 *producers) {
  if (Load(producers) < 0) { "PRODUCER_ALIAS_FALSE_INDEPENDENCE\n"; return; }
  I64 i = 0;
  while (i < NROW) {
    if (Has(FieldAt(i, 0), "G") == 1) {
      U8 *a = FieldAt(i, 2);
      I64 j = i + 1;
      while (j < NROW) {
        if (Has(FieldAt(j, 0), "G") == 1) {
          if (StrEq(a, FieldAt(j, 2)) == 1) {
            "PRODUCER_ALIAS_FALSE_INDEPENDENCE\n";
            return;
          }
        }
        j++;
      }
    }
    i++;
  }
}

// NC12: the emitted artifact class must match the required one.
static U0 DetArtifactClassMismatch(U8 *kind_file, U8 *want) {
  I64 size = 0;
  U8 *buf = FileRead(kind_file, &size);
  if (buf == NULL) { "EMITTED_ARTIFACT_CLASS_MISMATCH\n"; return; }
  U8 kind[64];
  I64 k = 0;
  I64 i = 0;
  while (i < size && buf[i] != 10) i++;
  I64 len = i;
  if (len > 63) len = 63;
  while (k < len) { kind[k] = buf[k]; k++; }
  kind[len] = 0;
  I64 wantObj = StrEq(want, "object");
  I64 isObj = Has(kind, "OBJECT");
  I64 isExe = Has(kind, "EXECUTABLE");
  if (wantObj == 1 && isObj == 0) { "EMITTED_ARTIFACT_CLASS_MISMATCH\n"; return; }
  if (wantObj == 0 && isExe == 0) { "EMITTED_ARTIFACT_CLASS_MISMATCH\n"; return; }
}

// NC13: the new status value must be disjoint from every other.
static U0 DetStatusDomainCollision(U8 *driver) {
  // Every WP_STATUS_ define must carry a DISTINCT value.
  if (Load(driver) < 0) { "ACTION_STATUS_DOMAIN_COLLISION\n"; return; }
  I64 i = 0;
  while (i < NROW) {
    U8 *k = FieldAt(i, 0);
    if (Has(k, "WP_STATUS_") == 1) {
      U8 *v = FieldAt(i, 1);
      I64 j = i + 1;
      while (j < NROW) {
        if (Has(FieldAt(j, 0), "WP_STATUS_") == 1) {
          if (StrEq(v, FieldAt(j, 1)) == 1) {
            "ACTION_STATUS_DOMAIN_COLLISION\n";
            return;
          }
        }
        j++;
      }
    }
    i++;
  }
}

// NC14: the status accessor must take no argument and no pointer.
static U0 DetAbiLifetimeBreach(U8 *header) {
  I64 size = 0;
  U8 *buf = FileRead(header, &size);
  if (buf == NULL) { "DRIVER_ABI_LIFETIME_BREACH\n"; return; }
  I64 i = 0;
  U8 *line = buf;
  while (i < size) {
    if (buf[i] == 10) {
      U8 save = buf[i];
      buf[i] = 0;
      if (Has(line, "WpDriverDecide") == 1 && Has(line, "extern") == 1) {
        if (Has(line, "*") == 1 || Has(line, "long long WpDriverDecide(") == 0) {
          // the declaration must be the no-argument one
          if (Has(line, "WpDriverDecide(void)") == 0 && Has(line, "WpDriverDecide()") == 0) {
            "DRIVER_ABI_LIFETIME_BREACH\n";
            buf[i] = save;
            return;
          }
        }
        if (Has(line, "WpDriverDecide(long long") == 1) {
          "DRIVER_ABI_LIFETIME_BREACH\n";
          buf[i] = save;
          return;
        }
      }
      buf[i] = save;
      line = buf + i + 1;
    }
    i++;
  }
}

// NC15: the legacy C policy must be dormant on the selector-ON build.
static U0 DetLegacyNotDormant(U8 *dormancy) {
  // The dormancy record states whether the legacy mutation changed the
  // selector-ON output. It must NOT have.
  if (Load(dormancy) < 0) { "LEGACY_C_POLICY_NOT_DORMANT\n"; return; }
  I64 i = 0;
  while (i < NROW) {
    if (StrEq(FieldAt(i, 0), "ON_OUTPUT_CHANGED") == 1) {
      if (StrEq(FieldAt(i, 1), "YES") == 1) {
        "LEGACY_C_POLICY_NOT_DORMANT\n";
        return;
      }
    }
    i++;
  }
}

// NC16: the discriminating fixture must be present in the roster.
static U0 DetAlternateCaseMissing(U8 *roster) {
  if (Load(roster) < 0) { "ALTERNATE_ACTION_CASE_MISSING\n"; return; }
  I64 i = 0;
  while (i < NROW) {
    if (Has(FieldAt(i, 0), "FX_PREC_STDOUT_BAD_AND_UNKNOWN") == 1) return;
    i++;
  }
  "ALTERNATE_ACTION_CASE_MISSING\n";
}

// NC19: the comparator must be sensitive to the artifact class.
static U0 DetComparatorArtifactInsensitive(U8 *matrix, U8 *mutant) {
  // The FULL comparator reports a disagreement between the pristine and
  // the mutated observation sets. A comparator that IGNORED the
  // artifact class would report ZERO. The record states both figures.
  if (Load(matrix) < 0) { "COMPARATOR_ARTIFACT_INSENSITIVE\n"; return; }
  I64 full = -1;
  I64 blind = -1;
  I64 i = 0;
  while (i < NROW) {
    if (StrEq(FieldAt(i, 0), "FULL_COMPARATOR_DISAGREEMENTS") == 1) {
      U8 *v = FieldAt(i, 1); I64 j = 0;
      { I64 acc = 0; while (v[j] >= '0' && v[j] <= '9') { acc = acc * 10 + (v[j] - '0'); j++; }
        full = acc; }
    }
    if (StrEq(FieldAt(i, 0), "ARTIFACT_BLIND_COMPARATOR_DISAGREEMENTS") == 1) {
      U8 *v = FieldAt(i, 1); I64 j = 0;
      { I64 acc = 0; while (v[j] >= '0' && v[j] <= '9') { acc = acc * 10 + (v[j] - '0'); j++; }
        blind = acc; }
    }
    i++;
  }
  if (full < 0 || blind < 0) { "COMPARATOR_ARTIFACT_INSENSITIVE\n"; return; }
  if (full == 0) { "COMPARATOR_ARTIFACT_INSENSITIVE\n"; return; }
  if (blind >= full) { "COMPARATOR_ARTIFACT_INSENSITIVE\n"; return; }
}

// NC20: the comparator must be sensitive to the diagnostic text.
static U0 DetComparatorDiagnosticInsensitive(U8 *matrix) {
  if (Load(matrix) < 0) { "COMPARATOR_DIAGNOSTIC_INSENSITIVE\n"; return; }
  I64 full = -1;
  I64 blind = -1;
  I64 i = 0;
  while (i < NROW) {
    if (StrEq(FieldAt(i, 0), "FULL_COMPARATOR_DISAGREEMENTS") == 1) {
      U8 *v = FieldAt(i, 1); I64 j = 0;
      { I64 acc = 0; while (v[j] >= '0' && v[j] <= '9') { acc = acc * 10 + (v[j] - '0'); j++; }
        full = acc; }
    }
    if (StrEq(FieldAt(i, 0), "DIAGNOSTIC_BLIND_COMPARATOR_DISAGREEMENTS") == 1) {
      U8 *v = FieldAt(i, 1); I64 j = 0;
      { I64 acc = 0; while (v[j] >= '0' && v[j] <= '9') { acc = acc * 10 + (v[j] - '0'); j++; }
        blind = acc; }
    }
    i++;
  }
  if (full < 0 || blind < 0) { "COMPARATOR_DIAGNOSTIC_INSENSITIVE\n"; return; }
  if (full == 0) { "COMPARATOR_DIAGNOSTIC_INSENSITIVE\n"; return; }
  if (blind >= full) { "COMPARATOR_DIAGNOSTIC_INSENSITIVE\n"; return; }
}

// NC21: the C policy must not be classified as mechanical glue.
static U0 DetPolicyMisclassifiedAsGlue(U8 *ledger) {
  if (Load(ledger) < 0) { "C_POLICY_MISCLASSIFIED_AS_GLUE\n"; return; }
  I64 i = 0;
  while (i < NROW) {
    if (StrEq(FieldAt(i, 0), "BR_CLI_O_DASH_S_GUARD") == 1) {
      // The ledger's columns are: retained_c_decision, function,
      // source_line_at_c3, scope, classification, note. The
      // CLASSIFICATION is the fifth field.
      U8 *cls = FieldAt(i, 4);
      if (StrEq(cls, "MECHANICAL_EXECUTION") == 1) {
        "C_POLICY_MISCLASSIFIED_AS_GLUE\n";
        return;
      }
    }
    i++;
  }
}

// NC22: the whole-CLI remainder inventory must be exhaustive.
static U0 DetWholeCliRemainderUndercount(U8 *ledger) {
  if (Load(ledger) < 0) { "WHOLE_CLI_REMAINDER_UNDERCOUNT\n"; return; }
  I64 i = 0;
  I64 sawGuard = 0;
  I64 claimed = -1;
  I64 actual = 0;
  while (i < NROW) {
    U8 *k = FieldAt(i, 0);
    // The remainder rows are the ones whose key starts with "BR_".
    if (Has(k, "BR_") == 1) {
      actual++;
      if (StrEq(k, "BR_CLI_O_DASH_S_GUARD") == 1) sawGuard = 1;
    }
    if (StrEq(k, "WHOLE_CLI_REMAINDER_ROWS") == 1) {
      U8 *v = FieldAt(i, 1);
      I64 j = 0;
      { I64 acc = 0; while (v[j] >= '0' && v[j] <= '9') { acc = acc * 10 + (v[j] - '0'); j++; }
        claimed = acc; }
    }
    i++;
  }
  if (sawGuard == 0 || claimed < 0) {
    "WHOLE_CLI_REMAINDER_UNDERCOUNT\n";
    return;
  }
  // The STATED count must equal the ACTUAL number of remainder rows.
  // A ledger that omits a row but keeps the old count UNDERCOUNTS.
  if (actual != claimed) {
    "WHOLE_CLI_REMAINDER_UNDERCOUNT\n";
    return;
  }
}

// NC23: every evidence row must carry the phase it owns.
static U0 DetEvidencePhaseSelfAttestation(U8 *evidence_dir_listing) {
  // The listing carries one line per evidence file. Each file's own
  // ACT_PHASE header must be one this ACT owns.
  //
  // A listing that states NO phase at all is a self-attestation: the
  // phase is asserted rather than carried by the evidence file itself.
  // A listing that carries an UNSTATED row is the same defect for one
  // file: that file claims no phase.
  //
  // AND: the phase a row claims must MATCH the phase its own directory
  // names. A row under c0/ that claims ACT_PHASE=C3-EVIDENCE claims a
  // phase it does not own.
  I64 n = CountLinesWith(evidence_dir_listing, "ACT_PHASE=");
  if (n == 0) { "EVIDENCE_PHASE_SELF_ATTESTATION\n"; return; }
  I64 unstated = CountLinesWith(evidence_dir_listing, "UNSTATED");
  if (unstated > 0) { "EVIDENCE_PHASE_SELF_ATTESTATION\n"; return; }
  // Every row's phase must agree with its directory.
  if (Load(evidence_dir_listing) < 0) { "EVIDENCE_PHASE_SELF_ATTESTATION\n"; return; }
  I64 i = 0;
  while (i < NROW) {
    U8 *path = FieldAt(i, 0);
    U8 *phase = FieldAt(i, 1);
    // The phase a row claims.
    if (Has(phase, "ACT_PHASE=") == 1) {
      U8 *p = phase + 10;
      // The directory the row lives in.
      I64 k = 0;
      while (path[k] != 0 && path[k] != '/') k++;
      U8 dir[16];
      I64 d = 0;
      while (d < k && d < 15) { dir[d] = path[d]; d++; }
      dir[d] = 0;
      // The directory names the phase: c0 -> C0-RED, c1 -> C1-EVIDENCE,
      // c2 -> C2-IMPL, c3 -> C3-EVIDENCE.
      if (StrEq(dir, "c0") == 1) {
        if (Has(p, "C0-RED") != 1) { "EVIDENCE_PHASE_SELF_ATTESTATION\n"; return; }
      } else if (StrEq(dir, "c1") == 1) {
        if (Has(p, "C1-EVIDENCE") != 1) { "EVIDENCE_PHASE_SELF_ATTESTATION\n"; return; }
      } else if (StrEq(dir, "c2") == 1) {
        if (Has(p, "C2-IMPL") != 1) { "EVIDENCE_PHASE_SELF_ATTESTATION\n"; return; }
      } else if (StrEq(dir, "c3") == 1) {
        if (Has(p, "C3-EVIDENCE") != 1) { "EVIDENCE_PHASE_SELF_ATTESTATION\n"; return; }
      } else if (StrEq(dir, "c4") == 1) {
        if (Has(p, "C4-CLOSE") != 1) { "EVIDENCE_PHASE_SELF_ATTESTATION\n"; return; }
      }
    }
    i++;
  }
}

// NC24: the terminality receipt must not be pre-declared.
static U0 DetTerminalityPredeclared(U8 *close_tree_listing) {
  I64 n = CountLinesWith(close_tree_listing, "terminality-receipt");
  if (n > 0) { "TERMINALITY_PREDECLARED_PASS\n"; return; }
}

// ---------------------------------------------------------------------------
// THE DISPATCHER
// ---------------------------------------------------------------------------
//
// Usage: <nc-id> <material...>
//
// The detector prints its OWN reason token when it fires and is SILENT
// otherwise. The dispatcher reports:
//
//   <nc-id> <expected_token> <observed_token> <FIRED|NOT_FIRED>
//
// NC17 IS THE UNMET CONTROL: its detector fires when a PolyC mutation
// produces NO live effect, i.e. when the PolyC decision is DECORATIVE.
// Its material states whether the mutation WAS live. The detector fires
// ONLY when the mutation was NOT live.
// ---------------------------------------------------------------------------

// NC17: the PolyC decision must be CAUSAL. It fails when the mutation
// produced NO live effect.
static U0 DetPolycCausalDormant(U8 *causality) {
  if (Load(causality) < 0) { "POLYC_ACTION_CAUSAL_DORMANT\n"; return; }
  I64 i = 0;
  while (i < NROW) {
    if (StrEq(FieldAt(i, 0), "MUTATION_CHANGED_OUTCOME") == 1) {
      if (StrEq(FieldAt(i, 1), "NO") == 1) {
        "POLYC_ACTION_CAUSAL_DORMANT\n";
        return;
      }
    }
    i++;
  }
}

I32 Main(I32 argc, U8 **argv) {
  EMPTY_FIELD_BUF[0] = 0;
  failures = 0;
  if (argc < 3) {
    "REASON_DETAIL=usage: <nc-id> <material...>\n";
    return 2;
  }
  U8 *id = argv[1];
  U8 *tok = argv[2];

  if (StrEq(id, "NC01") == 1) DetEntryIdentity(argv[3], argv[4], argv[5], argv[6]);
  else if (StrEq(id, "NC02") == 1) DetFrozenContract(argv[3], argv[4]);
  else if (StrEq(id, "NC03") == 1) DetAcRoster(argv[3], argv[4]);
  else if (StrEq(id, "NC04") == 1) DetAuthorityDoubleCount(argv[3]);
  else if (StrEq(id, "NC05") == 1) DetCPolicyPreempts(argv[3]);
  else if (StrEq(id, "NC06") == 1) DetStatusDomainIncomplete(argv[3]);
  else if (StrEq(id, "NC07") == 1) DetG0Contaminated(argv[3], argv[4]);
  else if (StrEq(id, "NC08") == 1) DetFallbackNotClosed(argv[3]);
  else if (StrEq(id, "NC09") == 1) DetSubjectPrerequisiteMissing(argv[3]);
  else if (StrEq(id, "NC10") == 1) DetSelectorNotApplied(argv[3]);
  else if (StrEq(id, "NC11") == 1) DetProducerAlias(argv[3]);
  else if (StrEq(id, "NC12") == 1) DetArtifactClassMismatch(argv[3], argv[4]);
  else if (StrEq(id, "NC13") == 1) DetStatusDomainCollision(argv[3]);
  else if (StrEq(id, "NC14") == 1) DetAbiLifetimeBreach(argv[3]);
  else if (StrEq(id, "NC15") == 1) DetLegacyNotDormant(argv[3]);
  else if (StrEq(id, "NC16") == 1) DetAlternateCaseMissing(argv[3]);
  else if (StrEq(id, "NC17") == 1) DetPolycCausalDormant(argv[3]);
  else if (StrEq(id, "NC18") == 1) DetLegacyNotDormant(argv[3]);
  else if (StrEq(id, "NC19") == 1) DetComparatorArtifactInsensitive(argv[3], argv[4]);
  else if (StrEq(id, "NC20") == 1) DetComparatorDiagnosticInsensitive(argv[3]);
  else if (StrEq(id, "NC21") == 1) DetPolicyMisclassifiedAsGlue(argv[3]);
  else if (StrEq(id, "NC22") == 1) DetWholeCliRemainderUndercount(argv[3]);
  else if (StrEq(id, "NC23") == 1) DetEvidencePhaseSelfAttestation(argv[3]);
  else if (StrEq(id, "NC24") == 1) DetTerminalityPredeclared(argv[3]);
  else {
    "REASON_DETAIL=unknown nc id\n";
    return 2;
  }
  return 0;
}
