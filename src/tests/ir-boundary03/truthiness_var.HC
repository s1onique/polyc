// ACT-POLYC-IR-BOUNDARY03 / truthiness variable discrimination

I64 IsTrueGeneric(I64 v) {
    if (v) return 1;
    return 0;
}

I64 DiscriminationTwo()  { return IsTrueGeneric(2);  }
I64 DiscriminationNegTwo() { return IsTrueGeneric(-2); }
I64 DiscriminationNegOne() { return IsTrueGeneric(-1); }
I64 DiscriminationZero() { return IsTrueGeneric(0); }
