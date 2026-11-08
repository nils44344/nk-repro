#!/bin/bash
# "huggingface-cli: command not found": what each huggingface_hub version installs and does (8 Nov 2026).
# One fresh venv per version; no token, so `whoami` shows the not-logged-in message. Downloads one small public file.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
echo "== $(date -u +%F) $(python -V) $(uname -s)"
for v in 0.36.0 1.0.0 1.10.0 1.10.1 1.33.0 2.0.0 2.4.0; do
  rm -rf "v$v"; python -m venv "v$v"; "v$v/bin/pip" install -q --disable-pip-version-check "huggingface_hub==$v" >/dev/null 2>&1
  echo; echo "### huggingface_hub $v   (bin: $(ls v$v/bin | grep -E '^(hf|huggingface-cli)$' | tr '\n' ' '))"
  PATH="$W/v$v/bin:/usr/bin:/bin"
  echo '$ huggingface-cli whoami'; huggingface-cli whoami 2>&1 | head -3; echo "   exit=${PIPESTATUS[0]}"
  echo '$ hf auth whoami'; hf auth whoami 2>&1 | head -2; echo "   exit=${PIPESTATUS[0]}"
done
echo; echo "### upgrade in place: 0.36.0 -> 2.4.0"
rm -rf vup; python -m venv vup; vup/bin/pip install -q "huggingface_hub==0.36.0" >/dev/null 2>&1; ls vup/bin | grep -E '^(hf|huggingface-cli)$' | tr '\n' ' '; echo
vup/bin/pip install -q -U "huggingface_hub==2.4.0" >/dev/null 2>&1; ls vup/bin | grep -E '^(hf|huggingface-cli)$' | tr '\n' ' '; echo
echo; echo "### the new commands, 2.4.0"
PATH="$W/v2.4.0/bin:/usr/bin:/bin"
hf --help 2>&1 | sed -n '1,40p'
echo '$ hf download openai-community/gpt2 config.json --local-dir dl'; hf download openai-community/gpt2 config.json --local-dir dl 2>&1 | tail -2; ls -la dl/config.json 2>&1 | awk '{print $5, $NF}'
echo "== done"
