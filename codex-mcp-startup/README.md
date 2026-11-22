# Codex CLI MCP startup errors, by cause

For the post [Codex MCP startup incomplete: what each failure prints](https://nilaykabariya.blog/agents/codex-mcp-startup-errors).

The workflow `.github/workflows/codex-mcp-startup.yml` runs `run.sh` on `ubuntu-latest` and `windows-latest` (Node 24,
`@openai/codex` from npm, 0.171.0 on the day of the run).

**No real keys or accounts.** `CODEX_HOME` is a throwaway folder inside the runner's temp directory, and the OpenAI key is
the invented string `sk-invented-test-key-not-real`, saved with `codex login --with-api-key`. Every model call therefore
fails with `401 Unauthorized ... invalid_api_key`, on purpose: MCP servers start before the first model call, so their
startup messages are produced anyway. That 401 also shows up as one warning of its own in the TUI's warnings list.

`ok.mjs` is a minimal stdio MCP server (`@modelcontextprotocol/sdk` 1.32.2) with switches set through
`[mcp_servers.demo.env]`: `NEED_KEY` (exit with "DEMO_API_KEY is not set" unless `DEMO_API_KEY` is set), `LOUD` (print one
line to stdout before the handshake), `SLOW=<seconds>` (wait before connecting). `crash.mjs` throws on start.

Each case writes one `config.toml` with one server, `demo`, then:

1. runs `codex exec --skip-git-repo-check "say hi"` with `RUST_LOG=warn` and prints the lines that name MCP or `demo`
   (the default filter of `codex exec` hides stdio startup failures);
2. on Linux only, opens the interactive TUI (`codex --no-alt-screen 'say hi'`) inside tmux, reads the footer after the
   wait, presses F2 (the key the footer names) and prints the warnings list.

| Case | Config |
|---|---|
| 1 | working server |
| 2 | server throws on start |
| 3 / 3b | server exits because its key is not set / the key set in `[mcp_servers.demo.env]` |
| 4 | `command = "nonexistent-command-xyz"` |
| 5 | server prints a line to stdout before the handshake |
| 6 / 6b | server takes 45 s to start, no `startup_timeout_sec` / `startup_timeout_sec = 60` |
| 7 | `npx -y` of a package that doesn't exist |
| 8 | `npx -y @modelcontextprotocol/server-everything` |

Output: run [45055615150](https://github.com/nils44344/nk-repro/actions/runs/45055615150), November 22, 2026
(Codex CLI 0.171.0, Node 24.22.3): `out/run-45055615150-ubuntu.txt` and `out/run-45055615150-windows.txt`.
Earlier runs that day were used to get the capture right (the plain `codex exec` output showed no MCP lines; the TUI
shows failures only in the F2 warnings list).
