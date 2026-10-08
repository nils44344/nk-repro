set -e
npm i -g bun@1.4.2 >/dev/null 2>&1; bun --version; node --version
cd /w/b-relative; echo "== case-sensitive import (Linux):"; bun run index.ts 2>&1 | head -1 || true
cd /w/i; bun install >/dev/null 2>&1
for v in "run dev" "--bun run dev" "--bun run n" "--bun run direct"; do echo "== bun $v"; bun $v 2>&1 | grep -m1 -v '^\$' || true; done
