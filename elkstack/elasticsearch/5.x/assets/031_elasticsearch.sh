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
service_name="elasticsearch"
service_version="5.5.1"
package_download_url="https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${service_version}.tar.gz"

## Main ----------------------------------------------------------------------
infobox "*** Checking for required libraries." 2> /dev/null ||
    source "/etc/functions.dash";

infobox "*** Creating reqired user and group ..."
[ $(grep -c "^${service_group}:" /etc/group) -eq 0 ] && addgroup -g "8031" "${service_group}" && success || failure
[ $(grep -c "^${service_owner}:" /etc/passwd) -eq 0 ] && adduser -SH -u "8031" -G "${service_group}" -s /usr/sbin/nologin "${service_owner}" && success || failure

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

infobox "*** Copying configure files ..."; \
find ${script_path}/service/${service_name}/. -maxdepth 1 -type f ! -name *.runit -exec cp "{}" "/etc/elastic/${service_name}" ";" && success || failure

# ICU analysis - integrated the Lucene ICU module, adding extended Unicode support.
exec_command "*** Installing ${service_name} ICU analysis plugins ..." \
	/usr/share/${service_name}/bin/${service_name}-plugin install --batch analysis-icu;
# Smart Chinese Analysis -an analyzer for Chinese or mixed Chinese-English text
exec_command "*** Installing ${service_name} Smart Chinese Analysis plugins ..." \
	/usr/share/${service_name}/bin/${service_name}-plugin install --batch analysis-smartcn;
# Ingest attachments - index file attachments in common formats using apache text extraction library Tika
exec_command "*** Installing ${service_name} Ingest attachments plugins ..." \
	/usr/share/${service_name}/bin/${service_name}-plugin install --batch ingest-attachment;
# Ingest-user-agent - extracts details from the user agent string
exec_command "*** Installing ${service_name} Ingest-user-agent plugins ..." \
	/usr/share/${service_name}/bin/${service_name}-plugin install --batch ingest-user-agent;
# Ingest-geoip - adds information about the geographical location of IP address
exec_command "*** Installing ${service_name} Ingest-geoip plugins ..." \
	/usr/share/${service_name}/bin/${service_name}-plugin install --batch ingest-geoip; \
	cp -r /usr/share/${service_name}/config/ingest-geoip /etc/elastic/${service_name}; \
	rm -rf /usrshare/${service_name}/config/ingest-geoip

# Elasticsearch x-pack and remove machine learning native code
#exec_command "*** Installing ${service_name} x-pack plugins ..." \
#	/usr/share/${service_name}/bin/${service_name}-plugin install --batch x-pack; \
#	rm -rf /usr/share/${service_name}/plugins/x-pack/platform;