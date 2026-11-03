// The frozen PRECEDENCE fixture for
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION02.
//
// It is the SAME SOURCE as the required-route fixture. The precedence
// cases differ only in the ARGV, never in the input, so any observed
// difference is a difference in the DECISION, not in the compilation.
//
// The decisive case is:
//
//   hcc --install-dir=<prefix> -c precedence-source.HC -o- --bogus-option
//
// The PolyC driver selects WP_STATUS_USAGE for that argv. Before the
// correction the C-owned `-o-` policy preempted it and reported its
// own diagnostic. After the correction the PolyC-selected diagnostic
// is the one reported.
I64 Main() {
    return 7;
}
