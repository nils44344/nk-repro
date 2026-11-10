# Cannot find native binding / Cannot find module '@rolldown/binding-wasm32-wasi' (Vite 8)

`vite build` on Vite 8 stops with this:

```
Error: Cannot find native binding. npm has a bug related to optional dependencies
(https://github.com/npm/cli/issues/4828). Please try `npm i` again after removing
both package-lock.json and node_modules directory.
    at file:///C:/project/node_modules/rolldown/dist/shared/binding-DPuPeV1X.mjs:603:34
  cause: Error: Cannot find module './rolldown-binding.win32-x64-msvc.node'
  cause: Error: Cannot find module '@rolldown/binding-win32-x64-msvc'
  cause: Error: Cannot find module './rolldown-binding.wasi.cjs'
  cause: Error: Cannot find module '@rolldown/binding-wasm32-wasi'
```

On Linux the names are `@rolldown/binding-linux-x64-gnu` and `rolldown-binding.linux-x64-gnu.node`. The file name and
line number in the `at` line change with the Rolldown version.

## What is missing

Rolldown ships one compiled file per operating system, as an optional npm package. The one for your system is not in
`node_modules`.

The last `cause:` line names `@rolldown/binding-wasm32-wasi`. That is the final fallback the loader tried, not the
package you need. The package you are missing is the one with your platform in
its name (`win32-x64-msvc`, `linux-x64-gnu`, `linux-x64-musl`, `darwin-arm64`).

## What `run.sh` does, and what happened

The script makes an empty Vite 8 project, breaks the binding in two ways, and tries each fix. Each row is one step of
the script.

| Step | Windows | Ubuntu |
|---|---|---|
| `npm install -D vite@8`, then `vite build` | 15 packages, built | 15 packages, built |
| Delete the `@rolldown/binding-*` folder, build | Cannot find native binding | Cannot find native binding |
| `npm rebuild`, build | still fails | still fails |
| `npm i` with `package-lock.json` and `node_modules` left in place, build | added 1 package, built | added 1 package, built |
| New project with `omit=optional` in `.npmrc`, install, build | 13 packages, Cannot find native binding | 13 packages, Cannot find native binding |
| Remove that line, `npm i`, build | added 2 packages, built | added 2 packages, built |
| npm 12.2.2: install, delete the binding, `npm i`, build | added 1 package, built | added 1 package, built |

Versions in that run: Vite 8.3.7, Rolldown 1.2.18, Node 24.22.2, npm 11.19.1 (and npm 12.2.2 for the last row),
`windows-latest` and `ubuntu-latest` runners.

Run: https://github.com/nils44344/nk-repro/actions/runs/42652948762 (November 9, 2026). Workflow:
[`rolldown-binding.yml`](../.github/workflows/rolldown-binding.yml).

## The fix

```bash
npm i
```

In these runs a plain `npm i` in the same folder put the binding back. The error message says to delete
`package-lock.json` and `node_modules` first; that was not needed here. Without the lockfile npm also resolves every
other dependency again, so their versions can change.

If the error comes back after `npm i`, npm has been told to skip optional packages:

```bash
npm config get omit
```

If it prints `optional`, remove `omit=optional` from the `.npmrc` it comes from (the project's or your user-level
one) and run `npm i` again.

`npm rebuild` did not help with the deleted folder (row 3). It re-runs install scripts for packages that are already
there; it does not download a missing one.

## Run it yourself

```bash
git clone https://github.com/nils44344/nk-repro
W=/tmp/rolldown-work bash nk-repro/rolldown-binding/run.sh
```

The CI run used Node 24. The script needs network access to the npm registry and builds its test projects in `$W`.

## More

The same message comes from other Rust-based packages (Tailwind CSS 4, Rspack, oxc), and the folder can also break
when one project is shared between Windows and WSL. Those cases are in the post:
https://nilaykabariya.blog/fixes/cannot-find-module-rolldown-binding
