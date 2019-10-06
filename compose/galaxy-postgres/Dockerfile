FROM library/postgres:11.2
COPY init-galaxy-db.sql.in /docker-entrypoint-initdb.d/
COPY init-galaxy-db.sh /docker-entrypoint-initdb.d/
RUN chmod a+rx /docker-entrypoint-initdb.d/init-galaxy-db.sh && \
    chmod a+r /docker-entrypoint-initdb.d/init-galaxy-db.sql.in
