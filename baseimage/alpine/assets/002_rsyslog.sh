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
service_id="002"
service_name="rsyslog"
service_source_root="${_self_root}/services/${service_name}"

## Functions -----------------------------------------------------------------
info_block "checking for required libraries." 2> /dev/null ||
    source "${_self_root}/scripts_library.sh";

## Main ----------------------------------------------------------------------
log_debug "[${service_name}] install ${service_name} daemon ..."
${package_install_command} rsyslog logrotate

log_debug "[${service_name}] configuring ${service_name} daemon ..."
[ ! -d "${services_init_root}/${service_id}-${service_name}" ] && mkdir -p "${services_init_root}/${service_id}-${service_name}";
cp "${service_source_root}/${service_name}.runit" "${services_init_root}/${service_id}-${service_name}/run";
chmod +x "${services_init_root}/${service_id}-${service_name}/run";

log_debug "[${service_name}] create directory and copy ${service_name} configuration files ..."
[ ! -d "/etc/${service_name}" ] && mkdir -p /etc/${service_name};
[ -f "${service_source_root}/rsyslog.conf" ] && cp "${service_source_root}/rsyslog.conf" /etc/rsyslog.conf;
chmod 0644 /etc/rsyslog.conf;
find ${service_source_root}/*.conf -maxdepth 1 -type f ! \( -name "rsyslog.conf" -o -name "logrotate.conf" \) -exec cp "{}" "/etc/${service_name}" ";"

[ -f "${service_source_root}/logrotate.conf" ] && cp "${service_source_root}/logrotate.conf" /etc/logrotate.conf;
chmod 0644 /etc/logrotate.conf;
find ${service_source_root}/*.logrotate -maxdepth 1 -type f -exec cp "{}" "/etc/${service_name}" ";"