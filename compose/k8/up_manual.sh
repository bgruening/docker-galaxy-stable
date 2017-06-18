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

for def in "${DEFS[@]}"
do
	kubectl create -f $def
done
