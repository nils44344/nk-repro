// "SASL: SCRAM-SERVER-FIRST-MESSAGE: client password must be a string" (node-postgres and the libraries built on it).
// Needs Postgres on localhost:5432, user postgres, password 12345 (scram-sha-256). Usage: node cases.mjs
import fs from "node:fs";
import pg from "pg";
const { Client, Pool } = pg;
const req = (m) => JSON.parse(fs.readFileSync(new URL(`./node_modules/${m}/package.json`, import.meta.url))).version;
console.log(`== node ${process.version}, pg ${req("pg")}, sequelize ${req("sequelize")}, dotenv ${req("dotenv")}`);
console.log(`== env: DB_PASSWORD=${process.env.DB_PASSWORD === undefined ? "(unset)" : "(set)"}, PGPASSWORD=${process.env.PGPASSWORD === undefined ? "(unset)" : "(set)"}`);
const base = { host: "localhost", port: 5432, user: "postgres", database: "postgres" };

async function tryClient(label, cfg) {
  const c = new Client(cfg);
  try {
    await c.connect();
    const r = await c.query("select current_user as u");
    console.log(`${label}\n   OK, connected as ${r.rows[0].u}`);
  } catch (e) {
    console.log(`${label}\n   ${e.constructor.name}: ${e.message}`);
  } finally {
    try { await c.end(); } catch {}
  }
}

const mode = process.argv[2] || "cases";
if (mode === "cases") {
  await tryClient("1. password: process.env.DB_PASSWORD, .env file present but never loaded", { ...base, password: process.env.DB_PASSWORD });
  await tryClient("2. no password option at all", { ...base });
  await tryClient("3. password: 12345 (a number)", { ...base, password: 12345 });
  await tryClient("4. password: null", { ...base, password: null });
  await tryClient("5. password: '' (empty string, e.g. DB_PASSWORD= in .env)", { ...base, password: "" });
  await tryClient("6. connectionString without a password: postgres://postgres@localhost:5432/postgres", { connectionString: "postgres://postgres@localhost:5432/postgres" });
  await tryClient("7. connectionString: process.env.DATABASE_URL, which is unset", { connectionString: process.env.DATABASE_URL });
  await tryClient("8. password: a function that returns undefined", { ...base, password: async () => process.env.DB_PASSWORD });
  await tryClient("9. wrong password (a string): for comparison", { ...base, password: "wrong" });
  const pool = new Pool({ ...base, password: process.env.DB_PASSWORD });
  try { await pool.query("select 1"); console.log("10. Pool, password undefined\n   OK"); }
  catch (e) { console.log(`10. Pool, password undefined\n   ${e.constructor.name}: ${e.message}`); }
  finally { await pool.end().catch(() => {}); }
  const { Sequelize } = await import("sequelize");
  const s = new Sequelize("postgres", "postgres", process.env.DB_PASSWORD, { host: "localhost", dialect: "postgres", logging: false });
  try { await s.authenticate(); console.log("11. Sequelize, password undefined\n   OK"); }
  catch (e) { console.log(`11. Sequelize, password undefined\n   ${e.constructor.name}: ${e.message}`); }
  finally { await s.close().catch(() => {}); }
} else if (mode === "dotenv") {
  await import("dotenv/config");
  await tryClient("FIX a. import 'dotenv/config' first, then password: process.env.DB_PASSWORD", { ...base, password: process.env.DB_PASSWORD });
} else if (mode === "envfile") {
  await tryClient("FIX b. node --env-file=.env, password: process.env.DB_PASSWORD", { ...base, password: process.env.DB_PASSWORD });
} else if (mode === "string") {
  await tryClient("FIX c. password: String(12345)", { ...base, password: String(12345) });
} else if (mode === "pgpassword") {
  await tryClient("FIX d. no password option, PGPASSWORD set in the environment", { ...base });
} else if (mode === "url") {
  await tryClient("FIX e. connectionString with the password: postgres://postgres:12345@localhost:5432/postgres", { connectionString: "postgres://postgres:12345@localhost:5432/postgres" });
}
