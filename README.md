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
| [`next-security`](next-security) | [Next.js 16.3 vulnerabilities: which version is patched?](https://nilaykabariya.blog/tested/nextjs-16-3-vulnerabilities-which-version-is-patched) | `npm audit` and `next build` at 16.3.0, 16.3.7, 16.3.8 and 16.4.0 (`check.sh <version>`), plus what `npm audit fix` and `next upgrade` install |
| [`gemini-429`](gemini-429) | [Gemini API 429 RESOURCE_EXHAUSTED](https://nilaykabariya.blog/ai/gemini-api-429-resource-exhausted) and [Gemini 2.5 Flash "no longer available to new users"](https://nilaykabariya.blog/ai/gemini-2-5-flash-no-longer-available-to-new-users) | Free-tier limits hit on purpose, the retry helper, and every retired model name |
| [`starters-windows`](starters-windows) | [16 framework starters tested on Windows: what breaks](https://nilaykabariya.blog/tested/framework-starters-on-windows-tested) | Scaffold, install, build and dev server for 16 starters on Windows 11 and Linux |
| [`bun-cannot-find-module`](bun-cannot-find-module) | [Bun "error: Cannot find module": every cause, tested](https://nilaykabariya.blog/fixes/bun-error-cannot-find-module) | Workspaces on the isolated linker, `bun test` aliases, the JSX runtime, `bun:sqlite` outside Bun (and `--bun` on Windows), wrong-case imports on Linux |

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
