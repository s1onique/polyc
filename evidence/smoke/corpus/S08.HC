I64 Dbl(I64 x){return 2*x;}
U0 Main(){ I64 (*f)(I64)=&Dbl; "%d\n",f(7); }
