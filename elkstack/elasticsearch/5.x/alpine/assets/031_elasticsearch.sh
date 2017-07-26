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
service_id="031"
service_owner="elk"
service_group="elk"
service_name="elasticsearch"
service_version="5.5.1"
service_source_root="${_self_root}/services/${service_name}"
service_home_root="/usr/share/${service_name}"
# for Elasticsearch 5.x
package_download_url="https://artifacts.elastic.co/downloads/${service_name}/${service_name}-${service_version}.tar.gz"

## Functions -----------------------------------------------------------------
info_block "checking for required libraries." 2> /dev/null ||
    source "/etc/scripts_library.sh";

## Main ----------------------------------------------------------------------
log_debug "[${service_name}] creating ${service_name} service user and group ..."
[ $(grep -c "^${service_group}:" /etc/group) -eq 0 ] && addgroup -g "8${service_id}" "${service_group}";
[ $(grep -c "^${service_owner}:" /etc/passwd) -eq 0 ] && adduser -SH -u "8${service_id}" -G "${service_group}" -s /usr/sbin/nologin "${service_owner}";

log_debug "[${service_name}] installing prerequsites packages ..."
${package_install_command} \
        bash \
        gnupg \
        openssl \
        tar

log_debug "[${service_name}] downloading ${service_name} package from elastic.io ..."
curl -L ${package_download_url} -o /tmp/${service_name}-${service_version}.tar.gz;

log_debug "[${service_name}] decompress ${service_name} ..."
[ ! -d "${service_home_root}" ] && mkdir -p "${service_home_root}";
tar -xzf /tmp/${service_name}-${service_version}.tar.gz -C "${service_home_root}" --strip-components=1;
rm -rf /tmp/${service_name}-${service_version}.tar.gz;
chown -R ${service_owner}:${service_group} "${service_home_root}";

log_debug "[${service_name}] configuring ${service_name} daemon ..."
[ ! -d "${services_init_root}/${service_id}-${service_name}" ] && mkdir -p "${services_init_root}/${service_id}-${service_name}";
cp "${service_source_root}/${service_name}.runit" "${services_init_root}/${service_id}-${service_name}/run";
chmod +x "${services_init_root}/${service_id}-${service_name}/run";

log_debug "[${service_name}] create directory and copy ${service_name} configuration files ..."
[ ! -d "/etc/elastic/${service_name}/scripts" ] && mkdir -p "/etc/elastic/${service_name}/scripts";
find ${service_source_root}/. -maxdepth 1 -type f ! -name *.runit -exec cp "{}" "/etc/elastic/${service_name}" ";"
chown root:${service_group} /etc/elastic/${service_name}/scripts;

log_debug "[${service_name}] install ${service_name} plugins ..."
# ICU analysis - integrated the Lucene ICU module, adding extended Unicode support.
${service_home_root}/bin/${service_name}-plugin install --batch analysis-icu
# Smart Chinese Analysis -an analyzer for Chinese or mixed Chinese-English text
${service_home_root}/bin/${service_name}-plugin install --batch analysis-smartcn
# Ingest attachments - index file attachments in common formats using apache text extraction library Tika
${service_home_root}/bin/${service_name}-plugin install --batch ingest-attachment
# Ingest-user-agent - extracts details from the user agent string
${service_home_root}/bin/${service_name}-plugin install --batch ingest-user-agent
# Ingest-geoip - adds information about the geographical location of IP address
${service_home_root}/bin/${service_name}-plugin install --batch ingest-geoip
[ -d "${service_home_root}/config/ingest-geoip" ] \
    && cp -r "${service_home_root}/config/ingest-geoip" "/etc/elastic/${service_name}" \
    && rm -rf "${service_home_root}/config/ingest-geoip"

#log_debug "[${service_name}] install ${service_name} plugins & x-pack..."
#${service_home_root}/bin/${service_name}-plugin install --batch x-pack
# remove unused machine learning native code
#[ -d "${service_home_root}/plugins/x-pack/platform" ] \
#    && rm -rf "${service_home_root}/plugins/x-pack/platform"