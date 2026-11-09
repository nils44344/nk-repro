# nk-repro

The exact code behind the fixes on [nilaykabariya.blog](https://nilaykabariya.blog). Every post there is reproduced on a real machine before it's written up. This repo is that reproduction, so you can run it yourself and check.

| Folder | Post | What it reproduces |
|---|---|---|
| [`supabase-42501`](supabase-42501) | [Supabase error 42501: new row violates row-level security policy](https://nilaykabariya.blog/database/supabase-error-42501-row-level-security) | Every 42501 case on a local Supabase stack: missing policies, `insert().select()`, `user_id`, upsert, Storage, and the "permission denied for table" grants change |
| [`prisma-init`](prisma-init) | [prisma generate not working: "No command registered" (Prisma 8)](https://nilaykabariya.blog/database/prisma-generate-no-command-registered-prisma-8) | A fresh install getting the Prisma 8 release candidate, then pinned back to Prisma 7 with a working query |
| [`prisma-ci`](prisma-ci) | same post | `npx prisma generate` in a folder with nothing installed (the Docker/CI case) |
| [`prisma6-noinit`](prisma6-noinit), [`prisma-noinit`](prisma-noinit) | [@prisma/client did not initialize yet (Prisma 6 and 7)](https://nilaykabariya.blog/database/prisma-client-did-not-initialize-yet) | The error on Prisma 6, and the different errors Prisma 7 throws for the same mistake |
| [`prisma6-noinit`](prisma6-noinit), [`prisma-init`](prisma-init) | [Prisma P1001: Can't reach database server](https://nilaykabariya.blog/database/prisma-p1001-cant-reach-database-server) | P1001 from the CLI and at runtime (`rt.cjs`, `rt7b.ts`) |
| [`prisma-p1012`](prisma-p1012) | [Prisma P1012: "url is no longer supported in schema files"](https://nilaykabariya.blog/database/prisma-datasource-url-no-longer-supported-p1012) | Prisma 7 rejecting `url`/`directUrl` in the schema, the config without `dotenv`, the adapter error, and the direct/pooled URL split (`prisma.config.ts`, `src/adapter.ts`) |
| [`drizzle-failed-query`](drizzle-failed-query) | [Drizzle "Failed query" error: find the real cause](https://nilaykabariya.blog/database/drizzle-failed-query-error) | Five DrizzleQueryError causes with PGlite, e.code vs e.cause.code on 0.43/0.44/0.45, and the migration case |
| [`eslint10`](eslint10) | [ESLint "couldn't find an eslint.config.* file" (ESLint 10)](https://nilaykabariya.blog/fixes/eslint-couldnt-find-an-eslint-config-file) | `.eslintrc` on ESLint 10 vs 9, the migrator, globals, eslint-config-next and eslint-plugin-react on ESLint 10 (ERESOLVE, overrides, jsx-runtime) |
| [`next-security`](next-security) | [Next.js 16.3 vulnerabilities: which version is patched?](https://nilaykabariya.blog/tested/nextjs-16-3-vulnerabilities-which-version-is-patched) | `npm audit` and `next build` at 16.3.0, 16.3.7, 16.3.8 and 16.4.0 (`check.sh <version>`), plus what `npm audit fix` and `next upgrade` install |
| [`gemini-429`](gemini-429) | [Gemini API 429 RESOURCE_EXHAUSTED](https://nilaykabariya.blog/ai/gemini-api-429-resource-exhausted) and [Gemini 2.5 Flash "no longer available to new users"](https://nilaykabariya.blog/ai/gemini-2-5-flash-no-longer-available-to-new-users) | Free-tier limits hit on purpose, the retry helper, and every retired model name |
| [`starters-windows`](starters-windows) | [16 framework starters tested on Windows: what breaks](https://nilaykabariya.blog/tested/framework-starters-on-windows-tested) | Scaffold, install, build and dev server for 16 starters on Windows 11 and Linux |
| [`bun-cannot-find-module`](bun-cannot-find-module) | [Bun "error: Cannot find module": every cause, tested](https://nilaykabariya.blog/fixes/bun-error-cannot-find-module) | Workspaces on the isolated linker, `bun test` aliases, the JSX runtime, `bun:sqlite` outside Bun (and `--bun` on Windows), wrong-case imports on Linux |

<!-- index:start -->
## Every folder and its post

94 folders, generated from the links in the posts. Each post links back to the exact folder it ran.

| Folder | Post |
|---|---|
| [`agents-windows`](agents-windows) | [Claude Code, Codex, Gemini CLI on Windows: install tested](https://nilaykabariya.blog/tested/ai-coding-agents-windows-install-tested) |
| [`anthropic-auth`](anthropic-auth) | [Fix: Could not resolve authentication method (Anthropic / Claude SDK)](https://nilaykabariya.blog/ai/anthropic-could-not-resolve-authentication-method) |
| [`anthropic-sdk2`](anthropic-sdk2) | [Claude SDK: unexpected keyword argument temperature, betas](https://nilaykabariya.blog/ai/anthropic-messages-create-unexpected-keyword-argument) |
| [`api-connection-error`](api-connection-error) | [Fix: APIConnectionError "Connection error." (OpenAI, Anthropic)](https://nilaykabariya.blog/ai/openai-apiconnectionerror-connection-error) |
| [`bigint-bindings`](bigint-bindings) | [Fix: bigint Failed to load bindings, pure JS will be used](https://nilaykabariya.blog/fixes/bigint-failed-to-load-bindings-pure-js-will-be-used) |
| [`bun-cannot-find-module`](bun-cannot-find-module) | [Bun "error: Cannot find module": every cause, tested](https://nilaykabariya.blog/fixes/bun-error-cannot-find-module) |
| [`bun-check`](bun-check) | [bun check vs tsc: TypeScript type-check speed, tested](https://nilaykabariya.blog/tested/bun-check-vs-tsc-typescript-type-check-tested) |
| [`bun-vs-node`](bun-vs-node) | [Bun vs Node.js 24 benchmark: startup, TypeScript and tests](https://nilaykabariya.blog/tested/bun-vs-node-24-startup-typescript-tests) |
| [`certs`](certs) | [Fix: self-signed certificate in certificate chain (npm)](https://nilaykabariya.blog/fixes/self-signed-certificate-in-certificate-chain-npm) |
| [`claude-auth`](claude-auth) | [Fix: Claude Code "Invalid API key · Fix external API key"](https://nilaykabariya.blog/agents/claude-code-invalid-api-key-please-run-login) |
| [`claude-exe-npm12`](claude-exe-npm12) | [Fix: Claude Code "not compatible with the version of Windows"](https://nilaykabariya.blog/agents/claude-code-exe-not-compatible-with-windows-npm-12) |
| [`claude-temperature`](claude-temperature) | [Claude "temperature is deprecated for this model" (400)](https://nilaykabariya.blog/ai/claude-temperature-is-deprecated-for-this-model) |
| [`codex-stdin`](codex-stdin) | [Fix: Codex CLI error "stdin is not a terminal"](https://nilaykabariya.blog/agents/codex-cli-stdin-is-not-a-terminal) |
| [`deno-deploy-move`](deno-deploy-move) | [Deno Deploy shutdown: move to Workers or Node, tested](https://nilaykabariya.blog/deploy/deno-deploy-shutdown-move-to-workers-or-node) |
| [`distutils`](distutils) | [No module named 'distutils' (Python 3.12+): 3 fixes, tested](https://nilaykabariya.blog/fixes/no-module-named-distutils-python-3-12) |
| [`dockerperm`](dockerperm) | [Docker permission denied on docker.sock after usermod (Ubuntu)](https://nilaykabariya.blog/deploy/permission-denied-docker-daemon-socket) |
| [`drizzle-failed-query`](drizzle-failed-query) | [Drizzle "Failed query" error: find the real cause](https://nilaykabariya.blog/database/drizzle-failed-query-error) |
| [`eacces`](eacces) | [npm error code EACCES: permission denied, 3 causes tested](https://nilaykabariya.blog/fixes/npm-error-code-eacces-permission-denied) |
| [`eaddrinuse-windows`](eaddrinuse-windows) | [Windows 11 address already in use: 3 traps beyond taskkill](https://nilaykabariya.blog/fixes/eaddrinuse-address-already-in-use-windows) |
| [`eallowremote`](eallowremote) | [Fix: npm error code EALLOWREMOTE (and EALLOWGIT), tested](https://nilaykabariya.blog/fixes/npm-error-code-eallowremote) |
| [`ebusy-windows`](ebusy-windows) | [Fix: EBUSY: resource busy or locked (npm, Windows)](https://nilaykabariya.blog/fixes/ebusy-resource-busy-or-locked-npm-windows) |
| [`erasable-syntax`](erasable-syntax) | [TS1294: syntax not allowed with 'erasableSyntaxOnly', fixed](https://nilaykabariya.blog/fixes/erasablesyntaxonly-syntax-not-allowed-ts1294) |
| [`eresolve`](eresolve) | [Fix: npm ERESOLVE unable to resolve dependency tree (React 19)](https://nilaykabariya.blog/fixes/npm-eresolve-unable-to-resolve-dependency-tree) |
| [`err-module-not-found`](err-module-not-found) | [Fix: ERR_MODULE_NOT_FOUND Cannot find module in ES modules](https://nilaykabariya.blog/fixes/err-module-not-found-cannot-find-module-esm) |
| [`esbuild-dynamic-require`](esbuild-dynamic-require) | [Fix: Dynamic require of "react" / "fs" is not supported](https://nilaykabariya.blog/fixes/dynamic-require-of-is-not-supported-esbuild) |
| [`eslint10`](eslint10) | [ESLint "couldn''t find an eslint.config.* file" (ESLint 10)](https://nilaykabariya.blog/fixes/eslint-couldnt-find-an-eslint-config-file) |
| [`esm-dirname`](esm-dirname) | [Fix: require, __dirname not defined in ES module scope](https://nilaykabariya.blog/fixes/dirname-is-not-defined-in-es-module-scope) |
| [`etarget`](etarget) | [npm error code ETARGET: No matching version found (5 causes)](https://nilaykabariya.blog/fixes/npm-error-code-etarget-no-matching-version-found) |
| [`gemini-429`](gemini-429) | ["No longer available to new users": Gemini 2.5 Flash fix](https://nilaykabariya.blog/ai/gemini-2-5-flash-no-longer-available-to-new-users)<br>[Gemini "model is not found for API version v1beta": the fix](https://nilaykabariya.blog/ai/gemini-model-is-not-found-for-api-version-v1beta)<br>[Gemini API 429 RESOURCE_EXHAUSTED: why your limit is 0](https://nilaykabariya.blog/ai/gemini-api-429-resource-exhausted) |
| [`hf-cli`](hf-cli) | [huggingface-cli: command not found (removed in 1.0, not 2.0)](https://nilaykabariya.blog/ai/huggingface-cli-command-not-found) |
| [`import-outside-module`](import-outside-module) | [Fix: “Cannot use import statement outside a module”](https://nilaykabariya.blog/fixes/cannot-use-import-statement-outside-a-module) |
| [`install-speed`](install-speed) | [npm vs pnpm vs Yarn vs Bun: install speed benchmark (2026)](https://nilaykabariya.blog/tested/npm-vs-pnpm-vs-yarn-vs-bun-install-speed) |
| [`libatomic`](libatomic) | [Node 26 error: libatomic.so.1 cannot open shared object file](https://nilaykabariya.blog/fixes/node-26-libatomic-so-1-cannot-open-shared-object-file) |
| [`mcp-32000`](mcp-32000) | [Fix: MCP error -32000 Connection closed / Failed to connect](https://nilaykabariya.blog/agents/mcp-error-32000-connection-closed) |
| [`missing-script`](missing-script) | [Fix: npm error Missing script: "dev" (and "start")](https://nilaykabariya.blog/fixes/npm-error-missing-script-dev) |
| [`modnf`](modnf) | [ModuleNotFoundError: No module named X, but it's installed](https://nilaykabariya.blog/fixes/modulenotfounderror-no-module-named-but-installed) |
| [`native-binding`](native-binding) | ["Cannot find native binding" in Vite 8: the missing @rolldown file](https://nilaykabariya.blog/fixes/cannot-find-module-rolldown-binding) |
| [`next-security`](next-security) | [Next.js 16.3 vulnerabilities: which version is patched?](https://nilaykabariya.blog/tested/nextjs-16-3-vulnerabilities-which-version-is-patched) |
| [`node26`](node26) | [Node 26 vs Node 24: what breaks when you upgrade, tested](https://nilaykabariya.blog/tested/node-26-vs-node-24-upgrade-tested) |
| [`not-recognized`](not-recognized) | ['vite' is not recognized as an internal or external command](https://nilaykabariya.blog/fixes/is-not-recognized-as-an-internal-or-external-command) |
| [`npm-ci-eusage`](npm-ci-eusage) | [npm ci EUSAGE: lock file not in sync (6 causes, tested)](https://nilaykabariya.blog/fixes/npm-ci-eusage-package-json-lock-file-not-in-sync) |
| [`npm-enoent`](npm-enoent) | [npm error code ENOENT, and spawn npx ENOENT on Windows](https://nilaykabariya.blog/fixes/npm-error-code-enoent) |
| [`npm-versions`](npm-versions) | [npm error Invalid Version: lockfile or package.json?](https://nilaykabariya.blog/fixes/npm-error-invalid-version)<br>[npm warn EBADENGINE Unsupported engine, tested](https://nilaykabariya.blog/fixes/npm-warn-ebadengine-unsupported-engine) |
| [`npm12-breaking`](npm12-breaking) | [npm 12 breaking changes, tested: what actually breaks](https://nilaykabariya.blog/tested/npm-12-breaking-changes-tested) |
| [`openai-401`](openai-401) | [Fix: The OPENAI_API_KEY environment variable is missing or empty](https://nilaykabariya.blog/ai/openai-api-key-environment-variable-missing-or-empty) |
| [`openai-chatcompletion`](openai-chatcompletion) | [module 'openai' has no attribute 'ChatCompletion', tested](https://nilaykabariya.blog/ai/openai-has-no-attribute-chatcompletion) |
| [`openai-key`](openai-key) | [Fix: The OPENAI_API_KEY environment variable is missing or empty](https://nilaykabariya.blog/ai/openai-api-key-environment-variable-missing-or-empty) |
| [`openai-responses-params`](openai-responses-params) | [Responses.create() unexpected keyword argument: new names](https://nilaykabariya.blog/ai/openai-responses-create-unexpected-keyword-argument) |
| [`openai-shutdown`](openai-shutdown) | [OpenAI Oct 23 model shutdown: the 404, list, replacements](https://nilaykabariya.blog/ai/openai-model-shutdown-october-23-2026) |
| [`ossl-evp`](ossl-evp) | [digital envelope routines::unsupported (ERR_OSSL_EVP): fix](https://nilaykabariya.blog/fixes/err-ossl-evp-unsupported-digital-envelope-routines) |
| [`p2002`](p2002) | [Prisma P2002 on Prisma 7: e.meta.target is now undefined](https://nilaykabariya.blog/database/prisma-p2002-unique-constraint-failed) |
| [`pep668`](pep668) | [pip error: externally-managed-environment, tested on 8 systems](https://nilaykabariya.blog/fixes/error-externally-managed-environment-pip) |
| [`pgauth`](pgauth) | [Postgres password authentication failed (password is right)](https://nilaykabariya.blog/database/password-authentication-failed-for-user-postgres) |
| [`pkg-resources`](pkg-resources) | [No module named 'pkg_resources': setuptools 82 removed it](https://nilaykabariya.blog/fixes/no-module-named-pkg-resources) |
| [`prisma-ci`](prisma-ci) | [prisma generate not working: "No command registered" (Prisma 8)](https://nilaykabariya.blog/database/prisma-generate-no-command-registered-prisma-8) |
| [`prisma-init`](prisma-init) | [Prisma P1001: Can't reach database server at localhost:5432](https://nilaykabariya.blog/database/prisma-p1001-cant-reach-database-server)<br>[prisma generate not working: "No command registered" (Prisma 8)](https://nilaykabariya.blog/database/prisma-generate-no-command-registered-prisma-8) |
| [`prisma-noinit`](prisma-noinit) | [Fix: @prisma/client did not initialize yet (Prisma 6 and 7)](https://nilaykabariya.blog/database/prisma-client-did-not-initialize-yet) |
| [`prisma-p1012`](prisma-p1012) | [Prisma P1012: "url is no longer supported in schema files"](https://nilaykabariya.blog/database/prisma-datasource-url-no-longer-supported-p1012) |
| [`prisma6-noinit`](prisma6-noinit) | [Fix: @prisma/client did not initialize yet (Prisma 6 and 7)](https://nilaykabariya.blog/database/prisma-client-did-not-initialize-yet)<br>[Prisma P1001: Can't reach database server at localhost:5432](https://nilaykabariya.blog/database/prisma-p1001-cant-reach-database-server) |
| [`proxies`](proxies) | [Responses.create() unexpected keyword argument: new names](https://nilaykabariya.blog/ai/openai-responses-create-unexpected-keyword-argument) |
| [`prt`](prt) | [pull_request_target blocked by default: Nov 9 brownout, Dec 2](https://nilaykabariya.blog/deploy/github-actions-pull-request-target-blocked-december-2) |
| [`punycode`](punycode) | [The punycode module is deprecated (DEP0040): who causes it](https://nilaykabariya.blog/fixes/punycode-module-is-deprecated-dep0040) |
| [`puppeteer-chrome`](puppeteer-chrome) | [Fix: Puppeteer "Could not find Chrome (ver. …)"](https://nilaykabariya.blog/fixes/puppeteer-could-not-find-chrome) |
| [`py310-to-314`](py310-to-314) | [Python 3.15 on Windows: which packages install (tested)](https://nilaykabariya.blog/tested/python-3-15-windows-packages-tested) |
| [`py315`](py315) | [ERROR: No matching distribution found for torch (Python too new?)](https://nilaykabariya.blog/fixes/no-matching-distribution-found-for-torch)<br>[Fix: Microsoft Visual C++ 14.0 or greater is required](https://nilaykabariya.blog/fixes/microsoft-visual-c-14-0-or-greater-is-required-pip)<br>[Python 3.15 on Windows: which packages install (tested)](https://nilaykabariya.blog/tested/python-3-15-windows-packages-tested) |
| [`pystub`](pystub) | [Python was not found, or pip not recognized (Windows fix)](https://nilaykabariya.blog/fixes/python-was-not-found-microsoft-store-windows) |
| [`pyyaml`](pyyaml) | [Fix: Microsoft Visual C++ 14.0 or greater is required](https://nilaykabariya.blog/fixes/microsoft-visual-c-14-0-or-greater-is-required-pip) |
| [`require-esm`](require-esm) | [Fix: ERR_REQUIRE_ESM require() of ES Module not supported](https://nilaykabariya.blog/fixes/err-require-esm-require-of-es-module) |
| [`rolldown-binding`](rolldown-binding) | ["Cannot find native binding" in Vite 8: the missing @rolldown file](https://nilaykabariya.blog/fixes/cannot-find-module-rolldown-binding) |
| [`sqlite-bindings`](sqlite-bindings) | [Fix: "Could not locate the bindings file" in sqlite3](https://nilaykabariya.blog/fixes/could-not-locate-the-bindings-file-sqlite3) |
| [`ssl-verify`](ssl-verify) | [Python CERTIFICATE_VERIFY_FAILED, tested on 3.12 to 3.15](https://nilaykabariya.blog/fixes/python-ssl-certificate-verify-failed) |
| [`starters-windows`](starters-windows) | [18 framework starters tested on Windows: what breaks](https://nilaykabariya.blog/tested/framework-starters-on-windows-tested) |
| [`supabase-42501`](supabase-42501) | [Supabase 42501: new row violates row-level security policy](https://nilaykabariya.blog/database/supabase-error-42501-row-level-security) |
| [`supabase-cli-3`](supabase-cli-3) | [Supabase CLI 3.0.0 tested: what breaks coming from v2](https://nilaykabariya.blog/tested/supabase-cli-3-tested) |
| [`sveltekit-3`](sveltekit-3) | [SvelteKit 3 migration, tested: what sv migrate misses](https://nilaykabariya.blog/tested/sveltekit-3-migration-tested) |
| [`swc-win`](swc-win) | [18 framework starters tested on Windows: what breaks](https://nilaykabariya.blog/tested/framework-starters-on-windows-tested) |
| [`tailwind-init`](tailwind-init) | [npx tailwindcss init: "could not determine executable to run"](https://nilaykabariya.blog/fixes/npx-tailwindcss-init-could-not-determine-executable) |
| [`tailwind-postcss`](tailwind-postcss) | [Failed to load PostCSS config in Vite (and the Tailwind v4 error)](https://nilaykabariya.blog/fixes/vite-failed-to-load-postcss-config) |
| [`ts-strip-only`](ts-strip-only) | [Fix: TypeScript enum is not supported in strip-only mode](https://nilaykabariya.blog/fixes/typescript-enum-not-supported-in-strip-only-mode) |
| [`ts7-frameworks`](ts7-frameworks) | [Angular compilation initialization failed on TypeScript 7](https://nilaykabariya.blog/fixes/angular-compilation-initialization-failed-typescript-7)<br>[Does NestJS, Next.js, Angular or Vue work with TypeScript 7?](https://nilaykabariya.blog/tested/typescript-7-frameworks-nextjs-angular-vue-nestjs) |
| [`ts7-migration`](ts7-migration) | [TypeScript 7 migration guide: breaking changes, tested](https://nilaykabariya.blog/tested/typescript-7-migration-guide) |
| [`ts7-retest`](ts7-retest) | [Fix: Cannot read properties of undefined (reading 'fileExists')](https://nilaykabariya.blog/fixes/ts-node-cannot-read-properties-of-undefined-fileexists)<br>[TypeScript 7 with ts-jest, ESLint, ts-node: 9 tools tested](https://nilaykabariya.blog/tested/typescript-7-compatibility-tools-tested) |
| [`ts71`](ts71) | [TypeScript 7.1 beta tested: ts-jest, ESLint, NestJS, Angular](https://nilaykabariya.blog/tested/typescript-7-1-beta-tested) |
| [`tseslint-ts7`](tseslint-ts7) | [Fix: typescript-eslint does not support TS 7.0 (ESLint on TS 7)](https://nilaykabariya.blog/fixes/typescript-eslint-does-not-support-ts-7) |
| [`tw-unknown-utility`](tw-unknown-utility) | [Cannot apply unknown utility class border-border in Tailwind v4](https://nilaykabariya.blog/fixes/tailwind-cannot-apply-unknown-utility-class) |
| [`unexpected-export`](unexpected-export) | [Fix: “Cannot use import statement outside a module”](https://nilaykabariya.blog/fixes/cannot-use-import-statement-outside-a-module) |
| [`unknown-file-extension-ts`](unknown-file-extension-ts) | [Unknown file extension ".ts" (ERR_UNKNOWN_FILE_EXTENSION)](https://nilaykabariya.blog/fixes/unknown-file-extension-ts) |
| [`vite-alias`](vite-alias) | [Fix: Vite “Failed to resolve import” for @/ path aliases](https://nilaykabariya.blog/fixes/vite-failed-to-resolve-import-alias) |
| [`vite-postcss-config`](vite-postcss-config) | [Failed to load PostCSS config in Vite (and the Tailwind v4 error)](https://nilaykabariya.blog/fixes/vite-failed-to-load-postcss-config) |
| [`vite-process`](vite-process) | [ReferenceError: process is not defined in Vite (dev vs build)](https://nilaykabariya.blog/fixes/process-is-not-defined-vite) |
| [`vitest5`](vitest5) | [Vitest 4 to 5 migration: 6 breaking changes, tested](https://nilaykabariya.blog/tested/vitest-5-migration-breaking-changes-tested) |
| [`worker-errors`](worker-errors) | [Cloudflare 1102: Worker exceeded resource limits (CPU time)](https://nilaykabariya.blog/deploy/worker-exceeded-cpu-time-limit-error-1102)<br>[Fix: Error 1101 Worker threw exception (Cloudflare Workers)](https://nilaykabariya.blog/deploy/error-1101-worker-threw-exception) |
| [`worker-handlers`](worker-handlers) | [Fix: The uploaded script has no registered event handlers](https://nilaykabariya.blog/deploy/uploaded-script-has-no-registered-event-handlers) |
| [`worker-startup-limit`](worker-startup-limit) | [Fix: Script startup exceeded CPU time limit (Workers 10021)](https://nilaykabariya.blog/deploy/script-startup-exceeded-cpu-time-limit-10021) |
<!-- index:end -->

## Re-verified nightly

[`reverify`](reverify) re-runs the key claim of each post every night on the newest versions (Bun on Windows and Linux; Prisma and Next.js on Linux). Results land in [`status/status.json`](status/status.json). A run fails when a claim stops holding, which means a fix shipped or something new broke.

## Release watcher

[`watch`](watch) checks every hour for new versions of the tools these posts cover (npm dist-tags and Node.js releases). A release that matters opens an issue in this repo listing the affected posts, and a new Prisma, Next.js or Bun version re-runs the checks above straight away. Versions seen so far: [`watch/state.json`](watch/state.json).

## Running it

- Node 24. Run `npm install` in a folder first.
- The Prisma folders expect Postgres on `localhost:55432`: `docker run -d --name nk-pg -e POSTGRES_PASSWORD=repro -p 55432:5432 postgres:17`. Copy `.env.example` to `.env`.
- `supabase-42501` needs Docker and the Supabase CLI (`npx supabase start`).
- `gemini-429` reads `GEMINI_API_KEY` from `../.env` (copy the root `.env.example`). The burst script deliberately uses up your free per-minute quota.

Versions are pinned in each `package-lock.json` and listed in each post's "Tested on" box. Dates matter: these were run on October 7, 2026, and npm tags, quotas and model names change.
