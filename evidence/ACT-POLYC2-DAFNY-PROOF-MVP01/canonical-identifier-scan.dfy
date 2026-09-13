// =====================================================================
// ACT-POLYC2-DAFNY-PROOF-MVP01
//
// Dafny model of the frozen PolyC identifier scanner contract.
//
// This is a MODEL of the frozen contract documented in
// evidence/ACT-POLYC2-DAFNY-PROOF-MVP01/lexical-contract-source.txt
// and evidence/ACT-POLYC-BOOTSTRAP02/c1/identifier-contract.txt.
//
// It is NOT a formal verification of the PolyC / HolyC
// implementation in src/lexer.c.
//
// Domain correspondence:
//   MODEL_INPUT_DOMAIN          = seq<byte>
//   IMPLEMENTATION_INPUT_DOMAIN = U8* + explicit length
//   DOMAIN_CORRESPONDENCE_CLAIM = SPECIFICATION_ALIGNMENT_ONLY
//
// Dafny 4.11.0 does not export a built-in `byte` type. We
// declare byte as a bounded int newtype (range 0..255) with
// witness 0; this preserves the same numeric domain as the
// PolyC U8 and is used here WITHOUT invoking any Unicode /
// locale semantics. Only ASCII ranges
// [0x30..0x39], [0x41..0x5a], [0x5f], [0x61..0x7a], [0x24]
// are ever tested.
//
// Algorithm correspondence to production
// ---------------------------------------
// Production src/lexer.c::lexIdentifier (default ctype path):
//
//   while (ch && (isalnum(ch) || ch == '_' || ch == '$')) {
//       i++;
//       ch = lexNextChar(l);
//   }
//
// In Dafny this becomes the pair (ScanIdentStart, ScanRest):
//   ScanIdentEnd(s,start) =
//     ScanRest(s, ScanIdentStart(s,start))
//
// where ScanIdentStart scans ONE identifier-start byte
// (requires it to exist) and ScanRest scans zero or more
// identifier-continuation bytes (requires no first byte).
// =====================================================================

newtype byte = x: int | 0 <= x < 256 witness 0

// ----- byte-domain predicates (no ctype.h, no Unicode) -----

predicate IsAsciiUpper(b: byte)
{
  0x41 <= b as int <= 0x5a
}

predicate IsAsciiLower(b: byte)
{
  0x61 <= b as int <= 0x7a
}

predicate IsAsciiAlpha(b: byte)
{
  IsAsciiUpper(b) || IsAsciiLower(b)
}

predicate IsAsciiDigit(b: byte)
{
  0x30 <= b as int <= 0x39
}

// Frozen production identifier-start predicate:
//   c == '_' || ('A' <= c <= 'Z') || ('a' <= c <= 'z')
predicate IsIdentStart(b: byte)
{
  b as int == 0x5f || IsAsciiAlpha(b)
}

// Frozen production identifier-continuation predicate:
//   prod_is_ident_start(b) || b == '$' || ('0' <= b <= '9')
predicate IsIdentContinue(b: byte)
{
  IsIdentStart(b) || b as int == 0x24 || IsAsciiDigit(b)
}

// ----- the scanner function (Dafny function = total & deterministic) -----

// ScanIdentStart consumes exactly one identifier-start byte
// from s[start] and returns start + 1. Precondition:
// s[start] must be a valid identifier-start byte.
function ScanIdentStart(s: seq<byte>, start: nat): nat
  requires start < |s|
  requires IsIdentStart(s[start])
  ensures ScanIdentStart(s, start) == start + 1
  ensures ScanIdentStart(s, start) <= |s|
  ensures IsIdentStart(s[start])
{
  start + 1
}

// ScanRest scans zero or more identifier-continuation bytes
// from s[i] and returns the first position past the maximal
// run. Precondition: i must be a valid position in s.
// Unlike ScanIdentStart, ScanRest does NOT require s[i] to
// be a continuation byte; it may stop immediately.
function ScanRest(s: seq<byte>, i: nat): nat
  requires i <= |s|
  decreases |s| - i
  ensures i <= ScanRest(s, i) <= |s|
  ensures forall k :: i <= k < ScanRest(s, i) ==> IsIdentContinue(s[k])
  ensures ScanRest(s, i) == |s| || !IsIdentContinue(s[ScanRest(s, i)])
{
  if i < |s| && IsIdentContinue(s[i]) then
    ScanRest(s, i + 1)
  else
    i
}

// ScanIdentEnd returns the first index strictly past the
// maximal identifier beginning at `start`. Pre: start must
// be in range and the byte at start must satisfy
// IsIdentStart.
//
// The function composes ScanIdentStart (consumes exactly one
// start byte) with ScanRest (consumes zero or more
// continuation bytes).
function ScanIdentEnd(s: seq<byte>, start: nat): nat
  requires start < |s|
  requires IsIdentStart(s[start])
  ensures start < ScanIdentEnd(s, start) <= |s|
  ensures IsIdentStart(s[start])
  ensures forall k :: start <= k < ScanIdentEnd(s, start)
              ==> IsIdentContinue(s[k])
  ensures ScanIdentEnd(s, start) == |s|
       || !IsIdentContinue(s[ScanIdentEnd(s, start)])
{
  var mid := ScanIdentStart(s, start);
  ScanRest(s, mid)
}

// IsValidScanResult is an abstract relation between the
// input sequence, scan start, and resulting endpoint.
//
// It does NOT model the production lexIdentifier ABI.
// Production correspondence to l->cur_strlen, cursor state,
// lexRewindChar behavior, and the TK_IDENT return value
// is deferred to ACT-POLYC2-DAFNY-CORRESPONDENCE01.
predicate IsValidScanResult(s: seq<byte>, start: int, end: int)
{
  0 <= start < |s|
  && start < end <= |s|
  && IsIdentStart(s[start])
  && (forall i :: start <= i < end ==> IsIdentContinue(s[i]))
  && (end == |s| || !IsIdentContinue(s[end]))
}

// =====================================================================
// THEOREMS (P1..P6) — the MVP theorem family
//
// Each lemma explicitly invokes ScanIdentEnd under the
// required precondition so that the call site (and not the
// lemma's own caller) is the locus of the precondition
// obligation. The lemma bodies are intentionally trivial:
// Dafny's verifier uses ScanIdentEnd's postcondition directly.
// =====================================================================

// P1 — Bounds:
//   start < end <= |s|
lemma LemmaBounds(s: seq<byte>, start: nat)
  requires start < |s|
  requires IsIdentStart(s[start])
  ensures start < ScanIdentEnd(s, start) <= |s|
{
  var _ := ScanIdentEnd(s, start);
}

// P2 — Progress:
//   ScanIdentEnd consumes at least one element.
lemma LemmaProgress(s: seq<byte>, start: nat)
  requires start < |s|
  requires IsIdentStart(s[start])
  ensures ScanIdentEnd(s, start) > start
{
  var _ := ScanIdentEnd(s, start);
}

// P3 — Consumed-region validity:
//   Every consumed position [start .. end) is an
//   identifier-continuation byte.
lemma LemmaConsumed(s: seq<byte>, start: nat)
  requires start < |s|
  requires IsIdentStart(s[start])
  ensures forall k :: start <= k < ScanIdentEnd(s, start)
              ==> IsIdentContinue(s[k])
{
  var _ := ScanIdentEnd(s, start);
}

// P4 — Maximality:
//   end == |s|  OR  !IsIdentContinue(s[end]).
lemma LemmaMaximal(s: seq<byte>, start: nat)
  requires start < |s|
  requires IsIdentStart(s[start])
  ensures ScanIdentEnd(s, start) == |s|
       || !IsIdentContinue(s[ScanIdentEnd(s, start)])
{
  var _ := ScanIdentEnd(s, start);
}

// P5 — No early stop:
//   For every mid strictly inside the consumed region,
//   s[mid] is a continuation byte — therefore the scan
//   could not have validly stopped there.
lemma LemmaNoEarlyStop(s: seq<byte>, start: nat)
  requires start < |s|
  requires IsIdentStart(s[start])
  ensures forall mid :: start < mid < ScanIdentEnd(s, start)
              ==> IsIdentContinue(s[mid])
{
  var _ := ScanIdentEnd(s, start);
}

// P6 — Determinism:
//   For identical input and start position, the formal
//   scan result is unique.
lemma LemmaDeterministic(s: seq<byte>, start: nat, end1: nat, end2: nat)
  requires start < |s|
  requires IsIdentStart(s[start])
  requires end1 == ScanIdentEnd(s, start)
  requires end2 == ScanIdentEnd(s, start)
  ensures end1 == end2
{
  var _ := ScanIdentEnd(s, start);
}
