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

With the additional ``-v /home/user/galaxy_storage/:/export/`` parameter, docker will mount the folder ``/home/user/galaxy_storage`` into the Container under ``/export/``. A ``startup.sh`` script, that is usually starting Apache, PostgreSQL and Galaxy, will recognize the export directory with one of the following outcomes:

  - In case of an empty ``/export/`` directory, it will move the [PostgreSQL](http://www.postgresql.org/) database, the Galaxy database directory, Shed Tools and Tool Dependencies and various config scripts to /export/ and symlink back to the original location.
  - In case of a non-empty ``/export/``, for example if you continue a previous session within the same folder, nothing will be moved, but the symlinks will be created.

This enables you to have different export folders for different sessions - means real separation of your different projects.

Enabling Interactive Environments in Galaxy
-------------------------------------------

Interactive Environments (IE) are sophisticated ways to extend Galaxy with powerful services, like IPython, in a secure and reproducible way.
For this we need to be able to launch Docker containers inside our Galaxy Docker container. At least docker 1.3 is needed on the host system.

  ```bash
  docker run -d -p 8080:80 -p 8021:21 -p 8800:8800 --privileged=true \
    -v /home/user/galaxy_storage/:/export/ bgruening/galaxy-stable
  ```

The port 8800 is the proxy port that is used to handle Interactive Environments. ``--privileged`` is needed to start docker containers inside docker.

Using Parent docker
-------------------
On some linux distributions, Docker-In-Docker can run into issues (such as running out of loopback interfaces). If this is an issue,
you can use a 'legacy' mode that use a docker socket for the parent docker installation mounted inside the container. To engage, set the 
environmental variable DOCKER_PARENT
  
  ```bash
  docker run -d -p 8080:80 -p 8021:21 -p 8800:8800 --privileged=true -e DOCKER_PARENT=True \
    -v /var/run/docker.sock:/var/run/docker.sock -v /home/user/galaxy_storage/:/export/ \
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

Personalize your Galaxy
-----------------------

The Galaxy welcome screen can be changed by providing a `welcome.hml` page in `/home/user/galaxy_storage/`. All files starting with `welcome` will be copied during starup and served as indroduction page. If you want to include images or other media, name them `welcome_*` and link them relative to your `welcome.html` ([example](`https://github.com/bgruening/docker-galaxy-stable/blob/master/galaxy/welcome.html`)).


Deactivating services
---------------------

Non-essential services can be deactivated during startup. Set the environment variable `NONUSE` to a comma separated list of services. Currently, `nodejs`, `proftp` and `reports` are supported.

  ```bash
  docker run -d -p 8080:80 -p 8021:21 -p 9002:9002 \
    -e "NONUSE=nodejs,proftp,reports" bgruening/galaxy-stable
  ```

Restarting Galaxy
-----------------

If you want to restart Galaxy without restarting the entire Galaxy container we can use `docker exec` (docker > 1.3).

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

In addition you can access the supersisord webinterface on port 9002 and get access to log files. Start your container with:

  ```sh
  docker run -d -p 8080:80 -p 8021:21 -p 9002:9002 -e "GALAXY_LOGGING=full" bgruening/galaxy-stable
  ```

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


Support & Bug Reports
---------------------

You can file an [github issue](https://github.com/bgruening/docker-galaxy-stable/issues) or ask
us on the [Galaxy development list](http://lists.bx.psu.edu/listinfo/galaxy-dev).
