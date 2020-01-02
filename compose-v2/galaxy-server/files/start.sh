set +x
# First start?? Check if something exists that indicates that environment is not new.. Config file? Something in DB maybe??

echo "Initialization: Check if files already exist, export otherwise."
if [ ! -d  "$EXPORT_DIR/$GALAXY_ROOT" ]; then
    # Create initial $GALAXY_ROOT in $EXPORT_DIR
    mkdir $EXPORT_DIR/$GALAXY_ROOT
fi

if [ ! -d  "$EXPORT_DIR/$GALAXY_CONFIG_DIR" ] || [ -z "$(ls -p $EXPORT_DIR/$GALAXY_CONFIG_DIR | grep -v /)" ]; then
    # Move config to $EXPORT_DIR and create symlink 
    mkdir $EXPORT_DIR/$GALAXY_CONFIG_DIR
    cp -rfv $GALAXY_CONFIG_DIR/* $EXPORT_DIR/$GALAXY_CONFIG_DIR
    cp -rfv $GALAXY_CONFIG_DIR/plugins/* $EXPORT_DIR/$GALAXY_CONFIG_DIR/plugins
fi
rm -rf $GALAXY_CONFIG_DIR
ln -v -s $EXPORT_DIR/$GALAXY_CONFIG_DIR $GALAXY_CONFIG_DIR

if [ ! -d  "$EXPORT_DIR/$GALAXY_STATIC_DIR" ] || [ -z "$(ls -A $EXPORT_DIR/$GALAXY_STATIC_DIR)" ]; then
    # Move static to $EXPORT_DIR and create symlink
    mkdir $EXPORT_DIR/$GALAXY_STATIC_DIR
    cp -rfv $GALAXY_STATIC_DIR/* $EXPORT_DIR/$GALAXY_STATIC_DIR
fi
rm -rf $GALAXY_STATIC_DIR
ln -v -s $EXPORT_DIR/$GALAXY_STATIC_DIR $GALAXY_STATIC_DIR

if [ ! -d  "$EXPORT_DIR/$GALAXY_CONFIG_TOOL_PATH" ] || [ -z "$(ls -A $EXPORT_DIR/$GALAXY_CONFIG_TOOL_PATH)" ]; then
    # Move environment to export and create symlink
    mkdir $EXPORT_DIR/$GALAXY_CONFIG_TOOL_PATH
    cp -rfv $GALAXY_CONFIG_TOOL_PATH/* $EXPORT_DIR/$GALAXY_CONFIG_TOOL_PATH
fi
rm -rf $GALAXY_CONFIG_TOOL_PATH
ln -v -s $EXPORT_DIR/$GALAXY_CONFIG_TOOL_PATH $GALAXY_CONFIG_TOOL_PATH

if [ ! -d  "$EXPORT_DIR/$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR" ] || [ -z "$(ls -A $EXPORT_DIR/$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR)" ]; then
    # Move tools and tool-deps to export and create symlink
    mkdir $EXPORT_DIR/$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR
    cp -rfv $GALAXY_CONFIG_TOOL_DEPENDENCY_DIR/* $EXPORT_DIR/$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR
fi
rm -rf $GALAXY_CONFIG_TOOL_DEPENDENCY_DIR
ln -v -s $EXPORT_DIR/$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR $GALAXY_CONFIG_TOOL_DEPENDENCY_DIR

# Move Galaxy virtual environment
if [ ! -d  "$EXPORT_DIR/$GALAXY_VIRTUAL_ENV" ] || [ -z "$(ls -A $EXPORT_DIR/$GALAXY_VIRTUAL_ENV)" ]; then
    mkdir $EXPORT_DIR/$GALAXY_VIRTUAL_ENV
    cp -rf $GALAXY_VIRTUAL_ENV/* $EXPORT_DIR/$GALAXY_VIRTUAL_ENV
fi
rm -rf $GALAXY_VIRTUAL_ENV
ln -v -s $EXPORT_DIR/$GALAXY_VIRTUAL_ENV $GALAXY_VIRTUAL_ENV

# Export database-folder (used for job files etc)
rm -rf $GALAXY_DATABASE_PATH
mkdir $EXPORT_DIR/$GALAXY_DATABASE_PATH
ln -v -s $EXPORT_DIR/$GALAXY_DATABASE_PATH $GALAXY_DATABASE_PATH

echo "Finished initialization"

echo "Waiting for RabbitMQ..."
until nc -z -w 2 rabbitmq 5672 && echo RabbitMQ started; do
    sleep 1;
done;

echo "Waiting for Postgres..."
until nc -z -w 2 postgres 5432 && echo Postgres started; do
    sleep 1;
done;

# Install additional dependency: psycopg2
. $GALAXY_ROOT/.venv/bin/activate
pip install psycopg2
deactivate

echo "Starting Galaxy now.."
cd $GALAXY_ROOT
$GALAXY_ROOT/.venv/bin/uwsgi --yaml $GALAXY_CONFIG_DIR/galaxy.yml --pythonpath $GALAXY_ROOT/lib --module 'galaxy.webapps.galaxy.buildapp:uwsgi_app()' --virtualenv /galaxy/.venv 
# --uid $GALAXY_UID --gid $GALAXY_GID 