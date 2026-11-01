#!/bin/bash
# PEP 668 across distros: does plain pip install hit externally-managed-environment, and the side errors and fixes
# (venv without python3-venv, PIP_BREAK_SYSTEM_PACKAGES, pip config, uv).
for IMG in ubuntu:22.04 ubuntu:24.04 ubuntu:26.04 debian:12 debian:13 fedora:latest python:3.13-slim; do
echo; echo "######## $IMG"
docker run --rm -e DEBIAN_FRONTEND=noninteractive $IMG bash -c '
if command -v apt-get >/dev/null; then apt-get update -qq >/dev/null; [ -x /usr/local/bin/python3 ] || apt-get install -y -qq python3-pip >/dev/null 2>&1; apt-get install -y -qq curl >/dev/null 2>&1;
else dnf install -y -q python3-pip >/dev/null 2>&1; fi
echo "$(. /etc/os-release; echo $PRETTY_NAME), $(python3 --version), pip $(python3 -m pip --version | cut -d" " -f2), EXTERNALLY-MANAGED: $(ls /usr/lib/python3*/EXTERNALLY-MANAGED 2>/dev/null | head -1 || echo none)"
echo "-- pip install six"; python3 -m pip install -q six 2>&1 | grep -E "^error|externally|Successfully" | head -1; python3 -c "import six; print(\"   installed\", six.__version__)" 2>&1 | tail -1
if command -v apt-get >/dev/null && [ ! -x /usr/local/bin/python3 ]; then
  echo "-- python3 -m venv without python3-venv"; python3 -m venv /tmp/v 2>&1 | grep -vE "^\s*$" | head -4
  echo "-- PIP_BREAK_SYSTEM_PACKAGES=1 pip install idna"; PIP_BREAK_SYSTEM_PACKAGES=1 python3 -m pip install -q idna 2>&1 | grep -v "^WARNING" | head -1; python3 -c "import idna; print(\"   installed\", idna.__version__)" 2>&1 | tail -1
  echo "-- pip config break-system-packages true, then pip install certifi"; python3 -m pip config set global.break-system-packages true 2>&1 | tail -1; python3 -m pip install -q certifi 2>&1 | grep -v "^WARNING" | head -1; python3 -c "import certifi; print(\"   installed\", certifi.__version__)" 2>&1 | tail -1
  python3 -m pip config unset global.break-system-packages >/dev/null 2>&1
  curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1; export PATH=$HOME/.local/bin:$PATH
  echo "-- uv $(uv --version | cut -d" " -f2): uv pip install --system attrs"; uv pip install --system attrs 2>&1 | grep -vE "^\s*$" | head -3 | cut -c1-200
  echo "-- uv venv + uv pip install requests (no python3-venv)"; cd /tmp && uv venv -q u 2>&1 | tail -1; VIRTUAL_ENV=/tmp/u uv pip install -q requests 2>&1 | tail -1; /tmp/u/bin/python -c "import requests; print(\"   uv venv ok\", requests.__version__)"
fi
'
done
