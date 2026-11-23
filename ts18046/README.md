# TS18046 "'error' is of type 'unknown'" in catch, by TypeScript version

For a post on https://nilaykabariya.blog (link added when it is live).

The workflow `.github/workflows/ts18046.yml` runs `run.sh` on `ubuntu-latest` with Node 24. For each TypeScript version
(5.9.3, 6.0.3, 7.0.2, 7.1.0-beta, each from `npx -p typescript@<version> tsc`) it compiles a `catch` block that reads
`error.message`: without a tsconfig, with the `tsc --init` tsconfig, with no `strict` key, with `strict: false`, and then
each fix (instanceof, a helper, `catch (error: any)`, `catch (error: Error)`, `useUnknownInCatchVariables: false`, a
promise `.catch`, `error.cause`). Case 7 runs in Node to show what `instanceof Error` misses at run time.

**No keys or accounts.** Only the public `typescript` package from npm.
