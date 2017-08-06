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

## Function Library ----------------------------------------------------------
print_info "*** Checking for required libraries." 2> /dev/null ||
    source "/etc/functions.bash";

## Vars ----------------------------------------------------------------------
service_name=cron

## Functions -----------------------------------------------------------------

## Main ----------------------------------------------------------------------
exec_command "*** Installing packages and common tools ..." \
	${package_cmd_install} dcron;

exec_command "*** Configuring ${service_name} ..." \
	mkdir -p "/etc/service/${service_name}"; \
	cp "${script_path}/service/${service_name}/${service_name}.runit" "/etc/service/${service_name}/run"; \
	chmod +x "/etc/service/${service_name}/run";

exec_command "*** Creating required directories and configure files ..." \
	mkdir -p /etc/crontabs; \
	mkdir -p /etc/periodic/daily; \
	cp "${script_path}/service/${service_name}/root.cron" "/etc/crontabs/root"; \
	cp "${script_path}/service/${service_name}/logrotate.sh" "/etc/periodic/daily/"; \
	chmod 0600 /etc/crontabs/root;
