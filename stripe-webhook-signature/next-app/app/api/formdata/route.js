import Stripe from 'stripe';
const stripe = new Stripe('sk_test_DUMMY_not_a_real_key');
export async function POST(req) {
  const body = Buffer.from(await req.arrayBuffer());
  try {
    const ev = stripe.webhooks.constructEvent(body, req.headers.get('stripe-signature'), 'whsec_test_DUMMY_not_a_real_secret_1');
    return new Response(`PASS  Next route: Buffer.from(await req.arrayBuffer()): ${ev.type}`);
  } catch (e) { return new Response(`FAIL  Next route: Buffer.from(await req.arrayBuffer()): ${e.message.split('\n')[0]}`); }
}
