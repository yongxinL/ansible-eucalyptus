# =============================================================================
#
# - Copyright (C) 2017     George Li <yongxinl@outlook.com>
#
# - This is part of docker library project.
# - the script is use to build the base docker image based on ubuntu linux
#
# - This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# =============================================================================

FROM ubuntu:16.04
MAINTAINER George Li <yongxinl@outlook.com>

# upload scripts to container unit
COPY assets/ /

# execute scripts to build
RUN set -e; \
    chmod +x /build_scripts/*.sh; \
    sync; \
    for sfile in `ls /build_scripts/*.sh | sort -V`; do \
        echo "executing script " $sfile; \
        $sfile; \
    done;

# ports exposed to host
EXPOSE _===EXPOSE_PORTS===_

# mount point from native host or other containers
VOLUME [_===EXPOSE_VOLUME===_]

# define default command
CMD ["/sbin/docker-entrypoint.sh"]