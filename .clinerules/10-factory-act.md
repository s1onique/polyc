# Cline ACT execution

When executing an ACT:

1. Read the complete ACT before editing.
2. Treat explicit SHALL / MUST / FORBIDDEN / HALT clauses as binding task
   boundaries.
3. Execute entry identity and predecessor gates first.
4. Do not edit production code before a required principal RED exists.
5. Use the real production seam when the ACT requires a real-seam witness.
6. On a HALT condition, stop implementation immediately and collect the
   bounded closure evidence required by the ACT.
7. Never continue into a later phase merely because the intended final
   implementation is obvious.
8. Never weaken an ACT gate or test to obtain PASS.
9. Do not silently widen file scope.
10. Report exact commands/results used for closure-critical claims.

Tool approval is not task authorization.
The ability to edit a file does not mean the ACT authorizes editing it.
