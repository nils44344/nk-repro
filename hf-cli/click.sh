#!/bin/bash
# hf on a pinned huggingface_hub 1.x installed today: does it crash on click, and does `pip install click` fix it? (8 Nov 2026)
set +e
W=${W:-$(pwd)/work-click}; mkdir -p "$W"; cd "$W" || exit 1
echo "== $(date -u +%F) $(python -V)"
for v in 1.10.0 1.16.0 1.17.0; do
  rm -rf "v$v"; python -m venv "v$v"; "v$v/bin/pip" install -q --disable-pip-version-check "huggingface_hub==$v" >/dev/null 2>&1
  echo; echo "### huggingface_hub $v, deps: $("v$v/bin/pip" list 2>/dev/null | grep -iE '^(typer|click) ' | tr -s ' ' | paste -sd',')"
  "v$v/bin/hf" auth whoami > o.txt 2>&1; e=$?; tail -1 o.txt; echo "   exit=$e"
  if grep -q "No module named 'click'" o.txt; then
    echo '$ pip install click'; "v$v/bin/pip" install -q click >/dev/null 2>&1
    "v$v/bin/hf" auth whoami > o.txt 2>&1; e=$?; tail -1 o.txt; echo "   exit=$e"
  fi
done
echo "== done"
