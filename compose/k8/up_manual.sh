declare -a DEFS=(
    "export-persistentvolumeclaim.yaml"
    "postgres-persistentvolumeclaim.yaml"
    "rabbitmq-persistentvolumeclaim.yaml"
    "galaxy-htcondor-executor-big-service.yaml"
    "galaxy-htcondor-executor-service.yaml"
    "galaxy-htcondor-service.yaml"
    "galaxy-init-service.yaml"
    "galaxy-postgres-service.yaml"
    "galaxy-proftpd-service.yaml"
    "galaxy-service.yaml"
    "galaxy-slurm-service.yaml"
    "pgadmin4-service.yaml"
    "rabbitmq-service.yaml"
    "galaxy-deployment.yaml"
    "galaxy-htcondor-deployment.yaml"
    "galaxy-htcondor-executor-big-deployment.yaml"
    "galaxy-htcondor-executor-deployment.yaml"
    "galaxy-init-deployment.yaml"
    "galaxy-postgres-deployment.yaml"
    "galaxy-proftpd-deployment.yaml"
    "galaxy-slurm-deployment.yaml"
    "pgadmin4-deployment.yaml"
    "rabbitmq-deployment.yaml"
)

# manually created PV defintions (this is needed on hosts without dynamic storage provisioning )
# "PersistentVolumeClaim: export of size 100Mi. If your cluster has dynamic storage provisioning, you don't have to do anything. Otherwise you have to create PersistentVolume to make PVC work "

kubectl create -f export-pv.yaml -f rabbitmq-pv.yaml -f postgresql-pv.yaml

for def in "${DEFS[@]}"
do
	kubectl create -f $def
done
