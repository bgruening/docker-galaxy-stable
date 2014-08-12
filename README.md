Galaxy Docker Image
===================

The [Galaxy](http://www.galaxyproject.org) [Docker](http://www.docker.io) Image is an easy distributable full-fledged Galaxy installation, that can be used for testing, teaching and presenting new tools and features.

One of the main goals is to make the access to entire tool suites as easy as possible. Usually, 
this includes the setup of a public available webservice that needs to be maintained, or that the Tool-user needs to either setup a Galaxy Server by its own or to have Admin access to a local Galaxy server. 
With docker, tool developers can create their own Image with all dependencies and the user only needs to run it within docker.

The Image is based on [Debian/wheezy](http://www.debian.org/). and all recommended Galaxy requirements are installed.


Usage
=====

At first you need to install docker. Please follow the instruction on https://www.docker.io/gettingstarted/#h_installation

After the successful installation, all what you need to do is:

``docker run -d -p 8080:80 bgruening/galaxy-stable``

I will shortly explain the meaning of all the parameters. For a more detailed describtion please consult the [docker manual](http://docs.docker.io/), it's really worth reading.
Let's start: ``docker run`` will run the Image/Container for you. In case you do not have the Container stored locally, docker will download it for you. ``-p 8080:80`` will make the port 80 (inside of the container) available on port 8080 on your host. Inside the container a Apache Webserver is running on port 80 and that port can be bound to a local port on your host computer. With this parameter you can access your Galaxy instance via ``http://localhost:8080`` immediately after executing the command above. ``bgruening/galaxy-stable`` is the Image/Container name, that directs docker to the correct path in the [docker index](https://index.docker.io/u/bgruening/galaxy-stable/). ``-d`` will start the docker container in daemon mode. For an interactive session, you can execute:

``docker run -i -t -p 8080:80 bgruening/galaxy-stable /bin/bash``

and run the ``` startup ``` script by yourself, to start PostgreSQL, Apache and Galaxy.

Docker images are "read-only", all your changes inside one session will be lost after restart. This mode is usefull to present Galaxy to your collegues or to run workshops with it. To install Tool Shed respositories or to save your data you need to export the calculated data to the host computer.

Fortunately, this is as easy as:

``docker run -d -p 8080:80 -v /home/user/galaxy_storage/:/export/ bgruening/galaxy-stable``

With the additional ``-v /home/user/galaxy_storage/:/export/`` parameter, docker will mount the folder ``/home/user/galaxy_storage`` into the Container under ``/export/``. A ``startup.sh`` script, that is usually starting Apache, PostgreSQL and Galaxy, will recognise the export directory with one of the following outcomes:

  - In case of an empty ``/export/`` directory, it will move the [PostgreSQL](http://www.postgresql.org/) database, the Galaxy database directory, Shed Tools and Tool Dependencies and various config scripts to /export/ and symlink back to the original location.
  - In case of a non-empty ``/export/``, for example if you continue a previouse session within the same folder, nothing will be moved, but the symlinks will be created.

This enables you to have different export folders for different sessions - means real separation of your different projects.


Extending the docker Image
==========================

If you have your Tools already included in the Tool Shed, building your own personalised Galaxy docker Image can be done using the following steps:

 1. Create a file the name ``Dockerfile``
 2. Include ``FROM bgruening/galaxy-stable`` at the top of the file. This means that you use the Galaxy Docker Image as base Image and build your own extensions on top of it.
 3. Install your Tools from the Tool Shed via the ``install_tool_shed_repositories.py`` script.
 4. execute ``docker build -t='my-docker-test'``
 5. run your container with ``docker run -d -p 8080:80 my-docker-test``
 6. open your web browser on ``http://localhost:8080``

For example have a look at the [deepTools](http://deeptools.github.io/) or the [ChemicalToolBox](https://github.com/bgruening/galaxytools/tree/master/chemicaltoolbox) Dockerfile's.

https://github.com/bgruening/docker-recipes/blob/master/galaxy-deeptools/Dockerfile
https://github.com/bgruening/docker-recipes/blob/master/galaxy-chemicaltoolbox/Dockerfile

```
# Galaxy - deepTools
#
# VERSION       0.1

FROM bgruening/galaxy-stable

MAINTAINER Björn A. Grüning, bjoern.gruening@gmail.com

WORKDIR /galaxy-central
RUN service postgresql start && service apache2 start && ./run.sh --daemon && sleep 120 && python ./scripts/api/install_tool_shed_repositories.py --api admin -l http://localhost:8080 --url

# Mark one folders as imported from the host.
VOLUME ["/export/"]

# Expose port 80 to the host
EXPOSE :80

# Autostart script that is invoked during container start
CMD ["/usr/bin/startup"]
```


Users & Passwords
================

The Galaxy Admin User has the username ``admin@galaxy.org`` and the password ``admin``.
The PostgreSQL username is ``galaxy``, the password is ``galaxy`` and the database name is ``galaxy`` (I know I was really creative ;)).
If you want to create new users, please make sure to use the ``/export/`` volume. Otherwise your user will be removed after your docker session is finished.


Requirements
============

- [docker](https://www.docker.io/gettingstarted/#h_installation)


ToDo
====

- FTP Server


History
=======

 - 0.1: Initial release!
   - with Apache2, PostgreSQL and Tool Shed integration


Support & Bug Reports
=====================

You can file an issue here https://github.com/bgruening/galaxy_recipes/issues or ask
us on the Galaxy development list http://lists.bx.psu.edu/listinfo/galaxy-dev
