// ACT-POLYC-IR-BOUNDARY03 / Phase 0 truthiness fixtures (literals)

I64 BranchOn(I64 v) {
    if (v) return 1;
    return 0;
}

I64 TestZero()   { return BranchOn(0);  }
I64 TestOne()    { return BranchOn(1);  }
I64 TestTwo()    { return BranchOn(2);  }
I64 TestThree()  { return BranchOn(3);  }
I64 TestNegOne() { return BranchOn(-1); }
I64 TestNegTwo() { return BranchOn(-2); }
