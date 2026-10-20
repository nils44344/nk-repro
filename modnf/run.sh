#!/bin/bash
# "ModuleNotFoundError: No module named X" although pip says it is installed: each cause reproduced.
set +e
cd "$(dirname "$0")"
echo "== which python / pip"; for c in python python3 pip pip3; do printf "%-8s %s\n" $c "$(command -v $c)"; done
python --version; /usr/bin/python3 --version; pip --version
echo "== 1. pip and python are different Pythons"
pip install -q requests 2>&1 | tail -1
echo "-- python (setup-python):"; python -c "import requests; print('requests', requests.__version__)" 2>&1 | tail -1
echo "-- /usr/bin/python3 (system):"; /usr/bin/python3 -c "import requests" 2>&1 | tail -1
/usr/bin/python3 -m pip --version 2>&1 | tail -1
echo "-- sys.executable of each:"; python -c "import sys;print(sys.executable)"; /usr/bin/python3 -c "import sys;print(sys.executable)"
echo "== 2. venv: installed inside, run outside"
python -m venv .venv; .venv/bin/pip install -q httpx 2>&1 | tail -1
python -c "import httpx" 2>&1 | tail -1
.venv/bin/python -c "import httpx; print('venv python: httpx', httpx.__version__)"
(source .venv/bin/activate; python -c "import httpx; print('after activate:', httpx.__version__)")
echo "== 3. install name != import name"
for p in sklearn cv2 PIL yaml bs4 dotenv psycopg2; do printf "pip install %-9s -> " $p; .venv/bin/pip install -q $p 2>&1 | grep -iE "error|deprecated|No matching|Successfully" | head -1 | cut -c1-170; [ ${PIPESTATUS[0]} ] ; echo; done
for pair in "scikit-learn sklearn" "opencv-python-headless cv2" "Pillow PIL" "PyYAML yaml" "beautifulsoup4 bs4" "python-dotenv dotenv" "psycopg2-binary psycopg2"; do set -- $pair; .venv/bin/pip install -q $1 2>&1 | grep -iE "^error" | head -1; printf "%-24s import %-9s " $1 $2; .venv/bin/python -c "import $2; print('OK')" 2>&1 | tail -1; done
echo "== 4. Jupyter kernel is another Python"
python -m venv jenv; jenv/bin/pip install -q nbconvert ipykernel nbformat 2>&1 | tail -1
cat > nb.py <<'P'
import nbformat as nbf
nb = nbf.v4.new_notebook(); nb.cells = [nbf.v4.new_code_cell("import sys; print(sys.executable)"), nbf.v4.new_code_cell("import tabulate; print('tabulate', tabulate.__version__)")]
nbf.write(nb, "t.ipynb")
P
jenv/bin/python nb.py
pip install -q tabulate 2>&1 | tail -1
echo "-- pip install tabulate (outside), then run notebook:"; jenv/bin/jupyter nbconvert --to notebook --execute t.ipynb --output out.ipynb 2>&1 | grep -E "ModuleNotFoundError|Writing" | head -2
cat > nb2.py <<'P'
import nbformat as nbf
nb = nbf.v4.new_notebook(); nb.cells = [nbf.v4.new_code_cell("%pip install -q tabulate"), nbf.v4.new_code_cell("import tabulate; print('tabulate', tabulate.__version__)")]
nbf.write(nb, "t2.ipynb")
P
jenv/bin/python nb2.py
echo "-- with %pip inside the notebook:"; jenv/bin/jupyter nbconvert --to notebook --execute t2.ipynb --output out2.ipynb 2>&1 | grep -E "ModuleNotFoundError|Writing" | head -2
jenv/bin/python -c "import json;o=json.load(open('out2.ipynb'));print([x.get('text','')[:60] for c in o['cells'] for x in c.get('outputs',[])])"
echo "== 5. a file named like the package"
mkdir -p shadow && cd shadow && echo "import requests; print(requests.get)" > requests.py && python requests.py 2>&1 | tail -1; cd ..
echo "== 6. python -m pip installs where python runs"
/usr/bin/python3 -m pip install -q --user --break-system-packages rich 2>&1 | tail -1; /usr/bin/python3 -c "import rich; print('system python: rich OK')"
