#!/bin/bash
echo "Initializing galaxy database with defaults"

psql -v "ON_ERROR_STOP=1" --username "${POSTGRES_USER:-galaxy}" --dbname "${POSTGRES_DB:-galaxy}" <<- EOSQL
    CREATE USER ${POSTGRES_USER:-galaxy};
    CREATE DATABASE ${POSTGRES_DB:-${POSTGRES_USER:-galaxy}};
    GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB:-galaxy} TO ${POSTGRES_USER:-galaxy};
EOSQL

psql -v "ON_ERROR_STOP=1" --username "${POSTGRES_USER:-galaxy}" --dbname "${POSTGRES_DB:-galaxy}" < /docker-entrypoint-initdb.d/init-galaxy-db.sql.in

echo "Successfully initialized galaxy database"
