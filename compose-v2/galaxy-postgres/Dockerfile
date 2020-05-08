FROM library/postgres:11.2 AS build

ARG GALAXY_RELEASE=release_20.05
ARG GALAXY_REPO=https://github.com/galaxyproject/galaxy

COPY init-galaxy-db.sql.in /docker-entrypoint-initdb.d/
COPY init-galaxy-db.sh /docker-entrypoint-initdb.d/
RUN chmod a+rx /docker-entrypoint-initdb.d/init-galaxy-db.sh && \
    chmod a+r /docker-entrypoint-initdb.d/init-galaxy-db.sql.in

# Initialize database with Galaxy model to create initial sql-dump
ENV POSTGRES_PASSWORD=build \
    POSTGRES_USER=galaxy \
    POSTGRES_DB=galaxy
# Install Galaxy (there needs to be a better way!!)
ENV GALAXY_PYTHON=/usr/bin/python
RUN apt update && apt install --no-install-recommends build-essential ca-certificates curl gcc libpq-dev python-pip python-dev -y \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir /galaxy && curl -L -s $GALAXY_REPO/archive/$GALAXY_RELEASE.tar.gz | tar xzf - --strip-components=1 -C /galaxy \
    && cd /galaxy && ./scripts/common_startup.sh --skip-client-build && cd / \
    && . /galaxy/.venv/bin/activate && pip install psycopg2 && deactivate
COPY files/galaxy.yml /galaxy/config/galaxy.yml
RUN docker-entrypoint.sh postgres & sleep 10 \
    && /galaxy/create_db.sh -c /galaxy/config/galaxy.yml \
    && PGPASSWORD=$POSTGRES_PASSWORD pg_dump -h localhost -U galaxy galaxy > /docker-entrypoint-initdb.d/galaxy.sql

FROM library/postgres:11.2

COPY init-galaxy-db.sql.in /docker-entrypoint-initdb.d/
COPY init-galaxy-db.sh /docker-entrypoint-initdb.d/
RUN chmod a+rx /docker-entrypoint-initdb.d/init-galaxy-db.sh && \
    chmod a+r /docker-entrypoint-initdb.d/init-galaxy-db.sql.in
COPY --from=build /docker-entrypoint-initdb.d/galaxy.sql /docker-entrypoint-initdb.d/galaxy.sql
