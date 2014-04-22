Galaxy Docker Image
===================

The Galaxy Docker Image project is an easy distributable full-fledged Galaxy installation,
that can be used for testing, teaching and presenting new tools and features.

One of the main goals of that project was to make the access to entire tool suites as easy as possible. Usually, 
that means to setup a public available webservice that needs to be maintained, or that the Tool-user needs to either
setup a Galaxy Server by its own or to have Admin access to one local Galaxy server. 
With docker, tool developers can create their own Image with all dependencies and the user only needs to run it within docker.

The Image is based on Debian/wheezy and all recommended Galaxy requirements are installed.


Usage
=====

If you have installed docker sucessfully, all what you need to do is:

``docker run -d -p 8080:80 bgruening/galaxy-stable``

I will shortly explain the meaning of all the parameters. If you want to have a more detailed describtion please consult the docker manual, it really worth to read it.
Lets start: ``docker run`` will run the Image/Container for you. If you do not have it locally docker will download it for you. ``-p 8080:80`` will make the port 80, inside of the container available on port 8080 on your host. Inside the container a Apache Webserver is running on port 80 and that port can be bound to a local port on your host computer. With that parameter you can access your Galaxy instance via ``http://localhost:8080`` immediatly after executing the command above. ``bgruening/galaxy-stable`` is just the image/container name, that points docker to the correct path in docker index. ``-d`` will start the docker container in daemon mode. If you want to have an interactive session you can execute:

``docker run -i -t -p 8080:80 bgruening/galaxy-stable``

Docker images are "read-only", all you changes you are doing inside one session will be lost after restart. That mode is usefull to present Galaxy to your collegues or to run workhops with it. To install Tool Shed respositories or save your data you will need to export the calculated data to the host computer.

Fortunatly, that is as easy as:

``docker run -d -p 8080:80 -v /home/user/galaxy_storage/:/export/ bgruening/galaxy-stable``

With the additional ``-v /home/user/galaxy_storage/:/export/`` parameter, docker will mount the folder ``/home/user/galaxy_storage`` into the container under ``/export/``. A ``startup.sh`` script, that is usually starting Apache, PostgreSQL and Galaxy, will recognise the export directory and will do one of the following:

  - In case of an empty /export/ directory, it will move the PostgreSQL database, the Galaxy database directory, Shed Tools and Tool Dependencies and various config scripts to /export/ and symlink back to the original location.
  - In case of an non-empty /export/, for example if you continue a previouse session with the same folder, nothing will be moved, but the symlinks will be created.

That enables you to have different export folders for different session - means real separation of your different projects.


Extending the docker Image
==========================

If you have your Tools already included in the Tool Shed, building your own personalised Galaxy docker Image can be done with the following steps:

 1. Create a file called 'Dockerfile'
 2. Include ``FROM bgruening/galaxy-stable`` at the top of the file. That means that you use this Galaxy docker Image as base Image and building your own extensions on top of it.
 3. Install your Tools from the Tool Shed via the ``install_tool_shed_repositories.py`` script.
 4. execute ``docker build -t='my-docker-test'``
 5. run your container with ``docker run -d -p 8080:80 my-docker-test``
 6. open your web browser on ``http://localhost:8080``

See for example the deepTools or the ChemicalToolBox Dockerfile.

```
# Galaxy - deepTools
#
# VERSION       0.1

FROM bgruening/galaxy-stable

MAINTAINER Björn A. Grüning, bjoern.gruening@gmail.com

WORKDIR /galaxy-central
RUN python ./scripts/api/install_tool_shed_repositories.py --api admin -l http://localhost:8080 --url http://toolshed.g2.bx.psu.edu/ -o bgruening -r f7712a057440 --name deeptools --tool-deps --repository-deps --panel-section-name deepTools
```


Users & Passwords
================

The Galaxy Admin User has the username ``admin@galaxy.org`` and the password ``admin``.
The PostgreSQL username is ``galaxy``, the password is ``galaxy`` and the database name is ``galaxy`` (I know I was really creative ;)).
If you want to create new users, please make sure you use the /export/ volume. Otherwise your user will be removed after your docker session is finished.


Requirements
============

- Docker


History
=======

 - 0.1: Initial release!


Bug Reports
===========

You can file an issue here https://github.com/bgruening/galaxy_docker/issues or ask
us on the Galaxy development list http://lists.bx.psu.edu/listinfo/galaxy-dev


Licence (MIT)
=============

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
