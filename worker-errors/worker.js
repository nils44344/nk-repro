// Error 1101 causes and Error 1102 (CPU limit) on one test Worker (8 Nov 2026). Deployed with limits.cpu_ms = 10
// to match the Free plan. Each route triggers one case; /ok answers normally.
export default {
  async fetch(request, env) {
    const { pathname, searchParams } = new URL(request.url);
    switch (pathname) {
      case '/ok': return new Response('ok');
      case '/undefined': { const user = undefined; return new Response(user.email); }
      case '/binding': return new Response(await env.MY_KV.get('k'));
      case '/not-response': return 'just a string';
      case '/relative-fetch': return fetch('/api/data');
      case '/json-no-body': { const body = await request.json(); return Response.json(body); }
      case '/hang': await new Promise(() => {}); return new Response('never');
      case '/burn': { const ms = Number(searchParams.get('ms') || 50); const end = Date.now() + ms; let x = 0; while (Date.now() < end) x++; return new Response(`burned ${ms} ms, ${x} loops`); }
      case '/loop': { const n = Number(searchParams.get('n') || 1e6); let x = 0; for (let i = 0; i < n; i++) x = (x * 31 + i) % 1000003; return new Response(`looped ${n}: ${x}`); }
      case '/now': { const a = Date.now(); let x = 0; for (let i = 0; i < 5e7; i++) x = (x * 31 + i) % 1000003; return new Response(`Date.now() before ${a}, after ${Date.now()}, diff ${Date.now() - a} ms, x=${x}`); }
      case '/wait': { const ms = Number(searchParams.get('ms') || 300); const a = Date.now(); await scheduler.wait(ms); const b = Date.now(); await new Promise((r) => setTimeout(r, ms)); return new Response(`scheduler.wait(${ms}): ${b - a} ms; setTimeout(${ms}): ${Date.now() - b} ms`); }
      default: return new Response('routes: /ok /undefined /binding /not-response /relative-fetch /json-no-body /hang /burn?ms=N /loop?n=N /now', { status: 404 });
    }
  },
};
