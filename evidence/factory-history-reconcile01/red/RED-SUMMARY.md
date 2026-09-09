# RED SUMMARY — ACT-POLYC-FACTORY-HISTORY-RECONCILE01

## Principal RED: divergent authoritative topology

The repository contains two independently rewritten `main` histories
that share patch-equivalent content but have different commit
identities. Neither lineage is an ancestor of the other.

## Reproduction (frozen at ENTRY)

```
$ git rev-list --left-right --count HEAD...origin/main
383	374

$ git rev-list --left-right --cherry-mark --count HEAD...origin/main
14	5	738

$ git merge-base --is-ancestor HEAD origin/main ; echo $?
1

$ git merge-base --is-ancestor origin/main HEAD ; echo $?
1
```

Both directions fail (rc=1). Ordinary `git push origin HEAD:main`
would be refused by the receiving Git server because the receiving
end (origin/main) is not an ancestor of the proposed new tip.

## Patch equivalence reduction

Using `--cherry-mark` against the two archive tips:

```
$ git rev-list --left-right --cherry-mark --count \
    archive/local-main-before-reconcile...archive/origin-main-before-reconcile
13	5	738
```

* 738 commits are patch-equivalent (`=`) — no individual decision
  required; both lineages already share the same content
* 13 commits are local-only (`<`) — 8 substantive + 5 merge-topology
* 5 commits are remote-only (`>`) — all 5 are merge-topology

## Conclusion

The RED is real, reproducible, and observer-independent.

Substantive unique local changes (8):
  PARITY01 RED/IMPL/EVIDENCE/CLOSE chain (0778954..590f37b)
  ROADMAP self-host pivot + wording tightening (62d5128, 28c778e)
  INTOPS01 close-with-addendum (adb202c)

Merge-topology collisions (10 = 5 local + 5 remote):
  All 5 pairs have identical trees (verified by SHA).
  Pure parent-identity differences from rewritten history.

No remote-only substantive changes:
  Remote unique non-merge commits = 0 (verified).
  All FLOAT01-CORRECTION01 content already present locally via
  the 738 cherry-equivalent path.

## RED commit

The first ACT execution commit freezes this observation.

ACT: ACT-POLYC-FACTORY-HISTORY-RECONCILE01
ACT-Phase: RED
