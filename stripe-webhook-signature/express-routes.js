// Real Express 5 server, real HTTP requests signed like Stripe signs them. Which body-parser setups verify?
const express = require('express');
const Stripe = require('stripe');
const stripe = new Stripe('sk_test_DUMMY_not_a_real_key');
const secret = 'whsec_test_DUMMY_not_a_real_secret_1';

function verify(label) {
  return (req, res) => {
    try {
      const ev = stripe.webhooks.constructEvent(req.body, req.headers['stripe-signature'], secret);
      res.send(`PASS  ${label}: ${ev.type}`);
    } catch (e) {
      res.send(`FAIL  ${label}: ${e.message.split('\n')[0]}`);
    }
  };
}

// App A: express.json() for the whole app, webhook route declared after it (the common mistake).
const a = express();
a.use(express.json());
a.post('/webhook', verify('A express.json() app-wide, then route'));

// App B: express.raw on the webhook route, declared BEFORE express.json() (Stripe's documented order).
const b = express();
b.post('/webhook', express.raw({ type: 'application/json' }), verify('B express.raw on route, before json()'));
b.use(express.json());

// App C: express.raw on the route, but express.json() registered app-wide first.
const c = express();
c.use(express.json());
c.post('/webhook', express.raw({ type: 'application/json' }), verify('C json() app-wide first, raw on route'));

// App D: express.raw with the default type (application/octet-stream) while Stripe sends application/json.
const d = express();
d.post('/webhook', express.raw(), verify('D express.raw() default type'));

// App E: express.text() on the route.
const e = express();
e.post('/webhook', express.text({ type: 'application/json' }), verify('E express.text on route'));

// App F: json() with a verify hook that keeps the raw buffer, verifying req.rawBody.
const f = express();
f.use(express.json({ verify: (req, _res, buf) => { req.rawBody = buf; } }));
f.post('/webhook', (req, res) => {
  try {
    const ev = stripe.webhooks.constructEvent(req.rawBody, req.headers['stripe-signature'], secret);
    res.send(`PASS  F json({ verify }) keeping req.rawBody: ${ev.type}`);
  } catch (err) { res.send(`FAIL  F json({ verify }) keeping req.rawBody: ${err.message.split('\n')[0]}`); }
});

(async () => {
  console.log('express', require('express/package.json').version, 'node', process.version);
  const payload = JSON.stringify({ id: 'evt_test_1', object: 'event', type: 'checkout.session.completed', data: { object: { id: 'cs_test_1' } } }, null, 2);
  let port = 4801;
  for (const app of [a, b, c, d, e, f]) {
    const srv = app.listen(port);
    await new Promise((r) => srv.once('listening', r));
    const header = stripe.webhooks.generateTestHeaderString({ payload, secret });
    const r = await fetch(`http://127.0.0.1:${port}/webhook`, { method: 'POST', headers: { 'content-type': 'application/json; charset=utf-8', 'stripe-signature': header }, body: payload });
    console.log(await r.text());
    srv.close();
    port++;
  }
})();
