#!/bin/bash
# "password authentication failed for user postgres": each cause reproduced with the official image, and what fixes it.
set +e
cd "$(dirname "$0")"
IMG=postgres:18
docker pull -q $IMG >/dev/null; docker run --rm $IMG postgres --version; psql --version
ready() { for i in $(seq 1 60); do pg_isready -q -h localhost -p ${1:-5432} && return 0; sleep 1; done; echo "NOT READY"; }
try() { PGPASSWORD="$2" psql -h localhost -p ${3:-5432} -U "$1" -d postgres -tAc "select 'OK as '||current_user" 2>&1 | head -2; }
detail() { docker logs "$1" 2>&1 | grep -E "FATAL|DETAIL|Skipping|skipping" | tail -${2:-2}; }

echo "== 1. compose: first start with password first"
cat > compose.yml <<'Y'
services:
  db:
    image: postgres:18
    environment:
      POSTGRES_PASSWORD: ${PW}
      POSTGRES_USER: ${PGU:-postgres}
    ports: ["5432:5432"]
    volumes: ["pgdata:/var/lib/postgresql"]
volumes:
  pgdata:
Y
export PW=first; docker compose up -d 2>/dev/null; ready; try postgres first
echo "== 2. change password in compose, down + up (volume kept)"
docker compose down 2>/dev/null; export PW=second; docker compose up -d 2>/dev/null; ready
C=$(docker compose ps -q db)
echo "-- new password:"; try postgres second
echo "-- old password:"; try postgres first
echo "-- server log:"; detail $C 3
echo "== 3. POSTGRES_USER=admin added later (volume kept)"
docker compose down 2>/dev/null; PGU=admin docker compose up -d 2>/dev/null; ready; C=$(docker compose ps -q db)
try admin second; detail $C 1
echo "== fix A: ALTER USER inside the container (local socket, no password)"
docker compose down 2>/dev/null; export PW=second; docker compose up -d 2>/dev/null; ready; C=$(docker compose ps -q db)
docker exec $C psql -U postgres -c "ALTER USER postgres PASSWORD 'second'"; try postgres second
echo "== fix B: down -v (deletes the data) then up"
docker compose down 2>/dev/null; PW=third docker compose down -v 2>&1 | tail -2; PW=third docker compose up -d 2>/dev/null; ready; try postgres third
docker compose down -v >/dev/null 2>&1

echo "== 4. quotes in an env file"
printf 'POSTGRES_PASSWORD="secret"\n' > q.env
docker run -d --name q1 --env-file q.env -p 5433:5432 $IMG >/dev/null; ready 5433
echo "-- docker run --env-file, password secret:"; try postgres secret 5433
echo "-- password with the quotes:"; try postgres '"secret"' 5433
docker rm -f q1 >/dev/null
cat > compose-q.yml <<'Y'
services:
  db:
    image: postgres:18
    env_file: q.env
    ports: ["5434:5432"]
Y
docker compose -f compose-q.yml up -d 2>/dev/null; ready 5434
echo "-- compose env_file, password secret:"; try postgres secret 5434
echo "-- with the quotes:"; try postgres '"secret"' 5434
docker compose -f compose-q.yml down -v >/dev/null 2>&1

echo "== 5. special characters in a connection URL"
docker run -d --name s1 -e 'POSTGRES_PASSWORD=p@ss#w0rd' -p 5435:5432 $IMG >/dev/null; ready 5435
echo "-- psql URL raw:"; psql 'postgresql://postgres:p@ss#w0rd@localhost:5435/postgres' -tAc "select 'OK'" 2>&1 | head -2
echo "-- psql URL encoded:"; psql 'postgresql://postgres:p%40ss%23w0rd@localhost:5435/postgres' -tAc "select 'OK'" 2>&1 | head -2
mkdir -p node && cd node && npm init -y >/dev/null && npm i pg --silent >/dev/null 2>&1 && echo "pg $(node -p "require('pg/package.json').version")"
for u in 'postgresql://postgres:p@ss#w0rd@localhost:5435/postgres' 'postgresql://postgres:p%40ss%23w0rd@localhost:5435/postgres'; do
  node -e "const {Client}=require('pg');const c=new Client({connectionString:process.argv[1]});c.connect().then(()=>c.query('select 1')).then(()=>{console.log('node pg OK');c.end()}).catch(e=>{console.log('node pg ERR',e.code||'',e.message);process.exit(0)})" "$u" 2>&1 | head -2
done
echo "== 6. no password at all from node pg"
node -e "const {Client}=require('pg');const c=new Client({host:'localhost',port:5435,user:'postgres',database:'postgres'});c.connect().then(()=>console.log('OK')).catch(e=>console.log('node pg ERR',e.message))" 2>&1 | head -2
echo "-- password from a missing env var (undefined):"
node -e "const {Client}=require('pg');const c=new Client({host:'localhost',port:5435,user:'postgres',database:'postgres',password:process.env.NOPE});c.connect().then(()=>console.log('OK')).catch(e=>console.log('node pg ERR',e.message))" 2>&1 | head -2
echo "-- wrong password, error code:"
node -e "const {Client}=require('pg');const c=new Client({host:'localhost',port:5435,user:'postgres',database:'postgres',password:'nope'});c.connect().then(()=>console.log('OK')).catch(e=>console.log('node pg ERR',e.code,e.message))" 2>&1 | head -2
cd ..
echo "== 7. Prisma 7 CLI, wrong password"
mkdir -p pr && cd pr && npm init -y >/dev/null && npm i prisma@7 --silent >/dev/null 2>&1 && echo "prisma $(node -p "require('prisma/package.json').version")"
mkdir -p prisma && printf 'datasource db {\n  provider = "postgresql"\n}\n' > prisma/schema.prisma
printf "import { defineConfig, env } from 'prisma/config';\nexport default defineConfig({ schema: 'prisma/schema.prisma', datasource: { url: env('DATABASE_URL') } });\n" > prisma.config.ts
DATABASE_URL='postgresql://postgres:nope@localhost:5435/postgres' npx prisma db pull 2>&1 | grep -vE "^\s*$|Loaded|Prisma schema loaded|Datasource" | head -4
DATABASE_URL='postgresql://postgres:p@ss#w0rd@localhost:5435/postgres' npx prisma db pull 2>&1 | grep -vE "^\s*$|Loaded|Prisma schema loaded|Datasource" | head -4
cd ..; docker rm -f s1 >/dev/null

echo "== 8. a second Postgres already on 5432 (native service on the host)"
sudo systemctl start postgresql; sleep 3; sudo -u postgres psql -tAc "select 'native '||version()" | cut -c1-40
docker run -d --name n1 -e POSTGRES_PASSWORD=dockerpw -p 5432:5432 $IMG 2>&1 | grep -i error | cut -c1-260
sleep 8; try postgres dockerpw
PGPASSWORD=dockerpw psql -h localhost -U postgres -d postgres -tAc "select version()" 2>&1 | cut -c1-40
ss -ltnp 2>/dev/null | grep 5432 | awk '{print $4}' | sort -u
docker rm -f n1 >/dev/null; sudo systemctl stop postgresql

echo "== bonus: Postgres 18 with the old volume path /var/lib/postgresql/data"
docker run -d --name o1 -e POSTGRES_PASSWORD=x -v old18:/var/lib/postgresql/data $IMG >/dev/null; sleep 10
docker ps -a --filter name=o1 --format '{{.Status}}'; docker logs o1 2>&1 | grep -iE "error|counter|upgrade|/var/lib" | head -5 | cut -c1-200
