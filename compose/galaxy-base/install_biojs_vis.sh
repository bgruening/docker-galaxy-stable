#!/bin/bash

mkdir ./biojs_install_temp
cd ./biojs_install_temp
npm install biojs2galaxy

for vis in "$@"; do
    echo "Installing BioJS Visualization:\t $vis"
    ./node_modules/biojs2galaxy/biojs2galaxy.js $vis -o $GALAXY_ROOT/config/plugins/visualizations/
done

cd ..
rm -r ./biojs_install_temp
