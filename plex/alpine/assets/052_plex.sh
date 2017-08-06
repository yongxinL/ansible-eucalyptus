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
service_owner="plex"
service_group="plex"
service_name="plex"
package_download_url="https://plex.tv/downloads/latest/1?channel=8&build=linux-ubuntu-x86_64&distro=ubuntu"

## Functions -----------------------------------------------------------------

## Main ----------------------------------------------------------------------
print_log "*** Creating reqired user and group ..."
[ $(grep -c "^${service_group}:" /etc/group) -eq 0 ] && addgroup -g "8052" "${service_group}" && success || passed
[ $(grep -c "^${service_owner}:" /etc/passwd) -eq 0 ] && adduser -SH -u "8052" -G "${service_group}" -s /usr/sbin/nologin "${service_owner}" && success || passed

exec_command "*** Installing required packages and common tools ..." \
    ${package_cmd_install} binutils file openssl patchelf xmlstarlet xz;

# donload and install plex (non plexpass) after displaying downloaded URL in the log.
# this gets the latest non-plexpass version
exec_command "*** Installing Plex package from plex.tv ..." \
    curl -L ${package_download_url} -o /tmp/plex.deb; \
    mkdir -p /tmp/plex; \
    cd /tmp/plex; \
    ar -x /tmp/plex.deb; \
    tar -xzf /tmp/plex/data.tar.* -C /tmp/plex --strip-components=1; \
    rm -f /tmp/plex.deb; \
    mv /tmp/plex/usr/lib/plexmediaserver /usr/share;

print_log "*** Applying Plex patch ..."
find /usr/share/plexmediaserver -type f -perm /0111 -exec sh -c "file --brief \"{}\" | grep -q "ELF" && patchelf --set-interpreter \"/lib/glibc/ld-linux-x86-64.so.2\" \"{}\" " \; | success | passed

exec_command "*** Configuring ${service_name} ..." \
    mkdir -p "/etc/service/${service_name}"; \
    cp "${script_path}/service/${service_name}/${service_name}.runit" "/etc/service/${service_name}/run"; \
    chmod +x "/etc/service/${service_name}/run"; \
    mkdir -p /etc/${service_name};

print_log "*** Copying configure files ...";
find ${script_path}/service/${service_name}/. -maxdepth 1 -type f ! -name *.runit -exec cp "{}" "/etc/${service_name}" ";" && success || passed

exec_command "*** Uninstalling unused packages and common tools ..." \
    ${package_cmd_delete} binutils file patchelf xz;
