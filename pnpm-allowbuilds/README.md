# pnpm ERR_PNPM_IGNORED_BUILDS: which setting makes a clean install pass?

Code behind the post [ERR_PNPM_IGNORED_BUILDS: onlyBuiltDependencies no longer works](https://nilaykabariya.blog/fixes/pnpm-err-pnpm-ignored-builds-allowbuilds). Each script makes a throwaway project in a `work*` folder next to it (esbuild, which has a postinstall script, plus lefthook in two of them), runs `pnpm install`, and prints one line per case: the exit code and the first `ERR_PNPM_*` or "Ignored build scripts" line.

| Script | Question it answers |
|---|---|
| `versions.sh` | What do pnpm 10, 11 and 12 do with `onlyBuiltDependencies` (in `package.json` and in `pnpm-workspace.yaml`) compared with `allowBuilds`? |
| `run.sh` | On pnpm 12 (`PNPM_V` overrides the version), which `allowBuilds` forms pass: name keys, `true` and `false`, and `name@version` keys that do or do not match the locked version? |
| `approve.sh` | On pnpm 12, what do `pnpm approve-builds --all`, `strictDepBuilds: false` and `CI=true` change? |

Run any of them with bash and Node on the PATH (pnpm is fetched with `npx -y pnpm@<version>`):

```bash
bash versions.sh
bash run.sh
PNPM_V=12.18.0 bash run.sh
bash approve.sh
```

Results depend on the pnpm version, so the scripts print the pnpm and Node versions first. The version table in the post comes from a GitHub Actions run of these scripts: [run 42574261589](https://github.com/nils44344/nk-repro/actions/runs/42574261589).
