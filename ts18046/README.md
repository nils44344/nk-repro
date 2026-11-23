# TS18046 "'error' is of type 'unknown'" in catch, by TypeScript version

For the post [Fix: TS18046 'error' is of type 'unknown' in a catch block](https://nilaykabariya.blog/fixes/typescript-error-is-of-type-unknown-ts18046).

The workflow `.github/workflows/ts18046.yml` runs `run.sh` on `ubuntu-latest` with Node 24. For each TypeScript version
(5.9.3, 6.0.3, 7.0.2, 7.1.0-beta, each from `npx -p typescript@<version> tsc`) it compiles a `catch` block that reads
`error.message`: without a tsconfig, with the `tsc --init` tsconfig, with no `strict` key, with `strict: false`, and then
each fix (instanceof, a helper, `catch (error: any)`, `catch (error: Error)`, `useUnknownInCatchVariables: false`, a
promise `.catch`, `error.cause`). Case 7 runs in Node to show what `instanceof Error` misses at run time.

**No keys or accounts.** Only the public `typescript` package from npm.

Output: run [45112034396](https://github.com/nils44344/nk-repro/actions/runs/45112034396), November 23, 2026 (Node 24.22.3):
`out/run-45112034396-ubuntu.txt`. An earlier run that day (45111579412) left `dom` out of `lib` in cases 6 and 8, so
`console` was not found there; it is not used. GitHub Actions adds an `##[error]` prefix to each compiler error line.
