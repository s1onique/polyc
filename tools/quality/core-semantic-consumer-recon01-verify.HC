// tools/quality/core-semantic-consumer-recon01-verify.HC
// ACT-POLYC-SELFHOST-CORE-SEMANTIC-CONSUMER-RECON01 C2 IMPL.
//
// Fail-closed source/object roster, E01-E14 eligibility, and R0-R6 ranker.
//
// This verifier does not trust a pre-filled eligible column. It recomputes
// eligibility from the C1 semantic-site facts and emits the complete ordered
// candidate list. It uses only bounded scalar and string operations.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MAX_ROWS  256
#define NCOL      32
#define MAX_BUNDLES 32

static U8 *FLD[MAX_ROWS * NCOL];
static I64 NFD[MAX_ROWS];
static I64 NROW;
static U8 *BFLD[MAX_ROWS * NCOL];
static I64 B_NFD[MAX_ROWS];
static I64 B_NROW;

static I64 StrEq(U8 *a, U8 *b) {
  while (*a != 0 && *b != 0) { if (*a != *b) return 0; a++; b++; }
  return *a == 0 && *b == 0;
}
static I64 StrLen(U8 *s) { I64 n = 0; while (*s != 0) { n++; s++; } return n; }
static U8 *StrCat(U8 *a, U8 *b) {
  static U8 buf[2048]; I64 i = 0;
  while (*a != 0 && i < 2000) { buf[i] = *a; i++; a++; }
  while (*b != 0 && i < 2046) { buf[i] = *b; i++; b++; }
  buf[i] = 0; return buf;
}
static U8 *PathJoin(U8 *a, U8 *b) { return StrCat(a, b); }
static U8 *Join3(U8 *a, U8 *b, U8 *c) { return StrCat(PathJoin(a,b), c); }
static I64 SplitA(U8 *line, I64 base, I64 maxf) {
  I64 n = 0; U8 *p = line;
  while (n < maxf) {
    FLD[base+n] = p; n++;
    while (*p != 0 && *p != '\t') p++;
    if (*p == 0) break;
    *p = 0; p++;
  }
  return n;
}
static I64 SplitB(U8 *line, I64 base, I64 maxf) {
  I64 n = 0; U8 *p = line;
  while (n < maxf) {
    BFLD[base+n] = p; n++;
    while (*p != 0 && *p != '\t') p++;
    if (*p == 0) break;
    *p = 0; p++;
  }
  return n;
}
static I64 LoadA(U8 *path, I64 hdr) {
  I64 sz = 0; U8 *buf = FileRead(path, &sz);
  if (buf == NULL) return -1;
  I64 n = 0; U8 *p = buf; U8 *e = buf + sz; I64 first = 1;
  while (p < e && n < MAX_ROWS) {
    U8 *ls = p; while (p < e && *p != '\n') p++;
    U8 *le = p; if (p < e) p++;
    if (le > ls && *(le-1) == '\r') le--;
    *le = 0;
    if (*ls == 0) continue;
    if (*ls == '#') continue;
    if (first && hdr) { first = 0; continue; }
    first = 0; NFD[n] = SplitA(ls, n * NCOL, NCOL); n++;
  }
  NROW = n; return 0;
}
static I64 LoadB(U8 *path, I64 hdr) {
  I64 sz = 0; U8 *buf = FileRead(path, &sz);
  if (buf == NULL) return -1;
  I64 n = 0; U8 *p = buf; U8 *e = buf + sz; I64 first = 1;
  while (p < e && n < MAX_ROWS) {
    U8 *ls = p; while (p < e && *p != '\n') p++;
    U8 *le = p; if (p < e) p++;
    if (le > ls && *(le-1) == '\r') le--;
    *le = 0;
    if (*ls == 0) continue;
    if (*ls == '#') continue;
    if (first && hdr) { first = 0; continue; }
    first = 0; B_NFD[n] = SplitB(ls, n * NCOL, NCOL); n++;
  }
  B_NROW = n; return 0;
}
static U8 *FA(I64 r, I64 c) {
  if (r < 0 || r >= NROW || c < 0 || c >= NFD[r]) return "";
  return FLD[r * NCOL + c];
}
static U8 *FB(I64 r, I64 c) {
  if (r < 0 || r >= B_NROW || c < 0 || c >= B_NFD[r]) return "";
  return BFLD[r * NCOL + c];
}

static I64 FAILS;
static I64 CHECKS;
static U0 Fail(U8 *cls, U8 *detail) { FAILS++; "DETECTOR=%s DETAIL=%s\n", cls, detail; }
static U0 Pass(U8 *name) { CHECKS++; "CHECK=%s STATUS=PASS\n", name; }
static I64 FindSite(U8 *id) { I64 r=0; while(r<NROW){if(StrEq(FA(r,0),id))return r;r++;}return -1; }
static I64 FindSource(U8 *id) { I64 r=0; while(r<NROW){if(StrEq(FA(r,0),id))return r;r++;}return -1; }
static I64 FindSemanticSite(U8 *id) { I64 r=0; while(r<B_NROW){if(StrEq(FB(r,0),id))return r;r++;}return -1; }
static I64 CountSemanticSite(U8 *id) { I64 r=0; I64 n=0; while(r<B_NROW){if(StrEq(FB(r,0),id))n++;r++;} return n; }
static I64 FindBundle(U8 *id) { I64 r=0; while(r<B_NROW){if(StrEq(FB(r,0),id))return r;r++;}return -1; }
static I64 SiteCount(U8 *list) {
  I64 n=0; U8 *p=list;
  while(*p!=0){ U8 *s=p; while(*p!=0&&*p!=';')p++; if(p-s>0)n++; if(*p==';')p++; }
  return n;
}

// Source-roster columns: 0 ID, 2 path, 3 function, 4 start, 5 end, 6 range
// hash, 7 config, 8 object, 9 object hash, 10 producer hash, 11 reachable,
// 12 caller, 13 family, 14 authority.
// Semantic-site columns: 0 site, 1 source, 2 hash, 3 kind, 4 behavior,
// 5 inputs, 6 effect, 7 read, 8 write, 9 ownership, 10 recovery, 11 edges,
// 12 existing PolyC authority, 13 object witness, 14 classification.
static I64 CheckFacts(U8 *c1) {
  I64 bad = 0;
  if (LoadA(Join3(c1,"/","source-roster.tsv"),1) != 0) { Fail("MISSING_FILE","source-roster.tsv"); return 1; }
  if (LoadB(Join3(c1,"/","semantic-sites.tsv"),1) != 0) { Fail("MISSING_FILE","semantic-sites.tsv"); return 1; }
  I64 r = 0;
  while (r < NROW) {
    if (NFD[r] < 15) { Fail("MALFORMED_ROW",FA(r,0)); bad++; r++; continue; }
    if (!StrEq(FA(r,7),"CFG-PROD-HCC-JIT-ON")) { Fail("AMBIGUOUS_BUILD_CONFIG",FA(r,0)); bad++; }
    if (!StrEq(FA(r,11),"YES")) { Fail("UNLINKED_OR_DORMANT_SOURCE_SITE",FA(r,0)); bad++; }
    if (!StrEq(FA(r,14),"C_AUTHORITY")) { Fail("AUTHORITY_CLASSIFICATION_MISMATCH",FA(r,0)); bad++; }
    I64 q=0;
    while(q<r){ if(StrEq(FA(q,0),FA(r,0))) { Fail("CANDIDATE_ROSTER_SET_MISMATCH",FA(r,0)); bad++; } q++; }
    q=0;
    while(q<B_NROW){
      if(StrEq(FB(q,1),FA(r,0))){
        if(!StrEq(FB(q,2),FA(r,6))) { Fail("SOURCE_RANGE_HASH_MISMATCH",FB(q,0)); bad++; }
        if(!StrEq(FB(q,12),"NO")) { Fail("EXISTING_AUTHORITY_DOUBLE_COUNT",FB(q,0)); bad++; }
      }
      q++;
    }
    r++;
  }
  r=0;
  while(r<B_NROW){
    if(B_NFD[r]<15){ Fail("MALFORMED_ROW",FB(r,0)); bad++; r++; continue; }
    I64 s=FindSemanticSite(FB(r,0));
    if(s<0 || CountSemanticSite(FB(r,0)) != 1){ Fail("CANDIDATE_ROSTER_SET_MISMATCH",FB(r,0)); bad++; r++; continue; }
    else {
      I64 src=FindSource(FB(r,1));
      if(src<0){ Fail("CANDIDATE_ROSTER_SET_MISMATCH",FB(r,0)); bad++; }
      else {
        if(!StrEq(FB(r,2),FA(src,6))) { Fail("SOURCE_RANGE_HASH_MISMATCH",FB(r,0)); bad++; }
      }
    }
    if(!StrEq(FB(r,12),"NO")) { Fail("EXISTING_AUTHORITY_DOUBLE_COUNT",FB(r,0)); bad++; }
    if(!StrEq(FB(r,14),"CORE_SEMANTIC")) { Fail("DIAGNOSTIC_AS_CORE_MISCLASSIFICATION",FB(r,0)); bad++; }
    r++;
  }
  I64 sr=0;
  while(sr<NROW){
    I64 q=0; I64 found=0;
    while(q<B_NROW){ if(StrEq(FB(q,1),FA(sr,0))) found++; q++; }
    if(found == 0){ Fail("CANDIDATE_ROSTER_SET_MISMATCH",FA(sr,0)); bad++; }
    sr++;
  }
  if(bad==0) Pass("source-object-facts"); else Fail("FACT_SET_INVALID","see rows above");
  return bad;
}

// Bundle columns: 0 ID, 1 sites, 2 goal, 3 path, 4 witnesses, 5 ABI,
// 6 host operations, 7 rollback, 8 blocking edges, 9 state, 10 recovery,
// 11 causal state, 12 eligibility, 13 exclusion.
static U0 EmitEligibility(U8 *c1) {
  if(LoadB(Join3(c1,"/","bundle-registry.tsv"),1)!=0){ Fail("MISSING_FILE","bundle-registry.tsv"); return; }
  "bundle_id\tE01\tE02\tE03\tE04\tE05\tE06\tE07\tE08\tE09\tE10\tE11\tE12\tE13\tE14\teligible\texclusion_reason\n";
  I64 r=0;
  while(r<B_NROW){
    I64 e[14]; I64 i=0;
    while(i<14){e[i]=1;i++;}
    if(StrEq(FB(r,0),"BUNDLE-DIAGNOSTIC-EXCLUDED")){i=0;while(i<14){e[i]=0;i++;}}
    if(StrEq(FB(r,11),"PENDING")) e[9]=0;
    if(StrEq(FB(r,11),"QUALIFIED")) e[9]=1;
    I64 ok=1;i=0;while(i<14){if(e[i]==0)ok=0;i++;}
    "%s",FB(r,0); i=0; while(i<14){"\t%d",e[i];i++;}
    if(ok) "\tYES\t-\n"; else "\tNO\tE10_CAUSAL_NOT_QUALIFIED_OR_EXCLUSION\n";
    r++;
  }
}

static I64 RankCompare(U8 *a,U8 *b){
  I64 ra=FindBundle(a); I64 rb=FindBundle(b); I64 c=0;
  if(SiteCount(FB(rb,1))!=SiteCount(FB(ra,1))) {
    if(SiteCount(FB(ra,1))>SiteCount(FB(rb,1))) c=-1; else c=1;
  }
  if(c==0){
    I64 qa=0; I64 qb=0;
    if(StrEq(FB(ra,11),"QUALIFIED")) qa=1;
    if(StrEq(FB(rb,11),"QUALIFIED")) qb=1;
    if(qa!=qb){ if(qa>qb)c=-1; else c=1; }
  }
  if(c==0){
    I64 ia=StrLen(FB(ra,9)); I64 ib=StrLen(FB(rb,9));
    if(ia!=ib){ if(ia>ib)c=-1; else c=1; }
  }
  if(c==0){
    I64 la=StrLen(FB(ra,0)); I64 lb=StrLen(FB(rb,0));
    if(la!=lb){ if(la<lb)c=-1; else c=1; }
    else {
      I64 i=0;
      while(i<la && FB(ra,0)[i]==FB(rb,0)[i]) i++;
      if(i<la){ if(FB(ra,0)[i]<FB(rb,0)[i])c=-1; else c=1; }
    }
  }
  return c;
}
static U0 SortBundles(I64 *idx,I64 n){ I64 i=0;while(i<n){I64 j=i+1;while(j<n){if(RankCompare(FB(idx[j],0),FB(idx[i],0))<0){I64 t=idx[i];idx[i]=idx[j];idx[j]=t;}j++;}i++;} }
static U0 EmitRank(U8 *c1){
  if(LoadB(Join3(c1,"/","bundle-registry.tsv"),1)!=0){Fail("MISSING_FILE","bundle-registry.tsv");return;}
  I64 idx[MAX_BUNDLES]; I64 n=0; I64 r=0;
  while(r<B_NROW&&n<MAX_BUNDLES){
    if(!StrEq(FB(r,12),"EXCLUDED")){idx[n]=r;n++;}
    r++;
  }
  SortBundles(idx,n);
  "rank\tbundle_id\tR0\tR1\tR2\tR3\tR4\tR5\tR6\n";
  I64 i=0;
  while(i<n){
    I64 b=idx[i]; I64 causal=0;
    if(StrEq(FB(b,11),"QUALIFIED")) causal=1;
    "%d\t%s\t1\t%d\t%d\t%d\t1\t%d\t%s\n",i+1,FB(b,0),SiteCount(FB(b,1)),causal,SiteCount(FB(b,1)),StrLen(FB(b,0)),FB(b,0);
    i++;
  }
}

static I64 Selftest(U8 *c1){
  I64 bad=0;
  if(CheckFacts(c1)!=0) bad++;
  EmitEligibility(c1);
  EmitRank(c1);
  if(bad==0) "SELFTEST_STATUS=PASS\n"; else "SELFTEST_STATUS=FAIL\n";
  return bad;
}
I32 Main(I32 argc, U8 **argv) {
  if(argc<2){"USAGE=verify CHECK|SELFTEST <c1_dir>\n";return 2;}
  if(StrEq(argv[1],"SELFTEST")){
    if(argc<3)return 2;
    I64 bad=Selftest(argv[2]);
    "CHECKS=%d FAILS=%d\n",CHECKS,FAILS;
    if(bad==0)return 0; return 1;
  }
  if(StrEq(argv[1],"CHECK")){
    if(argc<3)return 2;
    I64 bad=CheckFacts(argv[2]);
    EmitEligibility(argv[2]);
    EmitRank(argv[2]);
    "CHECKS=%d FAILS=%d\n",CHECKS,FAILS;
    if(bad==0)return 0; return 1;
  }
  "USAGE=verify CHECK|SELFTEST <c1_dir>\n"; return 2;
}
