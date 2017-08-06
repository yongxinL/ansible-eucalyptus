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
service_owner="elk"
service_group="elk"
service_name="elasticsearch"
service_version="2.4.5"
package_download_url="https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/${service_version}/elasticsearch-${service_version}.tar.gz"

## Functions -----------------------------------------------------------------

## Main ----------------------------------------------------------------------
print_log "*** Creating reqired user and group ..."
[ $(grep -c "^${service_group}:" /etc/group) -eq 0 ] && addgroup -g "8031" "${service_group}" && success || passed
[ $(grep -c "^${service_owner}:" /etc/passwd) -eq 0 ] && adduser -SH -u "8031" -G "${service_group}" -s /usr/sbin/nologin "${service_owner}" && success || passed

exec_command "*** Installing prerequsites packages and common tools ..." \
	${package_cmd_install} gnupg openssl tar;

exec_command "*** Installing ${service_name} package ..." \
	curl -L ${package_download_url} -o /tmp/${service_name}-${service_version}.tar.gz; \
	mkdir -p "/usr/share/${service_name}"; \
	tar -xzf /tmp/${service_name}-${service_version}.tar.gz -C /usr/share/${service_name} --strip-components=1; \
	chown -R ${service_owner}:${service_group} /usr/share/${service_name}

exec_command "*** Configuring ${service_name} ..." \
	mkdir -p "/etc/service/${service_name}"; \
	cp "${script_path}/service/${service_name}/${service_name}.runit" "/etc/service/${service_name}/run"; \
	chmod +x "/etc/service/${service_name}/run"; \
	mkdir -p /etc/elastic/${service_name}/scripts;

print_log "*** Copying configure files ...";
find ${script_path}/service/${service_name}/. -maxdepth 1 -type f ! -name *.runit -exec cp "{}" "/etc/elastic/${service_name}" ";" && success || passed

# ICU analysis - integrated the Lucene ICU module, adding extended Unicode support.
exec_command "*** Installing ${service_name} ICU analysis plugins ..." \
	/usr/share/${service_name}/bin/plugin install --batch analysis-icu >> ${log_file};
# Smart Chinese Analysis -an analyzer for Chinese or mixed Chinese-English text
exec_command "*** Installing ${service_name} Smart Chinese Analysis plugins ..." \
	/usr/share/${service_name}/bin/plugin install --batch analysis-smartcn >> ${log_file};
# Mapper attachments - index file attachments in common formats using apache text extraction library Tika
exec_command "*** Installing ${service_name} Mapper attachments plugins ..." \
	/usr/share/${service_name}/bin/plugin install --batch mapper-attachments >> ${log_file};
# Marval - collect data from each node in your cluster
exec_command "*** Installing ${service_name} Marval plugins ..." \
	/usr/share/${service_name}/bin/plugin install --batch license >> ${log_file}; \
	/usr/share/${service_name}/bin/plugin install --batch marvel-agent >> ${log_file};
