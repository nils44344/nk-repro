import { PGlite } from '@electric-sql/pglite';
import { drizzle } from 'drizzle-orm/pglite';
import { migrate } from 'drizzle-orm/pglite/migrator';
const db = drizzle(new PGlite('./pgdata'));
try { await migrate(db, { migrationsFolder: './drizzle' }); console.log('migrated'); }
catch (e) { console.log(e.constructor.name + ': ' + String(e.message).replace(/\n/g, ' ⏎ ').slice(0, 220)); console.log('cause:', e.cause?.message, '(code ' + e.cause?.code + ')'); }
