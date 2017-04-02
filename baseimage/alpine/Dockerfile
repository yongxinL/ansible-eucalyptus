# =============================================================================
#
# - Copyright (C) 2017     George Li <yongxinl@outlook.com>
#
# - This is part of docker library project.
# - the script is use to build the base docker image based on alpine linux
#
# - This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# =============================================================================

FROM alpine:3.5
MAINTAINER George Li <yongxinl@outlook.com>

# default to UTF-8 file.encoding
ENV LANG C.UTF-8

# version and Working directory
ENV SUPERVISOR_VERSION=3.3.1

# install required packages
RUN set -ex; \
    apk add --no-cache \
            ca-certificates \
            py2-pip \
            python2 \
            rsyslog \
    ; \
    pip install supervisor; \
    mkdir /etc/runonce /etc/runalways /etc/container_environment /var/log/supervisor; \
    touch /var/log/startup.log; \
    chmod 666 /var/log/startup.log;

# set environment variables
ENV HOME /root

# copy configurate files
COPY assets/ /

# ports exposed to host
EXPOSE _===EXPOSE_PORTS===_

# mount point from native host or other containers

# define default command
CMD ["/init.py"]