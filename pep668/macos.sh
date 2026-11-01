#!/bin/bash
# PEP 668 on macOS: Homebrew's Python.
P=$(brew --prefix)/bin/python3; [ -x "$P" ] || brew install -q python 2>&1 | tail -1
echo "$($P --version) at $P, pip $($P -m pip --version | cut -d' ' -f2), $(sw_vers -productName) $(sw_vers -productVersion)"
echo "-- pip install six"; $P -m pip install six 2>&1 | grep -vE "^\s*$" | head -10 | cut -c1-200
echo "-- --user"; $P -m pip install --user six 2>&1 | grep -E "^error|Successfully" | head -1
echo "-- venv"; $P -m venv /tmp/v && /tmp/v/bin/pip install -q requests && /tmp/v/bin/python -c "import requests; print('   venv ok', requests.__version__)"
