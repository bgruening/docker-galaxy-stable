FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive
ENV GALAXY_USER=galaxy \
GALAXY_UID=1450 \
GALAXY_GID=1450 \
GALAXY_HOME=/home/galaxy \
EXPORT_DIR=/export \
# Setting a standard encoding. This can get important for things like the unix sort tool.
LC_ALL=en_US.UTF-8 \
LANG=en_US.UTF-8

RUN locale-gen $LANG && dpkg-reconfigure locales

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    apt-transport-https software-properties-common wget && \
    sh -c "wget -qO- - https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -" && \
    add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu trusty stable" && \
    echo "deb http://research.cs.wisc.edu/htcondor/ubuntu/stable/ trusty contrib" > /etc/apt/sources.list.d/htcondor.list && \
    wget -qO - http://research.cs.wisc.edu/htcondor/ubuntu/HTCondor-Release.gpg.key | sudo apt-key add - && \
    apt-get update -qq && apt-get install -y condor docker-ce && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -r $GALAXY_USER -g $GALAXY_GID && \
    useradd -u $GALAXY_UID -r -g $GALAXY_USER -d $GALAXY_HOME -c "Galaxy user" $GALAXY_USER && \
    gpasswd -a $GALAXY_USER docker && \
    adduser condor docker && \
    mkdir /root/.docker && \
    chown root:docker /root/.docker && \
    chmod 750 /root/.docker && \
    chmod +rx /root

ADD startup.sh /usr/bin/startup.sh
RUN chmod +x /usr/bin/startup.sh
CMD ["/usr/bin/startup.sh"]
