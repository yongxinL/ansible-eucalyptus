# =============================================================================
#
# - Copyright (C) 2017     George Li <yongxinl@outlook.com>
#
# - This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# =============================================================================

FROM yongxinl/alpine-base:3.5
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
EXPOSE 5601

# mount point from native host or other containers
VOLUME ["/data"]

# define default command
CMD ["/sbin/dumb-init", "/sbin/runsvdir", "-P", "/etc/services.d"]