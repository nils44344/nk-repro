#!/usr/bin/env bash
# "The virtual environment was not created successfully because ensurepip is not available".
# Runs as root inside a clean Debian or Ubuntu container. Usage: bash ensurepip-venv/run.sh
set +e
export DEBIAN_FRONTEND=noninteractive
. /etc/os-release; echo "== $PRETTY_NAME"
apt-get update -qq >/dev/null; apt-get install -y -qq python3 curl ca-certificates >/dev/null 2>&1
echo "python3: $(python3 -V 2>&1); venv packages installed: $(dpkg -l | awk '/^ii/ && $2 ~ /^python3(\.[0-9]+)?-venv$/ {print $2}' | tr '\n' ' ')"
cd /tmp && rm -rf app && mkdir app && cd app
echo "== 1. python3 -m venv .venv"
python3 -m venv .venv 2>&1 | grep -v '^$'; echo "exit ${PIPESTATUS[0]}"
echo "   left behind: $(ls -d .venv 2>/dev/null && ls .venv/bin 2>/dev/null | tr '\n' ' ')"
echo "== 2. source .venv/bin/activate && pip install requests (what people try next)"
( . .venv/bin/activate 2>/dev/null && pip install requests 2>&1 | tail -2; echo "   pip resolves to: $(command -v pip || echo none)" )
echo "== 3. python3 -m venv --without-pip v2"
python3 -m venv --without-pip v2 2>&1 | tail -2; echo "exit ${PIPESTATUS[0]}"; v2/bin/python -m pip --version 2>&1 | tail -1
echo "== 4. uv venv (no python3-venv package)"
curl -LsSf https://astral.sh/uv/install.sh 2>/dev/null | sh >/dev/null 2>&1; UV=$HOME/.local/bin/uv
$UV venv v3 --python /usr/bin/python3 2>&1 | tail -1; v3/bin/python -V 2>&1
$UV pip install --python v3/bin/python requests 2>&1 | tail -1
echo "== 5. apt-get install python3-venv"
apt-get install -y -qq python3-venv >/dev/null 2>&1; echo "exit $?; now installed: $(dpkg -l | awk '/^ii/ && $2 ~ /^python3(\.[0-9]+)?-venv$/ {print $2}' | tr '\n' ' ')"
echo "== 6. python3 -m venv .venv again, over the half-made folder"
python3 -m venv .venv 2>&1 | tail -2; echo "exit ${PIPESTATUS[0]}"; .venv/bin/python -m pip --version 2>&1 | tail -1
echo "== 7. rm -rf .venv && python3 -m venv .venv"
rm -rf .venv; python3 -m venv .venv 2>&1 | tail -2; echo "exit ${PIPESTATUS[0]}"; .venv/bin/python -m pip --version 2>&1 | tail -1
.venv/bin/pip install -q requests 2>&1 | tail -1; .venv/bin/python -c "import requests; print('requests', requests.__version__)"
echo "== done"
