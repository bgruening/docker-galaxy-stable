FROM ubuntu:20.04 as final

ENV SLURM_USER=galaxy \
    SLURM_UID=1450 \
    SLURM_GID=1450 \
    MUNGER_USER=munge \
    MUNGE_UID=1200 \
    MUNGE_GID=1200

RUN groupadd -r $SLURM_USER -g $SLURM_GID \
    && useradd -u $SLURM_UID -r -g $SLURM_USER $SLURM_USER \
    && groupadd -r $MUNGER_USER -g $MUNGE_GID \
    && useradd -u $MUNGE_UID -r -g $MUNGER_USER $MUNGER_USER \
    && apt update \
    && apt install --no-install-recommends gosu munge python2 python2-dev slurm-wlm -y \
    && rm -rf /var/lib/apt/lists/* && rm -rf /var/cache/*

COPY start.sh /usr/bin/start.sh

ENTRYPOINT [ "/usr/bin/start.sh" ]
