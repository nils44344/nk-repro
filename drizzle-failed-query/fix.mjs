import { readFileSync } from 'node:fs';
import { PGlite } from '@electric-sql/pglite';
import { drizzle } from 'drizzle-orm/pglite';
import { DrizzleQueryError } from 'drizzle-orm/errors';
import { users } from './schema.js';
const v = JSON.parse(readFileSync(new URL('./node_modules/drizzle-orm/package.json', import.meta.url))).version;
// Works on every version: the Postgres error is the cause (0.44+), or the error itself (older).
const pgError = (e) => (e instanceof DrizzleQueryError ? e.cause : e);
const db = drizzle(new PGlite());
await db.execute('create table users (id serial primary key, email text not null unique, name text not null)');
await db.insert(users).values({ email: 'a@b.c', name: 'A' });
try { await db.insert(users).values({ email: 'a@b.c', name: 'B' }); }
catch (e) { console.log(`${v}: pgError(e).code=${pgError(e)?.code} -> ${pgError(e)?.code === '23505' ? 'handled as "email already taken"' : 'NOT handled'}`); }
