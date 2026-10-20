#!/bin/bash
set +e
cd "$(dirname "$0")"
echo "== 1b. pip and python are different Pythons (humanize)"
/usr/bin/python3 -c "import humanize" 2>&1 | tail -1
pip install -q humanize 2>&1 | tail -1
python -c "import humanize; print('python 3.13: humanize OK')" 2>&1 | tail -1
/usr/bin/python3 -c "import humanize" 2>&1 | tail -1
echo "== sklearn"; python -m venv v1; v1/bin/pip install sklearn 2>&1 | grep -iE "deprecated|scikit-learn|sklearn" | head -4 | cut -c1-200
for p in dotenv bs4 psycopg2; do rm -rf v2; python -m venv v2; echo "== pip install $p"; v2/bin/pip install $p 2>&1 | grep -E "Successfully installed|error" | head -2 | cut -c1-200; m=$p; v2/bin/python -c "import $m; print('import $m OK', getattr($m,'__file__',''))" 2>&1 | tail -1 | cut -c1-200; done
v2/bin/pip install -q python-dotenv 2>/dev/null; rm -rf v3; python -m venv v3; v3/bin/pip install -q dotenv; v3/bin/python -c "from dotenv import load_dotenv; print('load_dotenv OK')" 2>&1 | tail -1
