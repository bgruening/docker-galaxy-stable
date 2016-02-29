#!/bin/bash

do_backup () {
   backupdest="/export/preupgradebackup_"$(date +%Y_%m_%d_%H_%M_%S)
   mkdir -p "${backupdest}" && cp -R /export/galaxy-central /export/postgresql /export/shed_tools /export/var "${backupdest}"
}

do_upgrade () {
   cd "$( dirname "$0" )" || echo "Could not change directory! Aborting." 1>&2 && exit 1
   python ./scripts/manage_db.py "$@"
}

if [ -z "$DB_UPGRADE" ]; then
   echo "no upgrade performed. If you want to upgrade your database use 'export DB_UPGRADE=true'";
else
   echo "GALAXY_LOGGING will be set to full, because DB_UPGRADE is enabled."
   export GALAXY_LOGGING="full"
   echo DB_UPGRADE="${DB_UPGRADE,,}"
   if [ "$DB_UPGRADE" = "nobackup" ]; then
      do_upgrade "$@"
      else
      do_backup && do_upgrade "$@"
   fi
fi
