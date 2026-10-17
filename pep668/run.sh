#!/bin/bash
# pip "externally-managed-environment" (PEP 668) on Ubuntu's system Python, and which fixes work.
PY=/usr/bin/python3
echo "$($PY --version), $(lsb_release -ds 2>/dev/null), marker: $(ls /usr/lib/python3*/EXTERNALLY-MANAGED 2>/dev/null)"
echo "== 1. pip install requests"; $PY -m pip install requests 2>&1 | head -12
echo "== 2. pip install --user requests"; $PY -m pip install --user requests 2>&1 | grep -E "externally-managed|Successfully" | head -2
echo "== 3. venv"; $PY -m venv /tmp/v 2>&1 | tail -2; /tmp/v/bin/pip install -q requests && /tmp/v/bin/python -c "import requests;print('venv ok', requests.__version__)"
echo "== 4. pipx (CLI tools)"; sudo apt-get install -y -qq pipx >/dev/null 2>&1; pipx install -q httpie 2>&1 | tail -1; ~/.local/bin/http --version 2>&1 | head -1
echo "== 5. apt package"; sudo apt-get install -y -qq python3-requests >/dev/null 2>&1; $PY -c "import requests;print('apt ok', requests.__version__)"
echo "== 6. --break-system-packages"; $PY -m pip install --break-system-packages -q six 2>&1 | tail -1; $PY -c "import six;print('break ok', six.__version__)"
