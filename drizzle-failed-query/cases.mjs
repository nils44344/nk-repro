import { PGlite } from '@electric-sql/pglite';
import { drizzle } from 'drizzle-orm/pglite';
import { eq } from 'drizzle-orm';
import { users, posts } from './schema.js';

const show = (label, e) => {
  console.log(`\n=== ${label}`);
  console.log('name:   ', e.constructor.name);
  console.log('message:', String(e.message).split('\n').join(' ⏎ '));
  console.log('cause:  ', e.cause ? `${e.cause.constructor.name}: ${e.cause.message} (code ${e.cause.code})` : '(none)');
};
const run = async (label, fn) => { try { await fn(); console.log(`\n=== ${label}: no error`); } catch (e) { show(label, e); } };

const db = drizzle(new PGlite());
await run('1. select before the table exists', () => db.select().from(users));
await db.execute('create table users (id serial primary key, email text not null unique, name text not null)');
await db.execute('create table posts (id uuid primary key default gen_random_uuid(), author_id integer not null references users(id), title text not null)');
await db.insert(users).values({ email: 'a@b.c', name: 'A' });
await run('2. insert a duplicate email', () => db.insert(users).values({ email: 'a@b.c', name: 'A again' }));
await run('3. insert with a missing required column', () => db.insert(users).values({ email: 'x@y.z', name: null }));
await run('4. insert a post for a user that does not exist', () => db.insert(posts).values({ authorId: 999, title: 'Hi' }));
await run('5. select by a uuid that is not a uuid', () => db.select().from(posts).where(eq(posts.id, 'not-a-uuid')));
