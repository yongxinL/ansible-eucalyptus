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
java_version="8.141.15-r0"

## Functions -----------------------------------------------------------------

## Main ----------------------------------------------------------------------
exec_command "*** Installing packages and common tools ..." \
	${package_cmd_install} openjdk8-jre;

#java_home=$(readlink -f "$(which javac || which java)")
exec_command "*** configuring java home ..." \
	echo "/usr/lib/jvm/java-1.8-openjdk/jre/bin/java" > /etc/envdir/JAVA_HOME;
