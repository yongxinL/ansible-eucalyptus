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
service_id="052"
service_owner="plex"
service_group="plex"
service_name="plex"
service_version="latest"
service_source_root="${_self_root}/services/${service_name}"
service_home_root="/usr/share/plexmediaserver"
package_download_url="https://plex.tv/downloads/latest/1?channel=8&build=linux-ubuntu-x86_64&distro=ubuntu"

## Functions -----------------------------------------------------------------
info_block "checking for required libraries." 2> /dev/null ||
    source "/etc/scripts_library.sh";

## Main ----------------------------------------------------------------------
log_debug "[${service_name}] creating ${service_name} service user and group ..."
[ $(grep -c "^${service_group}:" /etc/group) -eq 0 ] && addgroup -g "8${service_id}" "${service_group}";
[ $(grep -c "^${service_owner}:" /etc/passwd) -eq 0 ] && adduser -SH -u "8${service_id}" -G "${service_group}" -s /usr/sbin/nologin "${service_owner}";

log_debug "[${service_name}] installing prerequsites packages ..."
${package_install_command} \
        binutils \
        curl \
        file \
        openssl \
        patchelf \
        xmlstarlet \
        xz

# donload and install plex (non plexpass) after displaying downloaded URL in the log.
# this gets the latest non-plexpass version
log_debug "[${service_name}] downloading ${service_name} package from plex.tv ..."
curl -L ${package_download_url} -o /tmp/${service_name}-${service_version}.deb;

log_debug "[${service_name}] decompress ${service_name}-${service_version} ..."
mkdir -p /tmp/${service_name};
cd /tmp/${service_name}
ar -x /tmp/${service_name}-${service_version}.deb
tar -xzf /tmp/${service_name}/data.tar.* -C /tmp/${service_name} --strip-components=1
rm -f ../${service_name}-${service_version}.deb;

log_debug "[${service_name}] install packages to ${service_home_root} ... "
mv /tmp/${service_name}/usr/lib/plexmediaserver ${service_home_root};
find ${service_home_root} -type f -perm /0111 -exec sh -c "file --brief \"{}\" | grep -q "ELF" && patchelf --set-interpreter \"${GLIBC_HOME}/ld-linux-x86-64.so.2\" \"{}\" " \; ;

log_debug "[${service_name}] configuring ${service_name} daemon ..."
[ ! -d "${services_init_root}/${service_id}-${service_name}" ] && mkdir -p "${services_init_root}/${service_id}-${service_name}";
cp "${service_source_root}/${service_name}.runit" "${services_init_root}/${service_id}-${service_name}/run";
chmod +x "${services_init_root}/${service_id}-${service_name}/run";

log_debug "[${service_name}] create directory and copy ${service_name} configuration files ..."
[ ! -d "/etc/${service_name}" ] && mkdir -p "/etc/${service_name}";
find ${service_source_root}/. -maxdepth 1 -type f ! -name *.runit -exec cp "{}" "/etc/${service_name}" ";"

log_debug "[${service_name}] remove unused packages and files after installing ..."
${package_install_command} \
        binutils \
        file \
        patchelf \
        xz

rm -rf /tmp/${service_name};