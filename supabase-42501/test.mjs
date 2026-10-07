// Runs every 42501 case against the local stack and prints the raw error objects.
import { createClient } from '@supabase/supabase-js';
import { execSync } from 'node:child_process';

const env = Object.fromEntries(
  execSync('npx supabase status -o env', { encoding: 'utf8' })
    .split('\n').filter((l) => l.includes('=')).map((l) => {
      const i = l.indexOf('=');
      return [l.slice(0, i), l.slice(i + 1).replace(/^"|"$/g, '')];
    }),
);
const URL = env.API_URL, ANON = env.ANON_KEY || env.PUBLISHABLE_KEY, SERVICE = env.SERVICE_ROLE_KEY || env.SECRET_KEY;
const only = process.argv[2]; // optional case filter

const show = (label, r) => {
  console.log(`\n### ${label}`);
  console.log(JSON.stringify({ status: r.status, statusText: r.statusText, error: r.error, data: r.data }, null, 2));
};
const anon = () => createClient(URL, ANON, { auth: { persistSession: false } });
const service = createClient(URL, SERVICE, { auth: { persistSession: false } });

async function signedIn(email) {
  const c = anon();
  const { data, error } = await c.auth.signUp({ email, password: 'repro-password-123' });
  if (error) throw error;
  return { c, uid: data.user.id };
}

const cases = {
  A: async () => show('A anon insert, RLS on, no policy', await anon().from('notes_nopolicy').insert({ body: 'x' })),
  A2: async () => show('A2 anon select, RLS on, no policy', await anon().from('notes_nopolicy').select()),
  B: async () => show('B anon insert, SELECT-only policy', await anon().from('notes_selectonly').insert({ body: 'x' })),
  C1: async () => show('C1 anon insert, INSERT-only policy', await anon().from('notes_insertonly').insert({ body: 'x' })),
  C2: async () => show('C2 anon insert().select(), INSERT-only policy', await anon().from('notes_insertonly').insert({ body: 'x' }).select()),
  D1: async () => show('D1 profiles insert as anon (not signed in)', await anon().from('profiles').insert({ id: crypto.randomUUID(), username: 'a' })),
  D2: async () => { const { c } = await signedIn(`d2-${Date.now()}@example.com`); show('D2 profiles insert signed in, wrong id', await c.from('profiles').insert({ id: crypto.randomUUID(), username: 'a' })); },
  D3: async () => { const { c, uid } = await signedIn(`d3-${Date.now()}@example.com`); show('D3 profiles insert signed in, own id, .select()', await c.from('profiles').insert({ id: uid, username: 'a' }).select()); },
  E1: async () => { const { c } = await signedIn(`e1-${Date.now()}@example.com`); show('E1 todos insert signed in, user_id omitted', await c.from('todos').insert({ task: 't' })); },
  E2: async () => { const { c, uid } = await signedIn(`e2-${Date.now()}@example.com`); show('E2 todos insert signed in, user_id set', await c.from('todos').insert({ task: 't', user_id: uid }).select()); },
  F1: async () => { const r = await anon().storage.from('avatars').upload(`a-${Date.now()}.txt`, new Blob(['hi'], { type: 'text/plain' })); console.log('\n### F1 anon storage upload, no storage.objects policy'); console.log(JSON.stringify({ data: r.data, error: r.error && { name: r.error.name, message: r.error.message, status: r.error.status, statusCode: r.error.statusCode } }, null, 2)); },
  S: async () => show('S service_role insert, RLS on, no policy', await service.from('notes_nopolicy').insert({ body: 'x' }).select()),
};

for (const [k, fn] of Object.entries(cases)) {
  if (only && !only.split(',').includes(k)) continue;
  try { await fn(); } catch (e) { console.log(`\n### ${k} THREW`, e); }
}
