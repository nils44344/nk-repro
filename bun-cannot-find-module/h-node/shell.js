import { $ } from 'bun';
console.log(await $`echo hi`.text());
