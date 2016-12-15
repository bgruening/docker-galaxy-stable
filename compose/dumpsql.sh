#!/bin/bash
# Sets the image of postgres to use
POSTGRES=postgres
POSTGRES_USER=galaxy
POSTGRES_PASSWORD=chaopagoosaequuashie
POSTGRES_DB=galaxy
# Create postgres in detached mode
pg_start=`date +%s`
docker run -d --name "dumpsql_postgres" -e "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" -e "POSTGRES_USER=$POSTGRES_USER" -e "POSTGRES_DB=$POSTGRES_DB" $POSTGRES
# Output postgres log
docker logs -f dumpsql_postgres &
# Wait until postgres has initialized
until docker run --rm --link dumpsql_postgres:pg $POSTGRES pg_isready -U postgres -h pg >/dev/null; do sleep 1; done
pg_end=`date +%s`
init_start=`date +%s`
docker run -i --rm --name "dumpsql_galaxy_installdb" -e "GALAXY_CONFIG_DATABASE_CONNECTION=postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@db/$POSTGRES_DB?client_encoding=utf8" --link "dumpsql_postgres:db" quay.io/bgruening/galaxy:compose install_db.sh
init_end=`date +%s`
dump_start=`date +%s`
docker exec "dumpsql_postgres" pg_dump --no-tablespace --no-acl --no-owner -U postgres galaxy > postgres-galaxy/init-galaxy-db.sql.in
dump_end=`date +%s`
docker rm -f dumpsql_postgres
echo "Stats:"
echo "Startup postgres: $((pg_end-pg_start)) sec"
echo "install_db: $((init_end-init_start)) sec"
echo "pg_dumpall: $((dump_end-dump_start)) sec"
echo "Total: $((dump_end-pg_start)) sec"
