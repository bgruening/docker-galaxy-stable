#!/bin/bash
# Configurable variables via env
playbookvars=('proftpd_db_connection' \
'proftpd_db_username' \
'proftpd_db_password' \
'proftpd_files_dir' \
'proftpd_sql_auth_type' \
'proftpd_welcome' \
'proftpd_passive_port_low' \
'proftpd_passive_port_high' \
'proftpd_use_sftp' \
'proftpd_nat_masquerade' \
'proftpd_masquerade_address')

# Generate override argument for ansible playbook
playbookargs=""
for var in "${playbookvars[@]}"
do
  if ! [ -z ${!var+x} ]
  then
    playbookargs="$playbookargs --extra-vars $var=\"${!var}\""
    echo "Overriding $var=${!var}"
  fi
done

# Run playbook to generate config, etc.
ansible-playbook /ansible/provision.yml \
    --tags=proftpd --skip-tags=proftpd_apt -c local $playbookargs
# Run service
proftpd --nodaemon
