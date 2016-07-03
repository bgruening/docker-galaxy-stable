docker build -t bioblend_test .
if [ "${COMPOSE}" ]
then
    docker run -it --link galaxy --net galaxy_compose -v /tmp/:/tmp/ bioblend_test
else
    docker run -it --link galaxy -v /tmp/:/tmp/ bioblend_test
fi
