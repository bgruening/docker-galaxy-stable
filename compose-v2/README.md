# Galaxy Docker Compose
This setup is built on the idea to use a basic docker-compose file and extend it
for additional use cases. Therefore the `docker-compose.yml` is the base of the
whole setup. By concatinating additional files, you can extend it to use, for
example, HTCondor (see [Usage](#usage)).

All working data (database, virtual environment, etc.) is exported in the
`EXPORT_DIR`, which defaults to ./export.


## Usage
### First startup
When starting the setup for the first time, the Galaxy container will copy
a bunch of files into the `EXPORT_DIR`. This might take quite some time
to finish (even 20 minutes or more). Please don't interrupt the setup in
this period, as this might result in a broken state of the `EXPORT_DIR`
(see [Killing while first start up](#killing-while-first-start-up)).

### Basic setup
Simply run

> docker-compose up

to start Galaxy. In the basic setup, Galaxy together with Nginx as the proxy,
Postgres as the DB, and RabbitMQ as the message queue is run.

## Extending the setup
Beyond the basic usage, extending the setup is as easy as adding a additional
docker-compose extension file. This is done be the [standard docker-compose syntax](https://docs.docker.com/compose/extends/):
`docker-compose -f docker-compose.yml -f docker-compose.EXTENSION.yml`. Simply
concatenate the extensions you want to use. The rest should be handled for you.

### Running a HTCondor cluster
> docker-compose -f docker-compose.yml -f docker-compose.htcondor.yml up

TODO: Scaling and configuration

### Running a SLURM cluster
Append the `docker-compose.slurm.yml` file to your `docker-compose up` command. This
will spin up a small Slurm cluster and configure Galaxy to schedule jobs there.
To scale the cluster, run the up statement with a `--scale slurm_node=n` option.
As all nodes need to be defined in the slurm.conf file, you will also need to
set the env variable `SLURM_NODE_COUNT` to the correct node count.
Here is an example for scaling to three nodes:
`SLURM_NODE_COUNT=3 docker-compose -f docker-compose.yml -f docker-compose.slurm.yml up --scale slurm_node=3`.

Some background info about the slurm.conf configuration: As said earlier, Slurm
expects to have all nodes be defined in the conf file, together with valid
hostnames. Therefore `galaxy-configurator` automatically adds references
(the names of the slurm_node-containers) to the nodes by utilizing `SLURM_NODE_COUNT`.
As the docker-compose containers can contain underscores, the names are not
valid as hostnames (even though they are resolvable from inside the containers).
To cope with this problem, the `galaxy-slurm-node-discovery`-container
uses the Docker API to fetch the correct hostnames and replaces them on the
fly inside the slurm.conf file.

### Configuration
The `galaxy-configurator` is the central place for configuration
and is used to configure Galaxy and its
additional services (currently Nginx, and Slurm). For this, it utilizes
environment variables (set in the docker-compose file) for common configs,
and the `base_config.yml` file, used for base-configuration that does not
change often. For environment variables, there are two categories of
configuration: The ones that contain a `_CONFIG_`
(like `GALAXY_CONFIG_ADMIN_USERS`) and the ones that don't (like
`GALAXY_PROXY_PREFIX`). The first category contains configuration
options within the tools itself and they are simply mapped to the
corresponding config-file one-to-one (see for example
[galaxy.yml.sample](https://github.com/galaxyproject/galaxy/blob/dev/lib/galaxy/config/sample/galaxy.yml.sample)
for reference). The other category contains options that have some
logic within the docker-compose setup. `GALAXY_PROXY_PREFIX`, for example,
touches multiple Galaxy and Nginx options, so you don't have to.

The base of the configrations are [Jinja2](https://jinja.palletsprojects.com/en/2.11.x/)
templates, located at `galaxy-configurator/templates`.
The `galaxy-configurator` renders these
templates on startup and saves them in the export-folder to be
used by the other containers. A diff is created to surface changes
that will be applied. To disable the configurator, simply remove the
corresponding `*_OVERWRITE_CONFIG` environment variable
(like `GALAXY_OVERWRITE_CONFIG`) or set it to `false`.

All options are discussed under [configuration reference](#configuration-reference).

### Use specific Galaxy version or Docker images
The `IMAGE_TAG` environment variable allows to use specific versions of the
setup - TODO

### Restarting
To restart the setup (for example after a configuration change), you can simply
kill (CTRL-C) Docker Compose and re-run `docker-compose ... up`. Your data will
not be lost, as long as you keep the `export`-folder.

### Using prefix
It is possible to host Galaxy under a prefix like example.com/galaxy. For that,
set the env variable `GALAXY_PROXY_PREFIX` to your wanted prefix (like `/galaxy`)
and remember to also update `GALAXY_CONFIG_INFRASTRUCTURE_URL` accordingly.

## More advanced stuff
### Extend the Galaxy-Configurator
It is possible to extend the usage of the configurator, both in extending the
Jinj2 templates, but also in adding additional files.

All environment variables are accessible within the templates. Additionally,
the configurator parses specific `*_CONFIG_*`
variables and makes them accessible as a dict (for example `galaxy` or
`galaxy_uwsgi`). It may be helpful to understand the current use cases
within the templates and how the `customize.py` file (actually just an
extension of the [J2cli](https://github.com/kolypto/j2cli) parses env
variables.

To add more template files, have a look into the `run.sh` file. For example
adding a configuration file for Galaxy is as simple as adding an entry
into the `galaxy_configs` array.

## Troubleshooting
### Killing while first start up
If you kill (CTRL-C) Docker Compose while Galaxy is performing the first
startup, you may come into the situation where not all files have been properly
exported. As the exporting is only done for the first start, this can result in
missing dependencies. In this case it is good to remove the whole
`export`-folder (or at least Galaxy related files - the `postgres` folder can
stay, if wanted).

### Resetting the setup
To start from the beginning, you of course need to delete the `export`-folder.
But remember to also do a `docker-compose -f <COMPOSE-FILES..> down`, as this
will shut down and remove all containers. If you forget this, while still
deleting the `export`-folder, the Galaxy container may have problems with
exporting all necessary files, as they are usually deleted within the container
after the first proper startup.

## Configuration reference
Tool specific configuration can be applied via `base_config.yml` or the following
environment variables:
* `GALAXY_CONFIG_`
* `GALAXY_UWSGI_CONFIG`
* `NGINX_CONFIG`
* `SLURM_CONFIG`

The following are settings specific to this docker-compose setup:
### Galaxy
| Variable                  | Description                                                                                                        |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| `GALAXY_OVERWRITE_CONFIG` | Enable Galaxy-configurator, which may result in overwriting manual config changes done in `EXPORT_DIR/galaxy/config`.                                                                                                        |
| `GALAXY_PROXY_PREFIX`     | Host Galaxy under a prefix (like example.com/galaxy). Note that you also need to update `GALAXY_CONFIG_INFRASTRUCTURE_URL` accordingly.                                                                                      |
| `GALAXY_JOB_DESTINATION`  | The name of the preferred job destination (local, condor, slurm, singularity..) defined in `job_conf.xml`. Generally, this does not need to be changed, as the docker-compose extensions are already taking care of that. |
| `GALAXY_JOB_METRICS_*`    | Enable the corresponding job metrics. Can be `CORE`, `CPUINFO` (`true` or `verbose`), `MEMINFO`, `UNAME`, and `ENV`, also see [job_metrics.xml.sample](https://github.com/galaxyproject/galaxy/blob/dev/lib/galaxy/config/sample/job_metrics_conf.xml.sample) for reference.

### Nginx
| Variable                  | Description                                                                                                        |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| `NGINX_OVERWRITE_CONFIG`  | Also see `GALAXY_OVERWRITE_CONFIG` |

### Slurm
| Variable                  | Description                                                                                                        |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| `SLURM_NODE_COUNT`        | The number of Slurm nodes running. This needs to be changed when scaling the setup (eg. `docker-compose up --scale slurm_node=n`) to let the Slurm controller know of all available nodes. |
| `SLURM_NODE_CPUS`         | Number of CPUs per node. Defaults to 1 |
| `SLURM_NODE_MEMORY`       | Amount of memory per node. Defaults to 1024 |
| `SLURM_NODE_HOSTNAME`     | Docker Compose adds a prefix in front of the container names by default. Change this value to the name of your setup and `_slurm_node` (e.g. `compose-v2_slurm_node`) to ensure a correct mapping of the Slurm nodes. |
| `SLURM_OVERWRITE_CONFIG`  | Also see `GALAXY_OVERWRITE_CONFIG` |
