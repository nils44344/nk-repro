#!/bin/bash
# Codex CLI "stdin is not a terminal": plain codex vs codex exec with no terminal attached (CI), throwaway CODEX_HOME,
# invented key. The "user" block Codex prints shows how it read the prompt.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
export CODEX_HOME=$W/codexhome OPENAI_API_KEY=sk-invented-test-key; mkdir -p $CODEX_HOME
npm install -g @openai/codex --no-audit --no-fund --loglevel=error 2>&1 | tail -1
echo "== $(date) node $(node -v) $(codex --version 2>&1 | tail -1), stdin is a tty: $([ -t 0 ] && echo yes || echo no)"
s() { timeout 25 bash -c "$1" 2>&1 | grep -aE "stdin is not a terminal|^user|prompt from|<stdin>|say hi" | head -4 | cut -c1-120; }
echo "-- codex < /dev/null"; s 'codex < /dev/null'
echo '-- echo "say hi" | codex'; s 'echo "say hi" | codex'
echo '-- codex "say hi" < /dev/null'; s 'codex "say hi" < /dev/null'
echo '-- codex exec "say hi" < /dev/null'; s 'codex exec --skip-git-repo-check "say hi" < /dev/null'
echo '-- echo "prompt from pipe" | codex exec'; s 'echo "prompt from pipe" | codex exec --skip-git-repo-check'
echo '-- echo "piped text" | codex exec "prompt from arg"'; s 'echo "piped text" | codex exec --skip-git-repo-check "prompt from arg"'
echo '-- echo "prompt from pipe" | codex exec -'; s 'echo "prompt from pipe" | codex exec --skip-git-repo-check -'
echo "== done"
