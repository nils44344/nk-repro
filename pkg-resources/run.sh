#!/bin/bash
# No module named 'pkg_resources': which setuptools still has it, TensorBoard old vs new, a package whose setup.py
# imports it (pip and uv, with and without --build-constraint), PIP_CONSTRAINT, and importlib.metadata.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
PY=${PY:-python3.14}; echo "== $(date -u) $($PY --version) $(uv --version 2>/dev/null)"
v() { rm -rf v; $PY -m venv v; }
e() { grep -aoE "No module named 'pkg_resources'|ModuleNotFoundError[^\n]{0,60}|AttributeError: [^\n]{0,90}|Successfully installed[^\n]{0,80}|build backend returned an error|Failed to build[^\n]{0,40}" | head -1; }
echo "######## import pkg_resources by setuptools version"
v; echo "-- fresh venv: $(v/bin/pip list 2>/dev/null | grep -ciE '^setuptools') setuptools | $(v/bin/python -c 'import pkg_resources' 2>&1 | e)"
for S in 80.10.2 81.0.0 82.0.0 83.0.0 ""; do v; v/bin/pip install -q --disable-pip-version-check "setuptools${S:+==$S}" 2>&1 | grep -v notice | tail -1; [ -d v/lib/python3.*/site-packages/pkg_resources ] && pr=dir || pr=nodir; out=$(v/bin/python -W always -c 'import pkg_resources; print("works")' 2>&1); echo "-- setuptools $(v/bin/python -c 'import setuptools;print(setuptools.__version__)') (fresh venv, pkg_resources folder: $pr): $(echo "$out" | grep -oE "works|No module named 'pkg_resources'" | head -1)$(echo "$out" | grep -q -i deprecat && echo ', with a deprecation warning')"; done
echo "######## TensorBoard"
v; v/bin/pip install -q tensorboard==2.15.2 setuptools 2>&1 | tail -1; echo "-- tensorboard 2.15.2 + latest setuptools: $(v/bin/tensorboard --version 2>&1 | e)"
v/bin/pip install -q "setuptools<82" 2>&1 | tail -1; echo "-- same, setuptools<82: $(v/bin/tensorboard --version 2>&1 | grep -aoE "AttributeError: [^\n]{0,70}|^[0-9.]+$" | head -1)"
v; v/bin/pip install -q tensorboard setuptools 2>&1 | tail -1; echo "-- latest tensorboard $(v/bin/pip show tensorboard | grep Version | cut -d' ' -f2) + setuptools $(v/bin/python -c 'import setuptools;print(setuptools.__version__)'): $(v/bin/tensorboard --version 2>&1 | tail -1)"
echo "######## a package whose setup.py imports pkg_resources"
mkdir -p oldpkg/oldpkg && echo 'import pkg_resources
from setuptools import setup
setup(name="oldpkg", version="1.0", packages=["oldpkg"])' > oldpkg/setup.py && touch oldpkg/oldpkg/__init__.py
echo "setuptools<82" > bc.txt
v; echo "-- pip install ./oldpkg: $(v/bin/pip install ./oldpkg 2>&1 | e)"
echo "-- pip install --build-constraint bc.txt: $(v/bin/pip install --build-constraint bc.txt ./oldpkg 2>&1 | e)"
v; echo "-- PIP_CONSTRAINT=bc.txt pip install: $(PIP_CONSTRAINT=$W/bc.txt v/bin/pip install ./oldpkg 2>&1 | e)"
rm -rf u; uv venv -q u; echo "-- uv pip install ./oldpkg: $(VIRTUAL_ENV=$W/u uv pip install ./oldpkg 2>&1 | e)"
echo "-- uv pip install --build-constraint bc.txt: $(VIRTUAL_ENV=$W/u uv pip install --build-constraint bc.txt ./oldpkg 2>&1 | grep -aoE 'Installed [0-9]+ package|oldpkg==1.0|error[^\n]{0,60}' | head -1)"
echo "-- uv venv + uv pip install setuptools: $(VIRTUAL_ENV=$W/u uv pip install -q setuptools 2>&1 | tail -1; u/bin/python -c 'import pkg_resources' 2>&1 | e)"
echo "######## replacement"; v; echo "-- importlib.metadata.version('pip'), no setuptools: $(v/bin/python -c 'import importlib.metadata as m; print(m.version("pip"))')"
echo "== done"
