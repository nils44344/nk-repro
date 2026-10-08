import { Database } from 'bun:sqlite';
console.log(new Database(':memory:').query('select 1 as x').get());
