# start master

# We use a temporary directory as an export dir that will hold the shared data b
# galaxy and gridengine:
EXPORT=`mktemp --directory`
chmod 777 ${EXPORT}
docker run --hostname sgemaster --name sgemaster -d -v ${EXPORT}:/export -v $PWD/master_script.sh:/usr/local/bin/master_script.sh  manabuishii/docker-sge-master:0.1.0 /usr/local/bin/master_script.sh
# wait to sge master
sleep 10

# start galaxy
GALAXY_CONTAINER=quay.io/bgruening/galaxy
GALAXY_CONTAINER_NAME=galaxytest
GALAXY_CONTAINER_HOSTNAME=galaxytest

docker run -d \
           -e SGE_ROOT=/var/lib/gridengine \
           --link sgemaster:sgemaster \
           --name ${GALAXY_CONTAINER_NAME} \
           --hostname ${GALAXY_CONTAINER_HOSTNAME} \
           -p 20080:80  -e NONUSE="condor" \
           -v $PWD/job_conf.xml.sge:/etc/galaxy/job_conf.xml \
           -v ${EXPORT}:/export \
           -v $PWD/outputhostname:/galaxy-central/tools/outputhostname \
           -v $PWD/outputhostname.tool.xml:/galaxy-central/outputhostname.tool.xml \
           -v $PWD/setup_tool.sh:/galaxy-central/setup_tool.sh \
           -v $PWD/tool_conf.xml:/galaxy-central/tool_conf.xml \
           -v $PWD/act_qmaster:/var/lib/gridengine/default/common/act_qmaster \
           ${GALAXY_CONTAINER} \
           /galaxy-central/setup_tool.sh
echo "Wait 10sec"
sleep 10

# Add host setting galaxytest to sgemaster
echo "Get host info from ${GALAXY_CONTAINER_HOSTNAME}"
SGECLIENT=$(docker exec ${GALAXY_CONTAINER_NAME} cat /etc/hosts | grep ${GALAXY_CONTAINER_HOSTNAME})
echo "Add host info to sgemaster"
docker exec sgemaster bash -c "echo ${SGECLIENT} >> /etc/hosts ; /etc/init.d/gridengine-master restart"
echo "Output /etc/hosts on sgemaster"
docker exec sgemaster cat /etc/hosts
echo "Wait 5 sec"
sleep 5
# Add gridengine client host
echo "Add submit host ${GALAXY_CONTAINER_HOSTNAME}"
docker exec sgemaster bash -c "qconf -as ${GALAXY_CONTAINER_HOSTNAME}"
echo "Exec test"
docker run --rm  --link galaxytest:galaxytest -v $PWD/test_outputhostname.py:/work/test_outputhostname.py manabuishii/docker-bioblend:0.8.0 python /work/test_outputhostname.py > out
grep sgemaster out
RET=$?
exit $RET
