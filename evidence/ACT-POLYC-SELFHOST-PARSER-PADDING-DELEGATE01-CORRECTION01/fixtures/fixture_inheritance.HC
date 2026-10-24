// evidence/ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01-CORRECTION01/fixtures/fixture_inheritance.HC
//
// CORRECTION01 C1 -- regenerated production fixture (FIXTURE_INHERITANCE).
//
// PROVENANCE: the predecessor DELEGATE01 fixture contract named the
// ephemeral path /tmp/fixture_inheritance.HC, which was never committed
// and did not survive the previous session. This file is the deterministic
// REGENERATION of that fixture.
//
// Values pinned by the predecessor's committed evidence:
//   evidence/.../DELEGATE01/c1/c1-production-fixture-contract.tsv:
//     "sizeof(BaseClass)=16; sizeof(SuperClass)=32; sizeof(Empty)=16;
//      sizeof(Cat)=8; field reads"
//   evidence/.../DELEGATE01/c3/c3-n01-production-causal-control.txt:
//     "< NarrowBase=1 WideDerived=16"   (exact line format and values)
//   evidence/.../DELEGATE01/c3/c3-call-site-coverage.tsv:
//     "tail-aligned-union: FIXTURE_INHERITANCE (sizeof(Cat)=8)"
//
// Class definitions are taken from the canonical committed tests
// src/tests/24_union.HC (BaseClass, SuperClass:BaseClass, union Cat)
// and src/tests/65_class_inheritance.HC (class Empty:Base and the
// NarrowBase/WideDerived pair).
//
// This fixture exercises the CalcPadding production path at the
// tail-aligned-empty, tail-aligned-class, tail-aligned-union and
// anonymous-pre-align call-site classes.

class BaseClass
{
  I64 base;
  U8 *base_name;
};

class SuperClass:BaseClass
{
  I64 super;
  U8 *super_name;
};

class Empty:BaseClass
{
};

union Cat
{
  U8 *fish;
  I64 is;
};

class NarrowBase { U8 lo; };
class WideDerived:NarrowBase { I64 wide; };

I32 Main()
{
  "FIXTURE_INHERITANCE\n";
  "BaseClass=%d SuperClass=%d Empty=%d Cat=%d\n",
    sizeof(BaseClass), sizeof(SuperClass), sizeof(Empty), sizeof(Cat);
  "NarrowBase=%d WideDerived=%d\n", sizeof(NarrowBase), sizeof(WideDerived);
  return 0;
}
