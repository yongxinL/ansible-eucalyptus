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
package_lists="libc6 libgcc1 libstdc++6"

## Functions -----------------------------------------------------------------

## Main ----------------------------------------------------------------------
exec_command "*** Installing required packages and common tools ..." \
    ${package_cmd_install} binutils file openssl xz;

# extracting packages ...
tar -xvf ${script_path}/glibc.tar.gz -C ${script_path}
for pkg in ${package_lists};
do
    exec_command "*** Extracting ${pkg} packages ..."  \
        mkdir -p /tmp/${pkg}; \
        cd /tmp/${pkg}; \
        ar -x ${script_path}/${pkg}*.deb; \
        tar -xf data.tar.* -C /tmp/${pkg} --strip-components=1; \
done

exec_command "*** Installing and configure glibc packages ..." \
    mkdir -p /lib/glibc; \
    mv /tmp/libc6/lib/x86_64-linux-gnu/* /lib/glibc; \
    mv /tmp/libgcc1/lib/x86_64-linux-gnu/* /lib/glibc; \
    mv /tmp/libstdc++6/usr/lib/x86_64-linux-gnu/* /lib/glibc; \
    echo "/lib/glibc" > /etc/envdir/GLIBC_HOME;

exec_command "*** Uninstalling unused packages and common tools ..." \
    ${package_cmd_delete} binutils file xz;
