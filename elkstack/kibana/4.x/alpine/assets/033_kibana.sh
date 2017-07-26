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
service_id="033"
service_owner="elk"
service_group="elk"
service_name="kibana"
service_version="4.6.4"
service_source_root="${_self_root}/services/${service_name}"
service_home_root="/usr/share/${service_name}"
# for Kibana 4.x
package_download_url="https://download.elastic.co/kibana/${service_name}/${service_name}-${service_version}-linux-x86_64.tar.gz"

## Functions -----------------------------------------------------------------
info_block "checking for required libraries." 2> /dev/null ||
    source "/etc/scripts_library.sh";

## Main ----------------------------------------------------------------------
log_debug "[${service_name}] creating ${service_name} service user and group ..."
[ $(grep -c "^${service_group}:" /etc/group) -eq 0 ] && addgroup -g "8${service_id}" "${service_group}";
[ $(grep -c "^${service_owner}:" /etc/passwd) -eq 0 ] && adduser -SH -u "8${service_id}" -G "${service_group}" -s /usr/sbin/nologin "${service_owner}";

log_debug "[${service_name}] installing prerequsites packages ..."
${package_install_command} nodejs

log_debug "[${service_name}] downloading ${service_name} package from elastic.io ..."
curl -L ${package_download_url} -o /tmp/${service_name}-${service_version}.tar.gz;

log_debug "[${service_name}] decompress ${service_name} ..."
[ ! -d "${service_home_root}" ] && mkdir -p "${service_home_root}";
tar -xzf /tmp/${service_name}-${service_version}.tar.gz -C "${service_home_root}" --strip-components=1;
rm -rf /tmp/${service_name}-${service_version}.tar.gz;

log_debug "[${service_name}] configuring ${service_name} daemon ..."
[ ! -d "${services_init_root}/${service_id}-${service_name}" ] && mkdir -p "${services_init_root}/${service_id}-${service_name}";
cp "${service_source_root}/${service_name}.runit" "${services_init_root}/${service_id}-${service_name}/run";
chmod +x "${services_init_root}/${service_id}-${service_name}/run";

log_debug "[${service_name}] replace bundled nodejs ..."
if [ ! -z $(which node) ]; then
    if [ -f "/usr/share/${service_name}/bin/${service_name}" ]; then
        cp "/usr/share/${service_name}/bin/${service_name}" "/usr/share/${service_name}/bin/${service_name}.bak"
        chmod -x "/usr/share/${service_name}/bin/${service_name}.bak"
        sed -i "s#^NODE=.*#NODE=$(which node)#g" "/usr/share/${service_name}/bin/${service_name}"
    fi
    [ -d "/usr/share/${service_name}/node"  ] && rm -rf /usr/share/${service_name}/node
fi

log_debug "[${service_name}] create directory and copy ${service_name} configuration files ..."
[ ! -d "/etc/elastic/${service_name}" ] && mkdir -p "/etc/elastic/${service_name}";
find ${service_source_root}/. -maxdepth 1 -type f ! -name *.runit -exec cp "{}" "/etc/elastic/${service_name}" ";"

log_debug "[${service_name}] install ${service_name} plugins ..."
# Marval - collect data from each node in your cluster
${service_home_root}/bin/${service_name} plugin --install elasticsearch/marvel/2.4.5

log_debug "[${service_name}] update ${service_name} permission ..."
chown -R ${service_owner}:${service_group} "${service_home_root}";
