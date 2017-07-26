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
service_id="051"
service_owner=
service_group=
service_name="glibc"
service_version=
service_source_root="${_self_root}/services/${service_name}"
service_home_root="/lib/${service_name}"
package_download_list="libc6 libgcc1 libstdc++6"
package_download_url="http://ftp.debian.org/debian/pool/main/g"

## Functions -----------------------------------------------------------------
info_block "checking for required libraries." 2> /dev/null ||
    source "/etc/scripts_library.sh";

## Main ----------------------------------------------------------------------
log_debug "[${service_name}] installing prerequsites packages ..."
${package_install_command} \
        binutils \
        curl \
        file \
        openssl \
        xz

log_debug "[${service_name}] downloading ${service_name} package from debian repository ..."
curl -L "${package_download_url}/glibc/libc6_2.24-11_amd64.deb" -o /tmp/libc6_amd64.deb;
curl -L "${package_download_url}/gcc-4.9/libgcc1_4.9.2-10_amd64.deb" -o /tmp/libgcc1.deb;
curl -L "${package_download_url}/gcc-4.9/libstdc++6_4.9.2-10_amd64.deb" -o /tmp/libstdc++6.deb;

for pkg in ${package_download_list}; do
    log_debug "[${service_name}] decompress ${pkg} ..."
    mkdir -p /tmp/${pkg};
    cd /tmp/${pkg}
    ar -x ../${pkg}*.deb;
    tar -xf data.tar.* -C /tmp/${pkg} --strip-components=1;
    rm -f ../$pkg*.deb;
done

log_debug "[${service_name}] install packages to ${service_home_root} ... "
[ ! -d "${service_home_root}" ] && mkdir -p "${service_home_root}";
mv /tmp/libc6/lib/x86_64-linux-gnu/* "${service_home_root}";
mv /tmp/libgcc1/lib/x86_64-linux-gnu/* "${service_home_root}";
mv /tmp/libstdc++6/usr/lib/x86_64-linux-gnu/* "${service_home_root}";

log_debug "[${service_name}] update scripts_library with variable ..."
sed -i "/^# ServicesVariables.*/a export GLIBC_HOME=${service_home_root}" /etc/scripts_library.sh

log_debug "[${service_name}] remove unused packages and files after installing ..."
${package_install_command} \
        binutils \
        file \
        xz

for pkg in ${package_download_list}; do
    rm -rf /tmp/${pkg};
done
