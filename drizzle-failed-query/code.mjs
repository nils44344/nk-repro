// What a unique-violation looks like to your catch block, per drizzle-orm version.
import { readFileSync } from 'node:fs';
import util from 'node:util';
import { PGlite } from '@electric-sql/pglite';
import { drizzle } from 'drizzle-orm/pglite';
import * as orm from 'drizzle-orm';
import { users } from './schema.js';

const v = JSON.parse(readFileSync(new URL('./node_modules/drizzle-orm/package.json', import.meta.url))).version;
const db = drizzle(new PGlite());
await db.execute('create table users (id serial primary key, email text not null unique, name text not null)');
await db.insert(users).values({ email: 'a@b.c', name: 'A' });
try {
  await db.insert(users).values({ email: 'a@b.c', name: 'B' });
} catch (e) {
  console.log(`drizzle-orm ${v}: thrown=${e.constructor.name} e.code=${e.code} e.cause?.code=${e.cause?.code} DrizzleQueryError exported=${'DrizzleQueryError' in orm}`);
  if (process.argv[2] === 'print') {
    console.log('String(e):', String(e).replace(/\n/g, ' ⏎ ').slice(0, 160));
    console.log('console.error(e) includes the cause:', /\[cause\]/.test(util.inspect(e)));
  }
}
