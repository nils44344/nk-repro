// One check per line: name -> ok / the error it threw.
const run = (name, fn) => {
  try { const r = fn(); console.log(`${name}: ok${r === undefined ? '' : ' ' + r}`); }
  catch (e) { console.log(`${name}: ${e.code ? e.code + ' ' : ''}${String(e.message).split('\n')[0].slice(0, 160)}`); }
};
console.log('node', process.version, 'modules', process.versions.modules);
run('jsonwebtoken', () => { const jwt = require('jsonwebtoken'); const t = jwt.sign({ a: 1 }, 's'); return jwt.verify(t, 's').a; });
run('better-sqlite3', () => { const D = require('better-sqlite3'); return new D(':memory:').prepare('select 1 as x').get().x; });
run('bcrypt', () => require('bcrypt').hashSync('x', 4).slice(0, 4));
run('sharp', () => typeof require('sharp'));
run('SlowBuffer', () => typeof require('buffer').SlowBuffer);
run('fs.F_OK', () => String(require('fs').F_OK));
run('_stream_readable', () => typeof require('_stream_readable'));
run('localStorage', () => typeof globalThis.localStorage);
run('Temporal', () => typeof globalThis.Temporal);
run('writeHeader', () => typeof require('http').ServerResponse.prototype.writeHeader);
run('fs.rmdir recursive', () => { const fs = require('fs'); fs.mkdirSync('rmd/x', { recursive: true }); fs.rmdirSync('rmd', { recursive: true }); return fs.existsSync('rmd'); });
