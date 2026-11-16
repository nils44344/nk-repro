# eallowgit

Repro for the post [npm error code EALLOWGIT, tested](https://nilaykabariya.blog/fixes/npm-error-code-eallowgit).

`ci.sh` runs every git dependency case on each npm version in `NPMS` (default `11.21.2 12.2.2`): `github:` shorthand, `git+https`, a tag, `#semver:`, a command-line install, `npx`, the three `allow-git` values, where the setting is read from, invalid values, an optional git dependency, and `npm ci` on a lockfile written by npm 11.

Run it on GitHub Actions with the `eallowgit` workflow (Ubuntu and Windows), or locally: `W=./work NPMS="11.21.2 12.2.2" bash eallowgit/ci.sh`.
