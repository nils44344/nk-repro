# 16 framework starters on Windows

Script and raw results for [16 framework starters tested on Windows: what breaks](https://nilaykabariya.blog/tested/framework-starters-on-windows-tested).

`node run.mjs [id ...]` scaffolds each starter with no keyboard input (as in CI), installs, builds, starts the dev server and requests the page. Results go to `results-<os>.json`.

- `results-windows.json`: Windows 11, Node 24.14.0 (Angular also on 24.21.0: `angular` vs `angular-node24.14`).
- `results-linux.json`: the Linux runs the post compares against (Docker `node:24`, Node 24.21.0). Other Linux runs were discarded: the first container run had a `localhost`/IPv6 bug in the script.

On Windows the script puts npm's cache and TEMP on `D:`; edit `ENV` at the top if you don't have a D: drive.

## Re-test: Nuxt 4.7.0 (24 Nov 2026)

Windows 11, Node 24.14.0, npm 11.9.0, isolated profile. Fresh `nuxi init --template minimal`, then `npm i nuxt@4.7.0` (Nitro 2.14.0, Vite 8.3.8):

- `nuxt build`: build complete, exit 0
- `nuxt dev`: 503 while starting, then `GET /` 200 (`<title>Welcome to Nuxt!`), no error in the log

The 4.6.0 500-on-every-page bug stays fixed. Write-up: https://nilaykabariya.blog/tested/framework-starters-on-windows-tested
