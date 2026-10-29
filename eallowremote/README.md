# npm error code EALLOWREMOTE / EALLOWGIT

npm 12 turns off git and remote (tarball URL) dependencies by default. These scripts run every case on npm 11.20.0 (bundled with Node 26.13.0 LTS) and npm 12.0.2, 12.1.0 and 12.2.1, on Windows 11 with Node 26.13.0.

- `run.sh`: each dependency type (URL on the CLI, URL in package.json, github: shorthand, git+https, GitHub archive .tar.gz, file:), npx with a tarball URL, env var, misspelled .npmrc key and flag, project .npmrc, and `npm ci` on a lockfile written by npm 11. Output: `out-cases.txt`.
- `run-g.sh`: a dependency of a dependency that points at a tarball URL (root vs all vs overrides), plus each fix on 12.2.1. Output: `out-transitive-and-fixes.txt`.

October 29, 2026. Post: https://nilaykabariya.blog/fixes/npm-error-code-eallowremote
