#!/bin/bash
# Python 3.10 reached end of life on 31 Oct 2026. Which popular packages no longer ship a version for it,
# and what does pip do: refuse, or quietly install an old release? (9 Nov 2026)
set +e
W=${W:-$(pwd)/work}; rm -rf "$W"; mkdir -p "$W"; cd "$W" || exit 1
PY=${PY:-python}
PKGS="numpy pandas scipy matplotlib pillow scikit-learn polars pyarrow requests httpx fastapi pydantic django flask sqlalchemy alembic celery redis boto3 google-genai openai anthropic transformers torch langchain huggingface-hub tokenizers jupyterlab ipython pytest ruff black mypy rich typer click uvicorn gunicorn psycopg cryptography pyyaml lxml beautifulsoup4 selenium playwright opencv-python-headless sentry-sdk"
echo "== $(date -u +%F) $($PY -V) pip $($PY -m pip -V | awk '{print $2}')"
printf '%-24s | %-12s | %-12s | %s\n' package latest installed note
for p in $PKGS; do
  latest=$(curl -s https://pypi.org/pypi/$p/json | python3 -c "import sys,json;j=json.load(sys.stdin);print(j['info']['version'],'|',j['info'].get('requires_python') or '-')" 2>/dev/null)
  lv=${latest%% |*}; rp=${latest##*| }
  rm -rf v && $PY -m venv v >/dev/null && v/bin/pip install -q --disable-pip-version-check --only-binary :all: "$p" >/dev/null 2>err.txt
  if [ $? -ne 0 ]; then iv="FAIL"; note=$(grep -m1 -oE "requires a different Python[^']*'[^']*'|No matching distribution[^ ]*|Could not find a version[^)]*\)" err.txt | cut -c1-80)
  else iv=$(v/bin/pip show "$p" 2>/dev/null | awk '/^Version/{print $2}'); [ "$iv" = "$lv" ] && note="latest" || note="OLD (latest needs Python $rp)"; fi
  printf '%-24s | %-12s | %-12s | %s\n' "$p" "$lv" "$iv" "$note"
done
echo "-- the message when you pin the latest Pillow on this Python:"
rm -rf v && $PY -m venv v && v/bin/pip install --disable-pip-version-check "pillow==$(curl -s https://pypi.org/pypi/pillow/json | python3 -c "import sys,json;print(json.load(sys.stdin)['info']['version'])")" 2>&1 | grep -E "ERROR|requires a different" | head -3
echo "-- uv on the same Python, pillow latest pinned:"
pip install -q uv >/dev/null 2>&1; rm -rf uvv && uv venv -q -p $PY uvv && VIRTUAL_ENV=uvv uv pip install -q "pillow==$(curl -s https://pypi.org/pypi/pillow/json | python3 -c "import sys,json;print(json.load(sys.stdin)['info']['version'])")" 2>&1 | head -6
echo "== done"
