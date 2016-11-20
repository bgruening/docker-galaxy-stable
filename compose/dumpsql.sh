#!/bin/bash
# Note: The postgres service must use the official image
docker-compose up -d postgres
docker-compose create galaxy
sleep 30
docker-compose run galaxy install_db.sh
docker-compose exec postgres pg_dumpall -x --no-tablespace -O -U postgres > postgres-galaxy/init-galaxy-db.sql.in

