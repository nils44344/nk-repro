#!/bin/bash
# MCP "-32000: Connection closed": servers that crash, lack a key, or name a missing command, through the official
# TypeScript SDK client; a server that logs to stdout; and claude mcp list in a throwaway profile (no login).
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
Q="--no-audit --no-fund --loglevel=error"
npm init -y >/dev/null; npm pkg set type=module; npm install @modelcontextprotocol/sdk zod $Q 2>&1 | tail -1
echo "== $(date) node $(node -v) sdk $(node -p 'require("./node_modules/@modelcontextprotocol/sdk/package.json").version')"
echo 'throw new Error("config file not found");' > crash.mjs
cat > ok.mjs <<'S'
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
if (process.env.NEED_KEY && !process.env.DEMO_API_KEY) { console.error("DEMO_API_KEY is not set"); process.exit(1); }
if (process.env.LOUD) console.log("starting up (stdout)"), console.log('{"not":"jsonrpc"}');
const s = new McpServer({ name: "demo", version: "1.0.0" });
s.tool("hello", { name: z.string() }, async ({ name }) => { if (process.env.LOUD) console.log("tool called (stdout)"); return { content: [{ type: "text", text: "hi " + name }] }; });
await s.connect(new StdioServerTransport());
S
cat > client.mjs <<'S'
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
const [cmd, ...args] = process.argv.slice(2); const env = { ...process.env };
const c = new Client({ name: "t", version: "1" });
try { await c.connect(new StdioClientTransport({ command: cmd, args, env, stderr: "ignore" }));
  const r = await c.callTool({ name: "hello", arguments: { name: "x" } }); console.log("   connected, tool said: " + r.content[0].text); }
catch (e) { console.log("   " + e.message); } process.exit(0);
S
echo "-- crash.mjs via SDK client"; node client.mjs node crash.mjs; echo "   by hand: $(node crash.mjs 2>&1 | grep -m1 Error:)"
echo "-- needs a key, not set"; NEED_KEY=1 node client.mjs node ok.mjs; echo "   by hand: $(NEED_KEY=1 node ok.mjs 2>&1 | head -1)"
echo "-- needs a key, set"; NEED_KEY=1 DEMO_API_KEY=x node client.mjs node ok.mjs
echo "-- command that doesn't exist"; node client.mjs nonexistent-command-xyz
echo "-- server printing to stdout (before connect and during the tool call)"; LOUD=1 node client.mjs node ok.mjs
echo "######## claude mcp list (throwaway HOME, no login)"
export HOME=$W/home CLAUDE_CONFIG_DIR=$W/home/.claude DISABLE_AUTOUPDATER=1; mkdir -p $CLAUDE_CONFIG_DIR
npm install -g @anthropic-ai/claude-code $Q 2>&1 | tail -1; echo "claude $(claude --version 2>&1 | tail -1)"
claude mcp add -s user crash -- node $W/crash.mjs >/dev/null
claude mcp add -s user nokey -e NEED_KEY=1 -- node $W/ok.mjs >/dev/null
claude mcp add -s user withkey -e NEED_KEY=1 -e DEMO_API_KEY=x -- node $W/ok.mjs >/dev/null
claude mcp add -s user missing -- nonexistent-command-xyz >/dev/null
claude mcp add -s user loud -e LOUD=1 -- node $W/ok.mjs >/dev/null
timeout 120 claude mcp list 2>&1 | grep -aE "crash|nokey|withkey|missing|loud|Connected|Failed|trust|approve" | head -8 | cut -c1-150
echo "== done"
