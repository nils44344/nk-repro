#!/bin/bash
# PyYAML installs in clean python slim images (no gcc), 30 Oct 2026
for img in python:3.15-slim python:3.14-slim python:3.15; do
  echo "== $img: pip install pyyaml"
  docker run --rm $img sh -c 'pip install --root-user-action=ignore --disable-pip-version-check pyyaml 2>&1 | grep -E "Downloading|error|Error|falling back|Successfully|Building wheel" | head -8; python -c "import yaml;print(\"yaml\", yaml.__version__, \"libyaml C:\", yaml.__with_libyaml__)"'
done
echo "== python:3.14-slim: pyyaml==5.4.1"
docker run --rm python:3.14-slim sh -c 'pip install --root-user-action=ignore --disable-pip-version-check pyyaml==5.4.1 2>&1 | grep -E "error|Error|cython_sources|Successfully" | head -6'
echo "== python:3.14-slim: pyyaml==5.4.1 + cython<3 --no-build-isolation"
docker run --rm python:3.14-slim sh -c 'pip install -q --root-user-action=ignore --disable-pip-version-check "cython<3" setuptools wheel; pip install --root-user-action=ignore --disable-pip-version-check --no-build-isolation pyyaml==5.4.1 2>&1 | grep -E "error|Error|falling back|Successfully" | head -6; python -c "import yaml;print(\"yaml\", yaml.__version__, \"libyaml C:\", yaml.__with_libyaml__)"'
