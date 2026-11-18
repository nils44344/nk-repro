# prisma generate fails on Prisma 8: the Prisma 7 project behind the post

Code behind [prisma generate not working: "No command registered" (Prisma 8)](https://nilaykabariya.blog/database/prisma-generate-no-command-registered-prisma-8). This folder is a small Prisma 7 project (Postgres, one `User` model, the `prisma-client` generator writing to `src/generated/prisma`). The post runs `npx prisma ...` against it with the Prisma 7 CLI and with the Prisma 8 release candidate that npm serves as `prisma@latest`, and shows what each one prints. The folder `../prisma-ci` holds the same schema and migration without `package.json`, for the Docker and CI runs.

| File | What it is for |
|---|---|
| `package.json` | Prisma 7 pinned with `^7.10.0` for `prisma`, `@prisma/client` and `@prisma/adapter-pg`. The fix in the post is exactly this pin: `npm i -D prisma@7`. |
| `prisma/schema.prisma`, `prisma/migrations/` | The `User` model (unique `email`) and its first migration. |
| `prisma.config.ts` | The Prisma 7 config: schema path, migrations path and `datasource: { url: env('DATABASE_URL') }`. |
| `prisma.config.v8.bak` | A Prisma 8 style config (`definePrismaConfig`) kept to show that the 7 config and the 8 config are different files. |
| `.env.example` | `DATABASE_URL` for a throwaway Postgres on port 55432. Copy it to `.env`. |
| `q.ts` | Upserts one user and counts rows through `@prisma/adapter-pg`, to prove the client works after the fix. |
| `rt7.ts`, `rt7b.ts` | Provoke an error on purpose and print `e.name`, `e.code` and `e.meta`. |

Try it yourself:

```bash
docker run -d --name pg -e POSTGRES_PASSWORD=repro -p 55432:5432 postgres:17
cp .env.example .env
npm install
npx prisma --version            # Prisma 7 prints a table; the 8 release candidate prints one bare version
npx prisma generate
npx tsx q.ts
```

To see the failure, swap the CLI for the 8 release candidate (`npm i -D prisma@latest` while `latest` is still an rc) and run `npx prisma generate` again. Results depend on which Prisma 8 release candidate `latest` points to that day, so the post lists the exact version it was checked on.
