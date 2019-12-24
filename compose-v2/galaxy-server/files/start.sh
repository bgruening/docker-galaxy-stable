# First start?? Check if something exists that indicates that environment is not new.. Config file? Something in DB maybe??

echo "Initialization: Check if files already exist, export otherwise."
if [ ! -d  "$EXPORT_DIR/$GALAXY_ROOT" ]; then
    # Create initial $GALAXY_ROOT in $EXPORT_DIR
    mkdir $EXPORT_DIR/$GALAXY_ROOT
fi

if [ ! -d  "$EXPORT_DIR/$GALAXY_CONFIG_DIR" ] || [ -z "$(ls -A $EXPORT_DIR/$GALAXY_CONFIG_DIR | grep -L plugins)" ]; then
    # Move config to $EXPORT_DIR and create symlink 
    mv -v $GALAXY_CONFIG_DIR/* $EXPORT_DIR/$GALAXY_CONFIG_DIR
    mv -v $GALAXY_CONFIG_DIR/plugins/* $EXPORT_DIR/$GALAXY_CONFIG_DIR/plugins
    rm -rf $GALAXY_CONFIG_DIR
    ln -v -s $EXPORT_DIR/$GALAXY_CONFIG_DIR $GALAXY_CONFIG_DIR
fi

if [ ! -d  "$EXPORT_DIR/$GALAXY_STATIC_DIR" ] || [ -z "$(ls -A $EXPORT_DIR/$GALAXY_STATIC_DIR)" ]; then
    # Move static to $EXPORT_DIR and create symlink
    mv -v $GALAXY_STATIC_DIR/* $EXPORT_DIR/$GALAXY_STATIC_DIR
    rm -rf $GALAXY_STATIC_DIR
    ln -v -s $EXPORT_DIR/$GALAXY_STATIC_DIR $GALAXY_STATIC_DIR
fi

# if [ ! -d  "$EXPORT_DIR/$GALAXY_CONFIG_TOOL_PATH" ]; then
#     # Move environment to export and create symlink
#     mv -v $GALAXY_CONFIG_TOOL_PATH $EXPORT_DIR/$GALAXY_CONFIG_TOOL_PATH
#     ln -v -s $EXPORT_DIR/$GALAXY_CONFIG_TOOL_PATH $GALAXY_CONFIG_TOOL_PATH
# fi

if [ ! -d  "$EXPORT_DIR/$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR" ]; then
    # Move tools and tool-deps to export and create symlink
    mv -v $GALAXY_CONFIG_TOOL_DEPENDENCY_DIR $EXPORT_DIR/$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR
    ln -v -s $EXPORT_DIR/$GALAXY_CONFIG_TOOL_DEPENDENCY_DIR $GALAXY_CONFIG_TOOL_DEPENDENCY_DIR
 fi   
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