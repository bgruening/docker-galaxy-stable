#!/bin/bash

mkdir ./biojs_install_temp
cd ./biojs_install_temp
npm install biojs2galaxy
./node_modules/biojs2galaxy/biojs2galaxy.js msa -o $GALAXY_ROOT/config/plugins/visualizations/
cd ..
rm -r ./biojs_install_temp
