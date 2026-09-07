class P{ I64 x; };
U0 Main(){ P *p=MAlloc(sizeof(P)); p->x=11; "%d\n",p->x; Free(p); }
