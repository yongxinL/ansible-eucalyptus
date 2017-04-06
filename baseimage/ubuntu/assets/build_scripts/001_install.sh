#!/usr/bin/env bash
# =============================================================================
#
# - Copyright (C) 2017     George Li <yongxinl@outlook.com>
#
# - This is part of docker library project.
#   This is script is use to install required packages in target debian/ubuntu
#
# - This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# =============================================================================

set -e

## Variables -----------------------------------------------------------------
source /build_scripts/build_config;
export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

# create unit_environment directory
mkdir -p "${unit_envvar_root}";

# temporarily disable dpkg fsync for faster building
if [[ ! -e /etc/dpkg/dpkg.cfg.d/docker-apt-speedup ]]; then
    echo force-unsafe-io > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup
fi

# prevent initramfs updates from trying to run grub and lio
export INITRD=no
echo -n no > "${unit_envvar_root}/INITRD"

# enable Ubuntu universe and multivese
sed -i 's/^#\s*\(deb.*universe\)$/\1/g' /etc/apt/sources.list
sed -i 's/^#\s*\(deb.*multiverse\)$/\1/g' /etc/apt/sources.list
apt-get update

# fix some issues with APT packates.
# See https://github.com/dotcloud/docker/issues/1024
dpkg-divert --local --rename --add /sbin/initctl
ln -sf /bin/true /sbin/initctl

# replace the 'ischroot' tool to make it always return true.
# prevent initscripts updates from breaking /dev/shm.
# https://bugs.launchpad.net/launchpad/+bug/974584
dpkg-divert --local --rename --add /usr/bin/ischroot
ln -sf /bin/true /usr/bin/ischroot

# install HTTPS support for APT
apt-get install -y --no-install-recommends apt-transport-https apt-utils ca-certificates

# upgrade all packates
apt-get dist-upgrade -y --no-install-recommends

# install add-apt-repository
# comment below as no python is required for docker-entrypoint.sh
# apt-get install -y --no-install-recommends software-properties-common

# fix locale
apt-get install -y --no-install-recommends language-pack-en
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8 
echo -n en_US.UTF-8 > "${unit_envvar_root}/LANG"
echo -n en_US.UTF-8 > "${unit_envvar_root}/LC_CTYPE"
echo -n en_US:en > "${unit_envvar_root}/LANGUAGE"
echo -n en_US.UTF-8 > "${unit_envvar_root}/LC_ALL"

# distrib code
echo `. /etc/lsb-release; echo ${DISTRIB_CODENAME/*, /}` >> "${unit_envvar_root}/DISTRIB_CODENAME";

# install container init process
cp "/build_scripts/sbin/docker-entrypoint.sh" "/sbin/docker-entrypoint.sh"
chmod +x "/sbin/docker-entrypoint.sh"
mkdir -p "${unit_run_root}";
touch "${unit_envshell}";
touch "${unit_envjson}";
chmod 700 "${unit_run_root}";

groupadd -g 8377 docker_env;
chown :docker_env "${unit_envshell}" "${unit_envjson}";
chmod 640 "${unit_envshell}" "${unit_envjson}";
ln -s "${unit_envshell}" /etc/profile.d/;

# install runit supervisor
apt-get install -y --no-install-recommends runit;

# install the common tools
apt-get install -y --no-install-recommends curl nano psmisc;
