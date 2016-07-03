docker build -t bioblend_test .
if [ "${COMPOSE}" ]
then
    docker run -it --link galaxy --net galaxycompose_default -v /tmp/:/tmp/ bioblend_test
else
    docker run -it --link galaxy -v /tmp/:/tmp/ bioblend_test
fi
