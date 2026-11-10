#!/usr/bin/env bash
# Ubuntu 22.04 + Python 3.13 from the deadsnakes PPA: python3-venv is installed, but it is the venv for 3.10.
set +e
export DEBIAN_FRONTEND=noninteractive
. /etc/os-release; echo "== $PRETTY_NAME"
apt-get update -qq >/dev/null; apt-get install -y -qq software-properties-common python3 python3-venv >/dev/null 2>&1
add-apt-repository -y ppa:deadsnakes/ppa >/dev/null 2>&1; apt-get update -qq >/dev/null
apt-get install -y -qq python3.13 >/dev/null 2>&1
echo "python3: $(python3 -V 2>&1); python3.13: $(python3.13 -V 2>&1); venv packages: $(dpkg -l | awk '/^ii/ && $2 ~ /^python3(\.[0-9]+)?-venv$/ {print $2}' | tr '\n' ' ')"
cd /tmp && rm -rf d && mkdir d && cd d
echo "== 1. python3 -m venv a (system 3.10)"; python3 -m venv a 2>&1 | tail -1; echo "exit ${PIPESTATUS[0]}"
echo "== 2. python3.13 -m venv b"; python3.13 -m venv b 2>&1 | grep -v '^$'; echo "exit ${PIPESTATUS[0]}"
echo "== 3. apt-get install python3.13-venv, then rm -rf b && python3.13 -m venv b"
apt-get install -y -qq python3.13-venv >/dev/null 2>&1; echo "apt exit $?"
rm -rf b; python3.13 -m venv b 2>&1 | tail -1; echo "exit ${PIPESTATUS[0]}"; b/bin/python -m pip --version 2>&1 | tail -1
echo "== done"
