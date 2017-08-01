#!/bin/sh
# please use sh as bash does not exist in the base alpine image
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

## Main ----------------------------------------------------------------------
infobox "*** Checking for required libraries." 2> /dev/null ||
    source "${script_path}/functions.dash";

# upgrade Linux repository and distribution
update_repository

# installing base packages and common tools
exec_command "*** Installing base packages and common tools ..." \
	${package_cmd_install} bash curl git gcc make musl-dev unzip zip;

# installing dumb-init
exec_command "*** Installing dumb-init ..." \
	unzip -o ${script_path}/dumb-init.zip -d /tmp; \
	cd /tmp/dumb-init; \
	make; \
	cp /tmp/dumb-init/dumb-init /sbin/

# installing runit
exec_command "*** Installing runit ..." \
	unzip -o ${script_path}/runit.zip -d /tmp; \
	cd /tmp/runit; \
	make; \
	cp chpst runit runit-init runsv runsvchdir runsvdir sv svlogd utmpset /sbin; \
	mkdir -p "/etc/startup"; \
	mkdir -p "/etc/service"; \
	mkdir -p "/etc/envdir";

# installing bash-lib.sh
exec_command "*** Installing bash-lib ..." \
	cp ${script_path}/functions.dash /etc/functions.dash; \

# uninstall unused base packages and common tools
exec_command "*** Uninstalling base packages and common tools ..." \
	${package_cmd_delete} git gcc make musl-dev unzip zip;