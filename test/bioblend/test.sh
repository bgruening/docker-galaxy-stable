docker build -t bioblend_test .
docker run -it --link galaxy_test_container -v /tmp/:/tmp/ bioblend_test
