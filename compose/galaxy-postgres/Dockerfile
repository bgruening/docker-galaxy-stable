FROM library/postgres:9.6.5
ADD init-galaxy-db.sql.in /docker-entrypoint-initdb.d/
ADD init-galaxy-db.sh /docker-entrypoint-initdb.d/
RUN chmod a+rx /docker-entrypoint-initdb.d/init-galaxy-db.sh
