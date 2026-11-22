import Stripe from 'stripe';
const stripe = new Stripe('sk_test_DUMMY_not_a_real_key');
const secret = 'whsec_test_DUMMY_not_a_real_secret_1';
const payload = JSON.stringify({ id: 'evt_test_1', object: 'event', type: 'customer.subscription.updated', data: { object: { id: 'sub_test_1' } } }, null, 2);
for (const p of ['/api/text', '/api/json', '/api/formdata']) {
  const r = await fetch('http://localhost:4821' + p, { method: 'POST', headers: { 'content-type': 'application/json', 'stripe-signature': stripe.webhooks.generateTestHeaderString({ payload, secret }) }, body: payload });
  console.log(r.status, await r.text());
}
