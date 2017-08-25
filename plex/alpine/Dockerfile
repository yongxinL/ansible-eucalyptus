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
EXPOSE _===EXPOSE_PORTS===_

# mount point from native host or other containers
VOLUME [_===EXPOSE_VOLUME===_]

# define default command
CMD ["/sbin/dumb-init", "/sbin/runsvdir", "-P", "/etc/service"]