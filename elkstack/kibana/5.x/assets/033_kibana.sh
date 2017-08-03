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
service_name="kibana"
service_version="5.5.1"
package_download_url="https://artifacts.elastic.co/downloads/kibana/kibana-${service_version}-linux-x86_64.tar.gz"

## Functions -----------------------------------------------------------------
print_info "*** Checking for required libraries." 2> /dev/null ||
    source "/etc/functions.dash";

## Main ----------------------------------------------------------------------
print_log "*** Creating reqired user and group ..."
[ $(grep -c "^${service_group}:" /etc/group) -eq 0 ] && addgroup -g "8031" "${service_group}" && success || failure
[ $(grep -c "^${service_owner}:" /etc/passwd) -eq 0 ] && adduser -SH -u "8031" -G "${service_group}" -s /usr/sbin/nologin "${service_owner}" && success || failure

exec_command "*** Installing prerequsites packages and common tools ..." \
	${package_cmd_install} nodejs;

exec_command "*** Installing ${service_name} package ..." \
	curl -L ${package_download_url} -o /tmp/${service_name}-${service_version}.tar.gz; \
	mkdir -p "/usr/share/${service_name}"; \
	tar -xzf /tmp/${service_name}-${service_version}.tar.gz -C /usr/share/${service_name} --strip-components=1; \
	chown -R ${service_owner}:${service_group} /usr/share/${service_name}

exec_command "*** replace bundled nodejs in ${service_name} package ..." \
	cp /usr/share/${service_name}/bin/${service_name} /usr/share/${service_name}/bin/${service_name}.bak; \
	sed -i "s#^NODE=.*#NODE=$(which node)#g" /usr/share/${service_name}/bin/${service_name}; \
	rm -rf /usr/share/${service_name}/node;

exec_command "*** Configuring ${service_name} ..." \
	mkdir -p "/etc/service/${service_name}"; \
	cp "${script_path}/service/${service_name}/${service_name}.runit" "/etc/service/${service_name}/run"; \
	chmod +x "/etc/service/${service_name}/run"; \
	mkdir -p /etc/elastic/${service_name};

print_log "*** Copying configure files ...";
find ${script_path}/service/${service_name}/. -maxdepth 1 -type f ! -name *.runit -exec cp "{}" "/etc/elastic/${service_name}" ";" && success || failure

# Elastic X-Pack - collect data from each node in your cluster
#exec_command "*** Installing ${service_name} X-Pack plugins ..." \
#	/usr/share/${service_name}/bin/${service_name}-plugin install --quiet x-pack &> /dev/null;
