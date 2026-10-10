import pg from 'pg';
import postgres from 'postgres';
import { drizzle as dPg } from 'drizzle-orm/node-postgres';
import { drizzle as dJs } from 'drizzle-orm/postgres-js';
import { DrizzleQueryError } from 'drizzle-orm/errors';
import { sql } from 'drizzle-orm';
import { users } from './schema.js';
const url = 'postgresql://postgres:repro@127.0.0.1:55432/postgres';
const pool = new pg.Pool({ connectionString: url });
const client = postgres(url, { onnotice: () => {} });
const dbs = { 'node-postgres (pg)': dPg(pool), 'postgres.js': dJs(client) };
await dbs['node-postgres (pg)'].execute(sql`drop table if exists posts; drop table if exists users`);
await dbs['node-postgres (pg)'].execute(sql`create table users (id serial primary key, email text not null unique, name text not null)`);
await dbs['node-postgres (pg)'].insert(users).values({ email: 'a@b.c', name: 'A' });
for (const [name, db] of Object.entries(dbs)) {
  try { await db.insert(users).values({ email: 'a@b.c', name: 'B' }); }
  catch (e) {
    console.log(`${name}: ${e.constructor.name} wrapped=${e instanceof DrizzleQueryError} e.code=${e.code} cause=${e.cause?.constructor.name} cause.code=${e.cause?.code} constraint=${e.cause?.constraint} constraint_name=${e.cause?.constraint_name} table=${e.cause?.table ?? e.cause?.table_name} detail=${e.cause?.detail}`);
  }
}
await pool.end(); await client.end();
