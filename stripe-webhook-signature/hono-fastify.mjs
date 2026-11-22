// Hono (Node adapter) and Fastify 5: which ways of reading the body verify a Stripe signature?
import Stripe from 'stripe';
import { Hono } from 'hono';
import { serve } from '@hono/node-server';
import Fastify from 'fastify';
import { readFileSync } from 'node:fs';

const v = (p) => JSON.parse(readFileSync(new URL(`./node_modules/${p}/package.json`, import.meta.url))).version;
const stripe = new Stripe('sk_test_DUMMY_not_a_real_key');
const secret = 'whsec_test_DUMMY_not_a_real_secret_1';
const payload = JSON.stringify({ id: 'evt_test_1', object: 'event', type: 'invoice.paid', data: { object: { id: 'in_test_1' } } }, null, 2);
const tryIt = async (label, fn) => { try { const ev = await fn(); return `PASS  ${label}: ${ev.type}`; } catch (e) { return `FAIL  ${label}: ${e.message.split('\n')[0]}`; } };
const post = async (port, path) => (await fetch(`http://127.0.0.1:${port}${path}`, { method: 'POST', headers: { 'content-type': 'application/json', 'stripe-signature': stripe.webhooks.generateTestHeaderString({ payload, secret }) }, body: payload })).text();

console.log('stripe', v('stripe'), 'hono', v('hono'), 'fastify', v('fastify'), 'node', process.version);

// Hono
const app = new Hono();
app.post('/text', async (c) => c.text(await tryIt('Hono c.req.text()', async () => stripe.webhooks.constructEvent(await c.req.text(), c.req.header('stripe-signature'), secret))));
app.post('/json', async (c) => c.text(await tryIt('Hono JSON.stringify(await c.req.json())', async () => stripe.webhooks.constructEvent(JSON.stringify(await c.req.json()), c.req.header('stripe-signature'), secret))));
app.post('/async', async (c) => c.text(await tryIt('Hono constructEventAsync + SubtleCrypto (Workers way)', async () => stripe.webhooks.constructEventAsync(await c.req.text(), c.req.header('stripe-signature'), secret, undefined, Stripe.createSubtleCryptoProvider()))));
app.post('/sync-subtle', async (c) => c.text(await tryIt('Hono constructEvent (sync) + SubtleCrypto', async () => stripe.webhooks.constructEvent(await c.req.text(), c.req.header('stripe-signature'), secret, undefined, Stripe.createSubtleCryptoProvider()))));
const hs = serve({ fetch: app.fetch, port: 4811 });
await new Promise((r) => setTimeout(r, 300));
for (const p of ['/text', '/json', '/async', '/sync-subtle']) console.log(await post(4811, p));
hs.close();

// Fastify: default JSON parser, then a raw-body content-type parser
const f1 = Fastify();
f1.post('/webhook', async (req) => tryIt('Fastify default JSON parser (req.body)', async () => stripe.webhooks.constructEvent(req.body, req.headers['stripe-signature'], secret)));
await f1.listen({ port: 4812 });
console.log(await post(4812, '/webhook'));
await f1.close();

const f2 = Fastify();
f2.addContentTypeParser('application/json', { parseAs: 'buffer' }, (_req, body, done) => done(null, body));
f2.post('/webhook', async (req) => tryIt('Fastify addContentTypeParser parseAs buffer', async () => stripe.webhooks.constructEvent(req.body, req.headers['stripe-signature'], secret)));
await f2.listen({ port: 4813 });
console.log(await post(4813, '/webhook'));
await f2.close();
