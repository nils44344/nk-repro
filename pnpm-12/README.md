# pnpm 11 vs pnpm 12: what the upgrade prints

For the post [pnpm 12 breaking changes, tested](https://nilaykabariya.blog/tested/pnpm-12-breaking-changes-tested).

The workflow `.github/workflows/pnpm-12.yml` runs `run.sh` on `ubuntu-latest` with Node 24. Each case runs in a fresh
folder with pnpm 11 (`npx -y pnpm@11.28.13`) and then pnpm 12 (`npx -y pnpm@12.21.0`) and prints the exit code and the
output. The cases follow pnpm's own list, "What's different in pnpm 12" (https://pnpm.io/blog/whats-different-in-pnpm-12).

**No keys, tokens or accounts.** Only public npm packages (`is-number`, `yarn`), one public GitHub repository
(`sindresorhus/slash`) and two throwaway local tarballs made by the script are used.

| Case | What it tests |
|---|---|
| 1 / 2 / 2b | a misspelled setting in `pnpm-workspace.yaml`, without and with a `packageManager` pin; the right spelling |
| 3 | `pnpm install --frozen-lockfile false`, `--frozen-lockfile=false`, `--no-frozen-lockfile` |
| 4 | `pnpm install --resolution-only`, and `pnpm peers check` |
| 5 | `pnpm add yarn` |
| 6 | `engineStrict` with an optional dependency whose regular dependency needs node >=99 |
| 7 | a `git+ssh://` dependency on a runner with no SSH key |
| 8 | `pnpm add -g` through `sudo` |

Output: run [45111198674](https://github.com/nils44344/nk-repro/actions/runs/45111198674), November 23, 2026 (Node 24.22.3,
pnpm 11.28.13 and 12.21.0): `out/run-45111198674-ubuntu.txt`. An earlier run that day (45110953408) had a script bug
(an extra argument in cases 3 to 7) and is not used.
