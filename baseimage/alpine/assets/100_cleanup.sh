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
service_name="cleanup"

## Functions -----------------------------------------------------------------
info_block "checking for required libraries." 2> /dev/null ||
    source "${_self_root}/scripts_library.sh";

## Main ----------------------------------------------------------------------
log_debug "[${service_name}] cleanup unnecessary files ..."
rm -rf /etc/service
rm -rf /usr/share/doc-base/*
rm -rf /usr/share/man/*
rm -rf /usr/share/man-db/*
rm -rf /usr/share/groff/*
rm -rf /usr/share/info/*
rm -rf /usr/share/lintian/*
rm -rf /usr/share/linda/*
rm -rf /var/cache/man/*
rm -rf /var/lib/initramfs-tools
rm -rf /var/share/initramfs-tools
rm -rf /usr/lib/initramfs-tools
rm -rf /etc/initramfs-tools

log_debug "[${service_name}] cleanup unnecessary locale files ..."
[ -d /usr/share/locale ] && find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en' |xargs rm -rf
[ -d /usr/share/i18n/charmaps ] && find /usr/share/i18n/charmaps -mindepth 1 -maxdepth 1 |xargs rm -rf

log_debug "[${service_name}] cleanup unnecessary package cache and compress files ..."
rm -rf /var/lib/{cache,log}
rm -rf /usr/src/*

log_debug "[${service_name}] cleanup all extra Log files and zero out the rest ..."
rm -rf /var/log/*

log_debug "[${service_name}] cleanup building scripts ..."
rm -rf "${_self_root}"