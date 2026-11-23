# Codex CLI "Error loading config.toml", by mistake

For a post on https://nilaykabariya.blog (link added when it is live).

The workflow `.github/workflows/codex-config-toml.yml` runs `run.sh` on `ubuntu-latest` and `windows-latest` (Node 24,
`@openai/codex` from npm). Each case writes one `config.toml` with one mistake (an unclosed string, Windows backslashes,
a UTF-8 BOM, UTF-16, a wrong type, a value outside the allowed list, a misspelled key, a duplicate table or key, an MCP
server with no command, an undefined profile), runs `codex exec --skip-git-repo-check "say hi"` and prints what Codex says.

**No real keys or accounts.** `CODEX_HOME` is a throwaway folder in the runner's temp directory and the OpenAI key is the
invented string `sk-invented-test-key-not-real`, so every model call fails with `401` on purpose; config errors show
before that.
