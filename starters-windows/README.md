# 16 framework starters on Windows

Script and raw results for [16 framework starters tested on Windows: what breaks](https://nilaykabariya.blog/tested/framework-starters-on-windows-tested).

`node run.mjs [id ...]` scaffolds each starter with no keyboard input (as in CI), installs, builds, starts the dev server and requests the page. Results go to `results-<os>.json`.

- `results-windows.json`: Windows 11, Node 24.14.0 (Angular also on 24.21.0: `angular` vs `angular-node24.14`).
- `results-linux.json`: the Linux runs the post compares against (Docker `node:24`, Node 24.21.0). Other Linux runs were discarded: the first container run had a `localhost`/IPv6 bug in the script.

On Windows the script puts npm's cache and TEMP on `D:`; edit `ENV` at the top if you don't have a D: drive.
