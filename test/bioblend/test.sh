#!/bin/bash
docker build -t bioblend_test .
docker run -it --link galaxy -v /tmp/:/tmp/ bioblend_test
