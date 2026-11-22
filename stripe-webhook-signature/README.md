# Stripe webhook signature errors, by framework

For the post [Stripe: No signatures found matching the expected signature](https://nilaykabariya.blog/fixes/stripe-webhook-no-signatures-found-matching-expected-signature).

**Dummy keys, no Stripe account used.** Every key in these scripts is a placeholder (`sk_test_DUMMY_not_a_real_key`,
`whsec_test_DUMMY_not_a_real_secret_1`). Events are made-up objects signed locally with stripe-node's
`stripe.webhooks.generateTestHeaderString`, the same HMAC-SHA256 Stripe uses, and sent over HTTP to servers on
localhost. Nothing talks to Stripe.

Ran on Windows 11 Pro, Node 24.14.0, stripe-node 23.2.0, November 22, 2026.

| Script | What it runs | Output |
|---|---|---|
| `cases.js` | 12 direct `constructEvent` calls: raw string/Buffer, parsed object, re-stringified body, wrong secret, API key as secret, secret with a trailing newline, missing header, empty secret, old timestamp (default and 900 s tolerance), CRLF | `cases-out-*.txt` |
| `express-routes.js` | Express 5.3.0, six body-parser setups | `express-out-*.txt` |
| `hono-fastify.mjs` | Hono 4.13.20 (Node adapter) x4, Fastify 5.12.8 x2 | `hono-fastify-out-*.txt` |
| `next-app/` + `post-next.mjs` | Next.js 16.4.6 App Router route handlers on `next dev -p 4821` | `next-out-*.txt` |
| `worker/` + `post-worker.mjs` | a Cloudflare Worker in `wrangler dev --local --port 8799` (compat 2026-09-01, `nodejs_compat`) | `worker-out-*.txt` |

```bash
npm install            # stripe, express, hono, @hono/node-server, fastify
node cases.js
node express-routes.js
node hono-fastify.mjs
cd next-app && npm install && npx next dev -p 4821   # then, in another terminal: node post-next.mjs
cd worker && npx wrangler dev --local --port 8799    # then: node post-worker.mjs
```
