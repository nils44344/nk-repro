#!/bin/bash
# After "stdin is not a terminal": the errors codex exec gives next in CI (8 Nov 2026). No terminal, throwaway
# CODEX_HOME, an invented key (so any model call fails with 401, which shows the run got that far).
set +e
W=${W:-$(pwd)/work-next}; mkdir -p "$W"; cd "$W" || exit 1
export CODEX_HOME=$W/codexhome; mkdir -p $CODEX_HOME
npm install -g @openai/codex@latest --no-audit --no-fund --loglevel=error 2>&1 | tail -1
echo "== $(date -u +%F) node $(node -v) $(codex --version 2>&1 | tail -1), stdin tty: $([ -t 0 ] && echo yes || echo no)"
s() { echo "-- $1"; timeout 40 bash -c "$1" < /dev/null 2>&1 | grep -av "^\s*$" | grep -aviE "^(\[|-+$|workdir|model|provider|approval|sandbox|reasoning|session id|OpenAI Codex)" | head -4 | cut -c1-150; echo "   exit=${PIPESTATUS[0]}"; }
mkdir -p plain repo && (cd repo && git init -q)
cd "$W/plain"
echo; echo "### 1. outside a git repository"
OPENAI_API_KEY=sk-invented-test-key s 'codex exec "say hi"'
OPENAI_API_KEY=sk-invented-test-key s 'codex exec --skip-git-repo-check "say hi"'
cd "$W/repo"
echo; echo "### 2. inside a git repository"
OPENAI_API_KEY=sk-invented-test-key s 'codex exec "say hi"'
echo; echo "### 3. no key and not signed in"
s 'env -u OPENAI_API_KEY codex exec "say hi"'
echo; echo "### 4. key from CODEX_API_KEY instead"
CODEX_API_KEY=sk-invented-test-key s 'env -u OPENAI_API_KEY codex exec "say hi"'
echo "== done"
