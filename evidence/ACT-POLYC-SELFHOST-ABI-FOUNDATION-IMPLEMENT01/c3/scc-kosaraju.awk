# Kosaraju SCC decomposition (C3 independent algorithm).
# Deliberately DIFFERENT from the C2 transitive-closure implementation.
# usage: awk -v nodes=<graph-nodes.tsv> -v edges=<edge-tsv> -f scc-kosaraju.awk
function dfs1(v,   i) {
  vis[v]=1
  for (i=1;i<=outdeg[v];i++) if (!vis[out[v,i]]) dfs1(out[v,i])
  order[++ordn]=v
}
function dfs2(v, root,   i) {
  comp[v]=root
  for (i=1;i<=rdeg[v];i++) if (!comp[rin[v,i]]) dfs2(rin[v,i], root)
}
BEGIN{
  FS="\t"; n=0
  while ((getline line < nodes) > 0) {
    split(line, f, "\t")
    if (f[1]=="node_id") continue
    n++; id[n]=f[1]; ix[f[1]]=n
  }
  close(nodes)
  while ((getline line < edges) > 0) {
    split(line, f, "\t")
    if (f[1]=="edge_id") continue
    a=ix[f[2]]; b=ix[f[3]]
    if (a && b) { out[a,++outdeg[a]]=b; rin[b,++rdeg[b]]=a }
  }
  close(edges)
  for (v=1;v<=n;v++) vis[v]=0
  ordn=0
  for (v=1;v<=n;v++) if (!vis[v]) dfs1(v)
  for (v=1;v<=n;v++) comp[v]=0
  nscc=0
  for (i=ordn;i>=1;i--) { v=order[i]; if (!comp[v]) { nscc++; dfs2(v, nscc) } }
  for (v=1;v<=n;v++) { members[comp[v]]=members[comp[v]] " " id[v]; sz[comp[v]]++ }
  largest=0; big=0
  for (s=1;s<=nscc;s++) { printf "KOSARAJU_SCC\t%d\t%d\t%s\n", s, sz[s], members[s]; if (sz[s]>largest) { largest=sz[s]; big=s } }
  printf "SUMMARY\tscc_count\t%d\n", nscc
  printf "SUMMARY\tlargest_size\t%d\n", largest
  printf "SUMMARY\tlargest_members\t%s\n", members[big]
}
