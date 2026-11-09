#!/bin/bash
# SQLAlchemy 2.1 "the greenlet library is required to use this function" (9 Nov 2026).
# 2.0.x vs 2.1.x, async engine with aiosqlite, installed with and without the [asyncio] extra, on the runner's Python.
set +e
W=${W:-$(pwd)/work}; rm -rf "$W"; mkdir -p "$W"; cd "$W" || exit 1
PY=${PY:-python}
cat > t.py <<'PY'
import asyncio, sqlalchemy
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
async def main():
    eng = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with eng.connect() as c:
        r = await c.execute(text("select 1"))
        print(f"sqlalchemy {sqlalchemy.__version__}: async query ok ->", r.scalar())
    await eng.dispose()
try:
    asyncio.run(main())
except Exception as e:
    print(f"sqlalchemy {sqlalchemy.__version__}: {type(e).__name__}: {str(e).splitlines()[0][:150]}")
PY
echo "== $(date -u +%F) $($PY -V) $(uname -s)"
run() { # $1 label, $2 pip spec
  rm -rf v && $PY -m venv v && v/bin/pip install -q --disable-pip-version-check $2 >/dev/null 2>pip.err || { echo "$1 | install failed: $(tail -1 pip.err | cut -c1-120)"; return; }
  g=$(v/bin/python -c "import importlib.util as u;print('greenlet installed' if u.find_spec('greenlet') else 'no greenlet')")
  printf '%-44s | %-16s | %s\n' "$1" "$g" "$(v/bin/python t.py 2>&1 | tail -1)"
}
run "sqlalchemy==2.0.* aiosqlite" "sqlalchemy==2.0.* aiosqlite"
run "sqlalchemy==2.1.* aiosqlite" "sqlalchemy==2.1.* aiosqlite"
run "sqlalchemy[asyncio]==2.1.* aiosqlite" "sqlalchemy[asyncio]==2.1.* aiosqlite"
run "sqlalchemy==2.1.* aiosqlite greenlet" "sqlalchemy==2.1.* aiosqlite greenlet"
run "sqlalchemy==2.1.* asyncpg" "sqlalchemy==2.1.* asyncpg"
echo "-- sync engine on 2.1 without greenlet:"
rm -rf v && $PY -m venv v && v/bin/pip install -q "sqlalchemy==2.1.*" >/dev/null 2>&1 && v/bin/python -c "
import sqlalchemy; from sqlalchemy import create_engine, text
e=create_engine('sqlite://'); print('sqlalchemy', sqlalchemy.__version__, 'sync:', e.connect().execute(text('select 1')).scalar())"
echo "-- pip metadata of the newest 2.1 (Requires-Python, greenlet requirement):"
v/bin/pip show sqlalchemy 2>/dev/null | grep -E "^(Version|Requires)"; v/bin/python - <<'PY'
from importlib.metadata import metadata, requires
m = metadata('sqlalchemy'); print('Requires-Python:', m['Requires-Python'])
print('greenlet lines:', [r for r in (requires('sqlalchemy') or []) if 'greenlet' in r])
PY
echo "== done"
echo "-- full error text on 2.1 without greenlet:"
rm -rf v && $PY -m venv v && v/bin/pip install -q "sqlalchemy==2.1.*" aiosqlite >/dev/null 2>&1 && v/bin/python t.py 2>&1 | tail -1; v/bin/python -c "
import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
async def m():
    e=create_async_engine('sqlite+aiosqlite:///:memory:')
    async with e.connect() as c: await c.execute(text('select 1'))
asyncio.run(m())" 2>&1 | tail -4
