# sh: vite: command not found, by cause

For the post [sh: vite: command not found on Linux, macOS, CI and Docker](https://nilaykabariya.blog/fixes/vite-command-not-found).

`ci.sh` builds a minimal Vite project (`vite` as a devDependency, `"build": "vite build"`), makes its lockfile once, then
runs each case in a fresh copy of it. For each command it prints the command, the matching output lines (filtered by
`grep`: not found, Permission denied, built in, added, up to date and similar) and the exit code.

The workflow `.github/workflows/vite-command-not-found.yml` runs it on `ubuntu-latest` and `macos-latest` with Node 24.
No keys, tokens or accounts are used.

| Case | What it does |
|---|---|
| 1 | build with nothing installed |
| 2 | control: `npm ci`, then build |
| 3 | `NODE_ENV=production npm ci` |
| 4 | `npm ci --omit=dev` |
| 5 | `NODE_ENV=production npm ci --include=dev` |
| 6 | `omit=dev` in `.npmrc`, then `npm ci --include=dev` |
| 7 | `vite build` typed in bash and in `sh -c`, then `npx vite build` and `./node_modules/.bin/vite build` |
| 8 | `chmod -x` on `node_modules/vite/bin/vite.js`, then `npm rebuild vite`, then `chmod +x` |
| 8b | the same broken bit, then a clean `npm ci` |
| 9 | `node_modules/.bin` removed, then `npm rebuild` |
| 10 | Docker (Ubuntu only): the image alone, with a bind mount over `/app`, and with an anonymous volume for `/app/node_modules` |

Outputs, November 22, 2026 (Node 24.22.3, npm 11.19.1, Vite 8.3.8):

- `out/run-45042966654-ubuntu.txt`, `out/run-45042966654-macos.txt`: cases 1 to 10 ([run](https://github.com/nils44344/nk-repro/actions/runs/45042966654))
- `out/run-45043227494-ubuntu.txt`, `out/run-45043227494-macos.txt`: the same plus `chmod +x` in case 8 and case 8b ([run](https://github.com/nils44344/nk-repro/actions/runs/45043227494))

```bash
bash ci.sh            # work folder defaults to ./work; set W=/some/tmp to change it
```
