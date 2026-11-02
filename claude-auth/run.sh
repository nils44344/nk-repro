#!/bin/bash
# Claude Code auth errors with fake keys only, in a throwaway HOME and CLAUDE_CONFIG_DIR (never a real profile).
set +e
W=${W:-$(pwd)/work}; mkdir -p "$W"; cd "$W" || exit 1
export HOME=$W/home CLAUDE_CONFIG_DIR=$W/home/.claude DISABLE_AUTOUPDATER=1; mkdir -p $CLAUDE_CONFIG_DIR
unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN
npm install -g @anthropic-ai/claude-code --no-audit --no-fund --loglevel=error 2>&1 | tail -1
echo "== $(date) node $(node -v) claude $(claude --version 2>&1 | tail -1)"
c() { timeout ${2:-60} claude -p "reply ok" 2>&1 | head -3 | cut -c1-200; echo "   exit ${PIPESTATUS[0]} (124 = still running at the timeout)"; }
FAKE="sk-ant-api03-$(head -c 60 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 80)-AAAAAAAA"
echo "-- no key, not logged in"; c
echo "-- key wrapped in double quotes"; ANTHROPIC_API_KEY="\"$FAKE\"" c
echo "-- well-formed fake key (60 s)"; ANTHROPIC_API_KEY="$FAKE" c 60
echo "-- well-formed fake key, 240 s"; ANTHROPIC_API_KEY="$FAKE" c 240
echo "-- auth status with the fake key"; ANTHROPIC_API_KEY="$FAKE" claude auth status 2>&1 | grep -E "loggedIn|authMethod|apiKeySource" | head -3
echo "== done"
