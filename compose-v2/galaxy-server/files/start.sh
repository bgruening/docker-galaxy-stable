# First start?? Check if something exists that indicates that environment is not new.. Config file? Something in DB maybe??

echo "Initialization: Check if files already exist, export otherwise."
if [ ! -d  "$EXPORT_DIR/$GALAXY_ROOT" ]; then
    # Create initial $GALAXY_ROOT in $EXPORT_DIR
    mkdir $EXPORT_DIR/$GALAXY_ROOT
fi

if [ ! -d  "$EXPORT_DIR/$GALAXY_CONFIG_DIR" ]; then
    # Move config to $EXPORT_DIR and create symlink 
    mv -v $GALAXY_CONFIG_DIR $EXPORT_DIR/$GALAXY_CONFIG_DIR
    ls /
    ln -v -s $EXPORT_DIR/$GALAXY_CONFIG_DIR $GALAXY_CONFIG_DIR
fi

if [ ! -d  "$EXPORT_DIR/$GALAXY_STATIC_DIR" ] || [ -z "$(ls -A $EXPORT_DIR/$GALAXY_STATIC_DIR)" ]; then
    # Move static to $EXPORT_DIR and create symlink
    mv -v $GALAXY_STATIC_DIR/* $EXPORT_DIR/$GALAXY_STATIC_DIR
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

# Not first start:
    # Start Galaxy

echo "Starting Galaxy now.."
$GALAXY_ROOT/run.sh