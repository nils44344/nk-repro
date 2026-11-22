# Cannot find module @rollup/rollup-&lt;platform&gt;, by cause

For the post [Cannot find module @rollup/rollup-linux-x64-gnu](https://nilaykabariya.blog/fixes/rollup-native-binding).

The workflow `.github/workflows/rollup-native-binding.yml` has two jobs. No keys, tokens or accounts are used.

1. `make.sh` on `windows-latest`, `macos-latest` and `ubuntu-latest`: a minimal project with `rollup` as a devDependency,
   `npm install`, one build, then the lockfile and a tarball of `node_modules` are uploaded.
2. `use.sh` on `ubuntu-latest`, with the three packs:

| Case | What it does |
|---|---|
| A-windows / A-macos / A-ubuntu | `npm ci` on Linux with the lockfile made on each OS |
| B-windows / B-macos | `node_modules` made on Windows or macOS, unpacked and run on Linux; then `npm ci` |
| C | `npm ci --omit=optional`; then plain `npm ci` |
| D | `omit=optional` in `.npmrc`; then `npm ci --include=optional` |
| E | `node_modules/@rollup/rollup-linux-x64-gnu` deleted; then `npm i`, `npm rebuild`, and removing both `node_modules` and `package-lock.json` |
| F1 | `npm ci` inside `node:24-alpine` with the Linux (glibc) lockfile |
| F2 | `node_modules` installed on the Ubuntu host, run inside `node:24-alpine` through a bind mount |
| F3 | the same bind mount plus an anonymous volume for `/app/node_modules`, `npm ci` inside |

Outputs, run [45047559200](https://github.com/nils44344/nk-repro/actions/runs/45047559200), November 22, 2026
(Node 24.22.3, npm 11.19.1, rollup 4.68.8): `out/make-45047559200-<os>.txt` and `out/use-45047559200.txt`
(docker pull progress lines removed). Each command prints its key lines (filtered with `grep`) and its exit code.
