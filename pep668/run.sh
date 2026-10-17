#!/bin/bash
# pip "externally-managed-environment" (PEP 668) inside a clean ubuntu:24.04 container, and which fixes work.
docker run --rm ubuntu:24.04 bash -c '
apt-get update -qq >/dev/null && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq python3-pip python3-venv pipx >/dev/null 2>&1
echo "$(python3 --version), $(. /etc/os-release; echo $PRETTY_NAME), pip $(pip3 --version | cut -d" " -f2)"
echo "== 1. pip install requests"; pip3 install requests 2>&1 | head -14
echo "== 2. pip install --user requests"; pip3 install --user requests 2>&1 | grep -E "externally-managed|Successfully" | head -1
echo "== 3. sudo-style (root) python3 -m pip install"; python3 -m pip install requests 2>&1 | grep -E "^error|Successfully" | head -1
echo "== 4. venv"; python3 -m venv /tmp/v && /tmp/v/bin/pip install -q requests && /tmp/v/bin/python -c "import requests;print(\"venv ok\", requests.__version__)"
echo "== 5. pipx"; pipx install httpie >/dev/null 2>&1; ~/.local/bin/http --version 2>&1 | head -1
echo "== 6. apt"; apt-get install -y -qq python3-requests >/dev/null 2>&1; python3 -c "import requests;print(\"apt ok\", requests.__version__)"
echo "== 7. --break-system-packages"; pip3 install --break-system-packages -q six 2>&1 | grep -v WARNING | tail -1; python3 -c "import six;print(\"break ok\", six.__version__)"
'
