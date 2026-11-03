# CORRECTION03 C4 ROUND 2 -- THE INTERIM HEAD FIELD CLARIFICATION

This file is FORWARD-ONLY evidence. It does NOT modify, rewrite, or
endorse any earlier committed artifact. The committed
`c4/interim-status.md` and its bytes are preserved exactly as committed.

## 1. THE FINDING

The second independent Codex review raised a P2 finding about the
`FINAL_HEAD` field of the committed `c4/interim-status.md`:

```text
FINAL_HEAD                          1cd483975c38d45a1085b5a9ebb707fae7e946b0
```

The document is committed by `b5fe53867db2b4b0a27d2639396e836d7e59c9d8`,
so the named SHA is the commit BEFORE the one that contains the
document.

## 2. WHY THE FIELD CANNOT NAME ITS OWN COMMIT

The field names a COMMIT SHA. The document is a file inside a COMMIT. The
SHA of a commit is computed from the commit's content, which includes
the document's bytes. A document that contains the SHA of the commit
that contains it would therefore have to contain a value that changes
when it is written, which is the classic self-reference.

The repository's canonical rule (`AGENTS.md`, "No SHA-of-self claims",
and `docs/factory/DOCTRINE.md` §22, F-GIT-IDENTITY) states this
directly: no committed artifact may claim the SHA of the commit that
contains it.

## 3. WHAT THE FIELD ACTUALLY NAMES

The `FINAL_HEAD` field names the LAST commit of the C4 REMEDIATION
WORK, which is the last commit that changed the production or
measurement subject. In the committed interim status that is the
commit `1cd483975c38d45a1085b5a9ebb707fae7e946b0`, which recorded the
parser and lexer conservation measurement.

The field is therefore ACCURATE for what it names: the last commit of
the remediation WORK. It is not, and cannot be, the commit that contains
the document. The intervening commit `b5fe53867db2b4b0a27d2639396e836d7e59c9d8`
added ONLY the evidence document, the covering manifest and the gate
logs. It changed NO production or measurement subject.

## 4. THE RESOLUTION

```text
The committed FINAL_HEAD field names the last commit of the C4
remediation WORK. It does NOT name, and cannot name, the commit that
contains the interim status document. A downstream reader who needs
the commit that contains the document MUST query the Git history; they
must not read it from the document.
```

The committed document is NOT modified. F14 forbids rewriting historical
evidence, and the field is not wrong: it names what it says it names.

## 5. THE FORWARD-ONLY CONVENTION ADOPTED

Every status document in this ACT's forward-only evidence uses the
following field names, so that no reader can mistake one for the other:

```text
WORK_FINAL_HEAD   the last commit that changed the production or
                  measurement subject
CONTAINED_BY      NOT RECORDED. The commit that contains this document
                  is discovered from the Git history.
```

The `c4r2/interim-status-r2.md` document of this remediation round uses
those names.
