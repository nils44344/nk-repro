#!/bin/bash
# Codex CLI: what each broken MCP server prints at startup ("MCP client ... failed to start", "MCP startup incomplete"),
# and which config change fixes it. Throwaway CODEX_HOME, invented API key: the model call fails after MCP startup, on purpose.
# Each case runs `codex exec` with RUST_LOG=warn (its default filter hides stdio startup failures), and on Linux also the
# interactive TUI inside tmux (a real terminal), where the "Booting MCP server" / "MCP startup incomplete" lines live.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
P=$(command -v cygpath >/dev/null && cygpath -m "$W" || echo "$W")   # path as Codex (and TOML) sees it
npm init -y >/dev/null; npm pkg set type=module; npm install @modelcontextprotocol/sdk@1 zod $Q 2>&1 | tail -1
npm install -g @openai/codex${CODEX:+@$CODEX} $Q 2>&1 | tail -1
export CODEX_HOME=$W/codexhome OPENAI_API_KEY=sk-invented-test-key-not-real; mkdir -p "$CODEX_HOME"
printf '%s' "$OPENAI_API_KEY" | codex login --with-api-key >/dev/null 2>&1; echo "login exit $?"
echo "== $(uname -s) | node $(node -v) | $(codex --version 2>&1 | tail -1) | sdk $(node -p 'require("./node_modules/@modelcontextprotocol/sdk/package.json").version')"
TUI=$([ "$(uname -s)" = Linux ] && echo 1)
[ -n "$TUI" ] && ! command -v tmux >/dev/null && sudo apt-get install -y -qq tmux >/dev/null 2>&1; [ -n "$TUI" ] && tmux -V

echo 'throw new Error("config file not found");' > crash.mjs
cat > ok.mjs <<'S'
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
if (process.env.NEED_KEY && !process.env.DEMO_API_KEY) { console.error("DEMO_API_KEY is not set"); process.exit(1); }
if (process.env.LOUD) console.log("starting up (stdout)");
if (process.env.SLOW) await new Promise((r) => setTimeout(r, Number(process.env.SLOW) * 1000));
const s = new McpServer({ name: "demo", version: "1.0.0" });
s.tool("hello", { name: z.string() }, async ({ name }) => ({ content: [{ type: "text", text: "hi " + name }] }));
await s.connect(new StdioServerTransport());
S

strip() { sed -E 's/\x1b\[[0-9;?<>=]*[A-Za-z]//g; s/\x1b\][^\x07]*\x07//g; s/\x1b[()][A-Z0-9]//g; s/\x1b[=>]//g' | tr '\r' '\n'; }
# one config per case, so each startup line is unambiguous; the work folder is trusted so the TUI skips that prompt
cfg() { { printf '%s\n' "$@"; printf '\n[projects."%s"]\ntrust_level = "trusted"\n' "$P"; } > "$CODEX_HOME/config.toml"; }
go() {
  local wait=${2:-40}
  echo; echo "### $1"
  ( RUST_LOG=warn timeout 120 codex exec --skip-git-repo-check "say hi" < /dev/null > exec.log 2>&1 ); echo "-- codex exec (exit $?), lines naming MCP or demo:"
  strip < exec.log | grep -aiE "mcp|demo" | grep -av "api.openai.com" | sort -u | head -8 | cut -c1-300
  if [ -n "$TUI" ]; then
    tmux new-session -d -s cx -x 200 -y 60 "codex --no-alt-screen"   # a real terminal, no prompt: only MCP startup runs; no keys are sent
    sleep "$wait"
    echo "-- TUI screen after ${wait}s (blank lines and the input box removed):"
    tmux capture-pane -p -t cx -S -200 | grep -avE "^\s*$|^\s*[╭╰│─]|for shortcuts|Ask Codex to do anything|OpenAI Codex \(v|^\s+~/|Tip:" | awk '!seen[$0]++' | tail -14 | cut -c1-200
    tmux kill-server 2>/dev/null
  fi
}

cfg '[mcp_servers.demo]' 'command = "node"' "args = [\"$P/ok.mjs\"]"
go "1. control: a working server"

cfg '[mcp_servers.demo]' 'command = "node"' "args = [\"$P/crash.mjs\"]"
go "2. server crashes on start"

cfg '[mcp_servers.demo]' 'command = "node"' "args = [\"$P/ok.mjs\"]" '[mcp_servers.demo.env]' 'NEED_KEY = "1"'
go "3. server exits: its API key is not set"

cfg '[mcp_servers.demo]' 'command = "node"' "args = [\"$P/ok.mjs\"]" '[mcp_servers.demo.env]' 'NEED_KEY = "1"' 'DEMO_API_KEY = "x"'
go "3b. same, key set in [mcp_servers.demo.env]"

cfg '[mcp_servers.demo]' 'command = "nonexistent-command-xyz"'
go "4. command that doesn't exist"

cfg '[mcp_servers.demo]' 'command = "node"' "args = [\"$P/ok.mjs\"]" '[mcp_servers.demo.env]' 'LOUD = "1"'
go "5. server prints a line to stdout before the handshake"

cfg '[mcp_servers.demo]' 'command = "node"' "args = [\"$P/ok.mjs\"]" '[mcp_servers.demo.env]' 'SLOW = "45"'
go "6. server takes 45 s to start, no startup_timeout_sec set" 70

cfg '[mcp_servers.demo]' 'command = "node"' "args = [\"$P/ok.mjs\"]" 'startup_timeout_sec = 60' '[mcp_servers.demo.env]' 'SLOW = "45"'
go "6b. same, startup_timeout_sec = 60" 70

cfg '[mcp_servers.demo]' 'command = "npx"' 'args = ["-y", "@modelcontextprotocol/server-does-not-exist-xyz"]'
go "7. npx package that doesn't exist"

cfg '[mcp_servers.demo]' 'command = "npx"' 'args = ["-y", "@modelcontextprotocol/server-everything"]'
go "8. npx -y @modelcontextprotocol/server-everything (control, first download)" 60
echo; echo "== done"
