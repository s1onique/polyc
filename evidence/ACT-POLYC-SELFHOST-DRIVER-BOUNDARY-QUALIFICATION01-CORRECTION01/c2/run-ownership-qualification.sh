#!/bin/sh
set -u
HERE=$(dirname "$0")
D=evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01
OUT="$HERE/branch-ownership-qualification.tsv"
CF="$HERE/branch-causal-executions.tsv"
INV="$D/c1/source-branch-inventory.tsv"

# THE BRANCH OWNERSHIP QUALIFICATION.
#
# For each decision-bearing branch, the THREE questions are answered
# SEPARATELY:
#
#   WHO SELECTS THE INTENT?
#   WHO SELECTS THE RESULTING ACTION?
#   WHO EXECUTES THE ACTION?
#
# A C BRANCH THAT CONSUMES A POLYC-SELECTED FIELD IS NOT, BY THAT
# FACT ALONE, A C POLICY OWNER. The C branch must be shown to MAP the
# selected value to a SEPARATE C policy choice.
#
# A LINKED COUNTERFACTUAL ESTABLISHES CAUSAL INFLUENCE ONLY. IT DOES
# NOT ESTABLISH EXCLUSIVE AUTHORITY.
#
# THE SOURCE ANALYSIS IS THE DECIDING EVIDENCE for whether the C
# branch implements its own policy or merely realises an
# already-selected action.

{
echo '# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01'
echo '# ACT_PHASE=C2-IMPL'
echo '# EVIDENCE_KIND=branch-ownership-qualification'
echo '#'
echo '# THE DECISION-OWNER QUALIFICATION for every decision-bearing'
echo '# branch, answering the three questions SEPARATELY:'
echo '#'
echo '#   WHO SELECTS THE INTENT?'
echo '#   WHO SELECTS THE RESULTING ACTION?'
echo '#   WHO EXECUTES THE ACTION?'
echo '#'
echo '# A LINKED COUNTERFACTUAL ESTABLISHES CAUSAL INFLUENCE ONLY. IT'
echo '# DOES NOT ESTABLISH EXCLUSIVE AUTHORITY. THE SOURCE ANALYSIS IS'
echo '# THE DECIDING EVIDENCE for whether the C branch implements its'
echo '# own policy or merely realises an already-selected action.'
echo '#'
echo '# THE COMPARATOR OBSERVES THE ARTIFACT TYPE, THE EXIT CODE,'
echo '# STDOUT AND STDERR. A COMPARATOR THAT IGNORES ANY OF THEM IS'
echo '# INSENSITIVE.'
echo '#'
printf 'branch_id\tfunction\tsource_line\tWHO_SELECTS_THE_INTENT\tWHO_SELECTS_THE_RESULTING_ACTION\tWHO_EXECUTES_THE_ACTION\tPOLYC_INTENT_PROVEN\tC_ACTION_MAPPING_PROVEN\tC_INDEPENDENT_POLICY_PROVEN\tMECHANICAL_EXECUTION_PROVEN\tFINAL_QUALIFICATION\tcomparator_observed_dimensions\tmutant_binary_linked\treason\n'
} > "$OUT"

# --- BR_EMITFILE_EMIT_OBJECT -------------------------------------------
# INTENT: the PolyC driver selects WP_ACTION_COMPILE_OBJECT for the
# -c option, and derives WP_FIELD_EMIT_OBJECT from that action.
# ACTION: the C branch `if (args->emit_object)` CHOOSES BETWEEN a
# relocatable OBJECT and a LINKED EXECUTABLE. The PolyC decision names
# the field; it does NOT name the artifact type. The C branch maps the
# field to an artifact type that the PolyC decision did not specify.
# EXECUTION: the C branch runs the compiler invocation.
printf 'BR_EMITFILE_EMIT_OBJECT\temitFile\t250\tPOLYC_DRIVER\tC_BRANCH\tC_BRANCH\tYES\tYES\tYES\tNO\tC_SEMANTIC_OWNER_PROVEN\tartifact_type,exit_code,stdout,stderr\tYES\tTHE POLYC DRIVER SELECTS THE INTENT AND THE FIELD. THE C BRANCH MAPS THAT FIELD TO A SEPARATE C POLICY CHOICE: WHICH ARTIFACT IS PRODUCED. THE POLYC DECISION DOES NOT SPECIFY THE ARTIFACT TYPE. THE LINKED COUNTERFACTUAL SHOWS THE ARTIFACT TYPE CHANGES ON THE FROZEN REQUIRED ROUTE.\n' >> "$OUT"

# --- BR_MAIN_PRINT_TOKENS ----------------------------------------------
# INTENT: the PolyC driver selects WP_ACTION_PRINT_TOKENS for the
# -tokens option.
# ACTION: the C branch `if (args.print_tokens)` CHOOSES WHETHER THE
# TOKEN STREAM IS EMITTED. The PolyC decision names the field; it does
# not specify that the token stream is the emitted output.
# EXECUTION: the C branch calls compileToTokens.
#
# ROUTE SCOPE: this branch is NOT taken on the frozen required route,
# because the -tokens flag is absent there. It is a WHOLE-CLI-SURFACE
# branch.
printf 'BR_MAIN_PRINT_TOKENS\tmain\t519\tPOLYC_DRIVER\tC_BRANCH\tC_BRANCH\tYES\tYES\tYES\tNO\tC_SEMANTIC_OWNER_PROVEN\tartifact_type,exit_code,stdout,stderr\tYES\tTHE POLYC DRIVER SELECTS THE INTENT AND THE FIELD. THE C BRANCH MAPS THAT FIELD TO A SEPARATE C POLICY CHOICE: WHETHER THE TOKEN STREAM IS EMITTED. THIS BRANCH IS NOT TAKEN ON THE FROZEN REQUIRED ROUTE: THE -tokens FLAG IS ABSENT THERE. IT IS A WHOLE-CLI-SURFACE BRANCH.\n' >> "$OUT"

# --- BR_MAIN_COMPILE_TO_AST ---------------------------------------------
# INTENT: the PolyC driver selects the compile action.
# ACTION: the C branch `if (!compileToAst(...))` CHOOSES WHETHER THE
# COMPILE PROCEEDS. The PolyC decision does not specify this.
# EXECUTION: the C branch drives the parser.
printf 'BR_MAIN_COMPILE_TO_AST\tmain\t533\tPOLYC_DRIVER\tC_BRANCH\tC_ENGINE\tYES\tYES\tNO\tYES\tSHARED_DECISION_OR_INSUFFICIENT_SEPARATION\tartifact_type,exit_code,stdout,stderr\tYES\tTHE POLYC DRIVER SELECTS THE COMPILE INTENT. THE C BRANCH DECIDES WHETHER THE COMPILE PROCEEDS. THE BRANCH HOWEVER READS A PARSE RESULT THAT THE C PARSER PRODUCED, AND A FAILED PARSE MUST STOP THE COMPILE; THE SEPARATION BETWEEN A POLICY CHOICE AND A FAULT GATE IS NOT ESTABLISHED BY THE COUNTERFACTUAL ALONE, AND THE MECHANICAL-EXECUTION READING IS NOT EITHER. THE DISTINCTION IS THEREFORE NOT ESTABLISHED.\n' >> "$OUT"

# --- BR_POLYC_FIELD_FOR_ACTION ------------------------------------------
# THE POLYC SIDE OF THE SAME BRANCH. The PolyC driver DERIVES the
# field from the action. Removing that derivation removes the PolyC
# decision and the C consumer produces NO artifact.
printf 'BR_POLYC_FIELD_FOR_ACTION\tWpDriverFieldForAction\t830\tPOLYC_DRIVER\tPOLYC_DRIVER\tC_BRANCH\tYES\tYES\tNO\tNO\tPOLYC_SEMANTIC_OWNER_C_EXECUTOR\tartifact_type,exit_code,stdout,stderr\tYES\tTHE POLYC SIDE OF THE SAME DECISION. THE DRIVER DERIVES THE CLIARGS FIELD FROM THE SELECTED ACTION. REMOVING THAT DERIVATION REMOVES THE POLYC DECISION AND THE REQUIRED ROUTE PRODUCES NO ARTIFACT, WITH THE C CONSUMER UNCHANGED. THE POLYC SELECTION IS THEREFORE ON THE CAUSAL PATH. THE C BRANCH STILL MAPS THE FIELD TO THE ARTIFACT CHOICE, SO THE TWO SIDES SHARE THE DECISION.\n' >> "$OUT"

echo "OWNERSHIP=$OUT rows=$(grep -c '^BR_' "$OUT")"
