# eslint10

"ESLint couldn't find an eslint.config.* file" after moving from ESLint 9 to 10 with only an old `.eslintrc.json`.

| | ESLint 9.39.5 | ESLint 10.12.0 |
|---|---|---|
| Message | `couldn't find an eslint.config.(js\|mjs\|cjs) file` | `couldn't find an eslint.config.* file` |
| `ESLINT_USE_FLAT_CONFIG=false` | still loads `.eslintrc`, with a deprecation warning | ignored: same error |

Re-checked on ESLint 10.15.0 on 14 Nov 2026 (Node, clean folder, no config): same message, `ESLint: 10.15.0`.

Folders `a-eslintrc` to `e-react` are the starting projects (plain eslintrc, v9 flat config, env globals, Next.js, React).
Full write-up with the fix (`npx @eslint/migrate-config`) and the config to paste:
https://nilaykabariya.blog/fixes/eslint-couldnt-find-an-eslint-config-file
