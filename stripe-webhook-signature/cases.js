// Offline repro: stripe-node webhook signature errors. No Stripe account or network needed:
// generateTestHeaderString signs a payload the same way Stripe does (HMAC-SHA256 of "t.payload" with the endpoint secret).
const Stripe = require('stripe');
const stripe = new Stripe('sk_test_DUMMY_not_a_real_key');
const secret = 'whsec_test_DUMMY_not_a_real_secret_1';
const payload = JSON.stringify({ id: 'evt_test_1', object: 'event', type: 'checkout.session.completed', data: { object: { id: 'cs_test_1', amount_total: 4999 } } }, null, 2);
const header = stripe.webhooks.generateTestHeaderString({ payload, secret });

function attempt(label, body, sig, sec, opts) {
  try {
    const ev = stripe.webhooks.constructEvent(body, sig, sec, opts?.tolerance);
    console.log(`PASS  ${label}: event ${ev.id} ${ev.type}`);
  } catch (e) {
    console.log(`FAIL  ${label}: ${e.type || e.name}: ${e.message.split('\n').join(' | ')}`);
  }
}

console.log('stripe-node', JSON.parse(require('fs').readFileSync(require.resolve('stripe').split('node_modules')[0]+'node_modules/stripe/package.json')).version, 'node', process.version);
attempt('raw string body, right secret', payload, header, secret);
attempt('raw Buffer body, right secret', Buffer.from(payload), header, secret);
attempt('parsed object (express.json) passed as body', JSON.parse(payload), header, secret);
attempt('parsed then JSON.stringify again', JSON.stringify(JSON.parse(payload)), header, secret);
attempt('wrong secret (another endpoint)', payload, header, 'whsec_test_DUMMY_not_a_real_secret_2');
attempt('API key passed as secret', payload, header, 'sk_test_DUMMY_not_a_real_key');
attempt('secret with trailing newline (.env copy)', payload, header, secret + '\n');
attempt('missing signature header', payload, undefined, secret);
attempt('empty secret', payload, header, '');
const old = stripe.webhooks.generateTestHeaderString({ payload, secret, timestamp: Math.floor(Date.now() / 1000) - 600 });
attempt('signed 10 min ago, default tolerance', payload, old, secret);
attempt('signed 10 min ago, tolerance 900', payload, old, secret, { tolerance: 900 });
attempt('CRLF line endings added', payload.replace(/\n/g, '\r\n'), header, secret);
