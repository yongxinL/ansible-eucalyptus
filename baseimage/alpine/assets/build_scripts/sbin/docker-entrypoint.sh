#!/bin/bash
# =============================================================================
#
# - Copyright (C) 2017     George Li <yongxinl@outlook.com>
#
# - This is part of docker library project.
# - the script is use to build the docker image
#
# - This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# =============================================================================

set -e

trap 'shutdown_runit_services' INT TERM

## Variables -----------------------------------------------------------------
unit_run_root="/etc/docker_run.d";
unit_envvar_root="/etc/docker_environments";
unit_envjson="/etc/docker_environment.json";
unit_envshell="/etc/docker_environment.sh";
unit_services_root="/etc/docker_services";

## Functions -----------------------------------------------------------------
#
# import environment variables
#
function import_envvars () {
    clear_existing_env=${1:-true};
    override_existing_env=${2:-ture};

    if [ -d "${unit_envvar_root}" ] && [ ! -n "$(find ${unit_envvar_root} -prune -type d)" ]; then
        for v_file in "${unit_envvar_root}"/*; do
            v_filename=$(basename ${v_file});
            if [ ${override_existing_env} = true ] || !(env | grep -q ${v_filename} ); then
                export eval ${v_filename}=`cat ${v_file}`;
            fi
        done
    fi
}
#
# export environment variables to json and script
#
function export_envvars() {
    export_to_dir=${1:-true};
    skip_record="HOME USER GROUP UID GID SHELL SHLVL PWD";

    # create directory if not exist
    if [ ! -d "${unit_envvar_root}" ]; then
        mkdir -p "${unit_envvar_root}";
    fi

    # create .json and .sh file if not exists
    echo -n "{" > "${unit_envjson}";
    echo -n "" > "${unit_envshell}";

    # take environment variables and save it to file. individual file by variable.
    # and separate environment by lines
    env | while read -r line
    do
        # separate lines in name and values
        str_a=`expr index "$line" \=`;
        str_b=$((str_a-1));
        v_filename=${line:0:$str_b};
        v_fileval=${line:$str_a};
        if [[ ${skip_record} == *"${v_filename}"* ]]; then
            continue
        else
            # write to file
            if [ ${export_to_dir} = true ]; then
                echo "${v_fileval}" > "${unit_envvar_root}/${v_filename}";
            fi
            # write to .sh file
            echo "export"  ${v_filename}"='"${v_fileval}"'" >> "${unit_envshell}";
            # write to .json file
            echo -n "\""$v_filename"\":\""$v_fileval"\"," >> "${unit_envjson}";
        fi
    done

    # to close the .json file
    echo -e "\b}" >> "${unit_envjson}";
}
#
# execute command and then update environemnt varialbes
#
function execute_command_reload_envvars () {
    v_filename=$1
    if [ -x "${v_filename}" ]; then
        echo "Running" $v_filename "..."
        "${v_filename}";
        retval=$?;
        if [ $retval != 0 ]; then
            echo >&2 "*** Failed with return value: $retval";
            exit $retval;
        else
            import_envvars;
            export_envvars fale;
        fi
    fi
}
#
# execute pre-service scripts when starting
#
function run_startup_files() {
    # execute pre-service scripts when starting
    if [ -d "${unit_run_root}" ] && [ ! -n "$(find ${unit_run_root} -prune -type d)" ]; then
        echo "Starting pre-service scripts in ${unit_run_root}...";
        for v_filename in "${unit_run_root}"/*; do
            execute_command_reload_envvars "${v_filename}";
        done
    fi

    # execute rc.local script when starting
    if [ -f "/etc/rc.local" ]; then
        execute_command_reload_envvars "/etc/rc.local";
    fi
}
#
# start runit supervisor process
#
function start_runit () {
    echo "Starting runit daemon ..."
    if [ ! -d "${unit_services_root}" ]; then
        mkdir -p "${unit_services_root}"
    fi
    /sbin/runsvdir -P "${unit_services_root}" 'log:.........................................................................................................' &
    runsvdir_PID=$!
    echo "Process runsvdir running with PID $runsvdir_PID"
}
#
# shutdown runit supervisor process
#
function shutdown_runit_services () {
    # check if runit service is running
    echo "Shutting down runit service ..."
    /sbin/sv down "${unit_services_root}"/*

    # give some time and check if service is down
    count=1
    while [ $(/sbin/sv status "${unit_services_root}"/* | grep -c "^run:") != 0 ]; do
        sleep 1
        count=`expr $count + 1`;
        if [ $count -gt 10 ]; then
            break;
        fi
    done
    exit 0
}
#
# display help message
#
function help_message() {
    echo "usage: my_init [-h|--help]"
    echo "                           [-- MAIN_COMMAND "
    echo "Initialize the system."
    echo "positional arguments:"
    echo "MAIN_COMMAND          The main command to run."
    echo "optional arguments:"
    echo "  -h, --help            show this help message and exit"
}

## Main -----------------------------------------------------------------------
import_envvars false false;
export_envvars;

# condition for --help
if [ `echo $@ | grep -c "\-\-help" ` -gt 0 ] || [ `echo $@ | grep -c "\-h" ` -gt 0 ] ; then
  help_message
  exit 0
fi

# initialize and start runit process
run_startup_files;
start_runit;

if  [ `echo $@  | grep -c "\-\- " ` -gt 0 ] ; then
    v_command=$(echo $@ |sed "s/--//")
    if [ ! "${v_command}" = "" ]; then
        # check if all services are online before executing command
        v_count=1
        while [ $(/sbin/sv status "${unit_services_root}"/* | grep -c "^down:") != 0 ]; do
            sleep 1
            count=`expr $count + 1`;
            if [ $count -gt 10 ]; then
                break;
            fi
        done
        exec "${v_command}";
        shutdown_runit_services;
    else
        echo "Need the command to do something: -- command "
        echo
        help_message;
        shutdown_runit_services;
    fi
fi

wait