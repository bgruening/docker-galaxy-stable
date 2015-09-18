[![DOI](https://zenodo.org/badge/5466/bgruening/docker-galaxy-stable.svg)](https://zenodo.org/badge/latestdoi/5466/bgruening/docker-galaxy-stable)

Galaxy Docker Image
===================

The [Galaxy](http://www.galaxyproject.org) [Docker](http://www.docker.io) Image is an easy distributable full-fledged Galaxy installation, that can be used for testing, teaching and presenting new tools and features.

One of the main goals is to make the access to entire tool suites as easy as possible. Usually,
this includes the setup of a public available webservice that needs to be maintained, or that the Tool-user needs to either setup a Galaxy Server by its own or to have Admin access to a local Galaxy server.
With docker, tool developers can create their own Image with all dependencies and the user only needs to run it within docker.

The Image is based on [Ubuntu 14.04 LTS](http://releases.ubuntu.com/14.04/) and all recommended Galaxy requirements are installed. The following chart should illustrate the [Docker](http://www.docker.io) image hierarchy we have build to make is as easy as possible to build on different layers of our stack and create many exciting Galaxy flavours.

![Docker hierarchy](chart.png)


Usage
=====

At first you need to install docker. Please follow the [very good instructions](https://docs.docker.com/installation/) from the Docker project.

After the successful installation, all what you need to do is:

  ```sh
  docker run -d -p 8080:80 -p 8021:21 bgruening/galaxy-stable
  ```

I will shortly explain the meaning of all the parameters. For a more detailed description please consult the [docker manual](http://docs.docker.io/), it's really worth reading.
Let's start: ``docker run`` will run the Image/Container for you. In case you do not have the Container stored locally, docker will download it for you. ``-p 8080:80`` will make the port 80 (inside of the container) available on port 8080 on your host. Same holds for port 8021, that can be used to transfer data via the FTP protocol. Inside the container a Apache Webserver is running on port 80 and that port can be bound to a local port on your host computer. With this parameter you can access your Galaxy instance via ``http://localhost:8080`` immediately after executing the command above. ``bgruening/galaxy-stable`` is the Image/Container name, that directs docker to the correct path in the [docker index](https://index.docker.io/u/bgruening/galaxy-stable/). ``-d`` will start the docker container in daemon mode. For an interactive session, you can execute:

  ```sh
  docker run -i -t -p 8080:80 bgruening/galaxy-stable /bin/bash
  ```

and run the ``` startup ``` script by yourself, to start PostgreSQL, Apache and Galaxy.

Docker images are "read-only", all your changes inside one session will be lost after restart. This mode is usefull to present Galaxy to your collegues or to run workshops with it. To install Tool Shed respositories or to save your data you need to export the calculated data to the host computer.

Fortunately, this is as easy as:

  ```sh
  docker run -d -p 8080:80 -v /home/user/galaxy_storage/:/export/ bgruening/galaxy-stable
  ```

With the additional ``-v /home/user/galaxy_storage/:/export/`` parameter, docker will mount the local folder ``/home/user/galaxy_storage`` into the Container under ``/export/``. A ``startup.sh`` script, that is usually starting Apache, PostgreSQL and Galaxy, will recognize the export directory with one of the following outcomes:

  - In case of an empty ``/export/`` directory, it will move the [PostgreSQL](http://www.postgresql.org/) database, the Galaxy database directory, Shed Tools and Tool Dependencies and various config scripts to /export/ and symlink back to the original location.
  - In case of a non-empty ``/export/``, for example if you continue a previous session within the same folder, nothing will be moved, but the symlinks will be created.

This enables you to have different export folders for different sessions - means real separation of your different projects.


Upgrading images
----------------

We will release a new version of this image concurrent with every new Galaxy release. For upgrading an image to a new version we have assembled a few hints for you:

 * Create a test instance with only the database and configuration files. This will allow testing to ensure that things run but won't require copying all of the data.
 * New unmodified configuration files are always stored in a hidden directory called `.distribution_config`. Use this folder to diff your configurations with the new configuration files shipped with Galaxy. This prevents needing to go through the change log files to find out which new files were added or which new features you can activate.
 * Start your container in interactive mode with an attached terminal and upgrade your database.
   1.  `docker run -i -t bgruening/galaxy-stable /bin/bash`
   2. `service postgresql start`
   3. `sh manage_db.sh upgrade`

Enabling Interactive Environments in Galaxy
-------------------------------------------

Interactive Environments (IE) are sophisticated ways to extend Galaxy with powerful services, like IPython, in a secure and reproducible way.
For this we need to be able to launch Docker containers inside our Galaxy Docker container. At least docker 1.3 is needed on the host system.

  ```bash
  docker run -d -p 8080:80 -p 8021:21 -p 8800:8800 --privileged=true \
    -v /home/user/galaxy_storage/:/export/ bgruening/galaxy-stable
  ```

The port 8800 is the proxy port that is used to handle Interactive Environments. ``--privileged`` is needed to start docker containers inside docker.

Using passive mode FTP
----------------------

By default, FTP servers running inside of docker containers are not accessible via passive mode FTP, due to not being able to expose extra ports. To circumvent this, you can use the `--net=host` option to allow Docker to directly open ports on the host server:

  ```bash
  docker run -d --net=host -v /home/user/galaxy_storage/:/export/ bgruening/galaxy-stable
  ```

Note that there is no need to specifically bind individual ports (e.g., `-p 80:80`).

Using Parent docker
-------------------
On some linux distributions, Docker-In-Docker can run into issues (such as running out of loopback interfaces). If this is an issue, you can use a 'legacy' mode that use a docker socket for the parent docker installation mounted inside the container. To engage, set the environmental variable `DOCKER_PARENT`

  ```bash
  docker run -p 8080:80 -p 8021:21 -p 8800:8800 \
    --privileged=true -e DOCKER_PARENT=True \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /home/user/galaxy_storage/:/export/ \
    bgruening/galaxy-stable
  ```

Galaxy Report Webapp
--------------------

For admins wishing to have more information on the status of a galaxy instance, the Galaxy Report Webapp is served on `http://localhost:8080/reports`. As default this site is password protected with `admin:admin`. You can change this by providing a `reports_htpasswd` file in `/home/user/galaxy_storage/`.

You can disable the Report Webapp entirely by providing the environment variable `NONUSE` during container startup.

  ```bash
  docker run -p 8080:80 -e "NONUSE=reports" bgruening/galaxy-stable
  ```

Galaxy's config settings
------------------------

Every Galaxy configuration setting can be overwritten by a given environment variable during startup. For example by default the `admin_users`, `master_api_key` and the `brand` variable it set to:

  ```sh
  GALAXY_CONFIG_ADMIN_USERS=admin@galaxy.org
  GALAXY_CONFIG_MASTER_API_KEY=HSNiugRFvgT574F43jZ7N9F3
  GALAXY_CONFIG_BRAND="Galaxy Docker Build"
  ```

You can and should overwrite these during launching your container:

  ```bash
  docker run -p 8080:80 \
    -e "GALAXY_CONFIG_ADMIN_USERS=albert@einstein.gov" \
    -e "GALAXY_CONFIG_MASTER_API_KEY=83D4jaba7330aDKHkakjGa937" \
    -e "GALAXY_CONFIG_BRAND='My own Galaxy flavour'" \
    bgruening/galaxy-stable
  ```

Note that if you would like to run any of the [cleanup scripts](https://wiki.galaxyproject.org/Admin/Config/Performance/Purge%20Histories%20and%20Datasets), you will need to add the following to `/export/galaxy-central/config/galaxy.ini`:

    database_connection = postgresql://galaxy:galaxy@localhost:5432/galaxy
    file_path = /export/galaxy-central/database/files

Personalize your Galaxy
-----------------------

The Galaxy welcome screen can be changed by providing a `welcome.hml` page in `/home/user/galaxy_storage/`. All files starting with `welcome` will be copied during starup and served as indroduction page. If you want to include images or other media, name them `welcome_*` and link them relative to your `welcome.html` ([example](`https://github.com/bgruening/docker-galaxy-stable/blob/master/galaxy/welcome.html`)).


Deactivating services
---------------------

Non-essential services can be deactivated during startup. Set the environment variable `NONUSE` to a comma separated list of services. Currently, `nodejs`, `proftp`, `reports`, `slurmd` and `slurmctld` are supported.

  ```bash
  docker run -d -p 8080:80 -p 8021:21 -p 9002:9002 \
    -e "NONUSE=nodejs,proftp,reports,slurmd,slurmctld" bgruening/galaxy-stable
  ```

A graphical user interface, to start and stop your services, is available on port `9002` if you run your container like above.


Restarting Galaxy
-----------------

If you want to restart Galaxy without restarting the entire Galaxy container you can use `docker exec` (docker > 1.3).

  ```sh
  docker exec <container name> supervisorctl restart galaxy:
  ```

In addition you start/stop every supersisord process using a webinterface on port `9002`. Start your container with:

  ```sh
  docker run -p 9002:9002 bgruening/galaxy-stable
  ```

Advanced Logging
----------------

You can set the environment variable $GALAXY_LOGGING to FULL to access all logs from supervisor. For example start your container with:

  ```sh
  docker run -d -p 8080:80 -p 8021:21 -e "GALAXY_LOGGING=full" bgruening/galaxy-stable
  ```

Then, you can access the supersisord webinterface on port `9002` and get access to log files. To do so, start your container with:

  ```sh
  docker run -d -p 8080:80 -p 8021:21 -p 9002:9002 -e "GALAXY_LOGGING=full" bgruening/galaxy-stable
  ```

Alternatively, you can access the container directly using the following command:

  ```sh
  docker exec -it <container name> bash
  ```

Once connected to the container, log files are available in `/home/galaxy`.

Using an external Slurm cluster
-------------------------------

It is often convenient to configure Galaxy to use a high-performance cluster for running jobs. To do so, two files are required:

 1. munge.key
 2. slurm.conf

These files from the cluster must be copied to the `/export` mount point (i.e., `/data/galaxy` on the host if using below command) accessible to Galaxy before starting the container. This must be done regardless of which Slurm daemons are running within Docker. At start, symbolic links will be created to these files to `/etc` within the container, allowing the various Slurm functions to communicate properly with your cluster. In such cases, there's no reason to run `slurmctld`, the Slurm controller daemon, from within Docker, so specify `-e "NONUSE=slurmctld"`. Unless you would like to also use Slurm (rather than the local job runner) to run jobs within the Docker container, then alternatively specify `-e "NONUSE=slurmctld,slurmd"`.

Importantly, Slurm relies on a shared filesystem between the Docker container and the execution nodes. To allow things to function correctly, each of the execution nodes will need `/export` and `/galaxy-central` directories to point to the appropriate places. Suppose you ran the following command to start the Docker image:

    ```sh
    docker run -d -e "NONUSE=slurmd,slurmctld" -p 80:80 -v /data/galaxy:/export bgruening/galaxy-stable
    ```

You would then need the following symbolic links on each of the nodes:

 1. `/export`  → `/data/galaxy`
 2. `/galaxy-central`  → `/data/galaxy/galaxy-central`

A brief note is in order regarding the version of Slurm installed. This Docker image uses Ubuntu 14.04 as its base image. The version of Slurm in the Unbuntu 14.04 repository is 2.6.5 and that is what is installed in this image. If your cluster is using an incompatible version of Slurm then you will likely need to modify this Docker image.

The following is an example for how to specify a destination in `job_conf.xml` that uses a custom partition ("work", rather than "debug") and 4 cores rather than 1:

    <destination id="slurm4threads" runner="slurm">
        <param id="embed_metadata_in_job">False</param>
        <param id="nativeSpecification">-p work -n 4</param>
    </destination>

The usage of `-n` can be confusing. Note that it will specify the number of cores, not the number of tasks (i.e., it's not equivalent to `srun -n 4`).

Magic Environment variables
===========================

| Name   | Description   |
|---|---|
| ENABLE_TTS_INSTALL  | Enables the Test Tool Shed during container startup. This change is not persistent. (`ENABLE_TTS_INSTALL=True`)  |
| GALAXY_LOGGING | Enables for verbose logging at Docker stdout. (`GALAXY_LOGGING=full`)  |
| NONUSE |  Disable services during container startup. (`NONUSE=nodejs,proftp,reports,slurmd,slurmctld`) |

Extending the Docker Image
==========================

If your tools are already included in the Tool Shed, building your own personalised Galaxy docker Image (Galaxy flavour) can be done using the following steps:

 1. Create a file the name ``Dockerfile``
 2. Include ``FROM bgruening/galaxy-stable`` at the top of the file. This means that you use the Galaxy Docker Image as base Image and build your own extensions on top of it.
 3. Install your Tools from the Tool Shed via the ``install_tool_shed_repositories.py`` script.
 4. execute ``docker build -t='my-docker-test'``
 5. run your container with ``docker run -p 8080:80 my-docker-test``
 6. open your web browser on ``http://localhost:8080``

For example have a look at the [deepTools](http://deeptools.github.io/) or the [ChemicalToolBox](https://github.com/bgruening/galaxytools/tree/master/chemicaltoolbox) Dockerfile's.
 * https://github.com/bgruening/docker-recipes/blob/master/galaxy-deeptools/Dockerfile
 * https://github.com/bgruening/docker-recipes/blob/master/galaxy-chemicaltoolbox/Dockerfile

```
# Galaxy - deepTools
#
# VERSION       0.2

FROM bgruening/galaxy-stable

MAINTAINER Björn A. Grüning, bjoern.gruening@gmail.com

ENV GALAXY_CONFIG_BRAND deepTools

WORKDIR /galaxy-central

RUN add-tool-shed --url 'http://testtoolshed.g2.bx.psu.edu/' --name 'Test Tool Shed'

# Install Visualisation
RUN install-biojs msa

# Install deepTools
RUN install-repository \
    "--url https://toolshed.g2.bx.psu.edu/ -o bgruening --name deeptools"

# Mark folders as imported from the host.
VOLUME ["/export/", "/data/", "/var/lib/docker"]

# Expose port 80 (webserver), 21 (FTP server), 8800 (Proxy)
EXPOSE :80
EXPOSE :21
EXPOSE :8800

# Autostart script that is invoked during container start
CMD ["/usr/bin/startup"]
```

List of Galaxy flavours
-----------------------

 * [docker-galaxy-blast](https://github.com/bgruening/docker-galaxy-blast)
 * [ChemicalToolBox](https://github.com/bgruening/docker-recipes/blob/master/galaxy-chemicaltoolbox)
 * [ballaxy](https://github.com/anhi/docker-scripts/tree/master/ballaxy)
 * [docker-galaxy-deeptools](https://github.com/bgruening/docker-recipes/blob/master/galaxy-deeptools)
 * [docker-galaxyp](https://github.com/bgruening/docker-galaxyp)


Users & Passwords
-----------------

The Galaxy Admin User has the username ``admin@galaxy.org`` and the password ``admin``.
The PostgreSQL username is ``galaxy``, the password is ``galaxy`` and the database name is ``galaxy`` (I know I was really creative ;)).
If you want to create new users, please make sure to use the ``/export/`` volume. Otherwise your user will be removed after your docker session is finished.

The proftpd server is configured to use the main galaxy PostgreSQL user to access the database and select the username and password. If you want to run the
docker container in production, please do not forget to change the user credentials in /etc/proftp/proftpd.conf too.

The Galaxy Report Webapp is `htpasswd` protected with username and password st to `admin`.


Development
-----------

This repository uses a git submodule to include [Ansible roles](https://github.com/galaxyproject/ansible-galaxy-extras) maintained by the Galaxy project.

You can clone this repository and the Ansible submodule with:

  ```sh
  git clone --recursive https://github.com/bgruening/docker-galaxy-stable.git
  ```

Updating already existing submodules is possible with:

  ```sh
  git submodule update --remote
  ```

Requirements
------------

- [docker](https://www.docker.io/gettingstarted/#h_installation)


History
-------

 - 0.1: Initial release!
   - with Apache2, PostgreSQL and Tool Shed integration
 - 0.2: complete new Galaxy stack.
   - with nginx, uwsgi, proftpd, docker, supervisord and SLURM
 - 0.3: Add Interactive Environments
   - IPython in docker in Galaxy in docker
   - advanged logging
 - 0.4:
   - base the image on toolshed/requirements with all required Galaxy dependencies
   - use Ansible roles to build large parts of the image
   - export the supervisord webinterface on port 9002
   - enable Galaxy reports webapp
 - 15.07:
  - `install-biojs` can install BioJS visualisations into Galaxy
  - `add-tool-shed` can be used to activate third party Tool Sheds in child Dockerfiles
  - many documentation improvements
  - RStudio is now part of Galaxy and this Image
  - configurable postgres UID/GID by @chambm
  - smarter starting of postgres during Tool installations by @shiltemann


Support & Bug Reports
---------------------

You can file an [github issue](https://github.com/bgruening/docker-galaxy-stable/issues) or ask
us on the [Galaxy development list](http://lists.bx.psu.edu/listinfo/galaxy-dev).
