#!/usr/bin/env bash
# "No matching distribution found for torch" on Windows: which Pythons and which PyTorch indexes have a torch wheel.
# Uses `pip index versions` and `pip install --dry-run`, so no multi-GB wheel is downloaded.
py=python
echo "== $($py -c 'import sys,struct,sysconfig;print(sys.version.split()[0], struct.calcsize("P")*8, "bit", "free-threaded" if sysconfig.get_config_var("Py_GIL_DISABLED") else "")') pip $($py -m pip --version | cut -d' ' -f2)"
echo "== PyPI: pip index versions torch"; $py -m pip index versions torch 2>&1 | head -2
echo "== pip install --dry-run torch"; $py -m pip install --dry-run --no-deps torch 2>&1 | grep -E "Would install|ERROR" | head -2
if [ "${INDEXES:-}" = 1 ]; then
  for ix in cu118 cu121 cu124 cu126 cu128 cu129 cu130 cu132 cpu; do
    echo "-- $ix: $($py -m pip index versions torch --index-url https://download.pytorch.org/whl/$ix 2>&1 | head -1)"
  done
  echo "== pinned too old: torch==2.1.2"; $py -m pip install --dry-run --no-deps "torch==2.1.2" 2>&1 | grep ERROR | head -1
  echo "== the wrong name: pytorch"; $py -m pip install --dry-run --no-deps pytorch 2>&1 | grep -i -E "tried to install|ERROR" | head -3
fi
