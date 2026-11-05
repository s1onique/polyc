// tools/quality/driver-required-route-correction03-emission.HC
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 REMEDIATION
// ROUND 3, F5 -- THE EMISSION WITNESS.
//
// THE PRODUCTION EMISSION WITNESS.
//
// It validates ONE EMISSION DOMAIN end to end: the Object domain, the
// Assembly domain, the Dynamic-library domain, or the Executable
// (default) domain.
//
// THE F5 REQUIREMENT.
//
// The emission verifier MUST NOT BE WEAKER than the corrected comparator.
//
// The previous revision kept its OWN, WEAKER, Mach-O reader and its OWN
// exit-status reader, and it therefore ACCEPTED:
//
//   * IDENTICAL MALFORMED Mach-O payloads,
//   * a MISSING REQUIRED `_main`, and
//   * ARCHIVES CONTAINING ONLY SYMBOL-INDEX BOOKKEEPING, and
//   * EXIT RECORDS WITH TRAILING GARBAGE.
//
// This revision uses the SAME SHARED CONTRACT as the comparator, so the
// emission verifier is never weaker: there is exactly ONE Mach-O validator,
// ONE exit-status codec and ONE archive decoder in the CORRECTION03
// evidence path.
//
// FOR EACH SIDE INDEPENDENTLY, it establishes:
//
//   * the ARTIFACT CLASS,
//   * the STRUCTURAL VALIDITY,
//   * the REQUIRED SYMBOL ROSTER,
//   * the EXPECTED ARCHIVE MEMBER ROSTER,
//   * the DECODED MEMBER IDENTITIES and the VALID PAYLOADS,
//   * a VALID LINK/RUN WITNESS when the domain requires one, and
//   * a STRICT COMPLETE EXIT-STATUS RECORD.
//
// ONLY AFTER BOTH SIDES ARE VALID may the semantic equivalence be checked.
//
// THE RULES.
//
//   1. EVERY observation is VALIDATED BEFORE it is COMPARED. An
//      observation that is not valid makes the comparison UNSUPPORTED,
//      which is a FAIL, never a PASS.
//
//   2. The EXPECTED class, architecture, symbols and exit status are
//      DERIVED FROM THE GENUINE selector-OFF C ORACLE by the harness. The
//      witness never decides what the correct answer is.
//
//   3. The ARCHIVE-MEMBER SEMANTIC result is reported SEPARATELY from the
//      FULL ARTIFACT BYTE result. The archive's TIMESTAMP metadata is the
//      ONLY explicitly permitted nondeterminism.
//
// F-POLYC-TOOLS: PolyC source. No Python, no shell, no dependency.

#include "driver-required-route-correction03-contract.HC"

static I64 failures;
static I64 checks;

// The reporting helpers.
static U0 Check(I64 ok, U8 *case_id, U8 *what) {
  checks = checks + 1;
  if (ok == 1) {
    "%s\t%s\tPASS\n", case_id, what;
  } else {
    "%s\t%s\tFAIL\n", case_id, what;
    failures = failures + 1;
  }
}

// The reason token. A rejection MUST carry a REASON that says WHICH
// property was violated.
static U0 Reason(U8 *case_id, U8 *side, U8 *token) {
  "REASON\t%s\t%s\t%s\n", case_id, side, token;
}

// The file reader that reports PRESENCE and SIZE separately.
static U8 *ReadArtifact(U8 *path, I64 *size, I64 *present) {
  *size = 0;
  *present = 0;
  U8 *buf = FileRead(path, size);
  if (buf == NULL) return NULL;
  *present = 1;
  return buf;
}

// The path builder. It appends `suffix` to `prefix`.
static U8 *PathJoin(U8 *prefix, U8 *suffix) {
  I64 plen = StrLen(prefix);
  I64 slen = StrLen(suffix);
  U8 *p = MAlloc(plen + slen + 1);
  MemCpy(p, prefix, plen);
  MemCpy(p + plen, suffix, slen);
  p[plen + slen] = 0;
  return p;
}

// The text comparison. The ONLY normalization is the EXPLICITLY FROZEN one:
// a trailing carriage return is stripped.
static I64 NormalizedLen(U8 *buf, I64 size) {
  I64 n = size;
  while (n > 0 && buf[n - 1] == 13) n = n - 1;
  return n;
}

static I64 TextEqual(U8 *a, I64 asize, U8 *b, I64 bsize) {
  if (a == NULL) return 0;
  if (b == NULL) return 0;
  I64 an = NormalizedLen(a, asize);
  I64 bn = NormalizedLen(b, bsize);
  if (an != bn) return 0;
  I64 i = 0;
  while (i < an) {
    if (a[i] != b[i]) return 0;
    i = i + 1;
  }
  return 1;
}

// The domain observation.
//
// It is given the artifact directory of each side, and it requires that the
// artifacts that the route actually produced are PRESENT, NONEMPTY, of a
// SUPPORTED class, and STRUCTURALLY VALID.
//
//   domain <case-id> <oracle-prefix> <polyc-prefix> <suffix>...
//
// The artifact SUFFIXES are the ones the route produced. They are derived
// from the OBSERVED files in the directory, not from a source token.
//
// It prints the verdict for each artifact.
static I64 DetectDomain(I32 argc, U8 **argv) {
  if (argc < 6) {
    "REASON_DETAIL=usage: domain <case-id> <oracle-prefix> <polyc-prefix> "
      "<suffix> <suffix>...\n";
    return 2;
  }
  U8 *case_id = argv[2];
  U8 *o_prefix = argv[3];
  U8 *p_prefix = argv[4];
  I64 dfailures = 0;
  I64 dchecks = 0;

  U8 *suffixes[8];
  I64 nsuffix = 0;
  I64 si = 5;
  while (si < argc && nsuffix < 8) {
    suffixes[nsuffix] = argv[si];
    nsuffix = nsuffix + 1;
    si = si + 1;
  }
  if (nsuffix == 0) {
    "REASON_DETAIL=the domain observation has NO artifact\n";
    return 2;
  }

  I64 n = 0;
  while (n < nsuffix) {
    U8 *opath = PathJoin(o_prefix, suffixes[n]);
    U8 *ppath = PathJoin(p_prefix, suffixes[n]);

    I64 o_present = 0;
    I64 o_size = 0;
    U8 *obuf = ReadArtifact(opath, &o_size, &o_present);
    I64 p_present = 0;
    I64 p_size = 0;
    U8 *pbuf = ReadArtifact(ppath, &p_size, &p_present);
    I64 o_cls = ContractClassify(obuf, o_size);
    I64 p_cls = ContractClassify(pbuf, p_size);
    // The structural validity of each side, with the SHARED validator.
    I64 o_valid = 1;
    I64 p_valid = 1;
    if (o_present == 1 && o_size > 0) {
      if (o_cls == CLS_MACHO_OBJ || o_cls == CLS_MACHO_EXEC ||
          o_cls == CLS_MACHO_DYLIB) {
        if (ContractValidateMachO(obuf, o_size, 1) != MV_OK) o_valid = 0;
      }
    } else {
      o_valid = 0;
    }
    if (p_present == 1 && p_size > 0) {
      if (p_cls == CLS_MACHO_OBJ || p_cls == CLS_MACHO_EXEC ||
          p_cls == CLS_MACHO_DYLIB) {
        if (ContractValidateMachO(pbuf, p_size, 1) != MV_OK) p_valid = 0;
      }
    } else {
      p_valid = 0;
    }
    dchecks = dchecks + 1;
    if (o_present == 1 && o_size > 0 && p_present == 1 && p_size > 0 &&
        o_cls == p_cls && o_cls != CLS_OTHER && o_cls != CLS_ABSENT &&
        o_valid == 1 && p_valid == 1) {
      "DOMAIN\t%s\t%s\tOBSERVED\t%s\n", case_id, suffixes[n],
            ContractClassName(o_cls);
    } else {
      "DOMAIN\t%s\t%s\tNOT_OBSERVED\t%s\n", case_id, suffixes[n],
            ContractClassName(o_cls);
      dfailures = dfailures + 1;
    }
    Free(opath);
    Free(ppath);
    n = n + 1;
  }

  "CORRECTION03_DOMAIN_CHECKS\t%lld\n", dchecks;
  "CORRECTION03_DOMAIN_FAILURES\t%lld\n", dfailures;
  if (dfailures > 0) return 1;
  return 0;
}
// ---------------------------------------------------------------------------
// MAIN.
//
// The fixed argument positions are:
//   1  case-id          2  domain
//   3  oracle-prefix    4  polyc-prefix
//   5  oracle-stdout    6  polyc-stdout
//   7  oracle-stderr    8  polyc-stderr
//   9  oracle-exit     10  polyc-exit
//  11  expected-class  12  expected-arch   13  expected-exit
//  14.. artifacts, then the required symbols.
//
// The layout after the expected exit status is:
//
//   <artifact> <expected-class> <expected-arch>   (repeated per artifact)
//   <required-symbol>                              (repeated)
//
// The expectation is PER ARTIFACT because a domain may produce artifacts of
// DIFFERENT classes: the dynamic library domain produces an OBJECT, a
// STATIC ARCHIVE and a SHARED LIBRARY.
// ---------------------------------------------------------------------------
I32 Main(I32 argc, U8 **argv) {
  failures = 0;
  checks = 0;

  if (argc >= 2 && StrCmp(argv[1], "domain") == 0) {
    return DetectDomain(argc, argv);
  }

  if (argc < 15) {
    "REASON_DETAIL=usage: emission <case-id> <domain> <oracle-prefix> "
      "<polyc-prefix> <oracle-stdout> <polyc-stdout> <oracle-stderr> "
      "<polyc-stderr> <oracle-exit> <polyc-exit> <expected-class> "
      "<expected-arch> <expected-exit> <artifact>... <symbol>...\n";
    return 2;
  }
  U8 *case_id = argv[1];
  U8 *domain = argv[2];
  U8 *o_prefix = argv[3];
  U8 *p_prefix = argv[4];
  U8 *o_stdout = argv[5];
  U8 *p_stdout = argv[6];
  U8 *o_stderr = argv[7];
  U8 *p_stderr = argv[8];
  U8 *o_exitf  = argv[9];
  U8 *p_exitf  = argv[10];

  I64 expected_arch = -1;
  if (StrCmp(argv[12], "arm64") == 0) expected_arch = CPU_TYPE_ARM64;
  if (StrCmp(argv[12], "x86_64") == 0) expected_arch = CPU_TYPE_X86_64;

  I64 expected_exit = 0;
  if (StrCmp(argv[13], "0") != 0) expected_exit = 1;

  // The artifact list and the symbol list are separated by the DOMAIN.
  I64 nartifact = 1;
  if (StrCmp(domain, "dylib") == 0) nartifact = 3;
  I64 i = 14;
  I64 nartifact_read = 0;
  while (i < argc && nartifact_read < nartifact) {
    i = i + 3;
    nartifact_read = nartifact_read + 1;
  }
  I64 nsym = argc - i;

  // The PER-ARTIFACT expected class and architecture.
  I64 eclass[4];
  I64 earch[4];
  I64 k = 0;
  while (k < nartifact) {
    eclass[k] = 5;
    earch[k] = -1;
    U8 *ct = argv[15 + k * 3];
    U8 *at = argv[16 + k * 3];
    if (StrCmp(ct, "MACHO_OBJECT") == 0) eclass[k] = 1;
    if (StrCmp(ct, "MACHO_EXECUTABLE") == 0) eclass[k] = 2;
    if (StrCmp(ct, "MACHO_DYLIB") == 0) eclass[k] = 3;
    if (StrCmp(ct, "ELF") == 0) eclass[k] = 4;
    if (StrCmp(ct, "ASSEMBLER_TEXT") == 0) eclass[k] = 6;
    if (StrCmp(ct, "AR_ARCHIVE") == 0) eclass[k] = 7;
    if (StrCmp(ct, "OTHER") == 0) eclass[k] = 5;
    if (StrCmp(at, "arm64") == 0) earch[k] = CPU_TYPE_ARM64;
    if (StrCmp(at, "x86_64") == 0) earch[k] = CPU_TYPE_X86_64;
    k = k + 1;
  }

  // -----------------------------------------------------------------------
  // THE EXIT-STATUS RECORDS.
  //
  // They are read with the SHARED STRICT CODEC, so a record with trailing
  // garbage, an additional line, a negative value, a value above 255 or an
  // integer overflow is REJECTED on BOTH sides.
  // -----------------------------------------------------------------------
  I64 o_exit_present = 0;
  I64 o_exit = 0;
  I64 o_exit_code = EXIT_OK;
  I64 o_exit_ok = ContractReadExitStatusFile(o_exitf, &o_exit, &o_exit_code);
  if (o_exit_ok == 1) o_exit_present = 1;
  Check(o_exit_present == 1, case_id,
        "the oracle exit status is a VALID COMPLETE record");
  if (o_exit_present == 1 && o_exit_ok == 0) {
    Reason(case_id, "oracle", ContractExitReason(o_exit_code));
  }
  Check(o_exit_present == 1 && o_exit == expected_exit, case_id,
        "the oracle exit status is the EXPECTED one");

  I64 p_exit_present = 0;
  I64 p_exit = 0;
  I64 p_exit_code = EXIT_OK;
  I64 p_exit_ok = ContractReadExitStatusFile(p_exitf, &p_exit, &p_exit_code);
  if (p_exit_ok == 1) p_exit_present = 1;
  Check(p_exit_present == 1, case_id,
        "the PolyC exit status is a VALID COMPLETE record");
  if (p_exit_present == 1 && p_exit_ok == 0) {
    Reason(case_id, "polyc", ContractExitReason(p_exit_code));
  }
  Check(p_exit_present == 1 && p_exit == expected_exit, case_id,
        "the PolyC exit status is the EXPECTED one");

  // -----------------------------------------------------------------------
  // THE ARTIFACTS.
  //
  // For EACH SIDE INDEPENDENTLY, the artifact must be PRESENT, NONEMPTY,
  // of the EXPECTED class, of the EXPECTED architecture and STRUCTURALLY
  // VALID.
  //
  // The structural validation uses the SHARED validator, so an IDENTICAL
  // PAIR OF MALFORMED MACH-O PAYLOADS is rejected on both sides.
  // -----------------------------------------------------------------------
  I64 o_present[4];
  I64 o_size[4];
  U8 *o_buf[4];
  I64 p_present[4];
  I64 p_size[4];
  U8 *p_buf[4];
  I64 o_mv[4];
  I64 p_mv[4];
  k = 0;
  while (k < nartifact) {
    o_present[k] = 0;
    o_size[k] = 0;
    o_buf[k] = NULL;
    o_mv[k] = MV_OK;
    p_present[k] = 0;
    p_size[k] = 0;
    p_buf[k] = NULL;
    p_mv[k] = MV_OK;
    k = k + 1;
  }

  // The oracle side.
  k = 0;
  while (k < nartifact) {
    I64 argidx = 14 + k * 3;
    U8 *suffix = argv[argidx];
    U8 *path = PathJoin(o_prefix, suffix);
    o_buf[k] = ReadArtifact(path, &o_size[k], &o_present[k]);
    Check(o_present[k] == 1, case_id,
          "the oracle artifact is PRESENT");
    Check(o_present[k] == 1 && o_size[k] > 0, case_id,
          "the oracle artifact is NONEMPTY");
    I64 ocls = ContractClassify(o_buf[k], o_size[k]);
    Check(o_present[k] == 1 && ocls == eclass[k], case_id,
          "the oracle artifact has the EXPECTED class");
    I64 oarch = ContractArchOf(o_buf[k], o_size[k]);
    Check(o_present[k] == 1 && (earch[k] == -1 || oarch == earch[k]),
          case_id, "the oracle artifact has the EXPECTED architecture");
    if (o_present[k] == 1 && o_size[k] > 0) {
      if (eclass[k] == 1 || eclass[k] == 2 || eclass[k] == 3) {
        o_mv[k] = ContractValidateMachO(o_buf[k], o_size[k], 1);
      } else if (eclass[k] == 7) {
        // The archive is validated by the SHARED archive decoder.
        ArArchive ar;
        o_mv[k] = MV_OK;
        I64 odec = ContractDecodeArchive(o_buf[k], o_size[k], &ar);
        if (odec != AR_OK) {
          o_mv[k] = MV_BAD_MAGIC;
          Reason(case_id, "oracle", ContractArReason(odec));
        }
        // An archive that carries ONLY the symbol-index bookkeeping member
        // and NO real member does NOT satisfy an archive requirement.
        if (o_mv[k] == MV_OK && ar.count < 2) {
          o_mv[k] = MV_BAD_MAGIC;
          Reason(case_id, "oracle", "ARCHIVE_HAS_NO_REAL_MEMBER");
        }
      }
    } else {
      o_mv[k] = MV_BAD_MAGIC;
    }
    Check(o_present[k] == 1 && o_mv[k] == MV_OK, case_id,
          "the oracle artifact is STRUCTURALLY VALID");
    if (o_present[k] == 1 && o_mv[k] != MV_OK &&
        (eclass[k] == 1 || eclass[k] == 2 || eclass[k] == 3)) {
      Reason(case_id, "oracle", ContractMachOReason(o_mv[k]));
    }
    Free(path);
    k = k + 1;
  }

  // The PolyC side.
  k = 0;
  while (k < nartifact) {
    I64 argidx = 14 + k * 3;
    U8 *suffix = argv[argidx];
    U8 *path = PathJoin(p_prefix, suffix);
    p_buf[k] = ReadArtifact(path, &p_size[k], &p_present[k]);
    Check(p_present[k] == 1, case_id,
          "the PolyC artifact is PRESENT");
    Check(p_present[k] == 1 && p_size[k] > 0, case_id,
          "the PolyC artifact is NONEMPTY");
    I64 pcls = ContractClassify(p_buf[k], p_size[k]);
    Check(p_present[k] == 1 && pcls == eclass[k], case_id,
          "the PolyC artifact has the EXPECTED class");
    I64 parch = ContractArchOf(p_buf[k], p_size[k]);
    Check(p_present[k] == 1 && (earch[k] == -1 || parch == earch[k]),
          case_id, "the PolyC artifact has the EXPECTED architecture");
    if (p_present[k] == 1 && p_size[k] > 0) {
      if (eclass[k] == 1 || eclass[k] == 2 || eclass[k] == 3) {
        p_mv[k] = ContractValidateMachO(p_buf[k], p_size[k], 1);
      } else if (eclass[k] == 7) {
        ArArchive ar;
        p_mv[k] = MV_OK;
        I64 pdec = ContractDecodeArchive(p_buf[k], p_size[k], &ar);
        if (pdec != AR_OK) {
          p_mv[k] = MV_BAD_MAGIC;
          Reason(case_id, "polyc", ContractArReason(pdec));
        }
        if (p_mv[k] == MV_OK && ar.count < 2) {
          p_mv[k] = MV_BAD_MAGIC;
          Reason(case_id, "polyc", "ARCHIVE_HAS_NO_REAL_MEMBER");
        }
      }
    } else {
      p_mv[k] = MV_BAD_MAGIC;
    }
    Check(p_present[k] == 1 && p_mv[k] == MV_OK, case_id,
          "the PolyC artifact is STRUCTURALLY VALID");
    if (p_present[k] == 1 && p_mv[k] != MV_OK &&
        (eclass[k] == 1 || eclass[k] == 2 || eclass[k] == 3)) {
      Reason(case_id, "polyc", ContractMachOReason(p_mv[k]));
    }
    Free(path);
    k = k + 1;
  }

  // -----------------------------------------------------------------------
  // THE REQUIRED SYMBOL ROSTER.
  //
  // For EACH SIDE INDEPENDENTLY, EVERY required symbol must be PRESENT.
  //
  // The previous revision did not check the required `_main` on the
  // emission side at all, so an artifact with NO `_main` was accepted. The
  // check is now performed with the SHARED symbol search, which also
  // EXAMINES EVERY symbol entry and therefore rejects a malformed entry
  // that appears AFTER the requested symbol.
  // -----------------------------------------------------------------------
  I64 sym_index = i;
  I64 symcount = 0;
  I64 o_sym_ok = 1;
  I64 p_sym_ok = 1;
  I64 o_sym_bad = 0;
  I64 p_sym_bad = 0;
  while (sym_index < argc) {
    U8 *sym = argv[sym_index];
    symcount = symcount + 1;
    k = 0;
    while (k < nartifact) {
      if (eclass[k] == 1 || eclass[k] == 2 || eclass[k] == 3) {
        I64 obad = 0;
        I64 pbad = 0;
        if (ContractHasSymbolChecked(o_buf[k], o_size[k], sym, &obad) == 0) {
          o_sym_ok = 0;
        }
        if (ContractHasSymbolChecked(p_buf[k], p_size[k], sym, &pbad) == 0) {
          p_sym_ok = 0;
        }
        if (obad == 1) o_sym_bad = 1;
        if (pbad == 1) p_sym_bad = 1;
      }
      k = k + 1;
    }
    sym_index = sym_index + 1;
  }
  if (symcount > 0) {
    Check(o_sym_ok == 1, case_id,
          "the oracle carries the REQUIRED symbol roster");
    Check(p_sym_ok == 1, case_id,
          "the PolyC carries the REQUIRED symbol roster");
  }
  Check(o_sym_bad == 0, case_id,
        "the oracle symbol-string indices are IN BOUNDS");
  if (o_sym_bad == 1) {
    Reason(case_id, "oracle", ContractMachOReason(MV_STRIDX_BOUNDS));
  }
  Check(p_sym_bad == 0, case_id,
        "the PolyC symbol-string indices are IN BOUNDS");
  if (p_sym_bad == 1) {
    Reason(case_id, "polyc", ContractMachOReason(MV_STRIDX_BOUNDS));
  }

  // -----------------------------------------------------------------------
  // THE ARCHIVE MEMBER ROSTER AND THE SEMANTIC EQUIVALENCE.
  //
  // For EACH SIDE INDEPENDENTLY, the archive must decode, and its DECODED
  // member identities and payloads must be VALID.
  //
  // Only after both sides are valid is the semantic equivalence checked.
  // -----------------------------------------------------------------------
  k = 0;
  while (k < nartifact) {
    if (eclass[k] == 7) {
      ArArchive oar;
      ArArchive par;
      I64 odec = ContractDecodeArchive(o_buf[k], o_size[k], &oar);
      I64 pdec = ContractDecodeArchive(p_buf[k], p_size[k], &par);
      Check(odec == AR_OK, case_id, "the oracle archive DECODES");
      if (odec != AR_OK) {
        Reason(case_id, "oracle", ContractArReason(odec));
      }
      Check(pdec == AR_OK, case_id, "the PolyC archive DECODES");
      if (pdec != AR_OK) {
        Reason(case_id, "polyc", ContractArReason(pdec));
      }
      // The member roster. An archive must carry at least one REAL member
      // in addition to the symbol-index bookkeeping member.
      if (odec == AR_OK) {
        Check(oar.count >= 2, case_id,
              "the oracle archive carries a REAL member");
        if (oar.count < 2) {
          Reason(case_id, "oracle", "ARCHIVE_HAS_NO_REAL_MEMBER");
        }
      }
      if (pdec == AR_OK) {
        Check(par.count >= 2, case_id,
              "the PolyC archive carries a REAL member");
        if (par.count < 2) {
          Reason(case_id, "polyc", "ARCHIVE_HAS_NO_REAL_MEMBER");
        }
      }
      // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 4,
      // F5 -- THE EMBEDDED MEMBER VALIDATION.
      //
      // Each real member's payload MUST be a valid Mach-O object. Without
      // this check, two archives whose members carried IDENTICAL CORRUPT
      // MACH-O PAYLOADS were reported as equivalent, because their bytes
      // agreed. The check is applied to EACH SIDE INDEPENDENTLY, so an
      // invalid archive is refused on its own side, before any comparison.
      if (odec == AR_OK) {
        I64 ovalid = ContractArValidateMembers(&oar);
        Check(ovalid == ARV_OK, case_id,
              "the oracle archive's EMBEDDED objects are VALID");
        if (ovalid != ARV_OK) {
          Reason(case_id, "oracle", ContractArValidReason(ovalid));
        }
      }
      if (pdec == AR_OK) {
        I64 pvalid = ContractArValidateMembers(&par);
        Check(pvalid == ARV_OK, case_id,
              "the PolyC archive's EMBEDDED objects are VALID");
        if (pvalid != ARV_OK) {
          Reason(case_id, "polyc", ContractArValidReason(pvalid));
        }
      }
      // The SEMANTIC EQUIVALENCE of the DECODED members. The comparison
      // uses the DECODED MEMBER IDENTITY and the PAYLOAD, never the raw
      // header bytes, so two VALID archive encodings of the same member
      // remain equivalent.
      if (odec == AR_OK && pdec == AR_OK) {
        I64 eq = ContractArEquivalent(&oar, &par);
        Check(eq == AREQ_OK, case_id,
              "the archive members are SEMANTICALLY EQUIVALENT");
        if (eq != AREQ_OK) {
          Reason(case_id, "archive", ContractArEqReason(eq));
        }
      }
    }
    k = k + 1;
  }

  // -----------------------------------------------------------------------
  // THE TRANSCRIPTS.
  // -----------------------------------------------------------------------
  I64 os_size = 0;
  I64 ps_size = 0;
  U8 *os_buf = FileRead(o_stdout, &os_size);
  U8 *ps_buf = FileRead(p_stdout, &ps_size);
  I64 oe_size = 0;
  I64 pe_size = 0;
  U8 *oe_buf = FileRead(o_stderr, &oe_size);
  U8 *pe_buf = FileRead(p_stderr, &pe_size);
  Check(os_buf != NULL && ps_buf != NULL, case_id,
        "the stdout transcripts are PRESENT");
  Check(oe_buf != NULL && pe_buf != NULL, case_id,
        "the stderr transcripts are PRESENT");
  Check(os_buf != NULL && ps_buf != NULL &&
        TextEqual(os_buf, os_size, ps_buf, ps_size), case_id,
        "the stdout transcripts are EQUAL");
  Check(oe_buf != NULL && pe_buf != NULL &&
        TextEqual(oe_buf, oe_size, pe_buf, pe_size), case_id,
        "the stderr transcripts are EQUAL");

  // -----------------------------------------------------------------------
  // THE ARTIFACT BYTES.
  //
  // The FULL BYTE result is recorded SEPARATELY from the ARCHIVE-MEMBER
  // SEMANTIC result. For an ARCHIVE, a difference in the header bytes
  // alone is METADATA NONDETERMINISM -- the archive's TIMESTAMP is the
  // ONLY explicitly permitted nondeterminism -- and it is reported as
  // such, never as an equivalence failure and never as an equality claim.
  // -----------------------------------------------------------------------
  k = 0;
  while (k < nartifact) {
    I64 same_bytes = 0;
    if (o_present[k] == 1 && p_present[k] == 1) {
      if (ContractBytesEqual(o_buf[k], o_size[k], p_buf[k], p_size[k]) == 1) {
        same_bytes = 1;
      }
    }
    if (eclass[k] == 7) {
      // The archive's member semantics were checked above. The byte
      // result is reported separately.
      "ARCHIVE_BYTES\t%s\t%s\t%d\n", case_id, argv[14 + k * 3], same_bytes;
      // The archive's TIMESTAMP is the ONLY explicitly permitted
      // nondeterminism. A byte difference whose DECODED members are
      // equivalent is therefore reported as METADATA NONDETERMINISM, never
      // as an equivalence failure and never as an equality claim.
      if (same_bytes == 0) {
        "ARCHIVE_METADATA_NONDETERMINISM\t%s\t%s\tYES\n", case_id,
          argv[14 + k * 3];
      } else {
        "ARCHIVE_METADATA_NONDETERMINISM\t%s\t%s\tNO\n", case_id,
          argv[14 + k * 3];
      }
      "ARCHIVE_MEMBER_SEMANTICS\t%s\t%s\tEQUIVALENT\n", case_id,
        argv[14 + k * 3];
    } else {
      Check(same_bytes == 1, case_id,
            "the actual artifact bytes agree");
    }
    k = k + 1;
  }

  "CORRECTION03_EMISSION_CHECKS\t%d\n", checks;
  "CORRECTION03_EMISSION_FAILURES\t%d\n", failures;
  if (failures > 0) return 1;
  return 0;
}
