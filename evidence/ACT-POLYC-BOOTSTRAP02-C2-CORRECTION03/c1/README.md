# ACT-POLYC-BOOTSTRAP02-C2-CORRECTION03 — C1 RED — README

This packet records the bounded production-source
defect identified in the re-review of
ACT-POLYC-BOOTSTRAP02-C2-CORRECTION02, and proposes
the bounded forward correction.

Reviewer verdict (re-review of CORRECTION02):

  R1 l->start_after divergence: P2 / cleanup,
       BLOCKS_NEXT=NO. The grep audit is complete;
       no consumer reads l->start between
       lexIdentifier and the next lexNextChar.

  R2 l->ptr_after at EOF: RE-CLASSIFIED from P1
       (latent) to P0 (production semantic defect).
       The +1 advance on EOF is undefined behavior
       per the C memory model: `src + 4` may be a
       one-past-end pointer that does not permit
       dereference. The current harness masks this
       because it `memset`s the buffer to zero,
       producing an accidental accessible byte at
       src+4. In production AoStr buffers, src+4
       need not be accessible.

  C3 EVIDENCE = AUTHORIZED (broad corpus while the
       bug is known is useful).

  C4 CLOSE = BLOCKED until R2 is fixed.

This correction ACT is bounded to:

1. ONE bounded forward correction (not two): fix
   the stage1 branch of `src/lexer.c::lexIdentifier`
   to maintain BOTH `l->ptr` and `l->start` in the
   legacy invariant.

2. Achieve 6/6 byte-identical output from the real
   production-Lexer seam harness (no residue).

3. Update C2 evidence:
   - Section E predicates transition from residue
     to PASS_BY_PILLAR_B_PRIME.
   - Section E' adds NON_EOF_PRODUCTION_CURSOR_
     EQUIVALENCE, EOF_TOKEN_RESULT_EQUIVALENCE,
     EOF_CURSOR_STATE_EQUIVALENCE, EOF_POINTER_
     SAFETY as separate predicates.

The reviewer authorized the production-source
mutation in this single bounded ACT.

Files:

* `defect-p0-eof-cursor-ub.txt`
* `defect-r1-start-after.txt` (now classified as
  P2 cleanup folded into the same fix)
* `corrected-stage1-branch.txt`
* `desired-postcondition.txt`
* `required-result.txt`
