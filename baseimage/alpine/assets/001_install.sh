#!/bin/sh
# please use sh as bash does not exist in base alpine image
# =============================================================================
#
# - Copyright (C) 2017     George Li <yongxinl@outlook.com>
#
# - This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# =============================================================================

## Shell Opts ----------------------------------------------------------------
set -e

## Vars ----------------------------------------------------------------------
_self_root="$( if [ "$( echo "${0%/*}" )" != "$( echo "${0}" )" ] ; then cd "$( echo "${0%/*}" )"; fi; pwd )";

# enable debug
debug_mode=${DEBUG:-on};

# service related configuration
service_id="001"
service_name="basesystem"

## Functions -----------------------------------------------------------------
info_block "checking for required libraries." 2> /dev/null ||
    source "${_self_root}/scripts_library.sh";

## Main ----------------------------------------------------------------------
log_info "configurating docker image ... "

log_debug "[${service_name}] create services directory and related files ... "
[ ! -d "${services_init_root}" ] && mkdir -p "${services_init_root}" && chmod 755 "${services_init_root}";
[ -f "${_self_root}/scripts_library.sh" ] && cp "${_self_root}/scripts_library.sh" "/etc/scripts_library.sh"

log_debug "[${service_name}] install base package and common tools ..."
${package_install_command} \
		bash \
        ca-certificates \
        curl

log_debug "[${service_name}] install dumb-init, a minimal init system designed to run as PID 1 ... "
${package_install_command} dumb-init

log_debug "[${service_name}] link dumb-init to /sbin/dumb-init ..."
if [ $(which dumb-init) != "/sbin/dumb-init" ]; then
    ln -s $(which dumb-init) /sbin/dumb-init
fi

log_debug "[${service_name}] install runit process management package ..."
${package_install_command} runit

log_debug "[${service_name}] replace runsvdir with hack version"
if [ -f "/sbin/runsvdir" ]; then
    mv /sbin/runsvdir /sbin/runsvdir.orig;
fi
cp "${_self_root}/sbin/runsvdir.apk" "/sbin/runsvdir";
chmod +x "/sbin/runsvdir";
