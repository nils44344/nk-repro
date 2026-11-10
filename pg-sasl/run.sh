#!/usr/bin/env bash
# Runs cases.mjs against Postgres on localhost:5432 (user postgres, password 12345). Usage: W=<work dir> bash pg-sasl/run.sh
set +e
H=$(cd "$(dirname "$0")" && pwd); W=${W:-$H/work}; rm -rf "$W"; mkdir -p "$W"; cp "$H/cases.mjs" "$W/"; cd "$W"
unset PGPASSWORD DB_PASSWORD DATABASE_URL
echo '{"name":"pg-sasl","version":"1.0.0","type":"module"}' > package.json
npm install pg sequelize dotenv --no-audit --no-fund --loglevel=error 2>&1 | tail -1
printf 'DB_PASSWORD=12345\n' > .env
echo "################ cases (.env exists, nothing loads it)"; node cases.mjs cases
echo "################ fixes"
node cases.mjs dotenv
node --env-file=.env cases.mjs envfile
node cases.mjs string
PGPASSWORD=12345 node cases.mjs pgpassword
node cases.mjs url
echo "== done $(date -u)"
