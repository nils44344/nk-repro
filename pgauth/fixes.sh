#!/bin/bash
# Checks for the fixes not covered by run.sh.
set +e
cd "$(dirname "$0")"
IMG=postgres:18
ready() { for i in $(seq 1 60); do pg_isready -q -h localhost -p ${1:-5432} && return 0; sleep 1; done; echo "NOT READY"; }
try() { PGPASSWORD="$2" psql -h localhost -p ${3:-5432} -U "$1" -d postgres -tAc "select 'OK as '||current_user" 2>&1 | head -2; }
export PW=second
docker compose up -d 2>/dev/null; ready; docker compose down 2>/dev/null
PGU=admin docker compose up -d 2>/dev/null; ready; C=$(docker compose ps -q db)
echo "== admin before:"; try admin second
docker exec $C psql -U postgres -c "CREATE USER admin WITH PASSWORD 'second' SUPERUSER"
echo "== admin after CREATE USER:"; try admin second
docker compose down -v >/dev/null 2>&1
echo "== quoted password, then ALTER"
printf 'POSTGRES_PASSWORD="secret"\n' > q.env
docker run -d --name q1 --env-file q.env -p 5433:5432 $IMG >/dev/null; ready 5433
PGPASSWORD='"secret"' psql -h localhost -p 5433 -U postgres -d postgres -c "ALTER USER postgres PASSWORD 'secret'"
try postgres secret 5433; docker rm -f q1 >/dev/null
echo "== native on 5432, docker run fails: what docker ps shows"
sudo systemctl start postgresql; sleep 3
docker run -d --name n1 -e POSTGRES_PASSWORD=dockerpw -p 5432:5432 $IMG >/dev/null 2>&1
docker ps --filter name=n1 --format 'ps: {{.Names}} {{.Status}}'; echo "(end of docker ps)"
docker ps -a --filter name=n1 --format 'ps -a: {{.Names}} {{.Status}}'
echo "== publish on 5433 instead"
docker rm -f n1 >/dev/null; docker run -d --name n2 -e POSTGRES_PASSWORD=dockerpw -p 5433:5432 $IMG >/dev/null; ready 5433; try postgres dockerpw 5433
sudo systemctl stop postgresql
