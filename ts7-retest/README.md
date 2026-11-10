# TypeScript 7: ts-jest, typescript-eslint, ts-node and typedoc errors

With `typescript@7.0.2` installed as `typescript`, the usual TypeScript tools stop with these messages:

```
ts-jest:
  The TypeScript compiler "typescript" (version 7.0.2) does not expose the JavaScript compiler API required by
  ts-jest. To use TypeScript 7 for project type-checking, install it as "@typescript/native" and alias
  "@typescript/typescript6" ...

typescript-eslint:
  typescript-eslint does not support TS 7.0.

ts-node:
  TypeError: Cannot read properties of undefined (reading 'fileExists')

typedoc:
  TypeError: Cannot read properties of undefined (reading 'PropertyDeclaration')
```

A plain `npm install` of these tools with TypeScript 7 fails before that, with
`ERESOLVE unable to resolve dependency tree` and `peer typescript@">=4.3 <7" from ts-jest@29.4.15`.

## Why

TypeScript 7 is the native (Go) compiler. It does not ship the JavaScript compiler API that these tools load with
`require("typescript")`. That API stays in the TypeScript 6 line, published as `@typescript/typescript6`.

## What `run.sh` does, and what happened

The script makes a small project (one source file, one Jest test, a type-checked ESLint config), installs TypeScript
7.0.2 with ts-jest, typescript-eslint, ts-node and typedoc, runs each tool, then installs TypeScript 7 and 6 side by
side and runs them again.

Run on GitHub Actions on November 7, 2026: https://github.com/nils44344/nk-repro/actions/runs/42337655212
(workflow [`ts7-retest.yml`](../.github/workflows/ts7-retest.yml)). Node 24.22.2, `ubuntu-latest` and
`windows-latest`, with the newest tool versions on npm that day: ts-jest 29.4.15, typescript-eslint 8.72.1,
ts-node 10.9.2, typedoc 0.28.20, Jest 30.5.2, ESLint 10. Both systems gave the same results.

| Step | Result |
|---|---|
| `npm install -D typescript@7.0.2` with the four tools | `ERESOLVE`: ts-jest wants `typescript >=4.3 <7` |
| Same install with `--legacy-peer-deps` | installs; `tsc --version` prints `Version 7.0.2` |
| `npx jest` | test suite fails to run: "does not expose the JavaScript compiler API required by ts-jest" |
| `npx eslint src` | "typescript-eslint does not support TS 7.0." |
| `npx ts-node src/index.ts` | `Cannot read properties of undefined (reading 'fileExists')` |
| `npx typedoc src/index.ts` | `Cannot read properties of undefined (reading 'PropertyDeclaration')` |
| `npx tsx src/index.ts` (tsx 4.23.15) | runs, prints `3` |
| `npm install -D @typescript/native` (the name in the ts-jest message) | `ERESOLVE` |
| TypeScript 7 and 6 side by side (below), then `tsc --noEmit` | passes, `tsc` is still 7.0.2 |
| ...then jest, eslint, ts-node, typedoc | all pass |

## The fix: TypeScript 7 and 6 side by side

Install TypeScript 7 under the name `@typescript/native`, and TypeScript 6 under the name `typescript`, which is where
the tools look for the compiler API:

```bash
npm install -D "@typescript/native@npm:typescript@7.0.2" "typescript@npm:@typescript/typescript6@^6.0.2" --legacy-peer-deps
```

In `package.json` that is:

```json
"devDependencies": {
  "@typescript/native": "npm:typescript@7.0.2",
  "typescript": "npm:@typescript/typescript6@^6.0.2"
}
```

In the run above, `npx tsc --version` still printed `Version 7.0.2` after this, `tsc --noEmit` passed, and ts-jest,
typescript-eslint, ts-node and typedoc all worked again.

If you only need to run `.ts` files, `tsx` worked on plain TypeScript 7 without any of this.

## Run it yourself

```bash
git clone https://github.com/nils44344/nk-repro
W=/tmp/ts7-work bash nk-repro/ts7-retest/run.sh
```

It needs Node 24 and the npm registry. It builds the test project in `$W`. Set `TOOLS=latest` to install the newest
versions of the tools instead of the pinned ones.

## More

Nine tools on TypeScript 7 in detail, including webpack's ts-loader, and what the side-by-side setup changes:
https://nilaykabariya.blog/tested/typescript-7-compatibility-tools-tested
