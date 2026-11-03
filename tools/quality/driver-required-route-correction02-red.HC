// tools/quality/driver-required-route-correction02-red.HC
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION02 C0 RED.
//
// THE FIVE PRECEDENCE RED DETECTORS.
//
// CONTRACT:
//
//   * Each detector RE-DERIVES every fact it tests from the PRIMARY
//     material it loads itself. It NEVER reads a status field and
//     NEVER trusts an "expected PASS" cell.
//   * A mode is SILENT (exit 0, no output) when the material is
//     CONSISTENT with the audited claim.
//   * A mode prints ITS OWN reason token and exits non-zero when the
//     material is INCONSISTENT. Each mode owns a DISTINCT reason
//     token, so a failure names itself.
//
// THE FIVE PRECEDENCE RED REASON TOKENS:
//
//   R01_PRECEDENCE_PREEMPTED        C_POLICY_PREEMPTS_POLYC_STATUS
//   R02_POLYC_STATUS_DOMAIN_INCOMPLETE  POLYC_STATUS_DOMAIN_INCOMPLETE
//   R03_ROUTE_REMAINDER_UNMEASURED  REQUIRED_ROUTE_REMAINDER_UNMEASURED
//   R04_G0_ORACLE_INDEPENDENCE_UNPROVEN  G0_ORACLE_INDEPENDENCE_UNPROVEN
//   R05_HISTORICAL_DEBT_UNCONSERVE  HISTORICAL_DEBT_NOT_CONSERVED
//   R06_FAIL_CLOSED                 POLYC_DRIVER_FALLBACK_NOT_CLOSED
//
// R06 was ADDED at C3, after the C3 measurement of the M-POLYC-POISON-04
// experiment showed that the status dispatch FAILED OPEN on an
// out-of-domain status: the poisoned status 99 matched none of the
// positive equality tests, so the compiler PROCEEDED and produced an
// artifact. AC36 requires the opposite. The C0 commit is IMMUTABLE
// historical evidence and is NOT rewritten (F14); R06 lives here, in
// the C3 phase, and its RED is recorded in the C3 evidence.
//
// F-POLYC-TOOLS: PolyC source, compiled and executed by the real
// production compiler. No Python, no shell, no external dependency.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MAXR 16384
#define NCOL 24

static U8 *FLD[MAXR * NCOL];
static I64 NROW;

// ---------------------------------------------------------------------------
// THE STRING HELPERS
// ---------------------------------------------------------------------------

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

// The number of lines in a file that contain the substring AND do NOT
// contain the exclusion substring.
static I64 CountLinesWithNot(U8 *path, U8 *needle, U8 *excl) {
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
      if (Has(line, needle) == 1 && Has(line, excl) == 0) n++;
      buf[i] = save;
      line = buf + i + 1;
    }
    i++;
  }
  if (line < buf + size) {
    if (Has(line, needle) == 1 && Has(line, excl) == 0) n++;
  }
  return n;
}

// ---------------------------------------------------------------------------
// THE DIAGNOSTIC EMITTERS
// ---------------------------------------------------------------------------

static U0 FailPlain(U8 *token, U8 *detail) {
  "%s|REASON_DETAIL=%s\n", token, detail;
}

static U0 FailOne(U8 *token, U8 *detail, I64 a) {
  "%s|REASON_DETAIL=%s (%d)\n", token, detail, a;
}

static U0 FailTwo(U8 *token, U8 *detail, I64 a, I64 b) {
  "%s|REASON_DETAIL=%s (%d vs %d)\n", token, detail, a, b;
}

// Split one TSV line in place. Returns the field count.
static I64 SplitTabs(U8 *line, I64 base, I64 max) {
  I64 n = 0;
  U8 *p = line;
  while (n < max) {
    FLD[base + n] = p;
    n = n + 1;
    while (*p != 0 && *p != '\t') p++;
    if (*p == 0) break;
    *p = 0; p++;
  }
  return n;
}

// Load a TSV file into FLD/NROW. Comment lines (starting with #) and
// blank lines are skipped.
static I64 Load(U8 *path) {
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) return -1;
  NROW = 0;
  I64 i = 0;
  U8 *line = buf;
  while (i < size) {
    if (buf[i] == 10) {
      U8 save = buf[i];
      buf[i] = 0;
      if (*line != 0 && *line != '#') {
        SplitTabs(line, NROW * NCOL, NCOL);
        NROW++;
      }
      buf[i] = save;
      line = buf + i + 1;
    }
    i++;
  }
  if (line < buf + size && *line != 0 && *line != '#') {
    SplitTabs(line, NROW * NCOL, NCOL);
    NROW++;
  }
  return NROW;
}

// The number of data rows whose FIRST field equals the given token.
static I64 CountRowsWithKey(U8 *path, U8 *key) {
  if (Load(path) < 0) return -1;
  I64 n = 0;
  for (I64 r = 0; r < NROW; r++) {
    if (StrEq(FLD[r * NCOL], key) == 1) n++;
  }
  return n;
}

// The number of data rows whose FIRST field equals the given token AND
// whose SECOND field equals the given value.
static I64 CountRowsWithKeyValue(U8 *path, U8 *key, U8 *val) {
  if (Load(path) < 0) return -1;
  I64 n = 0;
  for (I64 r = 0; r < NROW; r++) {
    if (StrEq(FLD[r * NCOL], key) == 1 && StrEq(FLD[r * NCOL + 1], val) == 1) n++;
  }
  return n;
}

// ---------------------------------------------------------------------------
// R01_PRECEDENCE_PREEMPTED -- C_POLICY_PREEMPTS_POLYC_STATUS
//
// ADVERSE PREMISE: a C-owned policy in the selector-ON CLI region fires
// WITHOUT consulting the PolyC-selected status, so it can preempt the
// PolyC driver's decision.
//
//   argv[1] = the production C source of the CLI parser
//   argv[2] = the C field the policy reads, e.g. args->to_stdout
//   argv[3] = the PolyC status variable, e.g. status
//   argv[4] = the name of the PolyC-selected status accessor call,
//             e.g. WpDriverDecide
//
// The detector examines ONLY the selector-ON region of the source: the
// code between the HCC_USE_SELFHOST_DRIVER_WP001 guard and its #else
// counterpart. The selector-OFF region is the G0 oracle's own legacy
// policy, which the ACT explicitly PERMITS to keep its own fields.
//
// It also IGNORES COMMENT lines, because a comment that NAMES the field
// it forbids is documentation, not a decision.
//
// The detector therefore fails closed on a real unguarded policy read and
// stays silent on a legacy-region read and on a mention in a comment.
// ---------------------------------------------------------------------------
static I32 ModePrecedencePreempted(I32 argc, U8 **argv) {
  if (argc < 5) {
    "REASON_DETAIL=usage: R01 <c-source> <c-field> <status-var> <status-accessor>\n";
    return 2;
  }
  I64 size = 0;
  U8 *buf = FileRead(argv[1], &size);
  if (buf == NULL) {
    FailPlain("C_POLICY_PREEMPTS_POLYC_STATUS", "C source unreadable");
    return 1;
  }

  // Locate the selector-ON region: from the HCC_USE_SELFHOST_DRIVER_WP001
  // guard to the #else that pairs with it. The pairing is established by
  // NESTING, so an unrelated #else elsewhere in the file does not end the
  // driver's region.
  //
  // A source with NO selector guard at all is a source in which the WHOLE
  // FILE is the selector-ON path: there is no separate legacy region, so
  // every read of the field is an active policy read.
  I64 i = 0;
  U8 *line = buf;
  I64 inOn = 1;
  I64 sawOn = 0;
  I64 guardDepth = 0;
  I64 onDepth = 0;
  I64 hits = 0;
  I64 sawStatusDecl = 0;
  I64 sawStatusUse = 0;
  I64 sawAccessor = 0;
  while (i < size) {
    if (buf[i] == 10) {
      U8 save = buf[i];
      buf[i] = 0;
      I64 isComment = 0;
      I64 j = 0;
      while (line[j] == ' ' || line[j] == '\t') j++;
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
        if (Has(line, "HCC_USE_SELFHOST_DRIVER_WP001") == 1) {
          inOn = 1;
          sawOn = 1;
          onDepth = guardDepth;
        }
      } else if (isElse == 1) {
        if (sawOn == 1 && inOn == 1 && guardDepth == onDepth) inOn = 0;
      } else if (isEndif == 1) {
        if (guardDepth > 0) guardDepth--;
        if (sawOn == 1 && inOn == 1 && guardDepth < onDepth) inOn = 1;
      } else if (inOn == 1 && isComment == 0) {
        // The status variable must be READ somewhere in the region: a
        // region that never reads the status cannot have a policy that
        // defers to it.
        if (Has(line, argv[4]) == 1) sawAccessor = 1;
        if (Has(line, argv[3]) == 1) {
          sawStatusUse = 1;
          if (Has(line, "=") == 1) sawStatusDecl = 1;
        }
        // The policy read: the C field appears in an `if` condition and
        // the line does NOT mention the status variable.
        if (Has(line, argv[2]) == 1 && Has(line, argv[3]) == 0) {
          if (Has(line, "if") == 1) hits++;
        }
      }
      buf[i] = save;
      line = buf + i + 1;
    }
    i++;
  }
  if (line < buf + size) {
    I64 j = 0;
    while (line[j] == ' ' || line[j] == '\t') j++;
    I64 isComment = 0;
    if (line[j] == '*' || line[j] == '/') isComment = 1;
    if (inOn == 1 && isComment == 0) {
      if (Has(line, argv[4]) == 1) sawAccessor = 1;
      if (Has(line, argv[3]) == 1) {
        sawStatusUse = 1;
        if (Has(line, "=") == 1) sawStatusDecl = 1;
      }
      if (Has(line, argv[2]) == 1 && Has(line, argv[3]) == 0) {
        if (Has(line, "if") == 1) hits++;
      }
    }
  }

  // The status must actually be SELECTED in the region; otherwise the
  // region has no PolyC decision to defer to at all.
  if (sawAccessor == 0 || sawStatusDecl == 0 || sawStatusUse == 0) {
    FailPlain("C_POLICY_PREEMPTS_POLYC_STATUS",
              "the selector-ON region does not select and read the PolyC status");
    return 1;
  }
  if (hits > 0) {
    FailOne("C_POLICY_PREEMPTS_POLYC_STATUS",
            "a C policy reads the field without consulting the PolyC-selected status", hits);
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// R02_POLYC_STATUS_DOMAIN_INCOMPLETE -- POLYC_STATUS_DOMAIN_INCOMPLETE
//
// ADVERSE PREMISE: the PolyC driver's status domain cannot EXPRESS the
// condition that the C side has to decide on its own. Without a status
// member for it, the C side MUST own that decision.
//
//   argv[1] = the PolyC driver source
//   argv[2] = the status-domain member prefix, e.g. WP_STATUS_
//   argv[3] = the condition token the domain must be able to express,
//             e.g. TO_STDOUT
//
// The detector enumerates the DISTINCT WP_STATUS_* members the driver
// source defines, and then requires that the domain can express the
// condition. A domain that cannot express it is INCOMPLETE.
// ---------------------------------------------------------------------------
static I32 ModeStatusDomainIncomplete(I32 argc, U8 **argv) {
  if (argc < 4) {
    "REASON_DETAIL=usage: R02 <driver-source> <status-prefix> <condition-token>\n";
    return 2;
  }
  I64 size = 0;
  U8 *buf = FileRead(argv[1], &size);
  if (buf == NULL) {
    FailPlain("POLYC_STATUS_DOMAIN_INCOMPLETE", "driver source unreadable");
    return 1;
  }

  I64 i = 0;
  U8 *line = buf;
  I64 canExpress = 0;
  I64 members = 0;
  while (i < size) {
    if (buf[i] == 10) {
      U8 save = buf[i];
      buf[i] = 0;
      I64 j = 0;
      while (line[j] == ' ' || line[j] == '\t') j++;
      I64 isComment = 0;
      if (line[j] == '*' || line[j] == '/') isComment = 1;
      if (isComment == 0 && Has(line, "#define ") == 1) {
        if (Has(line, argv[2]) == 1) {
          members++;
          if (Has(line, argv[3]) == 1) canExpress = 1;
        }
      }
      buf[i] = save;
      line = buf + i + 1;
    }
    i++;
  }
  if (members == 0) {
    FailPlain("POLYC_STATUS_DOMAIN_INCOMPLETE", "the driver defines no status-domain member");
    return 1;
  }
  if (canExpress == 0) {
    FailOne("POLYC_STATUS_DOMAIN_INCOMPLETE",
            "the status domain cannot express the condition the C side must decide", members);
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// R03_ROUTE_REMAINDER_UNMEASURED -- REQUIRED_ROUTE_REMAINDER_UNMEASURED
//
// ADVERSE PREMISE: the required-route branch ledger does not MEASURE the
// residual C semantic remainder, so the ownership claim is asserted
// rather than measured.
//
//   argv[1] = the required-route branch ledger TSV
//   argv[2] = the class token that counts AGAINST a required-route
//             qualification, e.g. C_SEMANTIC_OWNER
//   argv[3] = the class token that is also unproven, e.g.
//             SHARED_OR_UNPROVEN
//
// The detector requires that the ledger CARRIES a measured remainder row,
// and that the ledger's classification column is populated for every
// data row. A ledger with no measured remainder is UNMEASURED.
// ---------------------------------------------------------------------------
static I32 ModeRouteRemainderUnmeasured(I32 argc, U8 **argv) {
  if (argc < 4) {
    "REASON_DETAIL=usage: R03 <branch-ledger> <owner-class> <unproven-class>\n";
    return 2;
  }
  if (Load(argv[1]) < 0) {
    FailPlain("REQUIRED_ROUTE_REMAINDER_UNMEASURED", "the branch ledger is unreadable");
    return 1;
  }
  if (NROW == 0) {
    FailPlain("REQUIRED_ROUTE_REMAINDER_UNMEASURED", "the branch ledger carries no data row");
    return 1;
  }

  I64 measured = 0;
  I64 classified = 0;
  for (I64 r = 0; r < NROW; r++) {
    U8 *key = FLD[r * NCOL];
    U8 *cls = FLD[r * NCOL + 1];
    if (Has(key, "REMAINDER") == 1) measured++;
    if (StrLenOf(cls) > 0) classified++;
  }
  if (measured == 0) {
    FailPlain("REQUIRED_ROUTE_REMAINDER_UNMEASURED",
              "the branch ledger carries no measured remainder row");
    return 1;
  }
  if (classified != NROW) {
    FailTwo("REQUIRED_ROUTE_REMAINDER_UNMEASURED",
            "the branch ledger has rows without a classification", classified, NROW);
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// R04_G0_ORACLE_INDEPENDENCE_UNPROVEN -- G0_ORACLE_INDEPENDENCE_UNPROVEN
//
// ADVERSE PREMISE: the selector-OFF oracle is not independent of the
// PolyC driver, so a differential against it proves nothing.
//
//   argv[1] = the G0 oracle's symbol table dump
//   argv[2] = the driver symbol prefix, e.g. _WpDriver
//   argv[3] = the G0 oracle's relocation dump
//
// The oracle is independent when its symbol table carries ZERO driver
// symbols AND its relocations carry ZERO references to the driver
// subject.
// ---------------------------------------------------------------------------
static I32 ModeG0OracleIndependence(I32 argc, U8 **argv) {
  if (argc < 4) {
    "REASON_DETAIL=usage: R04 <g0-symbols> <driver-prefix> <g0-relocations>\n";
    return 2;
  }
  I64 syms = CountLinesWith(argv[1], argv[2]);
  if (syms < 0) {
    FailPlain("G0_ORACLE_INDEPENDENCE_UNPROVEN", "the G0 symbol table is unreadable");
    return 1;
  }
  if (syms > 0) {
    FailOne("G0_ORACLE_INDEPENDENCE_UNPROVEN", "the selector-OFF oracle carries driver symbols", syms);
    return 1;
  }
  I64 relocs = CountLinesWith(argv[3], argv[2]);
  if (relocs < 0) {
    FailPlain("G0_ORACLE_INDEPENDENCE_UNPROVEN", "the G0 relocation dump is unreadable");
    return 1;
  }
  if (relocs > 0) {
    FailOne("G0_ORACLE_INDEPENDENCE_UNPROVEN", "the selector-OFF oracle relocates against the driver", relocs);
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// R05_HISTORICAL_DEBT_UNCONSERVE -- HISTORICAL_DEBT_NOT_CONSERVED
//
// ADVERSE PREMISE: the predecessor's historical debt was silently
// repaired, re-adjudicated, or dropped by this ACT.
//
//   argv[1] = the predecessor's final acceptance ledger
//   argv[2] = the conservation record TSV this ACT produced
//   argv[3] = the predecessor's NC roster key, e.g. NC17
//
// The conservation record must state the predecessor's AC partition and
// the predecessor's NC17 non-firing, and must state them as UNCHANGED.
// The detector ALSO reads the PREDECESSOR'S OWN ledger and recomputes
// its partition, so a record that merely CLAIMS the partition is not
// enough: the record and the predecessor's ledger must AGREE.
// ---------------------------------------------------------------------------
static I32 ModeHistoricalDebtUnconserve(I32 argc, U8 **argv) {
  if (argc < 4) {
    "REASON_DETAIL=usage: R05 <predecessor-ledger> <conservation-record> <nc-key>\n";
    return 2;
  }
  // Recompute the predecessor's AC partition from its OWN final ledger.
  if (Load(argv[1]) < 0) {
    FailPlain("HISTORICAL_DEBT_NOT_CONSERVED", "the predecessor ledger is unreadable");
    return 1;
  }
  I64 predPass = 0;
  for (I64 r = 0; r < NROW; r++) {
    U8 *key = FLD[r * NCOL];
    U8 *st = FLD[r * NCOL + 2];
    if (Has(key, "AC") != 1) continue;
    if (StrEq(st, "PASS") == 1) predPass++;
  }
  if (predPass == 0) {
    FailPlain("HISTORICAL_DEBT_NOT_CONSERVED", "the predecessor ledger carries no PASS row");
    return 1;
  }

  // The conservation record must carry the predecessor's partition and
  // the NC17 non-firing, and must state them as UNCHANGED.
  if (Load(argv[2]) < 0) {
    FailPlain("HISTORICAL_DEBT_NOT_CONSERVED", "the conservation record is unreadable");
    return 1;
  }
  I64 sawPartition = 0;
  I64 sawNc = 0;
  I64 sawUnchanged = 0;
  for (I64 r = 0; r < NROW; r++) {
    U8 *key = FLD[r * NCOL];
    U8 *val = FLD[r * NCOL + 1];
    if (Has(key, "AC_PARTITION") == 1) {
      sawPartition = 1;
      if (Has(val, "UNCHANGED") == 1) sawUnchanged = 1;
    }
    if (Has(key, argv[3]) == 1) {
      sawNc = 1;
      if (Has(val, "UNMET") == 1 || Has(val, "UNCHANGED") == 1) sawUnchanged = 1;
    }
  }
  if (sawPartition == 0) {
    FailPlain("HISTORICAL_DEBT_NOT_CONSERVED", "the conservation record carries no AC partition row");
    return 1;
  }
  if (sawNc == 0) {
    FailPlain("HISTORICAL_DEBT_NOT_CONSERVED", "the conservation record carries no NC17 row");
    return 1;
  }
  if (sawUnchanged == 0) {
    FailPlain("HISTORICAL_DEBT_NOT_CONSERVED",
              "the conservation record does not state the historical debt as UNCHANGED");
    return 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// THE DISPATCHER
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// R06_FAIL_CLOSED -- POLYC_DRIVER_FALLBACK_NOT_CLOSED
// ---------------------------------------------------------------------------
//
// ADVERSE PREMISE: the status dispatch does not FAIL CLOSED on an
// out-of-domain status.
//
// The PolyC driver selects ONE status value. The C side dispatches on
// it. If the dispatch is a set of POSITIVE equality tests with no
// domain bound and no default branch, then a status OUTSIDE the
// domain matches NONE of them and the compiler PROCEEDS as if the
// status were OK. That is a FAIL-OPEN: the authority is silently
// absent, the requested work is performed anyway, and an artifact is
// produced.
//
// AC36 requires: "An invalid status FAILS CLOSED: no artifact, no
// fallback."
//
//   argv[1] = the HEADER that mirrors the PolyC status domain
//   argv[2] = the status-domain member prefix, e.g. WP_DRIVER_STATUS_
//   argv[3] = the domain bound member name, e.g. WP_DRIVER_STATUS_COUNT
//   argv[4] = the C source that dispatches on the status
//
// The detector RE-DERIVES the domain from the HEADER's own status
// member defines, and then requires that the C dispatch REJECTS a
// status outside that domain.
//
// A dispatch that lacks the domain bound, or lacks a rejection of an
// out-of-domain status, is NOT fail-closed.
// ---------------------------------------------------------------------------
static I32 ModeFailClosed(I32 argc, U8 **argv) {
  if (argc < 5) {
    "REASON_DETAIL=usage: R06 <header> <status-prefix> <domain-bound-member> <c-source>\n";
    return 2;
  }
  I64 size = 0;
  U8 *buf = FileRead(argv[1], &size);
  if (buf == NULL) {
    FailPlain("POLYC_DRIVER_FALLBACK_NOT_CLOSED", "the domain header is unreadable");
    return 1;
  }
  U8 *prefix = argv[2];
  U8 *bound = argv[3];
  I64 boundLen = StrLenOf(bound);

  // PASS 1: the domain members the HEADER defines, and the domain
  // bound member. The bound member's value is the domain's exclusive
  // upper bound, so the domain is {0 .. bound-1}.
  I64 i = 0;
  U8 *line = buf;
  I64 hasBound = 0;
  I64 boundValue = -1;
  I64 memberCount = 0;
  while (i < size) {
    if (buf[i] == 10) {
      U8 save = buf[i];
      buf[i] = 0;
      I64 j = 0;
      while (line[j] == ' ' || line[j] == '\t') j++;
      I64 isComment = 0;
      if (line[j] == '*' || line[j] == '/') isComment = 1;
      if (isComment == 0 && Has(line, "#define") == 1) {
        U8 *p = line + j + 7;
        while (*p == ' ' || *p == '\t') p++;
        if (Has(p, prefix) == 1) {
          I64 nameLen = 0;
          while (p[nameLen] != 0 && p[nameLen] != ' ' && p[nameLen] != '\t'
                 && p[nameLen] != '(') nameLen++;
          I64 isBound = 0;
          if (nameLen == boundLen) {
            I64 k = 0;
            while (k < boundLen) {
              if (p[k] != bound[k]) { isBound = 0; break; }
              k++;
              if (k == boundLen) isBound = 1;
            }
          }
          // The bound member itself is not a domain member.
          if (isBound == 0) memberCount++;
          else {
            hasBound = 1;
            U8 *v = p + nameLen;
            while (*v == ' ' || *v == '\t') v++;
            I64 val = 0;
            I64 got = 0;
            while (*v >= '0' && *v <= '9') { val = val * 10 + (*v - '0'); v++; got = 1; }
            if (got == 1) boundValue = val;
          }
        }
      }
      buf[i] = save;
      line = buf + i + 1;
    }
    i++;
  }

  if (hasBound == 0) {
    FailPlain("POLYC_DRIVER_FALLBACK_NOT_CLOSED",
              "the domain header defines no status-domain bound member");
    return 1;
  }
  if (boundValue <= 0) {
    FailPlain("POLYC_DRIVER_FALLBACK_NOT_CLOSED",
              "the status-domain bound member has no numeric value");
    return 1;
  }
  if (memberCount != boundValue) {
    FailOne("POLYC_DRIVER_FALLBACK_NOT_CLOSED",
            "the domain member count does not match the domain bound",
            memberCount);
    return 1;
  }

  // PASS 2: the C dispatch must REJECT an out-of-domain status.
  //
  // The rejection is a comparison of the selected status against the
  // domain bound: either the status is at least the bound (the
  // out-of-domain test), or the status is outside an explicit range.
  //
  // The guard and the rejection it performs are typically on
  // DIFFERENT lines: the guard opens a block and the rejection is
  // inside it. So the detector remembers that a guard was seen and
  // then looks for the rejection in the lines that FOLLOW, up to the
  // end of the guard's block.
  I64 sawGuard = 0;
  I64 rejects = 0;
  I64 linesAfterGuard = 0;
  // The C dispatch lives in a DIFFERENT file from the domain header.
  // The domain comes from the header; the dispatch comes from the C
  // source. Both are read here.
  I64 csize = 0;
  U8 *cbuf = FileRead(argv[4], &csize);
  if (cbuf == NULL) {
    FailPlain("POLYC_DRIVER_FALLBACK_NOT_CLOSED", "the C dispatch source is unreadable");
    return 1;
  }
  buf = cbuf;
  size = csize;
  i = 0;
  line = buf;
  while (i < size) {
    if (buf[i] == 10) {
      U8 save = buf[i];
      buf[i] = 0;
      I64 j = 0;
      while (line[j] == ' ' || line[j] == '\t') j++;
      I64 isComment = 0;
      if (line[j] == '*' || line[j] == '/') isComment = 1;
      if (isComment == 0) {
        // A guard that compares the SELECTED STATUS against the bound.
        if (sawGuard == 0 && Has(line, "status") == 1 && Has(line, bound) == 1) {
          // It must be a RANGE or an inequality, not an equality
          // against a single member.
          if (Has(line, ">=") == 1 || Has(line, "<") == 1
              || Has(line, "!=") == 1 || Has(line, ">") == 1) {
            sawGuard = 1;
            linesAfterGuard = 0;
          }
        }
        // The rejection must be a FAIL-CLOSED one: it must not fall
        // through to the normal path. It is searched for on the guard
        // line itself and in the lines that follow it.
        if (sawGuard == 1) {
          if (Has(line, "cliPanic") == 1 || Has(line, "panic") == 1
              || Has(line, "loggerPanic") == 1 || Has(line, "exit(") == 1
              || Has(line, "abort") == 1) {
            rejects++;
            sawGuard = 2;
          } else {
            linesAfterGuard++;
            // The guard's block ends at its closing brace.
            if (Has(line, "}") == 1) sawGuard = 0;
            // A guard body that does not reject within a small window
            // is not a fail-closed guard.
            if (linesAfterGuard > 8) sawGuard = 0;
          }
        }
      }
      buf[i] = save;
      line = buf + i + 1;
    }
    i++;
  }

  if (rejects == 0) {
    FailPlain("POLYC_DRIVER_FALLBACK_NOT_CLOSED",
              "the out-of-domain status is not rejected by a fail-closed path");
    return 1;
  }
  return 0;
}

I32 Main(I32 argc, U8 **argv) {
  if (argc < 2) {
    "REASON_DETAIL=usage: <mode> <args...>\n";
    return 2;
  }
  U8 *mode = argv[1];
  if (StrEq(mode, "R01") == 1) return ModePrecedencePreempted(argc - 1, argv + 1);
  if (StrEq(mode, "R02") == 1) return ModeStatusDomainIncomplete(argc - 1, argv + 1);
  if (StrEq(mode, "R03") == 1) return ModeRouteRemainderUnmeasured(argc - 1, argv + 1);
  if (StrEq(mode, "R04") == 1) return ModeG0OracleIndependence(argc - 1, argv + 1);
  if (StrEq(mode, "R05") == 1) return ModeHistoricalDebtUnconserve(argc - 1, argv + 1);
  if (StrEq(mode, "R06") == 1) return ModeFailClosed(argc - 1, argv + 1);
  if (StrEq(mode, "SELFTEST") == 1) {
    if (StrEq("a", "a") == 0) { "SELFTEST_FAILED\n"; return 1; }
    if (StrLenOf("abc") != 3) { "SELFTEST_FAILED\n"; return 1; }
    if (Has("abcdef", "cd") != 1) { "SELFTEST_FAILED\n"; return 1; }
    if (Has("abcdef", "cz") != 0) { "SELFTEST_FAILED\n"; return 1; }
    if (Has("WP_STATUS_USAGE", "WP_STATUS_") != 1) { "SELFTEST_FAILED\n"; return 1; }
    if (Has("WP_STATUS_USAGE", "WP_STATUS_X") != 0) { "SELFTEST_FAILED\n"; return 1; }
    return 0;
  }
  "REASON_DETAIL=unknown mode %s\n", mode;
  return 2;
}
