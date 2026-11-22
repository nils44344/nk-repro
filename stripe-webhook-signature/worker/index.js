import Stripe from 'stripe';
const stripe = new Stripe('sk_test_DUMMY_not_a_real_key');
const secret = 'whsec_test_DUMMY_not_a_real_secret_1';
export default {
  async fetch(req) {
    const path = new URL(req.url).pathname;
    const body = await req.text();
    const sig = req.headers.get('stripe-signature');
    try {
      let ev;
      if (path === '/sync') ev = stripe.webhooks.constructEvent(body, sig, secret);
      else if (path === '/async') ev = await stripe.webhooks.constructEventAsync(body, sig, secret);
      else if (path === '/async-subtle') ev = await stripe.webhooks.constructEventAsync(body, sig, secret, undefined, Stripe.createSubtleCryptoProvider());
      return new Response(`PASS  Worker ${path}: ${ev.type}`);
    } catch (e) { return new Response(`FAIL  Worker ${path}: ${e.message.split('\n')[0]}`); }
  },
};
