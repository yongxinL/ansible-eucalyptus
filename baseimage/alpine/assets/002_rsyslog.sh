#!/bin/bash
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
# - commonly used variables
script_path="$( if [ "$( echo "${0%/*}" )" != "$( echo "${0}" )" ] ; then cd "$( echo "${0%/*}" )"; fi; pwd )"

## Main ----------------------------------------------------------------------
infobox "*** Checking for required libraries." 2> /dev/null ||
    source "/etc/functions.dash";

service_name=$(split_str_first $(split_str_last ${script_name} "_") ".")

exec_command "*** Installing packages and common tools ..." \
	${package_cmd_install} rsyslog logrotate;

exec_command "*** Configuring ${service_name} ..." \
	mkdir -p "/etc/service/${service_name}"; \
	cp "${script_path}/service/${service_name}/${service_name}.runit" "/etc/service/${service_name}/run"; \
	chmod +x "/etc/service/${service_name}/run";

exec_command "*** Creating required directories and configure files ..." \
	cp "${script_path}/service/${service_name}/rsyslog.conf" "/etc/rsyslog.conf"; \
	mkdir -p /etc/rsyslog.d; \
	mkdir -p /etc/logrotate.d; \
	cp "${script_path}/service/${service_name}/logrotate.conf" "/etc/logrotate.conf";

infobox "*** Copying configure files ..." && success
find ${script_path}/service/${service_name}/*.conf -maxdepth 1 -type f ! \( -name "rsyslog.conf" -o -name "logrotate.conf" \) -exec cp "{}" /etc/rsyslog.d ";"
find ${script_path}/service/${service_name}/*.logrotate -maxdepth 1 -type f ! \( -name "rsyslog.conf" -o -name "logrotate.conf" \) -exec cp "{}" "/etc/logrotate.d" ";"