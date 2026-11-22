import Stripe from 'stripe';
const stripe = new Stripe('sk_test_DUMMY_not_a_real_key');
export async function POST(req) {
  try {
    const ev = stripe.webhooks.constructEvent(await req.text(), req.headers.get('stripe-signature'), 'whsec_test_DUMMY_not_a_real_secret_1');
    return new Response(`PASS  Next route: await req.text(): ${ev.type}`);
  } catch (e) { return new Response(`FAIL  Next route: await req.text(): ${e.message.split('\n')[0]}`); }
}
