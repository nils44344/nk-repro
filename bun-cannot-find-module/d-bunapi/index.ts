import { Database } from 'bun:sqlite';
const db = new Database(':memory:');
console.log(db.query('select 1 as x').get());
