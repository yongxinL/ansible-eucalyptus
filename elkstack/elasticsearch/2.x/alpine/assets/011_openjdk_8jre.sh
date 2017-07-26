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
service_id="011"
service_name="openjdk"
service_version="8.121.13-r0"
service_source_root="${_self_root}/services/${service_name}"

## Functions -----------------------------------------------------------------
info_block "checking for required libraries." 2> /dev/null ||
    source "/etc/scripts_library.sh";

## Main ----------------------------------------------------------------------
log_debug "[${service_name}] install ${service_name} daemon ..."
${package_install_command} \
		openjdk8-jre="${service_version}"

log_debug "[${service_name}] configuring ${service_name} daemon ..."
java_home=$(readlink -f "$(which javac || which java)")
sed -i "/^# ServicesVariables.*/a export JAVA_HOME=${java_home}" /etc/scripts_library.sh
