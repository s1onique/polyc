# scc-closure.awk -- a SECOND, INDEPENDENT strongly-connected-component
# algorithm for ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01.
#
# This is deliberately a DIFFERENT algorithm from the Kosaraju implementation
# in scc-kosaraju.awk: it computes the full TRANSITIVE CLOSURE of the edge
# set and then groups the nodes by their reachability signature. Two nodes
# are in the same SCC iff each reaches the other, i.e. iff their mutual
# reachability sets are equal.
#
# It reads the ORIGINAL individual edge IDs; it never subtracts a count.
#
# INPUT : the full node table (one node_id per line) followed by the edge
#         table (edge_id, src_id, dst_id).
# OUTPUT: SCC_INDEX <tab> SIZE <tab> SPACE_SEPARATED_NODES
#         SCC_COUNT <n>
#         LARGEST_SCC <n>
#         NODE_COUNT <n>
#
# Usage: awk -f scc-closure.awk nodes.txt edges.tsv

BEGIN { FS = "\t"; nn = 0 }

FILENAME == ARGV[1] {
  if (NF < 1) next
  if (!($1 in node)) { node[$1] = ++nn; nname[nn] = $1 }
  next
}

{
  if (NF < 3) next
  s = $2; d = $3
  if (!(s in node)) { node[s] = ++nn; nname[nn] = s }
  if (!(d in node)) { node[d] = ++nn; nname[nn] = d }
  adj[node[s]] = adj[node[s]] " " node[d]
}

END {
  # ---- transitive closure (Warshall over the adjacency matrix) ---------
  # reach[i][j] = 1 when i reaches j (including the reflexive edge i->i).
  for (i = 1; i <= nn; i++) reach[i, i] = 1
  for (i = 1; i <= nn; i++) {
    m = split(adj[i], a, " ")
    for (k = 1; k <= m; k++) if (a[k] != "") reach[i, a[k]] = 1
  }
  for (k = 1; k <= nn; k++)
    for (i = 1; i <= nn; i++)
      if (reach[i, k])
        for (j = 1; j <= nn; j++)
          if (reach[k, j]) reach[i, j] = 1

  # ---- group by the mutual-reachability signature ----------------------
  # The signature of a node is the SET of nodes it reaches that also reach
  # it; two nodes share an SCC iff those sets are identical.
  for (i = 1; i <= nn; i++) {
    sig = ""
    for (j = 1; j <= nn; j++)
      if (reach[i, j] && reach[j, i]) sig = sig " " j
    if (!(sig in seen)) {
      seen[sig] = ++nscc
      members[nscc] = ""
      csize[nscc] = 0
    }
    c = seen[sig]
    members[c] = members[c] " " nname[i]
    csize[c]++
  }

  max = 0
  for (c = 1; c <= nscc; c++) {
    print "SCC", c, csize[c], members[c]
    if (csize[c] > max) max = csize[c]
  }
  print "SCC_COUNT", nscc
  print "LARGEST_SCC", max
  print "NODE_COUNT", nn
}
