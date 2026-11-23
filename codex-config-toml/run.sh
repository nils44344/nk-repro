#!/bin/bash
# Codex CLI: what "Error loading config.toml" prints for each common mistake in ~/.codex/config.toml, and the fix.
# Throwaway CODEX_HOME, invented API key (sk-invented-test-key-not-real): the model call fails with 401 on purpose,
# config errors appear before any model call.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
npm install -g @openai/codex${CODEX:+@$CODEX} --no-audit --no-fund --loglevel=error 2>&1 | tail -1
export CODEX_HOME=$W/codexhome OPENAI_API_KEY=sk-invented-test-key-not-real; mkdir -p "$CODEX_HOME"
printf '%s' "$OPENAI_API_KEY" | codex login --with-api-key >/dev/null 2>&1; echo "login exit $?"
echo "== $(uname -s) | node $(node -v) | $(codex --version 2>&1 | tail -1)"
C="$CODEX_HOME/config.toml"
go() {
  echo; echo "### $1"
  ( timeout 90 codex exec --skip-git-repo-check "say hi" < /dev/null > out.log 2>&1 ); local e=$?
  sed -E 's/\x1b\[[0-9;]*[A-Za-z]//g' out.log | grep -avE "^\s*$|responses_websocket|Reconnecting|Falling back|^-+$|^workdir:|^session id:|^user$|^say hi$|^OpenAI Codex|^model:|^provider:|^approval:|^sandbox:|^reasoning" | head -10 | cut -c1-260
  echo "   exit $e"
}
printf 'model = "gpt-5.2"\n' > "$C";                                   go "1. control: a valid config.toml"
printf 'model = "gpt-5.2\n' > "$C";                                    go "2. unclosed string"
cat > "$C" <<'T'
[mcp_servers.demo]
command = "C:\Users\me\server.exe"
T
go "3. Windows path with backslashes in double quotes"
cat > "$C" <<'T'
[mcp_servers.demo]
command = 'C:\Users\me\server.exe'
T
go "3b. same path in single quotes (literal string)"
cat > "$C" <<'T'
[mcp_servers.demo]
command = "C:\\Users\\me\\server.exe"
T
go "3c. same path with doubled backslashes"
printf '\xef\xbb\xbfmodel = "gpt-5.2"\n' > "$C";                       go "4. UTF-8 with BOM (PowerShell 5.1 Out-File -Encoding utf8)"
printf 'model = "gpt-5.2"\n' | iconv -f utf-8 -t utf-16 > "$C";         go "5. UTF-16 with BOM (PowerShell 5.1 > redirection)"
printf 'model = 5\n' > "$C";                                           go "6. wrong type (number for a string)"
printf 'approval_policy = "sometimes"\n' > "$C";                       go "7. value not in the allowed list (approval_policy)"
printf 'sandbox_mode = "full"\n' > "$C";                               go "8. value not in the allowed list (sandbox_mode)"
printf 'modle = "gpt-5.2"\n' > "$C";                                   go "9. misspelled key (modle)"
printf '[mcp_servers.demo]\ncommand = "node"\n[mcp_servers.demo]\ncommand = "npx"\n' > "$C"; go "10. the same table twice"
printf 'model = "gpt-5.2"\nmodel = "gpt-5.1"\n' > "$C";                go "11. the same key twice"
printf '[mcp_servers.demo]\nargs = ["x"]\n' > "$C";                    go "12. MCP server with no command"
printf 'profile = "work"\n' > "$C";                                    go "13. profile that is not defined"
echo; echo "== done"
