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

# - service variables
service_owner="elk"
service_group="elk"
service_name="logstash"
service_version="5.5.1"
package_download_url="https://artifacts.elastic.co/downloads/logstash/logstash-${service_version}.tar.gz"

## Functions -----------------------------------------------------------------
print_info "*** Checking for required libraries." 2> /dev/null ||
    source "/etc/functions.dash";

## Main ----------------------------------------------------------------------
print_log "*** Creating reqired user and group ..."
[ $(grep -c "^${service_group}:" /etc/group) -eq 0 ] && addgroup -g "8031" "${service_group}" && success || passed
[ $(grep -c "^${service_owner}:" /etc/passwd) -eq 0 ] && adduser -SH -u "8031" -G "${service_group}" -s /usr/sbin/nologin "${service_owner}" && success || passed

exec_command "*** Installing prerequsites packages and common tools ..." \
	${package_cmd_install} bash;

exec_command "*** Installing ${service_name} package ..." \
	curl -L ${package_download_url} -o /tmp/${service_name}-${service_version}.tar.gz; \
	mkdir -p "/usr/share/${service_name}"; \
	tar -xzf /tmp/${service_name}-${service_version}.tar.gz -C /usr/share/${service_name} --strip-components=1; \
	chown -R ${service_owner}:${service_group} /usr/share/${service_name}

exec_command "*** Configuring ${service_name} ..." \
	mkdir -p "/etc/service/${service_name}"; \
	cp "${script_path}/service/${service_name}/${service_name}.runit" "/etc/service/${service_name}/run"; \
	chmod +x "/etc/service/${service_name}/run"; \
	mkdir -p /etc/elastic/${service_name}/config; \
	mkdir -p /etc/elastic/${service_name}/pipeline;

print_log "*** Copying configure files ...";
find ${script_path}/service/${service_name}/. -maxdepth 1 -type f \( -name "*.yml" -o -name "*.options" -o -name "*.properties" \) -exec cp "{}" "/etc/elastic/${service_name}/config" ";" && success || passed
find ${script_path}/service/${service_name}/. -maxdepth 1 -type f ! -name "[0-9][0-9]*.conf" -name *.conf -exec cp "{}" "/etc/elastic/${service_name}/pipeline" ";" && success || passed
