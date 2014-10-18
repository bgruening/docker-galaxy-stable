import sys
import os
import shutil
import subprocess

if len( sys.argv ) == 2:
    PG_DATA_DIR_DEFAULT = sys.argv[1]
else:
    PG_DATA_DIR_DEFAULT = "/var/lib/postgresql/9.3/main"
PG_DATA_DIR_HOST = os.environ.get("PG_DATA_DIR_HOST", "/export/postgresql/9.3/main/")
PG_CONF = '/etc/postgresql/9.3/main/postgresql.conf'


def change_path( src ):
    """
        src will be copied to /export/`src` and a symlink will be placed in src pointing to /export/
    """
    if os.path.exists( src ):
        dest = os.path.join( '/export/', src.strip('/') )
        # if destination is empty move all files into /export/ and symlink back to source
        if not os.path.exists( dest ):
            dest_dir = os.path.dirname(dest)
            if not os.path.exists( dest_dir ):
                os.makedirs(dest_dir)
            shutil.move( src, dest )
            os.symlink( dest, src.rstrip('/') )
        # if destination exists (e.g. continuing a previous session), remove source and symlink
        else:
            if os.path.isdir( src ):
                shutil.rmtree( src )
            else:
                os.unlink( src )
            os.symlink( dest, src.rstrip('/') )


if __name__ == "__main__":
    """
        If the '/export/' folder exist, meaning docker was started with '-v /home/foo/bar:/export',
        we will link every file that needs to persist to the host system. Addionaly a file (/.galaxy_save) is
        created that indicates all linking is already done.
        If the user re-starts (with docker start) the container the file /.galaxy_save is found and the linking
        is aborted.
    """
    if os.path.exists( '/export/.distribution_config/' ):
        shutil.rmtree( '/export/.distribution_config/' )
    shutil.copytree( '/galaxy-central/config/', '/export/.distribution_config/' )
    change_path('/galaxy-central/config/')
    change_path('/galaxy-central/static/welcome.html')
    change_path('/galaxy-central/integrated_tool_panel.xml')
    change_path('/galaxy-central/tool_deps/')
    change_path('/galaxy-central/tool-data/')
    change_path('/shed_tools/')

    if not os.path.exists( PG_DATA_DIR_HOST ) or 'PG_VERSION' not in os.listdir( PG_DATA_DIR_HOST ):
        dest_dir = os.path.dirname( PG_DATA_DIR_HOST )
        if not os.path.exists( dest_dir ):
            os.makedirs(dest_dir)
        # User given dbpath, usually a directory from the host machine
        # copy the postgresql data folder to the new location
        subprocess.call('cp -R %s/* %s' % (PG_DATA_DIR_DEFAULT, PG_DATA_DIR_HOST), shell=True)
        # copytree needs an non-existing dst dir, how annoying :(
        #shutil.copytree(PG_DATA_DIR_DEFAULT, PG_DATA_DIR_HOST)
        subprocess.call('chown -R postgres:postgres /export/postgresql/', shell=True)
        subprocess.call('chmod -R 0755 /export/', shell=True)
        subprocess.call('chmod -R 0700 %s' % PG_DATA_DIR_HOST, shell=True)

    # change data_directory of PostgreSQL to the new location
    # This is not strictly needed because we are starting postgresql with pointing to the data directory
    new_data_directory = "'%s'" % PG_DATA_DIR_HOST
    cmd = 'sed -i "s|data_directory = .*|data_directory = %s|g" %s' % (new_data_directory, PG_CONF)
    subprocess.call(cmd, shell=True)

