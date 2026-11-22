# Better Auth errors, by setup

For the post on Better Auth's origin, secret and base URL errors (nilaykabariya.blog/fixes/better-auth-errors).

**Dummy secrets, no real app, no network.** Every secret in `cases.mjs` is a placeholder that starts with
`DUMMY-not-a-real-secret` (one case uses `short-secret-123` on purpose). Each case builds a Better Auth instance with
the in-memory adapter and calls `auth.handler()` with a `Request` built in the script; nothing listens on a port and
nothing leaves the machine. The `token` values in the output are session tokens of that throwaway in-memory database.

Ran on Windows 11 Pro, Node 24.14.0, better-auth 1.7.27, November 22, 2026.

```bash
npm install
node cases.mjs all            # every case, each in its own Node process (env is read at init)
node cases.mjs origin-other-port   # one case
```

| Group | Cases |
|---|---|
| Origin | same origin; another port; another port in `trustedOrigins`; trusted origin written with a trailing slash; `127.0.0.1` vs `localhost`; a production origin not trusted, then as `baseURL`; a wildcard `https://*.example.com`; no Origin header and no cookie |
| Sign-out | from another port; with a session cookie but no Origin header |
| callbackURL | an untrusted absolute URL; a trusted one |
| Secret | none in development; none with `NODE_ENV=production`; a 16-character one; `AUTH_SECRET` instead of `BETTER_AUTH_SECRET` (dev and production); `BETTER_AUTH_SECRET` in production |
| Base URL | not set (dev and production); `BETTER_AUTH_URL`; without `http://`; a request outside `/api/auth` |

Output: `out-20261122-2207.txt`. Each case prints Better Auth's own log lines (`log`), then the HTTP status and body,
or the error thrown (`->`).
