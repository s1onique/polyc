=== C1 FIXTURES ===

Fixture files under fixtures/ reproduce the RED conditions byte-exactly.

  red1-valid-halt-close-message.b64
      base64 of the synthetic RED-1 CLOSE commit message (a real commit
      message, which ends with a trailing newline). Stored base64-encoded
      so that `git diff --check` patch hygiene does not reject the
      fixture's authentic trailing blank line.
      decoded sha256 = 4d4928731a9dfedb72cbff2086c719b64d665695b4049f883576ed74e7f2097a
      decode with: base64 -d < red1-valid-halt-close-message.b64

  red2-complete-halt-footer.txt
      A syntactically complete Factory HALT footer (RED-2 fail-open).

  red3-split-act-block.txt
      ACT / ACT-Phase / ACT-Verdict separated by blank lines (RED-3).

  control-literal-act-in-prose.txt
      An ordinary message whose BODY mentions a literal "ACT:" in prose.
      This MUST remain MODE=NON_ACT PASS after the repair.
