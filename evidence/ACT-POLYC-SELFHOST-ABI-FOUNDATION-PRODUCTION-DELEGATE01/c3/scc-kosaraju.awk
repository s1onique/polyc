# scc-kosaraju.awk -- an INDEPENDENT strongly-connected-component
# recomputation for ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01.
#
# This is deliberately a DIFFERENT algorithm from any closure-based counting:
# it is the two-pass Kosaraju algorithm over the ORIGINAL individual edge IDs,
# so it can only agree with another method if both are reading the same
# original edge set.
#
# INPUT : a TSV of edge_id, src_id, dst_id (tab separated, no header).
#         Optionally, a SECOND file passed with -v NODEFILE=<path> holding the
#         FULL node table (one node_id per line). Every node in that table is
#         included, so a node with no mandatory edge becomes its own
#         singleton SCC. This is what makes the SCC count comparable with the
#         frozen CENSUS01 baseline (52 nodes, 34 SCCs, largest 19).
# OUTPUT: one line per SCC:  SCC_INDEX <tab> SIZE <tab> SPACE_SEPARATED_NODES
#
# Algorithm:
#   pass 1: DFS over the ORIGINAL edges, record finish order
#   pass 2: DFS over the REVERSED edges in decreasing finish order
#
# Usage: awk -f scc-kosaraju.awk nodes.txt edges.tsv

BEGIN { FS = "\t"; n = 0; comp = 0; nn = 0; infile = 0 }

# ---- the full node table, if one was supplied --------------------------
# The node file is the FIRST input file (one node_id per line); the edge file
# is the SECOND. The boundary is detected with an explicit file index so the
# two streams are never confused.
FILENAME == ARGV[1] {
  if (NF < 1) next
  if (!($1 in node)) { node[$1] = ++nn; nname[nn] = $1 }
  next
}

# ---- read the edge set -------------------------------------------------
{
  if (NF < 3) next
  e = $1; s = $2; d = $3
  if (!(e in seen)) {
    seen[e] = 1
    n++
    eid[n] = e
    esrc[e] = s
    edst[e] = d
    if (!(s in node)) { node[s] = ++nn; nname[nn] = s }
    if (!(d in node)) { node[d] = ++nn; nname[nn] = d }
    adj[node[s]] = adj[node[s]] " " node[d]
    radj[node[d]] = radj[node[d]] " " node[s]
  }
}

END {
  # ---- pass 1: iterative DFS, recording finish order -------------------
  for (i = 1; i <= nn; i++) visited[i] = 0
  fo = 0
  for (root = 1; root <= nn; root++) {
    if (visited[root]) continue
    # stack entries: "node iterator-rest"
    stack[sp] = root; rest[sp] = adj[root]; sp++
    visited[root] = 1
    while (sp > 0) {
      top = sp - 1
      split(rest[top], parts, " ")
      nxt = 0
      for (p = 1; p <= length(parts); p++) {
        if (parts[p] != "" && !visited[parts[p]]) { nxt = parts[p]; break }
      }
      if (nxt != 0) {
        visited[nxt] = 1
        stack[sp] = nxt; rest[sp] = adj[nxt]; sp++
      } else {
        order[++fo] = stack[top]
        sp--
      }
    }
  }

  # ---- pass 2: DFS over the reversed edges in decreasing finish order --
  for (i = 1; i <= nn; i++) visited[i] = 0
  for (oi = fo; oi >= 1; oi--) {
    root = order[oi]
    if (visited[root]) continue
    comp++
    size = 0
    members = ""
    stack[sp] = root; rest[sp] = radj[root]; sp++
    visited[root] = 1
    while (sp > 0) {
      top = sp - 1
      cur = stack[top]
      size++
      members = members " " nname[cur]
      split(rest[top], parts, " ")
      for (p = 1; p <= length(parts); p++) {
        v = parts[p]
        if (v != "" && !visited[v]) {
          visited[v] = 1
          stack[sp] = v; rest[sp] = radj[v]; sp++
        }
      }
      sp--
    }
    print "SCC", comp, size, members
    csize[comp] = size
  }

  # ---- summary ---------------------------------------------------------
  print "SCC_COUNT", comp
  max = 0
  for (c = 1; c <= comp; c++) if (csize[c] > max) max = csize[c]
  print "LARGEST_SCC", max
  print "NODE_COUNT", nn
}
