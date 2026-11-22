#!/bin/bash
# Codex CLI: what each broken MCP server prints at startup ("MCP client ... failed to start", "MCP startup incomplete"),
# and which config change fixes it. Throwaway CODEX_HOME, invented API key: the model call fails after MCP startup, on purpose.
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
P=$(command -v cygpath >/dev/null && cygpath -m "$W" || echo "$W")   # path as Codex (and TOML) sees it
npm init -y >/dev/null; npm pkg set type=module; npm install @modelcontextprotocol/sdk@1 zod $Q 2>&1 | tail -1
npm install -g @openai/codex${CODEX:+@$CODEX} $Q 2>&1 | tail -1
export CODEX_HOME=$W/codexhome OPENAI_API_KEY=sk-invented-test-key-not-real; mkdir -p "$CODEX_HOME"
echo "== $(uname -s) | node $(node -v) | $(codex --version 2>&1 | tail -1) | sdk $(node -p 'require("./node_modules/@modelcontextprotocol/sdk/package.json").version')"

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

# one config per case, so each startup line is unambiguous
cfg() { printf '%s\n' "$@" > "$CODEX_HOME/config.toml"; }
go() {
  echo; echo "### $1"; shift
  ( timeout 90 codex exec --skip-git-repo-check "say hi" < /dev/null 2>&1 ) | sed 's/\x1b\[[0-9;]*m//g' \
    | grep -avE "^\s*$|^-+$|^(workdir|model|provider|approval|sandbox|reasoning|session id|user|say hi|OpenAI Codex|Reading additional)|responses_websocket|Reconnecting\.\.\.|Falling back from WebSockets" | head -30 | cut -c1-260
  echo "-- codex mcp list"; timeout 60 codex mcp list 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | head -6 | cut -c1-200
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

cfg '[mcp_servers.demo]' 'command = "node"' "args = [\"$P/ok.mjs\"]" '[mcp_servers.demo.env]' 'SLOW = "15"'
go "6. server takes 15 s to start, default startup timeout"

cfg '[mcp_servers.demo]' 'command = "node"' "args = [\"$P/ok.mjs\"]" 'startup_timeout_sec = 30' '[mcp_servers.demo.env]' 'SLOW = "15"'
go "6b. same, startup_timeout_sec = 30"

cfg '[mcp_servers.demo]' 'command = "npx"' 'args = ["-y", "@modelcontextprotocol/server-does-not-exist-xyz"]'
go "7. npx package that doesn't exist"

cfg '[mcp_servers.demo]' 'command = "npx"' 'args = ["-y", "@modelcontextprotocol/server-everything"]'
go "8. npx -y @modelcontextprotocol/server-everything (control, first download)"
echo; echo "== done"
