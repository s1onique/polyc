#!/usr/bin/env python3
"""
Mechanical migration queue scoring per ACT §6.

score = migration_isolation*3
      + runtime_substrate_ready*3
      + oracle_quality*2
      + shell_loc_reduction*1
      - external_dependency_complexity*2
      - destructive_side_effect_risk*3

Coefficients frozen at C2 BEFORE ranking.

Inputs are mechanically observable from the source.
"""
import os, subprocess, re, sys

# Coefficients (FROZEN here in C2 IMPL)
W_ISO = 3
W_RUN = 3
W_ORC = 2
W_LOC = 1
W_DEP = 2
W_RISK = 3

# Compute scores for each GRANDFATHERED scripts/quality/ candidate.
# We focus on scripts/quality/* (the real Track-B target).
# Other GRANDFATHERED files (evidence/, src/asm/) are SKIP per F14 / not-Track-B.

def read_safe(p):
    try:
        return open(p).read()
    except FileNotFoundError:
        return ''

def count(pattern, text):
    return len(re.findall(pattern, text))

def shell_loc(p):
    try:
        return sum(1 for _ in open(p, 'rb'))
    except FileNotFoundError:
        return 0

# Candidate categories. Only scripts/quality/* are real Track-B candidates.
# Evidence/* and src/asm/* are SKIP per F14 (immutable historical) or
# out-of-scope (compiler-dev).

candidates = []

for path in subprocess.run(
    ['git', 'ls-files', '*.sh'], capture_output=True, text=True
).stdout.splitlines():
    loc = shell_loc(path)
    if loc <= 50:
        continue  # TINY
    if path.startswith('evidence/'):
        continue  # F14 immutable
    if path.startswith('packaging/'):
        continue  # not scripts/quality/
    if path.startswith('src/asm/'):
        continue  # compiler-dev
    text = read_safe(path)
    # Migration isolation: small scripts easier; scripts that exec many
    # subprocesses harder.
    sub = count(r'\$\(|`|xargs|\| sh\b|eval\b', text)
    # External dependency: how many distinct tools are called?
    tools = set(re.findall(r'\b(hcc|polyc|hc-compile|gcc|clang|opt|llc|llvm-as|llvm-dis|file|diff|grep|awk|sed|cat|wc|head|tail|tr|sort|uniq|comm|find|mktemp|git|python3|sh|bash|cmake|make)\b', text))
    # Side-effect risk: writes to /tmp, rm -rf, etc.
    risk = count(r'rm -rf|>\s*/|tee\s+/|wget|curl', text)
    risk += count(r'mkdir -p', text)
    # Runtime substrate: how PolyC-friendly is this? Estimate:
    #   - direct argv invocations of compiler = 5
    #   - pure text-diff tests = 4
    #   - temp/scratch orchestration = 3
    runtime = 4
    if 'hcc' in text or 'polyc' in text or 'hc_compile' in text:
        runtime = 5
    if 'cmake' in text or 'make' in text:
        runtime = 3
    if 'wget' in text or 'curl' in text:
        runtime = 1
    # Oracle quality: 5 if explicit pass/fail counters; 3 if grep-based.
    oracle = 4
    if 'PASS' in text and 'FAIL' in text and 'rc=' in text:
        oracle = 5
    if 'grep -c' in text and 'PASS' in text:
        oracle = 3
    # LOC reduction potential: smaller = easier = higher score.
    if loc <= 200:
        loc_red = 5
    elif loc <= 300:
        loc_red = 4
    elif loc <= 400:
        loc_red = 3
    elif loc <= 500:
        loc_red = 2
    else:
        loc_red = 1
    # External dependency count.
    ext_dep = min(5, len(tools))
    # Migration isolation: lower sub count = higher isolation.
    iso = max(1, 5 - sub)
    # Risk score (1..5).
    risk = min(5, max(1, risk))
    score = iso*W_ISO + runtime*W_RUN + oracle*W_ORC + loc_red*W_LOC \
          - ext_dep*W_DEP - risk*W_RISK
    candidates.append({
        'path': path,
        'loc': loc,
        'iso': iso, 'runtime': runtime, 'oracle': oracle, 'loc_red': loc_red,
        'dep': ext_dep, 'risk': risk, 'score': score,
        'sub': sub, 'tools': len(tools),
    })

candidates.sort(key=lambda c: (-c['score'], c['path']))

# Classify categories per ACT §11.
def classify(c):
    text = read_safe(c['path'])
    if c['runtime'] >= 5 and c['oracle'] >= 4 and c['iso'] >= 3 and c['risk'] <= 2:
        return 'READY_NOW'
    if c['runtime'] < 4:
        return 'NEEDS_RUNTIME_PRIMITIVE'
    if c['risk'] >= 4:
        return 'DEFER_HIGH_RISK'
    if c['iso'] <= 2:
        return 'NEEDS_FACTORY_REDESIGN'
    return 'READY_NOW'

print('rank\tpath\tloc\tcategory\truntime_ready\toracle_ready\trisk\testimated_reduction\tscore\treason')
for i, c in enumerate(candidates, 1):
    cat = classify(c)
    red = c['loc']  # full reduction potential: delete entirely
    reason = f"score={c['score']} iso={c['iso']} runtime={c['runtime']} oracle={c['oracle']} dep={c['dep']} risk={c['risk']}"
    print(f"{i}\t{c['path']}\t{c['loc']}\t{cat}\t{c['runtime']}\t{c['oracle']}\t{c['risk']}\t{red}\t{c['score']}\t{reason}")
