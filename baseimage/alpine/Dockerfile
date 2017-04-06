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

# upload scripts to container unit
COPY assets/ /

# execute scripts to build
RUN set -ex; \
    chmod +x /build_scripts/*.sh; \
    sync; \
    for sfile in `ls /build_scripts/*.sh | sort -V`; do \
        echo "executing script " $sfile; \
        $sfile; \
    done;

# set environment variables
ENV HOME /root

# copy configurate files
COPY assets/ /

# ports exposed to host
EXPOSE _===EXPOSE_PORTS===_

# mount point from native host or other containers
VOLUME [_===EXPOSE_VOLUME===_]

# define default command
CMD ["/init.py"]