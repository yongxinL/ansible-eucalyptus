# =============================================================================
#
# - Copyright (C) 2017     George Li <yongxinl@outlook.com>
#
# - This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# =============================================================================

FROM yongxinl/base-alpine:latest
MAINTAINER George Li <yongxinl@outlook.com>

# upload scripts to container unit
COPY assets/ /scripts

# execute scripts to build
RUN set -e; \
    chmod +x /scripts/*.sh; \
    sync; \
    for sfile in $(ls /scripts/[0-9]*.sh); do \
        echo "executing script $sfile ..."; \
        $sfile; \
    done;

# ports exposed to host
EXPOSE 32400/tcp 3005/tcp 8324/tcp 32469/tcp 1900/udp 32412/udp 32413/udp 32414/udp

# mount point from native host or other containers
VOLUME ["/data","/media"]

# define default command
CMD ["/sbin/dumb-init", "/sbin/runsvdir", "-P", "/etc/service"]