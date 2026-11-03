#!/bin/bash
set +e
W=${W:-$(pwd)/work}; HERE=$(cd "$(dirname "$0")" && pwd); mkdir -p "$W"; cd "$W" || exit 1; cp $HERE/cpu.mjs $HERE/bench.mjs .
echo "== $(date -u) $(uname -s) node $(node -v) bun $(bun -v), $(nproc) cpus"
node bench.mjs; echo "== done"
