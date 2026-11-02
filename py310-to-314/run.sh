#!/bin/bash
# Python 3.10-era code on 3.14: each removed/changed API on both versions, the replacements, the PyPI backports,
# asyncio.get_event_loop(), and old pins in a fresh 3.14 venv.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
echo "== $(date) $(python3.10 --version) $(python3.14 --version)"
t() { for V in 3.10 3.14; do r=$(python$V -c "$2" 2>&1 | tail -1 | cut -c1-130); echo "   $V: ${r:-ok}"; done; }
c() { echo "-- $1"; t "$1" "$2"; }
c "import distutils" "import distutils"
c "import imp" "import imp"
c "import asyncore" "import asyncore"
c "import cgi" "import cgi"
c "import telnetlib" "import telnetlib"
c "from typing.io import TextIO" "from typing.io import TextIO"
c "SafeConfigParser" "from configparser import SafeConfigParser"
c "ssl.wrap_socket" "import ssl; ssl.wrap_socket"
c "ast.Num" "import ast; ast.Num"
c "pkgutil.find_loader" "import pkgutil; pkgutil.find_loader('json')"
c "assertEquals" "import unittest
class T(unittest.TestCase):
    def test(self): self.assertEquals(1, 1)
T('test').test()"
c "asyncio.get_event_loop() at top level" "import asyncio
async def m(): return 1
loop = asyncio.get_event_loop(); print(loop.run_until_complete(m()))"
echo "######## replacements on 3.14"
python3.14 -c "
import importlib, json, configparser, ssl, ast, importlib.util, datetime, asyncio
importlib.reload(json); configparser.ConfigParser(); ssl.create_default_context().wrap_socket
ast.Constant; print('find_spec:', importlib.util.find_spec('json') is not None); print('utc:', datetime.datetime.now(datetime.UTC).tzinfo)
async def m(): return 1
print('asyncio.run:', asyncio.run(m()))
import unittest
class T(unittest.TestCase):
    def test(self): self.assertEqual(1, 1)
T('test').test(); print('replacements ok')" 2>&1 | tail -4
echo "######## backports on 3.14"
python3.14 -m venv bp && bp/bin/pip install -q setuptools legacy-cgi standard-telnetlib standard-asyncore 2>&1 | tail -1
bp/bin/python -c "import distutils, cgi, telnetlib, asyncore; print('backports ok')" 2>&1 | tail -1
echo "######## old pins on 3.14 (fresh venv each)"
for pin in numpy==1.24.4 PyYAML==6.0 pandas==1.5.3 requests==2.28.2; do
  python3.14 -m venv v && out=$(timeout 600 v/bin/pip install "$pin" 2>&1); ok=$?
  echo "-- $pin: $( [ $ok = 0 ] && echo installed || (echo "$out" | grep -aoE "BackendUnavailable[^\n]*|AttributeError: [^\n]*|ModuleNotFoundError: [^\n]*|error: [a-z-]+" | head -1 | cut -c1-140))"; rm -rf v
done
python3.14 -m venv u && u/bin/pip install -q --only-binary=:all: numpy pandas pyyaml 2>&1 | tail -1; echo "-- current numpy/pandas/pyyaml from wheels only: $(u/bin/python -c 'import numpy,pandas,yaml;print(numpy.__version__,pandas.__version__,yaml.__version__)' 2>&1 | tail -1)"
echo "== done"
