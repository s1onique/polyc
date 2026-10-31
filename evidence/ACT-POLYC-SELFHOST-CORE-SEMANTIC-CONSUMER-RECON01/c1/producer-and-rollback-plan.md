# Producer and rollback plan
# Normal production configuration: CFG-PROD-HCC-JIT-ON with nine parser selectors and HCC_USE_SELFHOST_ABI_CPA ON.
# Future selector names: HCC_USE_SELFHOST_CORE_OPERATOR_CLASSIFY (operator bundle), HCC_USE_SELFHOST_CORE_TRANSPILER_OPERATOR_CLASSIFY, HCC_USE_SELFHOST_CORE_TYPE_CLASSIFY.
# Selector OFF must compile the unchanged C rule into the same consumer object as a genuine G0 oracle.
# Selector ON links a PolyC subject object compiled by the recorded stage0 hcc producer.
# Stage0 OFF means the stage0 compiler itself retains C ownership and does not link the future subject.
# Make prerequisite plan: subject source -> stage0 producer -> subject object -> hcc link; consumer object must explicitly depend on the selected subject object to avoid late-prerequisite expansion.
# Rollback: rebuild with selector OFF; verify no subject symbol/import and C rule active.
# No raw AST/Map/List/Cctrl/Arena layout crosses the proposed ABI; inputs and outputs are bounded scalar values.
