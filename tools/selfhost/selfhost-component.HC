// tools/selfhost/selfhost-component.HC
//
// ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01 C2.2 IMPL.
//
// PolyC-native self-host component registry + control plane.
//
// Replaces the predecessor Python validator and the substantive
// shell driver with a single PolyC executable. Compiles with the
// existing stage0 compiler (./hcc), links against libtos.a for
// tooling primitives (SpawnAndCapture, file IO, string utils).
//
// Operations:
//   selfhost-component validate [REGISTRY]      -- registry validate
//   selfhost-component build  [REGISTRY]        -- build component (needs env COMPONENT/STAGE)
//   selfhost-component test   [REGISTRY]        -- test  (needs env COMPONENT/STAGE)
//   selfhost-component selftest                 -- 13 frozen negative controls
//
// Environment:
//   SHC_REPO_ROOT  default "."    (overrides repo-root resolution)
//   SHC_REGISTRY   default docs/factory/SELF-HOST-COMPONENTS.tsv
//   COMPONENT      required for build/test
//   STAGE          required for build/test (accepted: 0|1|2|3)
//
// Process execution: NEVER constructs a shell. Producer is invoked
// via SpawnAndCapture with a fixed argv vector. Injection hardening
// is enforced at the COMPONENT/STAGE validation layer (regex on
// component_id; exact-set check on stage) and again at the
// resolution layer (lookup must return exactly one row).

#include "../../src/holyc-lib/tooling.HC"

// ============================================================
// libc environment accessor (direct binding, no shell)
// ============================================================

extern "c" U8 *getenv(U8 *name);

U8 *GetEnv(U8 *name)
{
  U8 *v = getenv(name);
  return v;
}

// ============================================================
// Compile-time constants (registry schema)
// ============================================================

#define SHC_NUM_FIELDS         10
#define SHC_MAX_COMPONENTS     64
#define SHC_MAX_PATH           4096

#define SHC_STATE_STABLE       0
#define SHC_STATE_MIGRATING    1
#define SHC_STATE_DISABLED     2

// ============================================================
// Frozen registry schema (10 columns, binding)
// ============================================================

U8 *SHC_HEADER[SHC_NUM_FIELDS] = {
  "component_id",
  "source",
  "symbol",
  "consumer_seam",
  "language",
  "state",
  "oracle",
  "cursor_gate",
  "production_seam_gate",
  "introduced_by",
};

U8 *SHC_VALID_LANGUAGES[] = {
  "POLYC",
  NULL,
};

U8 *SHC_VALID_STATES[] = {
  "STABLE",
  "MIGRATING",
  "DISABLED",
  NULL,
};

// ============================================================
// Stage resolver (binding — see ACT §9)
//
// stage0 -> ./hcc
// stage1 -> ./build/hcc-bootstrap02
// stage2 -> ./build/hcc-bootstrap03
// ============================================================

U8 *SHC_STAGE_PRODUCERS[4] = {
  "./hcc",
  "./build/hcc-bootstrap02",
  "./build/hcc-bootstrap03",
  "./build/hcc-bootstrap04",
};

U8 *SHC_GENERIC_OUT_TEMPLATE = "build/selfhost/stage%d/%s.o";

U8 *SHC_GOOD_HEADER =
  "component_id\tsource\tsymbol\tconsumer_seam\tlanguage\tstate\toracle\tcursor_gate\tproduction_seam_gate\tintroduced_by";

// ============================================================
// Component row + Registry
// ============================================================

class SHCRow {
  I64 lineno;
  U8 *component_id;
  U8 *source;
  U8 *symbol;
  U8 *consumer_seam;
  U8 *language;
  U8 *state;
  I64 state_id;
  U8 *oracle;
  U8 *cursor_gate;
  U8 *production_seam_gate;
  U8 *introduced_by;
};

class SHCRegistry {
  SHCRow *rows[SHC_MAX_COMPONENTS];
  I64     count;
  U8     *path;
};

// ============================================================
// Small helpers
// ============================================================

U0 SHCDie(U8 *msg)
{
  "FAIL: %s\n", msg;
  Exit(1);
}

U0 SHCDieRow(I64 lineno, U8 *msg)
{
  "FAIL: row %d: %s\n", lineno, msg;
  Exit(1);
}

Bool SHCStrEq(U8 *a, U8 *b)
{
  if (!a || !b) return FALSE;
  return !StrCmp(a, b);
}

Bool SHCStrInList(U8 *needle, U8 **list)
{
  for (I64 i = 0; list[i] != NULL; ++i) {
    if (SHCStrEq(needle, list[i])) return TRUE;
  }
  return FALSE;
}

I64 SHCStateId(U8 *s)
{
  if (SHCStrEq(s, "STABLE"))    return SHC_STATE_STABLE;
  if (SHCStrEq(s, "MIGRATING")) return SHC_STATE_MIGRATING;
  if (SHCStrEq(s, "DISABLED"))  return SHC_STATE_DISABLED;
  return -1;
}

U8 *SHCStateName(I64 id)
{
  switch (id) {
    case SHC_STATE_STABLE:    return "STABLE";
    case SHC_STATE_MIGRATING: return "MIGRATING";
    case SHC_STATE_DISABLED:  return "DISABLED";
  }
  return "UNKNOWN";
}

U8 *SHCDup(U8 *s)
{
  if (!s) return NULL;
  I64 n = StrLen(s);
  U8 *d = MAlloc(n + 1);
  MemCpy(d, s, n + 1);
  return d;
}

// ============================================================
// TSV field extraction (no embedded TAB / LF allowed)
// ============================================================

// Find the next TAB or LF (or NUL) starting at *p. Returns the
// terminator character. Advances *p past the field to the
// terminator. Sets *field_len to the field length.
U8 SHCSplitField(U8 **p, I64 *field_len)
{
  U8 *start = *p;
  while (**p != 0 && **p != '\t' && **p != '\n') {
    if (**p == '\r') {
      "FAIL: registry contains embedded CR (registry must be LF-terminated)\n";
      Exit(1);
    }
    (*p)++;
  }
  *field_len = *p - start;
  U8 term = **p;
  if (term != 0) {
    **p = 0;
    (*p)++;
  }
  return term;
}

// ============================================================
// Registry parser (skeleton; logic continues below)
// ============================================================

U0 SHCParseRegistry(SHCRegistry *r0, U8 *path);  // forward
U0 SHCRegistryFree(SHCRegistry *r0)
{
  for (I64 i = 0; i < r0->count; ++i) {
    SHCRow *r = r0->rows[i];
    Free(r->component_id);
    Free(r->source);
    Free(r->symbol);
    Free(r->consumer_seam);
    Free(r->language);
    Free(r->state);
    Free(r->oracle);
    Free(r->cursor_gate);
    Free(r->production_seam_gate);
    Free(r->introduced_by);
    Free(r);
  }
  r0->count = 0;
}

U0 SHCRegistryParseInner(SHCRegistry *r0, U8 *raw)
{
  r0->count = 0;
  U8 *cursor = raw;
  I64 line_no = 0;
  I64 header_idx = 0;

  while (*cursor != 0) {
    line_no++;

    if (*cursor == '\n') {
      cursor++;
      continue;
    }

    // Pre-scan: count TABs in this row (until LF or NUL). A
    // well-formed data row has exactly SHC_NUM_FIELDS-1 tabs
    // (9 tabs for 10 fields). Anything else is malformed.
    {
      U8 *p = cursor;
      I64 tabs = 0;
      while (*p != '\n' && *p != 0) {
        if (*p == '\t') tabs++;
        p++;
      }
      if (tabs != SHC_NUM_FIELDS - 1) {
        "FAIL: row %d: malformed field count (expected %d, got %d)\n",
          line_no, SHC_NUM_FIELDS, tabs + 1;
        Exit(1);
      }
    }

    U8 *fields[SHC_NUM_FIELDS];
    I64 field_lens[SHC_NUM_FIELDS];
    U8  term = 0;

    for (I64 i = 0; i < SHC_NUM_FIELDS; ++i) {
      fields[i] = cursor;
      term = SHCSplitField(&cursor, &field_lens[i]);
    }

    if (term != '\n' && term != 0) {
      "FAIL: row %d: malformed field count (expected %d)\n",
        line_no, SHC_NUM_FIELDS;
      Exit(1);
    }

    if (header_idx == 0) {
      for (I64 i = 0; i < SHC_NUM_FIELDS; ++i) {
        if (!SHCStrEq(fields[i], SHC_HEADER[i])) {
          "FAIL: registry header mismatch at column %d\n", i + 1;
          "FAIL:   expected: %s\n", SHC_HEADER[i];
          "FAIL:   got:      %s\n", fields[i];
          Exit(1);
        }
      }
      header_idx = 1;
      continue;
    }

    U8 *component_id        = fields[0];
    U8 *source              = fields[1];
    U8 *symbol              = fields[2];
    U8 *consumer_seam       = fields[3];
    U8 *language            = fields[4];
    U8 *state               = fields[5];
    U8 *oracle              = fields[6];
    U8 *cursor_gate         = fields[7];
    U8 *production_seam_gate= fields[8];
    U8 *introduced_by       = fields[9];

    if (StrLen(component_id) == 0) SHCDieRow(line_no, "component_id is empty");
    if (StrLen(source)       == 0) SHCDieRow(line_no, "source is empty");
    if (StrLen(symbol)       == 0) SHCDieRow(line_no, "symbol is empty");
    if (StrLen(consumer_seam)== 0) SHCDieRow(line_no, "consumer_seam is empty");
    if (StrLen(language)     == 0) SHCDieRow(line_no, "language is empty");
    if (StrLen(state)        == 0) SHCDieRow(line_no, "state is empty");
    if (StrLen(oracle)       == 0) SHCDieRow(line_no, "oracle is empty");
    if (StrLen(cursor_gate)  == 0) SHCDieRow(line_no, "cursor_gate is empty");
    if (StrLen(production_seam_gate) == 0) SHCDieRow(line_no, "production_seam_gate is empty");
    if (StrLen(introduced_by)== 0) SHCDieRow(line_no, "introduced_by is empty");

    if (source[0] == '/') {
      "FAIL: row %d: source must be repository-relative\n", line_no;
      Exit(1);
    }
    {
      U8 *p = source;
      while (*p) {
        if (p[0] == '.' && p[1] == '.' && (p[2] == 0 || p[2] == '/')) {
          "FAIL: row %d: source must not contain '..'\n", line_no;
          Exit(1);
        }
        p++;
      }
    }

    if (!SHCStrInList(language, SHC_VALID_LANGUAGES)) {
      "FAIL: row %d: invalid language '%s'\n", line_no, language;
      Exit(1);
    }
    I64 state_id = SHCStateId(state);
    if (state_id < 0) {
      "FAIL: row %d: invalid state '%s'\n", line_no, state;
      Exit(1);
    }

    {
      U8 *s = symbol;
      if (!(  (s[0] >= 'A' && s[0] <= 'Z')
           || (s[0] >= 'a' && s[0] <= 'z')
           || s[0] == '_')) {
        "FAIL: row %d: symbol '%s' must start with [A-Za-z_]\n",
          line_no, symbol;
        Exit(1);
      }
      for (I64 i = 1; s[i] != 0; ++i) {
        U8 c = s[i];
        Bool ok = (c >= 'A' && c <= 'Z')
               || (c >= 'a' && c <= 'z')
               || (c >= '0' && c <= '9')
               || c == '_'
               || c == '$';
        if (!ok) {
          "FAIL: row %d: symbol '%s' contains forbidden character '%c'\n",
            line_no, symbol, c;
          Exit(1);
        }
      }
    }

    for (I64 j = 0; j < r0->count; ++j) {
      if (SHCStrEq(r0->rows[j]->component_id, component_id)) {
        "FAIL: row %d: duplicate component_id '%s'\n", line_no, component_id;
        Exit(1);
      }
    }

    {
      U8 *c = component_id;
      for (I64 i = 0; c[i] != 0; ++i) {
        U8 ch = c[i];
        Bool ok = (ch >= 'A' && ch <= 'Z')
               || (ch >= 'a' && ch <= 'z')
               || (ch >= '0' && ch <= '9')
               || ch == '_';
        if (!ok) {
          "FAIL: row %d: component_id '%s' contains forbidden character '%c'\n",
            line_no, component_id, ch;
          Exit(1);
        }
      }
    }

    // Source-existence check (predecessor parity).
    if (!FileExists(source)) {
      "FAIL: row %d: source file does not exist: %s\n",
        line_no, source;
      Exit(1);
    }

    SHCRow *r = MAlloc(sizeof(SHCRow));
    r->lineno              = line_no;
    r->component_id        = SHCDup(component_id);
    r->source              = SHCDup(source);
    r->symbol              = SHCDup(symbol);
    r->consumer_seam       = SHCDup(consumer_seam);
    r->language            = SHCDup(language);
    r->state               = SHCDup(state);
    r->state_id            = state_id;
    r->oracle              = SHCDup(oracle);
    r->cursor_gate         = SHCDup(cursor_gate);
    r->production_seam_gate= SHCDup(production_seam_gate);
    r->introduced_by       = SHCDup(introduced_by);

    r0->rows[r0->count++] = r;
  }
}

U0 SHCParseRegistry(SHCRegistry *r0, U8 *path)
{
  if (!FileExists(path)) {
    "FAIL: registry not found: %s\n", path;
    Exit(1);
  }

  U8 *raw = FileRead(path);
  if (!raw) {
    "FAIL: cannot read registry: %s\n", path;
    Exit(1);
  }

  r0->path = path;
  SHCRegistryParseInner(r0, raw);
  Free(raw);
}

SHCRow *SHCRegistryFind(SHCRegistry *r0, U8 *component_id)
{
  I64 matches = 0;
  SHCRow *match = NULL;
  for (I64 i = 0; i < r0->count; ++i) {
    if (SHCStrEq(r0->rows[i]->component_id, component_id)) {
      matches++;
      match = r0->rows[i];
    }
  }
  if (matches == 0) {
    "FAIL: unknown component_id: '%s'\n", component_id;
    Exit(1);
  }
  if (matches > 1) {
    "FAIL: multiple rows match component_id '%s'\n", component_id;
    Exit(1);
  }
  return match;
}

// ============================================================
// COMPONENT / STAGE value validation (defense-in-depth)
// ============================================================

U8 *SHCValidateComponent(U8 *c)
{
  if (!c || StrLen(c) == 0) {
    "FAIL: COMPONENT=<id> is required\n";
    Exit(2);
  }
  for (I64 i = 0; c[i] != 0; ++i) {
    U8 ch = c[i];
    Bool ok = (ch >= 'A' && ch <= 'Z')
           || (ch >= 'a' && ch <= 'z')
           || (ch >= '0' && ch <= '9')
           || ch == '_';
    if (!ok) {
      "FAIL: COMPONENT contains forbidden character\n";
      Exit(2);
    }
  }
  return c;
}

I64 SHCValidateStage(U8 *s)
{
  if (!s || StrLen(s) == 0) {
    "FAIL: STAGE=<0|1|2|3> is required\n";
    Exit(2);
  }
  if (!StrCmp(s, "0")) return 0;
  if (!StrCmp(s, "1")) return 1;
  if (!StrCmp(s, "2")) return 2;
  if (!StrCmp(s, "3")) return 3;
  "FAIL: STAGE='%s' is required (expected 0|1|2|3)\n", s;
  Exit(2);
  // Unreachable: Exit() does not return, but this defensive
  // return silences the "control may reach end of non-void
  // function" warning and makes the contract explicit.
  return -1;
}

// ============================================================
// Stage -> producer
// ============================================================

U8 *SHCProducerForStage(I64 stage)
{
  if (stage < 0 || stage > 3) {
    "FAIL: unknown producer stage: %d (expected 0|1|2|3)\n", stage;
    Exit(1);
  }
  return SHC_STAGE_PRODUCERS[stage];
}

U8 *SHCGenericOutPath(I64 stage, U8 *component_id)
{
  return StrPrint(NULL, SHC_GENERIC_OUT_TEMPLATE, stage, component_id);
}

U8 *SHCResolvePath(U8 *base_dir, U8 *rel)
{
  if (rel[0] == '/') return StrPrint(NULL, "%s", rel);
  return StrPrint(NULL, "%s/%s", base_dir, rel);
}

U0 SHCCheckNoOutputAlias(U8 *source, U8 *generic_out)
{
  if (StrLen(source) < 3) return;
  if (!StrCmp(source + StrLen(source) - 2, ".o")) {
    if (SHCStrEq(source, generic_out)) {
      "FAIL: generic output '%s' aliases source '%s'\n",
        generic_out, source;
      Exit(1);
    }
  }
}

// ============================================================
// SHA256 (delegated to /usr/bin/shasum or sha256sum)
// ============================================================

U8 *SHCSha256File(U8 *path)
{
  U8 *out = NULL, *err = NULL;
  U8 *argv[4];

  // Try /usr/bin/shasum -a 256 first (macOS).
  argv[0] = "/usr/bin/shasum";
  argv[1] = "-a";
  argv[2] = "256";
  argv[3] = path;
  I64 rc = SpawnAndCapture("/usr/bin/shasum", argv, &out, &err);
  if (rc != 0) {
    Free(out); Free(err);
    out = NULL; err = NULL;
    argv[0] = "sha256sum";
    argv[1] = path;
    argv[2] = NULL;
    argv[3] = NULL;
    rc = SpawnAndCapture("sha256sum", argv, &out, &err);
  }
  if (rc != 0 || !out) {
    Free(out); Free(err);
    return StrPrint(NULL, "UNKNOWN");
  }
  // Output: "<hex>  <path>\n" or "<hex> <path>\n".
  for (I64 i = 0; out[i] != 0; ++i) {
    if (out[i] == ' ' || out[i] == '\n') {
      out[i] = 0;
      break;
    }
  }
  U8 *hex = StrPrint(NULL, "%s", out);
  Free(out); Free(err);
  return hex;
}

// ============================================================
// nm-based symbol check
// ============================================================

Bool SHCSymbolPresent(U8 *path, U8 *expected)
{
  U8 *out = NULL, *err = NULL;
  U8 *argv[3];
  argv[0] = "/usr/bin/nm";
  argv[1] = path;
  argv[2] = NULL;
  I64 rc = SpawnAndCapture("/usr/bin/nm", argv, &out, &err);
  if (rc != 0 || !out) {
    Free(out); Free(err);
    return FALSE;
  }
  // Match: line ends with " [TBDRS] <expected>$" with optional
  // address prefix. Use the same anchoring the predecessor uses
  // (nm | grep -E " [TBDRS] <expected>$").
  U8 *needle = StrPrint(NULL, " %s", expected);
  I64 nlen = StrLen(needle);
  U8 *p = out;
  while (*p) {
    U8 *line = p;
    while (*p && *p != '\n') p++;
    if (*p == '\n') { *p = 0; p++; }
    I64 llen = StrLen(line);
    if (llen < nlen + 2) continue;
    if (StrCmp(line + llen - nlen, needle) != 0) continue;
    // needle starts with " " (space). The TBDRS letter is the
    // char immediately before the needle; the space before that
    // is one position earlier.
    U8 sym_letter = line[llen - nlen - 1];
    if (sym_letter != 'T' && sym_letter != 'B' &&
        sym_letter != 'D' && sym_letter != 'R' &&
        sym_letter != 'S') continue;
    if (line[llen - nlen - 2] != ' ') continue;
    Free(out); Free(err);
    Free(needle);
    return TRUE;
  }
  Free(out); Free(err);
  Free(needle);
  return FALSE;
}

// ============================================================
// Platform-aware link-symbol prefix
// ============================================================

U8 *SHCLinkPrefix()
{
  U8 *out = NULL, *err = NULL;
  U8 *argv[3];
  argv[0] = "/usr/bin/uname";
  argv[1] = "-s";
  argv[2] = NULL;
  I64 rc = SpawnAndCapture("/usr/bin/uname", argv, &out, &err);
  Free(err);
  if (rc == 0 && out && Contains(out, "Darwin")) {
    Free(out);
    return StrPrint(NULL, "_");
  }
  Free(out);
  return StrPrint(NULL, "");
}

// ============================================================
// Validate operation
// ============================================================

U0 SHCValidateMakefileTargets(SHCRegistry *r0, U8 *repo_root)
{
  U8 *mf_path = StrPrint(NULL, "%s/Makefile", repo_root);
  if (!FileExists(mf_path)) {
    "FAIL: Makefile not found at %s\n", mf_path;
    Free(mf_path);
    Exit(1);
  }
  U8 *mf_text = FileRead(mf_path);
  if (!mf_text) {
    "FAIL: cannot read Makefile at %s\n", mf_path;
    Free(mf_path);
    Exit(1);
  }
  Free(mf_path);

  for (I64 i = 0; i < r0->count; ++i) {
    SHCRow *r = r0->rows[i];
    if (r->state_id == SHC_STATE_DISABLED) continue;
    U8 *keys[3] = { r->oracle, r->cursor_gate, r->production_seam_gate };
    U8 *names[3] = { "oracle", "cursor_gate", "production_seam_gate" };
    for (I64 k = 0; k < 3; ++k) {
      U8 *target = keys[k];
      Bool found = FALSE;
      U8 *line = mf_text;
      while (*line) {
        U8 *eol = line;
        while (*eol && *eol != '\n') eol++;
        U8 saved = *eol;
        *eol = 0;
        if (line[0] != '\t') {
          U8 *p = line;
          while (*p == ' ' || *p == '\t') p++;
          if (!StrNCmp(p, target, StrLen(target))) {
            U8 *q = p + StrLen(target);
            while (*q == ' ' || *q == '\t') q++;
            if (*q == ':') {
              found = TRUE;
              *eol = saved;
              break;
            }
          }
        }
        *eol = saved;
        line = eol;
        if (*line == '\n') line++;
      }
      if (!found) {
        "FAIL: row %d: Makefile target for %s '%s' not found (component '%s')\n",
          r->lineno, names[k], target, r->component_id;
        Free(mf_text);
        Exit(1);
      }
    }
  }
  Free(mf_text);
}

U0 SHCOpValidate(U8 *registry_path, U8 *repo_root)
{
  SHCRegistry sr;
  SHCParseRegistry(&sr, registry_path);
  // Output-aliases-source guard (per-row). The generic template
  // always appends ".o", so a literal alias requires source to
  // also end in ".o". Since real PolyC sources end in ".HC",
  // this is structurally impossible today, but we keep the
  // gate for future-proofing.
  for (I64 i = 0; i < sr.count; ++i) {
    SHCRow *r = sr.rows[i];
    if (StrLen(r->source) >= 2) {
      if (!StrCmp(r->source + StrLen(r->source) - 2, ".o")) {
        U8 *gen0 = SHCGenericOutPath(0, r->component_id);
        if (SHCStrEq(r->source, gen0)) {
          "FAIL: generic output '%s' aliases source '%s'\n",
            gen0, r->source;
          Free(gen0);
          SHCRegistryFree(&sr);
          Exit(1);
        }
        Free(gen0);
      }
    }
  }
  SHCValidateMakefileTargets(&sr, repo_root);
  "PASS: %d component row(s) validated against %s\n", sr.count, registry_path;
  for (I64 i = 0; i < sr.count; ++i) {
    SHCRow *r = sr.rows[i];
    "  - %s [%s] source=%s symbol=%s\n",
      r->component_id, SHCStateName(r->state_id), r->source, r->symbol;
  }
  SHCRegistryFree(&sr);
}

// ============================================================
// Build operation
//
// Required sequence:
//   1 validate registry
//   2 validate COMPONENT
//   3 validate STAGE
//   4 resolve component exactly once
//   5 resolve producer exactly once
//   6 require producer exists
//   7 resolve source
//   8 require source exists
//   9 resolve output path
//  10 reject source/output alias
//  11 clear stale output safely
//  12 invoke producer directly
//  13 propagate nonzero rc
//  14 require output exists
//  15 verify expected symbol
//  16 emit provenance
// ============================================================

U0 SHCEnsureDir(U8 *dir)
{
  if (!FileExists(dir)) {
    U8 *argv[4];
    argv[0] = "/bin/mkdir";
    argv[1] = "-p";
    argv[2] = dir;
    argv[3] = NULL;
    U8 *out, *err;
    SpawnAndCapture("/bin/mkdir", argv, &out, &err);
    Free(out); Free(err);
  }
}

U0 SHCRmIfExists(U8 *path)
{
  if (FileExists(path)) {
    U8 *argv[4];
    argv[0] = "/bin/rm";
    argv[1] = "-f";
    argv[2] = path;
    argv[3] = NULL;
    U8 *out, *err;
    SpawnAndCapture("/bin/rm", argv, &out, &err);
    Free(out); Free(err);
  }
}

U0 SHCOpBuild(U8 *registry_path, U8 *repo_root,
              U8 *component, U8 *stage_str)
{
  SHCValidateComponent(component);
  I64 stage = SHCValidateStage(stage_str);

  // 1 validate registry
  SHCRegistry sr;
  SHCParseRegistry(&sr, registry_path);

  // 4 resolve component exactly once
  SHCRow *r = SHCRegistryFind(&sr, component);

  if (r->state_id == SHC_STATE_DISABLED) {
    "FAIL: %s is DISABLED in registry; refusing to build\n", component;
    SHCRegistryFree(&sr);
    Exit(1);
  }

  // 5 resolve producer exactly once
  U8 *producer = SHCProducerForStage(stage);
  // 9 resolve output path
  U8 *generic  = SHCGenericOutPath(stage, component);

  // 7 resolve source
  // 8 require source exists
  if (!FileExists(r->source)) {
    // Try repo-rooted path.
    U8 *src_abs = SHCResolvePath(repo_root, r->source);
    if (!FileExists(src_abs)) {
      "FAIL: source missing: %s\n", r->source;
      Free(src_abs); Free(generic);
      SHCRegistryFree(&sr);
      Exit(1);
    }
    Free(src_abs);
  }

  // 10 reject source/output alias
  SHCCheckNoOutputAlias(r->source, generic);

  // 6 require producer exists
  U8 *producer_abs = SHCResolvePath(repo_root, producer);
  if (!FileExists(producer_abs)) {
    "FAIL: producer %s missing or not executable\n", producer;
    "FAIL: required for STAGE=%d; build the previous stage first\n", stage;
    Free(producer_abs); Free(generic);
    SHCRegistryFree(&sr);
    Exit(1);
  }

  // Ensure test-prefix exists (compilers read include/lib from it).
  U8 *test_prefix = StrPrint(NULL, "%s/build/test-prefix", repo_root);
  SHCEnsureDir(test_prefix);

  // Compute dir of generic output and ensure it exists.
  U8 *gen_dir = StrPrint(NULL, "%s/build/selfhost/stage%d",
                          repo_root, stage);
  SHCEnsureDir(gen_dir);
  Free(gen_dir);

  // 11 clear stale output safely
  SHCRmIfExists(generic);

  // 12 invoke producer directly
  U8 *install_dir = StrPrint(NULL, "%s", test_prefix);
  U8 *argv[8];
  argv[0] = producer_abs;
  argv[1] = StrPrint(NULL, "--install-dir=%s", install_dir);
  argv[2] = "-c";
  argv[3] = r->source;
  argv[4] = "-o";
  argv[5] = generic;
  argv[6] = NULL;

  U8 *out = NULL, *err = NULL;
  I64 rc = SpawnAndCapture(producer_abs, argv, &out, &err);
  if (out) { "%s", out; Free(out); }
  if (err) { "%s", err; Free(err); }

  // 13 propagate nonzero rc; 14 require output exists
  if (rc != 0 || !FileExists(generic)) {
    "FAIL: build FAILED (rc=%d, output=%s)\n", rc, generic;
    Free(producer_abs); Free(install_dir); Free(test_prefix);
    Free(generic);
    SHCRegistryFree(&sr);
    Exit(1);
  }

  // 15 verify expected symbol
  U8 *prefix = SHCLinkPrefix();
  U8 *expected = StrPrint(NULL, "%s%s", prefix, r->symbol);
  Bool sym_ok = SHCSymbolPresent(generic, expected);
  if (!sym_ok) {
    "FAIL: expected symbol '%s' not found in %s\n", expected, generic;
    Free(prefix); Free(expected);
    Free(producer_abs); Free(install_dir); Free(test_prefix); Free(generic);
    SHCRegistryFree(&sr);
    Exit(1);
  }

  // 16 emit provenance
  U8 *producer_sha = SHCSha256File(producer_abs);
  U8 *output_sha   = SHCSha256File(generic);

  "SELFHOST_COMPONENT_BUILD=PASS\n";
  "SELFHOST_COMPONENT_ID=%s\n", component;
  "SELFHOST_COMPONENT_SOURCE=%s\n", r->source;
  "SELFHOST_COMPONENT_PRODUCER_STAGE=%d\n", stage;
  "SELFHOST_COMPONENT_PRODUCER_BINARY=%s\n", producer;
  "SELFHOST_COMPONENT_PRODUCER_BINARY_SHA256=%s\n", producer_sha;
  "SELFHOST_COMPONENT_OUTPUT=%s\n", generic;
  "SELFHOST_COMPONENT_OUTPUT_SHA256=%s\n", output_sha;
  "SELFHOST_COMPONENT_EXPECTED_SYMBOL=%s\n", expected;
  "SELFHOST_COMPONENT_SYMBOL_CHECK=PASS\n";
  "SELFHOST_COMPONENT_BUILD_RC=0\n";
  "SELFHOST_COMPONENT_LINK_SYMBOL_PREFIX=%s\n", prefix;
  "SELFHOST_COMPONENT_REGISTRY=%s\n", registry_path;

  Free(producer_sha);
  Free(output_sha);
  Free(expected);
  Free(prefix);
  Free(producer_abs);
  Free(install_dir);
  Free(test_prefix);
  Free(generic);
  SHCRegistryFree(&sr);
}

// ============================================================
// Test operation
// ============================================================

U0 SHCOpTest(U8 *registry_path, U8 *repo_root,
             U8 *component, U8 *stage_str)
{
  SHCValidateComponent(component);
  SHCValidateStage(stage_str);

  // First, build.
  SHCOpBuild(registry_path, repo_root, component, stage_str);

  SHCRegistry sr;
  SHCParseRegistry(&sr, registry_path);
  SHCRow *r = SHCRegistryFind(&sr, component);

  U8 *argv[5];
  U8 *out, *err;
  I64 rc;

  argv[0] = "/usr/bin/make";
  argv[1] = "-C";
  argv[2] = repo_root;
  argv[3] = NULL;
  argv[4] = NULL;

  // oracle
  argv[3] = r->oracle;
  out = NULL; err = NULL;
  rc = SpawnAndCapture("/usr/bin/make", argv, &out, &err);
  if (out) { "%s", out; Free(out); }
  if (err) { "%s", err; Free(err); }
  if (rc != 0) {
    "FAIL: oracle '%s' failed (rc=%d)\n", r->oracle, rc;
    SHCRegistryFree(&sr);
    Exit(1);
  }

  // cursor_gate
  argv[3] = r->cursor_gate;
  out = NULL; err = NULL;
  rc = SpawnAndCapture("/usr/bin/make", argv, &out, &err);
  if (out) { "%s", out; Free(out); }
  if (err) { "%s", err; Free(err); }
  if (rc != 0) {
    "FAIL: cursor_gate '%s' failed (rc=%d)\n", r->cursor_gate, rc;
    SHCRegistryFree(&sr);
    Exit(1);
  }

  // production_seam_gate
  argv[3] = r->production_seam_gate;
  out = NULL; err = NULL;
  rc = SpawnAndCapture("/usr/bin/make", argv, &out, &err);
  if (out) { "%s", out; Free(out); }
  if (err) { "%s", err; Free(err); }
  if (rc != 0) {
    "FAIL: production_seam_gate '%s' failed (rc=%d)\n",
      r->production_seam_gate, rc;
    SHCRegistryFree(&sr);
    Exit(1);
  }

  "SELFHOST_COMPONENT_TEST=PASS\n";
  "SELFHOST_COMPONENT_TEST_ORACLE=%s\n", r->oracle;
  "SELFHOST_COMPONENT_TEST_CURSOR=%s\n", r->cursor_gate;
  "SELFHOST_COMPONENT_TEST_SEAM=%s\n", r->production_seam_gate;

  SHCRegistryFree(&sr);
}

// ============================================================
// Selftest — 13 frozen negative controls
// ============================================================

class SHCVerdict {
  I64 pass;
  I64 fail;
};

U0 SHCVerdictPass(SHCVerdict *v, U8 *name)
{
  v->pass++;
  "  PASS  %s\n", name;
}

U0 SHCVerdictFail(SHCVerdict *v, U8 *name, U8 *why)
{
  v->fail++;
  "  FAIL  %s  (%s)\n", name, why;
}

// WriteText: write `text` to `path` (overwrite).
U0 SHCWriteText(U8 *path, U8 *text)
{
  I32 fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, 384);
  if (fd < 0) return;
  I64 n = StrLen(text);
  I64 off = 0;
  while (off < n) {
    I64 w = write(fd, text + off, n - off);
    if (w <= 0) { close(fd); return; }
    off += w;
  }
  close(fd);
}

I64 SHCRunValidateOn(U8 *bin, U8 *path)
{
  U8 *argv[4];
  argv[0] = bin;
  argv[1] = "validate";
  argv[2] = path;
  argv[3] = NULL;
  U8 *out = NULL, *err = NULL;
  I64 rc = SpawnAndCapture(bin, argv, &out, &err);
  Free(out); Free(err);
  return rc;
}

I64 SHCRunBuildOn(U8 *bin, U8 *registry, U8 *component, U8 *stage)
{
  U8 *argv[6];
  argv[0] = bin;
  argv[1] = "build";
  argv[2] = registry;
  argv[3] = component;
  argv[4] = stage;
  argv[5] = NULL;
  U8 *out = NULL, *err = NULL;
  I64 rc = SpawnAndCapture(bin, argv, &out, &err);
  Free(out); Free(err);
  return rc;
}

U0 SHCSelfTestN1toN8(U8 *binary, U8 *repo_root, U8 *scratch, SHCVerdict *v)
{
  // N1 — current registry valid
  {
    U8 *p = StrPrint(NULL, "%s/docs/factory/SELF-HOST-COMPONENTS.tsv",
                      repo_root);
    I64 rc = SHCRunValidateOn(binary, p);
    if (rc == 0) SHCVerdictPass(v, "N1_current_registry_valid_PASS");
    else         SHCVerdictFail(v, "N1_current_registry_valid_PASS",
                                  "current registry rejected");
    Free(p);
  }

  // N3 — duplicate component_id
  {
    U8 *p = StrPrint(NULL, "%s/N3_dup.tsv", scratch);
    U8 *body = StrPrint(NULL,
      "%s\n"
      "identifier_scanner\ttools/bootstrap/bootstrap02-ident.HC\tBootstrapScanIdent\tsrc/lexer.c::lexIdentifier\tPOLYC\tSTABLE\tbootstrap02-oracle\tbootstrap02-cursor-test\tbootstrap02-lexer-seam-test\tACT-POLYC-BOOTSTRAP02\n"
      "identifier_scanner\ttools/bootstrap/bootstrap02-ident.HC\tBootstrapScanIdent\tsrc/lexer.c::lexIdentifier\tPOLYC\tSTABLE\tbootstrap02-oracle\tbootstrap02-cursor-test\tbootstrap02-lexer-seam-test\tACT-POLYC-BOOTSTRAP02\n",
      SHC_GOOD_HEADER);
    SHCWriteText(p, body);
    Free(body);
    I64 rc = SHCRunValidateOn(binary, p);
    if (rc == 1) SHCVerdictPass(v, "N3_duplicate_component_id_FAIL");
    else         SHCVerdictFail(v, "N3_duplicate_component_id_FAIL",
                                  "duplicate did not fail");
    Free(p);
  }

  // N4 — missing source
  {
    U8 *p = StrPrint(NULL, "%s/N4_missing.tsv", scratch);
    U8 *body = StrPrint(NULL,
      "%s\n"
      "phantom_scanner\ttools/bootstrap/does-not-exist.HC\tPhantomSym\tsrc/lexer.c::lexIdentifier\tPOLYC\tSTABLE\tbootstrap02-oracle\tbootstrap02-cursor-test\tbootstrap02-lexer-seam-test\tACT-POLYC-BOOTSTRAP02\n",
      SHC_GOOD_HEADER);
    SHCWriteText(p, body);
    Free(body);
    I64 rc = SHCRunValidateOn(binary, p);
    if (rc == 1) SHCVerdictPass(v, "N4_missing_source_path_FAIL");
    else         SHCVerdictFail(v, "N4_missing_source_path_FAIL",
                                  "missing source did not fail");
    Free(p);
  }

  // N5 — source outside repository (absolute path)
  {
    U8 *p = StrPrint(NULL, "%s/N5_outside.tsv", scratch);
    U8 *body = StrPrint(NULL,
      "%s\n"
      "outside_scanner\t/etc/passwd\tOutsideSym\tsrc/lexer.c::lexIdentifier\tPOLYC\tSTABLE\tbootstrap02-oracle\tbootstrap02-cursor-test\tbootstrap02-lexer-seam-test\tACT-POLYC-BOOTSTRAP02\n",
      SHC_GOOD_HEADER);
    SHCWriteText(p, body);
    Free(body);
    I64 rc = SHCRunValidateOn(binary, p);
    if (rc == 1) SHCVerdictPass(v, "N5_source_outside_repository_FAIL");
    else         SHCVerdictFail(v, "N5_source_outside_repository_FAIL",
                                  "absolute source did not fail");
    Free(p);
  }

  // N6 — empty symbol
  {
    U8 *p = StrPrint(NULL, "%s/N6_nosym.tsv", scratch);
    U8 *body = StrPrint(NULL,
      "%s\n"
      "nosym_scanner\ttools/bootstrap/bootstrap02-ident.HC\t\tsrc/lexer.c::lexIdentifier\tPOLYC\tSTABLE\tbootstrap02-oracle\tbootstrap02-cursor-test\tbootstrap02-lexer-seam-test\tACT-POLYC-BOOTSTRAP02\n",
      SHC_GOOD_HEADER);
    SHCWriteText(p, body);
    Free(body);
    I64 rc = SHCRunValidateOn(binary, p);
    if (rc == 1) SHCVerdictPass(v, "N6_missing_symbol_FAIL");
    else         SHCVerdictFail(v, "N6_missing_symbol_FAIL",
                                  "missing symbol did not fail");
    Free(p);
  }

  // N7 — invalid language
  {
    U8 *p = StrPrint(NULL, "%s/N7_badlang.tsv", scratch);
    U8 *body = StrPrint(NULL,
      "%s\n"
      "badlang_scanner\ttools/bootstrap/bootstrap02-ident.HC\tBootstrapScanIdent\tsrc/lexer.c::lexIdentifier\tPYTHON\tSTABLE\tbootstrap02-oracle\tbootstrap02-cursor-test\tbootstrap02-lexer-seam-test\tACT-POLYC-BOOTSTRAP02\n",
      SHC_GOOD_HEADER);
    SHCWriteText(p, body);
    Free(body);
    I64 rc = SHCRunValidateOn(binary, p);
    if (rc == 1) SHCVerdictPass(v, "N7_invalid_language_FAIL");
    else         SHCVerdictFail(v, "N7_invalid_language_FAIL",
                                  "PYTHON language did not fail");
    Free(p);
  }

  // N8 — invalid state
  {
    U8 *p = StrPrint(NULL, "%s/N8_badstate.tsv", scratch);
    U8 *body = StrPrint(NULL,
      "%s\n"
      "badstate_scanner\ttools/bootstrap/bootstrap02-ident.HC\tBootstrapScanIdent\tsrc/lexer.c::lexIdentifier\tPOLYC\tWONKY\tbootstrap02-oracle\tbootstrap02-cursor-test\tbootstrap02-lexer-seam-test\tACT-POLYC-BOOTSTRAP02\n",
      SHC_GOOD_HEADER);
    SHCWriteText(p, body);
    Free(body);
    I64 rc = SHCRunValidateOn(binary, p);
    if (rc == 1) SHCVerdictPass(v, "N8_invalid_state_FAIL");
    else         SHCVerdictFail(v, "N8_invalid_state_FAIL",
                                  "WONKY state did not fail");
    Free(p);
  }
}

U0 SHCSelfTestN10toN12(U8 *binary, U8 *repo_root, U8 *scratch, SHCVerdict *v)
{
  // N10 — malformed field count (5 fields)
  {
    U8 *p = StrPrint(NULL, "%s/N10_malformed.tsv", scratch);
    U8 *body = StrPrint(NULL,
      "%s\n"
      "malformed_scanner\ttools/bootstrap/bootstrap02-ident.HC\tBootstrapScanIdent\tsrc/lexer.c::lexIdentifier\tPOLYC\tSTABLE\n",
      SHC_GOOD_HEADER);
    SHCWriteText(p, body);
    Free(body);
    I64 rc = SHCRunValidateOn(binary, p);
    if (rc == 1) SHCVerdictPass(v, "N10_malformed_field_count_FAIL");
    else         SHCVerdictFail(v, "N10_malformed_field_count_FAIL",
                                  "5-field row did not fail");
    Free(p);
  }

  // N11 — output path aliases source. Construct a temp ".o" file
  // and use the EXACT generic-output path as the source (this is
  // the actual alias scenario the gate is meant to catch).
  {
    U8 *o_path = StrPrint(NULL, "%s/N11_aliased.o", scratch);
    SHCWriteText(o_path, StrPrint(NULL, ""));
    // Generic output for stage 0, cid=alias_source:
    U8 *gen_path = SHCGenericOutPath(0, "alias_source");
    U8 *p = StrPrint(NULL, "%s/N11_aliases.tsv", scratch);
    U8 *body = StrPrint(NULL,
      "%s\n"
      "alias_source\t%s\tAliasSym\tsrc/lexer.c::lexIdentifier\tPOLYC\tSTABLE\tbootstrap02-oracle\tbootstrap02-cursor-test\tbootstrap02-lexer-seam-test\tACT-POLYC-BOOTSTRAP02\n",
      SHC_GOOD_HEADER, gen_path);
    SHCWriteText(p, body);
    Free(body);
    I64 rc = SHCRunValidateOn(binary, p);
    if (rc == 1) SHCVerdictPass(v, "N11_output_aliases_source_FAIL");
    else         SHCVerdictFail(v, "N11_output_aliases_source_FAIL",
                                  ".o source did not fail");
    Free(p);
    Free(o_path);
    Free(gen_path);
  }

  // N12a — DISABLED row validates (rc=0).
  {
    U8 *p = StrPrint(NULL, "%s/N12a_disabled.tsv", scratch);
    U8 *body = StrPrint(NULL,
      "%s\n"
      "disabled_scanner\ttools/bootstrap/bootstrap02-ident.HC\tBootstrapScanIdent\tsrc/lexer.c::nonexistent\tPOLYC\tDISABLED\tbootstrap02-oracle\tbootstrap02-cursor-test\tbootstrap02-lexer-seam-test\tACT-POLYC-BOOTSTRAP02\n",
      SHC_GOOD_HEADER);
    SHCWriteText(p, body);
    Free(body);
    I64 rc = SHCRunValidateOn(binary, p);
    if (rc == 0) SHCVerdictPass(v, "N12a_disabled_row_validates_PASS");
    else         SHCVerdictFail(v, "N12a_disabled_row_validates_PASS",
                                  "DISABLED row was rejected");
    Free(p);
  }

  // N12b — DISABLED row refuses build (rc=1). Substitute the
  // registry with the disabled one and run `build` for
  // disabled_scanner; expect rc=1.
  {
    U8 *target_reg = StrPrint(NULL,
      "%s/docs/factory/SELF-HOST-COMPONENTS.tsv", repo_root);
    U8 *backup = StrPrint(NULL, "%s.bak", target_reg);
    U8 *disabled_reg = StrPrint(NULL, "%s/N12b_disabled.tsv", scratch);
    U8 *body = StrPrint(NULL,
      "%s\n"
      "disabled_scanner\ttools/bootstrap/bootstrap02-ident.HC\tBootstrapScanIdent\tsrc/lexer.c::nonexistent\tPOLYC\tDISABLED\tbootstrap02-oracle\tbootstrap02-cursor-test\tbootstrap02-lexer-seam-test\tACT-POLYC-BOOTSTRAP02\n",
      SHC_GOOD_HEADER);
    SHCWriteText(disabled_reg, body);
    Free(body);

    // Backup current registry.
    U8 *argv[4];
    argv[0] = "/bin/cp";
    argv[1] = target_reg;
    argv[2] = backup;
    argv[3] = NULL;
    U8 *out, *err;
    I64 rc = SpawnAndCapture("/bin/cp", argv, &out, &err);
    Free(out); Free(err);
    if (rc != 0) {
      SHCVerdictFail(v, "N12b_disabled_row_refuses_build_FAIL",
                      "could not back up registry");
    } else {
      argv[1] = disabled_reg;
      argv[2] = target_reg;
      rc = SpawnAndCapture("/bin/cp", argv, &out, &err);
      Free(out); Free(err);
      if (rc != 0) {
        SHCVerdictFail(v, "N12b_disabled_row_refuses_build_FAIL",
                        "could not substitute registry");
      } else {
        // Run build for disabled_scanner. We invoke via env(1)
        // to force COMPONENT=disabled_scanner STAGE=0 in the
        // child, overriding whatever the parent inherited.
        // SpawnAndCapture has no envp parameter, so env is the
        // portable way to inject env into the child without
        // shelling out.
        U8 *bld_argv[8];
        bld_argv[0] = "/usr/bin/env";
        bld_argv[1] = "COMPONENT=disabled_scanner";
        bld_argv[2] = "STAGE=0";
        bld_argv[3] = binary;
        bld_argv[4] = "build";
        bld_argv[5] = target_reg;
        bld_argv[6] = NULL;
        out = NULL; err = NULL;
        rc = SpawnAndCapture("/usr/bin/env", bld_argv, &out, &err);
        Free(out); Free(err);
        // Restore.
        U8 *restore_argv[4];
        restore_argv[0] = "/bin/cp";
        restore_argv[1] = backup;
        restore_argv[2] = target_reg;
        restore_argv[3] = NULL;
        I64 rrc = SpawnAndCapture("/bin/cp", restore_argv, &out, &err);
        Free(out); Free(err);
        if (rc == 1 && rrc == 0) {
          SHCVerdictPass(v, "N12b_disabled_row_refuses_build_FAIL");
        } else {
          SHCVerdictFail(v, "N12b_disabled_row_refuses_build_FAIL",
                          "build did not refuse DISABLED");
        }
      }
    }
    Free(backup); Free(target_reg); Free(disabled_reg);
  }
}

U0 SHCSelfTest(U8 *binary, U8 *repo_root)
{
  U8 *scratch = StrPrint(NULL, "%s/build/shc-selftest", repo_root);
  SHCEnsureDir(scratch);
  SHCVerdict v;
  v.pass = 0;
  v.fail = 0;

  SHCSelfTestN1toN8(binary, repo_root, scratch, &v);
  SHCSelfTestN10toN12(binary, repo_root, scratch, &v);

  // N2 — unknown component via build. Substitute the registry
  // with one that does NOT contain `nonexistent_component`, then
  // build that id; expect rc=1.
  {
    U8 *target_reg = StrPrint(NULL,
      "%s/docs/factory/SELF-HOST-COMPONENTS.tsv", repo_root);
    U8 *backup = StrPrint(NULL, "%s.bak", target_reg);
    U8 *disabled_reg = StrPrint(NULL, "%s/N2_unknown.tsv", scratch);
    U8 *body = StrPrint(NULL,
      "%s\n"
      "enabled_scanner\ttools/bootstrap/bootstrap02-ident.HC\tBootstrapScanIdent\tsrc/lexer.c::lexIdentifier\tPOLYC\tSTABLE\tbootstrap02-oracle\tbootstrap02-cursor-test\tbootstrap02-lexer-seam-test\tACT-POLYC-BOOTSTRAP02\n",
      SHC_GOOD_HEADER);
    SHCWriteText(disabled_reg, body);
    Free(body);

    U8 *argv[4];
    argv[0] = "/bin/cp";
    argv[1] = target_reg;
    argv[2] = backup;
    argv[3] = NULL;
    U8 *out, *err;
    I64 rc = SpawnAndCapture("/bin/cp", argv, &out, &err);
    Free(out); Free(err);
    if (rc != 0) {
      SHCVerdictFail(&v, "N2_unknown_component_lookup_FAIL",
                      "could not back up registry");
    } else {
      argv[1] = disabled_reg;
      argv[2] = target_reg;
      rc = SpawnAndCapture("/bin/cp", argv, &out, &err);
      Free(out); Free(err);
      if (rc != 0) {
        SHCVerdictFail(&v, "N2_unknown_component_lookup_FAIL",
                        "could not substitute registry");
      } else {
        // Build nonexistent_component.
        U8 *bld_argv[8];
        bld_argv[0] = "/usr/bin/env";
        bld_argv[1] = "COMPONENT=nonexistent_component";
        bld_argv[2] = "STAGE=0";
        bld_argv[3] = binary;
        bld_argv[4] = "build";
        bld_argv[5] = target_reg;
        bld_argv[6] = NULL;
        out = NULL; err = NULL;
        rc = SpawnAndCapture("/usr/bin/env", bld_argv, &out, &err);
        Free(out); Free(err);
        // Restore.
        U8 *restore_argv[4];
        restore_argv[0] = "/bin/cp";
        restore_argv[1] = backup;
        restore_argv[2] = target_reg;
        restore_argv[3] = NULL;
        I64 rrc = SpawnAndCapture("/bin/cp", restore_argv, &out, &err);
        Free(out); Free(err);
        // Clean up the backup file (we don't want to leave a .bak
        // residue in the repository tree).
        U8 *rm_argv[3];
        rm_argv[0] = "/bin/rm";
        rm_argv[1] = backup;
        rm_argv[2] = NULL;
        U8 *out2 = NULL, *err2 = NULL;
        SpawnAndCapture("/bin/rm", rm_argv, &out2, &err2);
        Free(out2); Free(err2);
        if (rc == 1 && rrc == 0) {
          SHCVerdictPass(&v, "N2_unknown_component_lookup_FAIL");
        } else {
          SHCVerdictFail(&v, "N2_unknown_component_lookup_FAIL",
                          "build did not reject unknown component");
        }
      }
    }
    Free(backup); Free(target_reg); Free(disabled_reg);
  }

  // N9 — unknown stage. Build identifier_scanner with STAGE=7.
  {
    U8 *bld_argv[8];
    bld_argv[0] = "/usr/bin/env";
    bld_argv[1] = "COMPONENT=identifier_scanner";
    bld_argv[2] = "STAGE=7";
    bld_argv[3] = binary;
    bld_argv[4] = "build";
    bld_argv[5] = NULL;
    bld_argv[6] = NULL;
    bld_argv[7] = NULL;
    U8 *out, *err;
    I64 rc = SpawnAndCapture("/usr/bin/env", bld_argv, &out, &err);
    Free(out); Free(err);
    if (rc == 2) {
      SHCVerdictPass(&v, "N9_unknown_stage_FAIL");
    } else {
      SHCVerdictFail(&v, "N9_unknown_stage_FAIL",
                      "build did not reject STAGE=7");
    }
  }

  "----\n";
  "SHC_SELFTEST_PASS=%d\n", v.pass;
  "SHC_SELFTEST_FAIL=%d\n", v.fail;
  if (v.fail == 0) "STATUS=PASS\n";
  else             "STATUS=FAIL\n";

  Free(scratch);
  if (v.fail != 0) Exit(1);
}

// ============================================================
// Main
// ============================================================

I32 main(I32 argc, U8 **argv)
{
  if (argc < 2) {
    "usage: selfhost-component <op> [args]\n";
    "  ops:\n";
    "    validate [REGISTRY]      -- validate registry\n";
    "    build    [REGISTRY]      -- build (env COMPONENT STAGE)\n";
    "    test     [REGISTRY]      -- test  (env COMPONENT STAGE)\n";
    "    selftest                  -- 13 frozen negative controls\n";
    Exit(2);
  }

  U8 *op = argv[1];

  U8 *repo_root = GetEnv("SHC_REPO_ROOT");
  if (!repo_root) repo_root = ".";

  U8 *registry = GetEnv("SHC_REGISTRY");
  if (!registry) {
    registry = StrPrint(NULL, "%s/docs/factory/SELF-HOST-COMPONENTS.tsv",
                          repo_root);
  }

  U8 *component = GetEnv("COMPONENT");
  U8 *stage_str = GetEnv("STAGE");

  if (!StrCmp(op, "validate")) {
    if (argc >= 3) registry = argv[2];
    SHCOpValidate(registry, repo_root);
    Exit(0);
  }
  if (!StrCmp(op, "build")) {
    if (argc >= 3) registry = argv[2];
    SHCOpBuild(registry, repo_root, component, stage_str);
    Exit(0);
  }
  if (!StrCmp(op, "test")) {
    if (argc >= 3) registry = argv[2];
    SHCOpTest(registry, repo_root, component, stage_str);
    Exit(0);
  }
  if (!StrCmp(op, "selftest")) {
    U8 *bin = GetEnv("SHC_BIN");
    if (!bin) bin = "build/selfhost-component";
    SHCSelfTest(bin, repo_root);
    Exit(0);
  }

  "FAIL: unknown op '%s'\n", op;
  Exit(2);
  // Unreachable: Exit() does not return, but this defensive
  // return silences the "control may reach end of non-void
  // function" warning and makes the CLI contract explicit.
  return 2;
}
