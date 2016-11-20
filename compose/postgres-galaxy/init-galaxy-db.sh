#!/bin/bash
echo "Initializing galaxy database with defaults"
"${psql[@]}" < /docker-entrypoint-initdb.d/init-galaxy-db.sql.in >/dev/null
echo "Successfully initialized galaxy database"
