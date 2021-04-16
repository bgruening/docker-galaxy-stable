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

The default username and password is "admin", "password" (API key "fakekey").
Those credentials are set at first run and can be tweaked using the environment
variables `GALAXY_DEFAULT_ADMIN_USER`, `GALAXY_DEFAULT_ADMIN_EMAIL`,
`GALAXY_DEFAULT_ADMIN_PASSWORD`, and `GALAXY_DEFAULT_ADMIN_KEY` in the
`docker-compose.yml` file. If you want to change the email address of an admin,
remember to update the `admin_users` setting of the Galaxy config (also
see [Configuration](#configuration) to learn how to configure Galaxy).

### Running in background
If you want to run the setup in the background, use the detach option (`-d`):

> docker-compose up -d

### Upgrading to a newer Galaxy version
When not setting `IMAGE_TAG` to a specific version, Docker-Compose will always
fetch the newest image and therefore Galaxy version available. Depending
on the magnitude of the upgrade, you may need to delete the virtual
environment of Galaxy (EXPORT_PATH/galaxy/.venv) before you start the
setup again. The DB migration depends on the `database_auto_migrate`
setting for Galaxy (which is not
set on default and will therefore be `false` normally).


## Extending the setup
Beyond the basic usage, extending the setup is as easy as adding a additional
docker-compose extension file. This is done be the [standard docker-compose syntax](https://docs.docker.com/compose/extends/):
`docker-compose -f docker-compose.yml -f docker-compose.EXTENSION.yml`. Simply
concatenate the extensions you want to use. The rest should be handled for you.

### Running a HTCondor cluster
The `docker-compose.htcondor.yml` file is responsible to build up
an HTCondor cluster. Simply run:

> docker-compose -f docker-compose.yml -f docker-compose.htcondor.yml up

This will bring up a "cluster" with one master and one executor. Galaxy
acts like the submit node. To scale
the cluster, run the up statement with a `--scale htcondor-executor=n` option.
The setup ships with a basic configuration for HTCondor (see the
`base_config.yml` file). To customize the settings, set the appropriate
`HTCONDOR_MASTER_CONFIG_`, `HTCONDOR_EXECUTOR_CONFIG_`, `HTCONDOR_GALAXY_CONFIG`
environment variables (see [Configuration](#configuration)).

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

### Running a Kubernetes Cluster (with kind)
It is possible to start a small Kubernetes (k8s) cluster using [kind](https://kind.sigs.k8s.io)
(Kubernetes in Docker) and let Galaxy run your jobs there. For this use the
`docker-compose.k8s.yml` file. Note that this extension is only meant
to run individually (so no Pulsar, HTCondor etc.).

The `galaxy-kind` container is responsible for starting up your local Kubernetes
cluster and applying all the configuration the Galaxy-Configurator created. You can
find these files under `galaxy-configurator/templates/kind`. The `kind_config.yml`
file is used to configure Kind itself (also see https://kind.sigs.k8s.io/docs/user/configuration/),
while the files in the `k8s_config` are the configs that will be applied to
Kubernetes using `kubectl apply -f <k8s_config>`. By default, k8s is configured
to add some persistent volumes (PV) and persistent volume claims (PVC) so jobs
can access all the needed files from Galaxy.
It is relatively easy to add your own k8s_configs: Simply place your files into the
template folder (remember to add the `.j2` extension!) and mention it in the
`kind_configs` variable in the run.sh file of the galaxy-configurator
(see [Extend the Galaxy-Configurator](#extend-the-galaxy-configurator)).

While Kind is starting up the cluster, it blocks Galaxy from starting itself.
This is needed as Galaxy will parse the KUBECONFIG (that is created after k8s has started)
only once on startup. So don't be surprised if Galaxy is quite for some time :)

Note that the cluster is being rebuilt on every start (to be more precise,
a `kind delete cluster` is called on shut down), so manual changes will
be overwritten if they are not defined in the k8s_config!

### Using Singularity for dependency resolution
Conda is used as the default dependency resolution. To switch to using
Singularity containers, add the `docker-compose.singularity.yml` file.
This will advice Galaxy to - if possible - stick with Singularity
for the dependency resolution. See the
[Galaxy documentation](https://docs.galaxyproject.org/en/master/admin/special_topics/mulled_containers.html)
for more information.

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
setup. Say, you want to stay with Galaxy v20.09 for now:

> export IMAGE_TAG=20.09
> docker-compose up

Without setting this variable, you will always get updated to the newest
version available.

### Restarting
To restart the setup (for example after a configuration change), you can simply
kill (CTRL-C) Docker Compose and re-run `docker-compose ... up`. Your data will
not be lost, as long as you keep the `export`-folder.

### Using prefix
It is possible to host Galaxy under a prefix like example.com/galaxy. For that,
set the env variable in the `galaxy-configurator` part to
`GALAXY_PROXY_PREFIX=/your/wanted/prefix` (like `/galaxy`)
and remember to also update `GALAXY_CONFIG_INFRASTRUCTURE_URL` accordingly.

## More advanced stuff
### "SSH"ing into a container
When facing a bug it may be helpful to have command-line controle over a
container. This is as simple as running `docker exec -it CONTAINER_NAME /bin/bash`.
For the galaxy-server container that would mean:

> docker exec -it compose_galaxy-server_1 /bin/bash

Note that not all containers have bash shipped with them. In this case replace
it by `/bin/sh`.

### Build containers locally
When developing locally, you may come to the point were you need to build
images yourself. In most cases adding a `--build` to the docker-compose statement
should be enough. It's
recommended to build the images using custom tags, so it's easy to switch between
versions. Simply set `IMAGE_TAG` to something other than `latest`:

> export IMAGE_TAG=bugfix1
> docker-compose up --build

Maybe you found a bug in Galaxy itself and you want to test it now. For this,
you can set the `GALAXY_REPO` and `GALAXY_RELEASE` build arguments to your
own fork and branch.

> docker build galaxy-server -t quay.io/bgruening/galaxy-server:$IMAGE_TAG --build-arg GALAXY_REPO=https://github.com/YOUR-USERNAME/galaxy --build-arg GALAXY_RELEASE=my_custom_branch

Some containers use base-images that share some common dependencies (like
Docker that is not only used for Galaxy, but also Pulsar, HTCondor, or Slurm).
After re-building these images yourself, you may also need to add
`--build-arg IMAGE_TAG=your_base_image_tag` and `SETUP_REPO` if your
base-images are tagged differently or are stored in a different repository.

### Extend the Galaxy-Configurator
It is possible to extend the usage of the configurator, both in extending the
Jinj2 templates, but also in adding additional files.

All environment variables of the `galaxy-configurator` are accessible
within the templates. Additionally,
the configurator parses specific `*_CONFIG_*`
variables and makes them accessible as a dict (for example `galaxy` or
`galaxy_uwsgi`). It may be helpful to understand the current use cases
within the templates and how the `customize.py` file (actually just an
extension of the [J2cli](https://github.com/kolypto/j2cli) parses env
variables.

To add more template files, have a look into the `run.sh` file. For example
adding a configuration file for Galaxy is as simple as adding an entry
into the `galaxy_configs` array.

### Adding additional containers or configurations
So you want to extend the setup to - for example - support a new
Workload Manager for Galaxy? Or you have a specific configuration
of Galaxy in mind that goes out of the scope of the basic
`docker-compose.yml` file? Aweseome!
Let's have a look at two examples for how you can create a custom
extension:
**HTCondor**:
The `docker-compose.htcondor.yml` file is a good example of what
the idea of extensions are in the context of this setup.
The HTCondor "cluster" is based on a single image (`galaxy-htcondor`)
and, depending on the containers purpose, it gets exposed to
different volumes. As Galaxy needs some addition files, one volume
is added to its container. The `galaxy-configurator` part
overwrites a single
environment variable and sets a new one. The neat thing of this
approach is that if you don't need
to run HTCondor, the base setup will work just fine without
much additional balast. However, adding HTCondor isn't a hassle
either.

**Singularity**
Changing a bunch of variables all the time, just to be able to switch
between different setups can become a hassle quickly. The
`docker-compose.singularity.yml` file is a good a example of how you
can avoid that. In normal cases, Galaxy should run jobs in the
shell directly, changing that to Singularity requires some
different settings. The file is a good example in how you can
quickly overwrite settings and be able to reuse it for different
occasions (remember that by concatinating this file behind
HTCondor, Slurm, or Pulsar enables Singularity the same way). Another
example would be to create a custom `docker-compose.debug.yml` file
that could be used to enable some debug flags or
setting `GALAXY_CONFIG_CLEANUP_JOB=never`.

### Running the CI pipeline on your own fork
The GitHub Actions workflow used to build, test and deploy this setup
is independent of any specific username or Docker Registry. To run
the workflow on your fork, simply
[set the following secrets](https://help.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets):
* `docker_registry`: The Registry the images should be pushed
to (`docker.io`, for example)
* `docker_registry_username`: Your username
* `docker_registry_password`: Your password


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

## Testing
The setup provides a bunch of different integration tests to run against Galaxy.
Have a look inside the `tests` folder. There you find the containers that run
the tests and their docker-compose files. The containers are essentially just
a wrapper around the test tools to simplify using them. Running a tests
is the same as extending
any other part of the setup: Just concatinate the test file at the end.
To run, for example, some Planemo Worklow tests against a Galaxy installation that
is connected to a HTCondor cluster using Singularity, just enter:
`docker-compose -f docker-compose.yml -f docker-compose.htcondor.yml
-f docker-compose.singularity.yml -f tests/docker-compose.test.yml
-f tests/docker-compose.test.workflows.yml up`. To stop the setup when a test
has finished, you may want to add the option `--exit-code-from galaxy-workflow-test`.
This returns the exit code of the test container (should be 0 if successful),
which you could use for further automation.

The tests are run using GitHub Actions on every commit. So feel free to inspect
the `.github/workflows/compose-v2.yml` file for more test cases and get inspired
by them :)

### Planemo workflow tests
Like the name suggests, this runs [Planemo](https://planemo.readthedocs.io/en/latest/)
workflow tests. The container uses the tests from [UseGalaxy.eu](https://github.com/usegalaxy-eu/workflow-testing),
but you can mount any test you could think of inside the container at the `/src` path.
By default, it will run some select workflows, but you can choose your own
by setting the `WORKFLOWS` env variable to a comma separated list of paths to some tests
(e.g. `WORKFLOWS=test1/test1.ga,test2/test2.ga docker-compose ...`).

### Selenium tests
The Selenium tests simulate a real user that is accessing Galaxy through the
browser to performe some actions. For that it uses a headless Chrome to runs the
tests from the [Galaxy repo](https://github.com/galaxyproject/galaxy/tree/dev/lib/galaxy_test/selenium).
The GitHub Actions currently just run a few of those. To select more tests,
set the env variable `TESTS` to a comma separated list (like `TESTS=navigates_galaxy.py,login.py`).
Note that you don't need to append the `test_` prefix for every
single file!

### BioBlend tests
BioBlend has some tests that run against Galaxy. We are using some of them to test
our setup too. Have a look into the `run.sh` file of the container to see
which tests we have excluded (at least for now).


## Configuration reference
Tool specific configuration can be applied via `base_config.yml` or the following
environment variables:
* `GALAXY_CONFIG_`
* `GALAXY_UWSGI_CONFIG_`
* `NGINX_CONFIG_`
* `PULSAR_CONFIG_`
* `HTCONDOR_MASTER_CONFIG_`
* `HTCONDOR_EXECUTOR_CONFIG_`
* `HTCONDOR_GALAXY_CONFIG`
* `SLURM_CONFIG_`

The following are settings specific to this docker-compose setup:
### Galaxy
| Variable                  | Description                                                                                                        |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| `GALAXY_OVERWRITE_CONFIG` | Enable Galaxy-configurator, which may result in overwriting manual config changes done in `EXPORT_DIR/galaxy/config`.                                                                                                        |
| `GALAXY_PROXY_PREFIX`     | Host Galaxy under a prefix (like example.com/galaxy). Note that you also need to update `GALAXY_CONFIG_INFRASTRUCTURE_URL` accordingly.                                                                                      |
| `GALAXY_JOB_DESTINATION`  | The name of the preferred job destination (local, condor, slurm, singularity..) defined in `job_conf.xml`. Generally, this does not need to be changed, as the docker-compose extensions are already taking care of that. |
| `GALAXY_JOB_RUNNER`       | The job runner Galaxy will use to process jobs. Can be `local`, `condor`, `slurm`, `pular_rest` or `pulsar_mq`, or `k8s`. |
| `GALAXY_DEPENDENCY_RESOLUTION ` | Determines how Galaxy should resolve dependencies. You can choose between Conda (`conda`) or running them inside a Singularity container (`singularity`).|
| `GALAXY_PULSAR_URL`       | The URL Galaxy will communicate with Pulsar, when choosing the `pulsar_rest` job runner. |
| `GALAXY_JOB_METRICS_*`    | Enable the corresponding job metrics. Can be `CORE`, `CPUINFO` (`true` or `verbose`), `MEMINFO`, `UNAME`, and `ENV`, also see [job_metrics.xml.sample](https://github.com/galaxyproject/galaxy/blob/dev/lib/galaxy/config/sample/job_metrics_conf.xml.sample) for reference.

### Nginx
| Variable                  | Description                                                                                                        |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| `NGINX_OVERWRITE_CONFIG`  | Also see `GALAXY_OVERWRITE_CONFIG`. |
| `NGINX_UWSGI_READ_TIMEOUT` | Determines how long Nginx will wait (in seconds) for Galaxy to respond to a request until it times out. Defaults to 180 seconds. |

### Pulsar
| Variable                  | Description                                                                                                        |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| `PULSAR_OVERWRITE_CONFIG` | Also see `GALAXY_OVERWRITE_CONFIG`. |
| `PULSAR_JOB_RUNNER`       | The job runner Pulsar will use to process jobs. Currently, only `local` is supported, but this will be extended to HTCondor and Slurm in the future. |
| `PULSAR_NUM_CONCURRENT_JOBS ` | The number of jobs Pulsar will run concurrently. Defaults to 1. |
| `PULSAR_GALAXY_URL`       | The URL Pulsar will use to send results back to Galaxy. Defaults to `http://nginx:80`. |
| `PULSAR_HOSTNAME`         | The hostname Pulsar will listen to for requests. Defaults to `pulsar`. |
| `PULSAR_PORT`             | The port Pulsar will listen to for requests. Defaults to 8913. |
| `PULSAR_LOG_LEVEL`        | The log level (like `DEBUG` or `INFO`) of Pulsar. Defaults to `INFO`. |

### Kind (Kubernetes in Docker)
| Variable                  | Description                                                                                                        |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| `KIND_OVERWRITE_CONFIG` | Also see `GALAXY_OVERWRITE_CONFIG`. |
| `KIND_NODE_COUNT`       | The number of Kubernetes nodes kind should start. Defaults to 1. |
| `KIND_PV_STORAGE_SIZE`  | The size limit (in Gi) of a Kubernetes Persistent Volume. Defaults to 100.  |
| `GALAXY_KUBECONFIG`     | The path to the KUBECONFIG that Galaxy will use to connect to Kubernetes. Defaults to the one created with galaxy-kind. |
| `GALAXY_K8S_PVC`        | The PVCs a job pod should mount. Defaults to `galaxy-root:/galaxy,galaxy-database:/galaxy/database,galaxy-tool-deps:/tool_deps`. |
| `GALAXY_K8S_DOCKER_REPO_DEFAULT` | The Docker Repo/Registry to use if the resolver could not resolve the proper image for a job. Defaults to `docker.io`. |
| `GALAXY_K8S_DOCKER_OWNER_DEFAULT` | The Owner/Username to use if the resolver could not resolve the proper image for a job. Is not set by default. |
| `GALAXY_K8S_DOCKER_IMAGE_DEFAULT` | The Image to use if the resolver could not resolve the proper image for a job. Defaults to `ubuntu`. |
| `GALAXY_K8S_DOCKER_TAG_DEFAULT` | The Image Tag to use if the resolver could not resolve the proper image for a job. Defaults to `20.04`. |

### HTCondor
| Variable                    | Description                                                                                                        |
|-----------------------------|--------------------------------------------------------------------------------------------------------------------|
| `HTCONDOR_OVERWRITE_CONFIG` | Also see `GALAXY_OVERWRITE_CONFIG`. |

### Slurm
| Variable                  | Description                                                                                                        |
|---------------------------|--------------------------------------------------------------------------------------------------------------------|
| `SLURM_OVERWRITE_CONFIG`  | Also see `GALAXY_OVERWRITE_CONFIG`. |
| `SLURM_NODE_COUNT`        | The number of Slurm nodes running. This needs to be changed when scaling the setup (eg. `docker-compose up --scale slurm_node=n`) to let the Slurm controller know of all available nodes. |
| `SLURM_NODE_CPUS`         | Number of CPUs per node. Defaults to 1. |
| `SLURM_NODE_MEMORY`       | Amount of memory per node. Defaults to 1024. |
| `SLURM_NODE_HOSTNAME`     | Docker Compose adds a prefix in front of the container names by default. Change this value to the name of your setup and `_slurm_node` (e.g. `compose_slurm_node`) to ensure a correct mapping of the Slurm nodes. |

### Github Workflow Tests (Branch 20.09)
| Setup                  | bioblend           | workflow ard       | workflow mapping_by_sequencing | workflow wf3-shed-tools (example1) | selenium           |
|------------------------|--------------------|--------------------|--------------------------------|------------------------------------|--------------------|
| Galaxy Base            | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark:             | :x:                                | :heavy_check_mark: |
| Galaxy Proxy Prefix    | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark:             | :x:                                | :heavy_check_mark: |
| HTCondor               | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark:             | :x:                                | :heavy_check_mark: |
| Slurm                  | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark:             | :x:                                | :heavy_check_mark: |
| Pulsar                 | :heavy_check_mark: | :x:                | :x:                            | :x:                                | :heavy_check_mark: |
| k8s                    | :x:                | :x:                | :x:                            | :x:                                | :x:                |
| Singularity            | :x:                | :x:                | :x:                            | :heavy_check_mark:                 | :x:                |
| Slurm + Singularity    | :x:                | :x:                | :x:                            | :heavy_check_mark:                 | :x:                |
| HTCondor + Singularity | :x:                | :x:                | :x:                            | :heavy_check_mark:                 | :x:                |


Implemented: :heavy_check_mark:   
Not Implemented: :x:

