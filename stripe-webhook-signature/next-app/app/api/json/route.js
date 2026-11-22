import Stripe from 'stripe';
const stripe = new Stripe('sk_test_DUMMY_not_a_real_key');
export async function POST(req) {
  try {
    const ev = stripe.webhooks.constructEvent(JSON.stringify(await req.json()), req.headers.get('stripe-signature'), 'whsec_test_DUMMY_not_a_real_secret_1');
    return new Response(`PASS  Next route: JSON.stringify(await req.json()): ${ev.type}`);
  } catch (e) { return new Response(`FAIL  Next route: JSON.stringify(await req.json()): ${e.message.split('\n')[0]}`); }
}
