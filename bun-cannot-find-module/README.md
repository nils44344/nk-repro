# Bun "Cannot find module", every case

Bun 1.4.2. `npm install` here installs Bun into `node_modules/bun`, then run each folder with that `bun`.

| Folder | Case |
|---|---|
| `e-mono` | Workspace: isolated linker (`Cannot find module '@mono/ui'`, `Cannot find package 'ms'` from `apps/web/phantom.ts`). The files are in their fixed state; remove the `dependencies` from `apps/web/package.json` to see the error, or add `[install] linker = "hoisted"` to a `bunfig.toml`. |
| `f-test`, `g-sub` | `bun test` with a Jest `moduleNameMapper` alias. Delete `f-test/tsconfig.json` to see the error. |
| `c-jsx`, `c2` | `react/jsx-dev-runtime` and `preact/jsx-runtime` (remove `node_modules` first). |
| `h-node`, `d-bunapi` | `bun:sqlite` and `'bun'` under `node`, `tsx`, `tsc`. |
| `i-shebang` | A CLI with a `#!/usr/bin/env node` bin, run through scripts with and without `--bun`. |
| `a-missing-pkg`, `b-relative` | Missing package, missing file, wrong-case import. |
| `linux-test` | `run.sh` for the Linux side, run in `node:24` with this folder mounted at `/w`. Copy `b-relative` into the container before running it: a mounted Windows folder is case-insensitive. |
