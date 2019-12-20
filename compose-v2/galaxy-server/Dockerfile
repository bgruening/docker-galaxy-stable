FROM alpine:3.10

ENV EXPORT_DIR=/export \
    GALAXY_ROOT=/galaxy

ENV GALAXY_RELEASE=${GALAXY_RELEASE:-release_19.05} \
    GALAXY_REPO=${GALAXY_REPO:-https://github.com/galaxyproject/galaxy} \
    GALAXY_STATIC_DIR=$GALAXY_ROOT/static \
    GALAXY_EXPORT=$EXPORT_DIR/galaxy \
    GALAXY_CONFIG_DIR=$GALAXY_ROOT/config \
    GALAXY_CONFIG_TOOL_DEPENDENCY_DIR=/tool_deps \
    GALAXY_CONFIG_TOOL_PATH=/tools

ENV GALAXY_USER=galaxy \
    GALAXY_GROUP=galaxy \
    GALAXY_UID=1450 \
    GALAXY_GID=1450 \
    GALAXY_HOME=/home/galaxy

ENV GALAXY_CONDA_PREFIX=$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR/_conda \
    MINICONDA_VERSION=4.7.10

# TODO: CLEAN UP!!!!
# Install all needed dependencies
RUN apk add --no-cache py2-virtualenv git curl nodejs wget gcc bash musl-dev python2-dev libffi-dev zlib-dev xz-dev curl-dev build-base bzip2-dev libxml2-dev libxslt-dev
RUN apk add --no-cache \
            --allow-untrusted \
            --repository \
             http://dl-3.alpinelinux.org/alpine/edge/testing \
            hdf5 \
            hdf5-dev
# Needed for miniconda, see https://github.com/CognitiveScale/alpine-miniconda/blob/master/Dockerfile
RUN apk --update  --repository http://dl-4.alpinelinux.org/alpine/edge/community add \
    bash \
    git \
    curl \
    ca-certificates \
    bzip2 \
    unzip \
    sudo \
    libstdc++ \
    glib \
    libxext \
    libxrender \
    tini \ 
    && curl -L "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/2.25-r0/glibc-2.25-r0.apk" -o /tmp/glibc.apk \
    && curl -L "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/2.25-r0/glibc-bin-2.25-r0.apk" -o /tmp/glibc-bin.apk \
    && curl -L "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/2.25-r0/glibc-i18n-2.25-r0.apk" -o /tmp/glibc-i18n.apk \
    && apk add --allow-untrusted /tmp/glibc*.apk \
    && /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib \
    && /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 \
    && rm -rf /tmp/glibc*apk /var/cache/apk/*

RUN addgroup -S -g $GALAXY_GID $GALAXY_GROUP && adduser -S -G $GALAXY_GROUP -u $GALAXY_UID $GALAXY_USER

# Install Miniconda
RUN curl -s -L "https://repo.anaconda.com/miniconda/Miniconda2-${MINICONDA_VERSION}-Linux-x86_64.sh" > ~/miniconda.sh \
    && /bin/bash ~/miniconda.sh -b -p $GALAXY_CONDA_PREFIX \
    && rm ~/miniconda.sh \
    && ln -s $GALAXY_CONDA_PREFIX/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && echo ". $GALAXY_CONDA_PREFIX/etc/profile.d/conda.sh" >> $GALAXY_HOME/.bashrc \
    && echo "conda activate base" >> $GALAXY_HOME/.bashrc \
    && export PATH=$GALAXY_CONDA_PREFIX/bin/:$PATH \
    && conda config --add channels defaults \
    && conda config --add channels bioconda \
    && conda config --add channels conda-forge \
    && conda install virtualenv pip ephemeris \
    && chown $GALAXY_GROUP:$GALAXY_USER -R $GALAXY_CONFIG_TOOL_DEPENDENCY_DIR /etc/profile.d/conda.sh \
    && conda clean --packages -t -i 
    # cleanup dance
    # && find $GALAXY_ROOT -name '*.pyc' -delete | true \
    # && find /usr/lib/ -name '*.pyc' -delete | true \
    # && find $GALAXY_CONDA_PREFIX/ -name '*.pyc' -delete | true \
    #&& find $GALAXY_VIRTUAL_ENV -name '*.pyc' -delete | true \
    #&& rm -rf /tmp/* /root/.cache/ /var/cache/* $GALAXY_ROOT/client/node_modules/ $GALAXY_VIRTUAL_ENV/src/ /home/galaxy/.cache/ /home/galaxy/.npm

# Install Galaxy
RUN mkdir "${GALAXY_ROOT}" \
    && curl -L -s $GALAXY_REPO/archive/$GALAXY_RELEASE.tar.gz | tar xzf - --strip-components=1 -C $GALAXY_ROOT \
    && chown -R $GALAXY_GROUP:$GALAXY_USER $GALAXY_ROOT 
    # cleanup dance
    # && find $GALAXY_ROOT -name '*.pyc' -delete | true \
    # && find /usr/lib/ -name '*.pyc' -delete | true \
    #&& find $GALAXY_CONDA_PREFIX/ -name '*.pyc' -delete | true \
    #&& find $GALAXY_VIRTUAL_ENV -name '*.pyc' -delete | true \
    #&& rm -rf /tmp/* /root/.cache/ /var/cache/* $GALAXY_ROOT/client/node_modules/ $GALAXY_VIRTUAL_ENV/src/ /home/galaxy/.cache/ /home/galaxy/.npm

# Install Galaxy dependencies
# USER $GALAXY_USER
RUN cd $GALAXY_ROOT && ./scripts/common_startup.sh

COPY ./files/galaxy.yml /galaxy/config/galaxy.yml
COPY ./files/start.sh /usr/bin/start.sh

EXPOSE 80

ENTRYPOINT "/usr/bin/start.sh"