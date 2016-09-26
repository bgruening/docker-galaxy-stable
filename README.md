[![DOI](https://zenodo.org/badge/5466/bgruening/docker-galaxy-stable.svg)](https://zenodo.org/badge/latestdoi/5466/bgruening/docker-galaxy-stable)
[![Build Status](https://travis-ci.org/bgruening/docker-galaxy-stable.svg?branch=master)](https://travis-ci.org/bgruening/docker-galaxy-stable)
[![Docker Repository on Quay](https://quay.io/repository/bgruening/galaxy/status "Docker Repository on Quay")](https://quay.io/repository/bgruening/galaxy)
[![Gitter](https://badges.gitter.im/bgruening/docker-galaxy-stable.svg)](https://gitter.im/bgruening/docker-galaxy-stable?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
![docker pulls](https://img.shields.io/docker/pulls/bgruening/galaxy-stable.svg) ![docker stars](https://img.shields.io/docker/stars/bgruening/galaxy-stable.svg)

Galaxy Docker Image
===================

The [Galaxy](http://www.galaxyproject.org) [Docker](http://www.docker.io) Image is an easy distributable full-fledged Galaxy installation, that can be used for testing, teaching and presenting new tools and features.

One of the main goals is to make the access to entire tool suites as easy as possible. Usually,
this includes the setup of a public available webservice that needs to be maintained, or that the Tool-user needs to either setup a Galaxy Server by its own or to have Admin access to a local Galaxy server.
With docker, tool developers can create their own Image with all dependencies and the user only needs to run it within docker.

The Image is based on [Ubuntu 14.04 LTS](http://releases.ubuntu.com/14.04/) and all recommended Galaxy requirements are installed. The following chart should illustrate the [Docker](http://www.docker.io) image hierarchy we have build to make is as easy as possible to build on different layers of our stack and create many exciting Galaxy flavours.


![Docker hierarchy](chart.png)

