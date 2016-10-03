#!/bin/bash
cp tool_conf.xml config
cp galaxy.ini /etc/galaxy/galaxy.ini
/usr/bin/startup
tailf /home/galaxy/logs/*

