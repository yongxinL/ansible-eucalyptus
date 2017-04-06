#!/bin/ash
# =============================================================================
#
# - Copyright (C) 2017     George Li <yongxinl@outlook.com>
#
# - This is part of docker library project.
#   This is script is use to install required packages in target debian/ubuntu
#
# - This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# =============================================================================

set -ex

## Variables -----------------------------------------------------------------
source /build_scripts/build_config;
export LC_ALL=C

# create unit_environment directory
mkdir -p "${unit_envvar_root}";

# install base packages
apk add --no-cache \
        ca-certificates \
        bash \
        runit \
        su-exec

# install container init process
cp "/build_scripts/sbin/docker-entrypoint.sh" "/sbin/docker-entrypoint.sh"
chmod +x "/sbin/docker-entrypoint.sh"
mkdir -p "${unit_run_root}";
touch "${unit_envshell}";
touch "${unit_envjson}";
chmod 700 "${unit_run_root}";

addgroup -g 8377 docker_env;
chown :docker_env "${unit_envshell}" "${unit_envjson}";
chmod 640 "${unit_envshell}" "${unit_envjson}";
ln -s "${unit_envshell}" /etc/profile.d/;
