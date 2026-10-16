#!/bin/bash
# "No module named 'distutils'": old vs new node-gyp configuring a tiny N-API addon with Python 3.14.
cd "$(dirname "$0")"
PY=$(python -c "import sys;print(sys.executable)"); echo "$(python --version), node $(node -v)"
for v in 9.4.1 10.0.0 11.5.0; do
  echo "== node-gyp $v configure"
  npx -y node-gyp@$v configure --python="$PY" 2>&1 | grep -E "ModuleNotFoundError|No module named|gyp info ok|gyp ERR! (stack|configure error)|not ok" | head -3 | cut -c1-200
  rm -rf build
done
echo "== node-gyp 9.4.1 after pip install setuptools"
python -m pip install -q setuptools
npx -y node-gyp@9.4.1 configure --python="$PY" 2>&1 | grep -E "ModuleNotFoundError|No module named|gyp info ok|not ok" | head -2 | cut -c1-200
