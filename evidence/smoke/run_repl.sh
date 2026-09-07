#!/bin/bash
set -u
HCC=../../hcc
ARGS="--install-dir=$PWD/../../build/recon-prefix -repl"
for f in corpus/S*.HC; do
  echo "=== $f REPL ==="
  # Convert "U0 Main(){ ... }" into submission Main; + trailing newline
  BODY=$(cat "$f")
  # If file has U0 Main(){...} block, append Main;
  printf '%s\nMain;\n\n' "$BODY" | $HCC $ARGS 2>&1
done
