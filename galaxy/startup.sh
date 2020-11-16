#!/usr/bin/env bash

# Migration path for old images that had the tool_deps under /export/galaxy-central/tool_deps/

if [ -d "/export/galaxy-central/tool_deps/" ] && [ ! -L "/export/galaxy-central/tool_deps/" ]; then
    mkdir -p /export/tool_deps/
    mv /export/galaxy-central/tool_deps /export/
    ln -s /export/tool_deps/ $GALAXY_ROOT/
fi

# This is needed for Docker compose to have a unified alias for the main container.
# Modifying /etc/hosts can only happen during runtime not during build-time
echo "127.0.0.1      galaxy" >> /etc/hosts

# Set number of Galaxy handlers via GALAXY_HANDLER_NUMPROCS or default to 2
ansible localhost -m ini_file -a "dest=/etc/supervisor/conf.d/galaxy.conf section=program:handler option=numprocs value=${GALAXY_HANDLER_NUMPROCS:-2}" &> /dev/null

# If the Galaxy config file is not in the expected place, copy from the sample
# and hope for the best (that the admin has done all the setup through env vars.)
if [ ! -f $GALAXY_CONFIG_FILE ]
  then
  # this should succesfully copy either .yml or .ini sample file to the expected location
  cp /export/config/galaxy${GALAXY_CONFIG_FILE: -4}.sample $GALAXY_CONFIG_FILE
fi

# Configure proxy prefix filtering
if [[ ! -z $PROXY_PREFIX ]]
    then
    if [ ${GALAXY_CONFIG_FILE: -4} == ".ini" ]
        then
        ansible localhost -m ini_file -a "dest=${GALAXY_CONFIG_FILE} section=filter:proxy-prefix option=prefix value=${PROXY_PREFIX}" &> /dev/null
        ansible localhost -m ini_file -a "dest=${GALAXY_CONFIG_FILE} section=app:main option=filter-with value=proxy-prefix" &> /dev/null
    else
        ansible localhost -m lineinfile -a "path=${GALAXY_CONFIG_FILE} regexp='^  module:' state=absent" &> /dev/null
        ansible localhost -m lineinfile -a "path=${GALAXY_CONFIG_FILE} regexp='^  socket:' state=absent" &> /dev/null
        ansible localhost -m lineinfile -a "path=${GALAXY_CONFIG_FILE} regexp='^  mount:' state=absent" &> /dev/null
        ansible localhost -m lineinfile -a "path=${GALAXY_CONFIG_FILE} regexp='^  manage-script-name:' state=absent" &> /dev/null
        ansible localhost -m lineinfile -a "path=${GALAXY_CONFIG_FILE} insertafter='^uwsgi:' line='  manage-script-name: true'" &> /dev/null
        ansible localhost -m lineinfile -a "path=${GALAXY_CONFIG_FILE} insertafter='^uwsgi:' line='  mount: ${PROXY_PREFIX}=galaxy.webapps.galaxy.buildapp:uwsgi_app()'" &> /dev/null
        ansible localhost -m lineinfile -a "path=${GALAXY_CONFIG_FILE} insertafter='^uwsgi:' line='  socket: unix:///srv/galaxy/var/uwsgi.sock'" &> /dev/null

        # Also set SCRIPT_NAME. It's not always necessary due to manage-script-name: true in galaxy.yml, but it makes life easier in this container + it does no harm
        ansible localhost -m lineinfile -a "path=/etc/nginx/conf.d/uwsgi.conf regexp='^    uwsgi_param SCRIPT_NAME' state=absent" &> /dev/null
        ansible localhost -m lineinfile -a "path=/etc/nginx/conf.d/uwsgi.conf insertafter='^    include uwsgi_params' line='    uwsgi_param SCRIPT_NAME ${PROXY_PREFIX};'" &> /dev/null
    fi

    ansible localhost -m ini_file -a "dest=${GALAXY_CONFIG_DIR}/reports_wsgi.ini section=filter:proxy-prefix option=prefix value=${PROXY_PREFIX}/reports" &> /dev/null
    ansible localhost -m ini_file -a "dest=${GALAXY_CONFIG_DIR}/reports_wsgi.ini section=app:main option=filter-with value=proxy-prefix" &> /dev/null

    # Fix path to html assets
    ansible localhost -m replace -a "dest=$GALAXY_CONFIG_DIR/web/welcome.html regexp='(href=\"|\')[/\\w]*(/static)' replace='\\1${PROXY_PREFIX}\\2'" &> /dev/null

    # Set some other vars based on that prefix
    if [ "x$GALAXY_CONFIG_COOKIE_PATH" == "x" ]
        then
        export GALAXY_CONFIG_COOKIE_PATH="$PROXY_PREFIX"
    fi
    if [ "x$GALAXY_CONFIG_DYNAMIC_PROXY_PREFIX" == "x" ]
        then
        export GALAXY_CONFIG_DYNAMIC_PROXY_PREFIX="$PROXY_PREFIX/gie_proxy"
    fi

    # Change the defaults nginx upload/x-accel paths
    if [ "$GALAXY_CONFIG_NGINX_UPLOAD_PATH" == "/_upload" ]
        then
            export GALAXY_CONFIG_NGINX_UPLOAD_PATH="${PROXY_PREFIX}${GALAXY_CONFIG_NGINX_UPLOAD_PATH}"
    fi
fi

# Disable authentication of Galaxy reports
if [[ ! -z $DISABLE_REPORTS_AUTH ]]
    then
        # disable authentification
        echo "Disable Galaxy reports authentification "
        echo "" > /etc/nginx/conf.d/reports_auth.conf
    else
        # enable authentification
        echo "Enable Galaxy reports authentification "
        cp /etc/nginx/conf.d/reports_auth.conf.source /etc/nginx/conf.d/reports_auth.conf
fi

# Try to guess if we are running under --privileged mode
if [[ ! -z $HOST_DOCKER_LEGACY ]]; then
    if mount | grep "/proc/kcore"; then
        PRIVILEGED=false
    else
        PRIVILEGED=true
    fi
else
    # Taken from http://stackoverflow.com/questions/32144575/how-to-know-if-a-docker-container-is-running-in-privileged-mode
    ip link add dummy0 type dummy 2>/dev/null
    if [[ $? -eq 0 ]]; then
        PRIVILEGED=true
        # clean the dummy0 link
        ip link delete dummy0 2>/dev/null
    else
        PRIVILEGED=false
    fi
fi

cd $GALAXY_ROOT
. $GALAXY_VIRTUAL_ENV/bin/activate

if $PRIVILEGED; then
    umount /var/lib/docker
fi

if [[ ! -z $STARTUP_EXPORT_USER_FILES ]]; then
    # If /export/ is mounted, export_user_files file moving all data to /export/
    # symlinks will point from the original location to the new path under /export/
    # If /export/ is not given, nothing will happen in that step
    echo "Checking /export..."
    python3 /usr/local/bin/export_user_files.py $PG_DATA_DIR_DEFAULT
fi

# Delete compiled templates in case they are out of date
if [[ ! -z $GALAXY_CONFIG_TEMPLATE_CACHE_PATH ]]; then
    rm -rf $GALAXY_CONFIG_TEMPLATE_CACHE_PATH/*
fi

# Enable loading of dependencies on startup. Such as LDAP.
# Adapted from galaxyproject/galaxy/scripts/common_startup.sh
if [[ ! -z $LOAD_GALAXY_CONDITIONAL_DEPENDENCIES ]]
    then
        echo "Installing optional dependencies in galaxy virtual environment..."
        : ${GALAXY_WHEELS_INDEX_URL:="https://wheels.galaxyproject.org/simple"}
        GALAXY_CONDITIONAL_DEPENDENCIES=$(PYTHONPATH=lib python -c "import galaxy.dependencies; print('\n'.join(galaxy.dependencies.optional('$GALAXY_CONFIG_FILE')))")
        [ -z "$GALAXY_CONDITIONAL_DEPENDENCIES" ] || echo "$GALAXY_CONDITIONAL_DEPENDENCIES" | pip install -q -r /dev/stdin --index-url "${GALAXY_WHEELS_INDEX_URL}"
fi

if [[ ! -z $LOAD_GALAXY_CONDITIONAL_DEPENDENCIES ]] && [[ ! -z $LOAD_PYTHON_DEV_DEPENDENCIES ]]
    then
        echo "Installing development requirements in galaxy virtual environment..."
        : ${GALAXY_WHEELS_INDEX_URL:="https://wheels.galaxyproject.org/simple"}
        dev_requirements='./lib/galaxy/dependencies/dev-requirements.txt'
        [ -f $dev_requirements ] && pip install -q -r $dev_requirements --index-url "${GALAXY_WHEELS_INDEX_URL}"
fi

# Enable Test Tool Shed
if [[ ! -z $ENABLE_TTS_INSTALL ]]
    then
        echo "Enable installation from the Test Tool Shed."
        export GALAXY_CONFIG_TOOL_SHEDS_CONFIG_FILE=$GALAXY_HOME/tool_sheds_conf.xml
fi

# Remove all default tools from Galaxy by default
if [[ ! -z $BARE ]]
    then
        echo "Remove all tools from the tool_conf.xml file."
        export GALAXY_CONFIG_TOOL_CONFIG_FILE=config/shed_tool_conf.xml,$GALAXY_ROOT/test/functional/tools/upload_tool_conf.xml
fi

# If auto installing conda envs, make sure bcftools is installed for __set_metadata__ tool
if [[ ! -z $GALAXY_CONFIG_CONDA_AUTO_INSTALL ]]
    then
        if [ ! -d "/tool_deps/_conda/envs/__bcftools@1.5" ]; then
            su $GALAXY_USER -c "/tool_deps/_conda/bin/conda create -y --override-channels --channel iuc --channel conda-forge --channel bioconda --channel defaults --name __bcftools@1.5 bcftools=1.5"
            su $GALAXY_USER -c "/tool_deps/_conda/bin/conda clean --tarballs --yes"
        fi
fi

if [[ ! -z $GALAXY_EXTRAS_CONFIG_POSTGRES ]]; then
    if [[ $NONUSE != *"postgres"* ]]
    then
        # Backward compatibility for exported postgresql directories before version 15.08.
        # In previous versions postgres has the UID/GID of 102/106. We changed this in
        # https://github.com/bgruening/docker-galaxy-stable/pull/71 to GALAXY_POSTGRES_UID=1550 and
        # GALAXY_POSTGRES_GID=1550
        if [ -e /export/postgresql/ ];
            then
                if [ `stat -c %g /export/postgresql/` == "106" ];
                    then
                        chown -R postgres:postgres /export/postgresql/
                fi
        fi
    fi
fi


if [[ ! -z $GALAXY_EXTRAS_CONFIG_CONDOR ]]; then
    if [[ ! -z $ENABLE_CONDOR ]]
    then
        if [[ ! -z $CONDOR_HOST ]]
        then
            echo "Enabling Condor with external scheduler at $CONDOR_HOST"
        echo "# Config generated by startup.sh
CONDOR_HOST = $CONDOR_HOST
ALLOW_ADMINISTRATOR = *
ALLOW_OWNER = *
ALLOW_READ = *
ALLOW_WRITE = *
ALLOW_CLIENT = *
ALLOW_NEGOTIATOR = *
DAEMON_LIST = MASTER, SCHEDD
UID_DOMAIN = galaxy
DISCARD_SESSION_KEYRING_ON_STARTUP = False
TRUST_UID_DOMAIN = true" > /etc/condor/condor_config.local
        fi

        if [[ -e /export/condor_config ]]
        then
            echo "Replacing Condor config by locally supplied config from /export/condor_config"
            rm -f /etc/condor/condor_config
            ln -s /export/condor_config /etc/condor/condor_config
        fi
    fi
fi


# Copy or link the slurm/munge config files
if [ -e /export/slurm.conf ]
then
    rm -f /etc/slurm-llnl/slurm.conf
    ln -s /export/slurm.conf /etc/slurm-llnl/slurm.conf
else
    # Configure SLURM with runtime hostname.
    # Use absolute path to python so virtualenv is not used.
    /usr/bin/python3 /usr/sbin/configure_slurm.py
fi
if [ -e /export/munge.key ]
then
    rm -f /etc/munge/munge.key
    ln -s /export/munge.key /etc/munge/munge.key
    chmod 400 /export/munge.key
fi

# link the gridengine config file
if [ -e /export/act_qmaster ]
then
    rm -f /var/lib/gridengine/default/common/act_qmaster
    ln -s /export/act_qmaster /var/lib/gridengine/default/common/act_qmaster
fi

# Waits until postgres is ready
function wait_for_postgres {
    echo "Checking if database is up and running"
    until /usr/local/bin/check_database.py 2>&1 >/dev/null; do sleep 1; echo "Waiting for database"; done
    echo "Database connected"
}

# $NONUSE can be set to include cron, proftp, reports or nodejs
# if included we will _not_ start these services.
function start_supervisor {
    supervisord -c /etc/supervisor/supervisord.conf
    sleep 5

    if [[ ! -z $SUPERVISOR_MANAGE_POSTGRES && ! -z $SUPERVISOR_POSTGRES_AUTOSTART ]]; then
        if [[ $NONUSE != *"postgres"* ]]
        then
            echo "Starting postgres"
            supervisorctl start postgresql
        fi
    fi

    wait_for_postgres

    # Make sure the database is automatically updated
    if [[ ! -z $GALAXY_AUTO_UPDATE_DB ]]
    then
        echo "Updating Galaxy database"
        sh manage_db.sh -c /etc/galaxy/galaxy.yml upgrade
    fi

    if [[ ! -z $SUPERVISOR_MANAGE_CRON ]]; then
        if [[ $NONUSE != *"cron"* ]]
        then
            echo "Starting cron"
            supervisorctl start cron
        fi
    fi

    if [[ ! -z $SUPERVISOR_MANAGE_PROFTP ]]; then
        if [[ $NONUSE != *"proftp"* ]]
        then
            echo "Starting ProFTP"
            supervisorctl start proftpd
        fi
    fi

    if [[ ! -z $SUPERVISOR_MANAGE_REPORTS ]]; then
        if [[ $NONUSE != *"reports"* ]]
        then
            echo "Starting Galaxy reports webapp"
            supervisorctl start reports
        fi
    fi

    if [[ ! -z $SUPERVISOR_MANAGE_IE_PROXY ]]; then
        if [[ $NONUSE != *"nodejs"* ]]
        then
            echo "Starting nodejs"
            supervisorctl start galaxy:galaxy_nodejs_proxy
        fi
    fi

    if [[ ! -z $SUPERVISOR_MANAGE_CONDOR ]]; then
        if [[ $NONUSE != *"condor"* ]]
        then
            echo "Starting condor"
            supervisorctl start condor
        fi
    fi

    if [[ ! -z $SUPERVISOR_MANAGE_SLURM ]]; then
        if [[ $NONUSE != *"slurmctld"* ]]
        then
            echo "Starting slurmctld"
            supervisorctl start slurmctld
        fi
        if [[ $NONUSE != *"slurmd"* ]]
        then
            echo "Starting slurmd"
            supervisorctl start slurmd
        fi
        supervisorctl start munge
    else
        if [[ $NONUSE != *"slurmctld"* ]]
        then
            echo "Starting slurmctld"
            /usr/sbin/slurmctld -L $GALAXY_LOGS_DIR/slurmctld.log
        fi
        if [[ $NONUSE != *"slurmd"* ]]
        then
            echo "Starting slurmd"
            /usr/sbin/slurmd -L $GALAXY_LOGS_DIR/slurmd.log
        fi

        # We need to run munged regardless
        mkdir -p /var/run/munge && /usr/sbin/munged -f
    fi
}

if [[ ! -z $SUPERVISOR_POSTGRES_AUTOSTART ]]; then
    if [[ $NONUSE != *"postgres"* ]]
    then
        # Change the data_directory of postgresql in the main config file
        ansible localhost -m lineinfile -a "line='data_directory = \'$PG_DATA_DIR_HOST\'' dest=$PG_CONF_DIR_DEFAULT/postgresql.conf backup=yes state=present regexp='data_directory'" &> /dev/null
    fi
fi

if $PRIVILEGED; then
    echo "Enable Galaxy Interactive Environments."
    export GALAXY_CONFIG_INTERACTIVE_ENVIRONMENT_PLUGINS_DIRECTORY="config/plugins/interactive_environments"
    if [ x$DOCKER_PARENT == "x" ]; then
        #build the docker in docker environment
        bash /root/cgroupfs_mount.sh
        start_supervisor
        supervisorctl start docker
    else
        #inheriting /var/run/docker.sock from parent, assume that you need to
        #run docker with sudo to validate
        echo "$GALAXY_USER ALL = NOPASSWD : ALL" >> /etc/sudoers
        start_supervisor
    fi
    if  [[ ! -z $PULL_IE_IMAGES ]]; then
        echo "About to pull IE images. Depending on the size, this may take a while!"

        for ie in {JUPYTER,RSTUDIO,ETHERCALC,PHINCH,NEO}; do
            enabled_var_name="GALAXY_EXTRAS_IE_FETCH_${ie}";
            if [[ ${!enabled_var_name} ]]; then
                # Store name in a var
                image_var_name="GALAXY_EXTRAS_${ie}_IMAGE"
                # And then read from that var
                docker pull "${!image_var_name}"
            fi
        done
    fi

    # in privileged mode autofs and CVMFS is available
    # install autofs
    echo "Installing autofs to enable automatic CVMFS mounts"
    apt-get install autofs --no-install-recommends -y
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*
else
    echo "Disable Galaxy Interactive Environments. Start with --privileged to enable IE's."
    export GALAXY_CONFIG_INTERACTIVE_ENVIRONMENT_PLUGINS_DIRECTORY=""
    start_supervisor
fi

if [ "$USE_HTTPS_LETSENCRYPT" != "False" ]
then
    echo "Settting up letsencrypt"
    ansible-playbook -c local /ansible/provision.yml \
    --extra-vars gather_facts=False \
    --extra-vars galaxy_extras_config_ssl=True \
    --extra-vars galaxy_extras_config_ssl_method=letsencrypt \
    --extra-vars galaxy_extras_galaxy_domain="GALAXY_CONFIG_GALAXY_INFRASTRUCTURE_URL" \
    --extra-vars galaxy_extras_config_nginx_upload=False \
    --tags https
fi
if [ "$USE_HTTPS" != "False" ]
then
    if [ -f /export/server.key -a -f /export/server.crt ]
    then
        echo "Copying SSL keys"
        ansible-playbook -c local /ansible/provision.yml \
        --extra-vars gather_facts=False \
        --extra-vars galaxy_extras_config_ssl=True \
        --extra-vars galaxy_extras_config_ssl_method=own \
        --extra-vars src_nginx_ssl_certificate_key=/export/server.key \
        --extra-vars src_nginx_ssl_certificate=/export/server.crt \
        --extra-vars galaxy_extras_config_nginx_upload=False \
        --tags https
    else
        echo "Setting up self-signed SSL keys"
        ansible-playbook -c local /ansible/provision.yml \
        --extra-vars gather_facts=False \
        --extra-vars galaxy_extras_config_ssl=True \
        --extra-vars galaxy_extras_config_ssl_method=self-signed \
        --extra-vars galaxy_extras_config_nginx_upload=False \
        --tags https
    fi
fi

# In case the user wants the default admin to be created, do so.
if [[ ! -z $GALAXY_DEFAULT_ADMIN_USER ]]
    then
        echo "Creating admin user $GALAXY_DEFAULT_ADMIN_USER with key $GALAXY_DEFAULT_ADMIN_KEY and password $GALAXY_DEFAULT_ADMIN_PASSWORD if not existing"
        python /usr/local/bin/create_galaxy_user.py --user "$GALAXY_DEFAULT_ADMIN_EMAIL" --password "$GALAXY_DEFAULT_ADMIN_PASSWORD" \
        -c "$GALAXY_CONFIG_FILE" --username "$GALAXY_DEFAULT_ADMIN_USER" --key "$GALAXY_DEFAULT_ADMIN_KEY"
    # If there is a need to execute actions that would require a live galaxy instance, such as adding workflows, setting quotas, adding more users, etc.
    # then place a file with that logic named post-start-actions.sh on the /export/ directory, it should have access to all environment variables
    # visible here.
    # The file needs to be executable (chmod a+x post-start-actions.sh)
        if [ -x /export/post-start-actions.sh ]
            then
           # uses ephemeris, present in docker-galaxy-stable, to wait for the local instance
           /tool_deps/_conda/bin/galaxy-wait -g http://127.0.0.1 -v --timeout 120 > $GALAXY_LOGS_DIR/post-start-actions.log &&
           /export/post-start-actions.sh >> $GALAXY_LOGS_DIR/post-start-actions.log &
    fi
fi

# Reinstall tools if the user want to
if [[ ! -z $GALAXY_AUTO_UPDATE_TOOLS ]]
    then
        /tool_deps/_conda/bin/galaxy-wait -g http://127.0.0.1 -v --timeout 120 > /home/galaxy/logs/post-start-actions.log &&
        OLDIFS=$IFS
        IFS=','
        for TOOL_YML in `echo "$GALAXY_AUTO_UPDATE_TOOLS"`
        do
            echo "Installing tools from $TOOL_YML"
            /tool_deps/_conda/bin/shed-tools install -g "http://127.0.0.1" -a "$GALAXY_DEFAULT_ADMIN_KEY" -t "$TOOL_YML"
            /tool_deps/_conda/bin/conda clean --tarballs --yes
        done
        IFS=$OLDIFS
fi

# migrate custom IEs or Visualisations (Galaxy plugins)
# this is needed for by the new client build system
python3 ${GALAXY_ROOT}/scripts/plugin_staging.py

# Enable verbose output
if [ `echo ${GALAXY_LOGGING:-'no'} | tr [:upper:] [:lower:]` = "full" ]
    then
        tail -f /var/log/supervisor/* /var/log/nginx/* $GALAXY_LOGS_DIR/*.log
    else
        tail -f $GALAXY_LOGS_DIR/*.log
fi
