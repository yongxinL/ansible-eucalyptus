#!/bin/bash
# =============================================================================
#
# - Copyright (C) 2017     George Li <yongxinl@outlook.com>
#
# - This is part of docker library project.
# - the script is use to run the docker image
#
# - This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# =============================================================================

set -e

## Variables -----------------------------------------------------------------
self_name=${SCRIPT_NAME:-$(basename $0)}
self_root="$( if [ "$( echo "${0%/*}" )" != "$( echo "${0}" )" ] ; then cd "$( echo "${0%/*}" )"; fi; pwd )"
unit_configfile="unit.conf"
unit_dockerfile="Dockerfile"
unit_name=$1


## Functions -----------------------------------------------------------------
echo_SUCCESS() {
    echo -en "\\033[1;32m"
    echo $@
    echo -en "\\033[0;39m"
}

echo_WARNING() {
    echo -en "\\033[1;33m"
    echo $@
    echo -en "\\033[0;39m"
}

echo_FAILURE() {
    echo -en "\\033[1;31m"
    echo $@
    echo -en "\\033[0;39m"
}
#
# return image id if exists
#
function get_docker_imageid() {
    local v_unit_name=$1;
    local v_name_array=(${v_unit_name//:/ });
    local v_name=${v_name_array[0]};
    local v_tag=${v_name_array[1]};

    # to get number of elements in an array, using ${#array[@]}
    # set tag as 'latest' if no tag been set
    if [ -z ${v_tag} ]; then
        v_tag='latest';
    fi

    local v_image_id=$(docker images | awk -v name="${v_name}" -v tag="${v_tag}" '($1 == name) && ($2 == tag) {print $3}');
    echo "${v_image_id}";
}
#
# remove related containers if exists
#
function remove_docker_containers() {
    local v_unit_name=$1;
    local v_name_array=(${v_unit_name//:/ });
    local v_name=${v_name_array[0]};
    local v_tag=${v_name_array[1]};

    # set tag as 'latest' if no tag been set
    if [ -z ${v_tag} ]; then
        v_tag='latest';
    fi

    # stop containers if necessary
    local v_container_running=$(docker ps | awk -v name="${v_name}:${v_tag}" '$2 == name {print $1}');
    if [ ! -z "${v_container_running}" ]; then
        for running_id in ${v_container_running}; do
            echo_WARNING -n "--> Stopping container: id - ${running_id} ... "
            docker stop ${running_id} > /dev/null;
            echo_SUCCESS "Done!";
        done
    fi

    # remove the container if necessary
    local v_container_all=$(docker ps -a | awk -v name="${v_name}:${v_tag}" '$2 == name {print $1}');
    if [ ! -z "${v_container_all}" ]; then
        for container_id in ${v_container_all}; do
            echo_WARNING -n "--> Removing container: id - ${container_id} ... "
            docker rm --force ${container_id} > /dev/null;
            echo_SUCCESS "Done!";
        done
    fi
}
#
# remove docker image if exists
#
function remove_docker_image() {
    local v_unit_name=$1;

    # check if docker image exists
    local v_image_id=$(get_docker_imageid ${v_unit_name});
    if [ ! -z ${v_image_id} ]; then
        # remove related containers
        remove_docker_containers ${v_unit_name};

        # remove docker image
        echo_WARNING -n "--> Removing image ${v_unit_name}: id - ${v_image_id} ... "
        docker rmi --force ${v_image_id} > /dev/null;
        echo_SUCCESS "Done!";
    else
        echo_WARNING "--> repository ${v_unit_name} does not exist ... "
    fi
}
#
# update dockerfile
#
update_dockerfile() {
    local v_file=$1;

    if [ -f "${v_file}" ]; then
        echo_WARNING -n "--> Updating Dockerfile ... "
        sed -i 's#_===EXPOSE_PORTS===_#'"${unit_exposed_ports}"'#g' "${v_file}"
        echo_SUCCESS "Done!"
    fi
}
#
# show image information
#
show_image_info() {
    local v_unit_name=$1;

    # check if docker image exists
    local v_image_id=$(get_docker_imageid ${v_unit_name});
    if [ ! -z ${v_image_id} ]; then
        docker images | grep -e "${v_image_id}"
    else
        echo_FAILURE "Something wrong here,  please check!"
        exit 1
    fi
}

## Main -----------------------------------------------------------------------

echo_WARNING -n "--> Checking image ... "
unit_image_id=$(get_docker_imageid ${unit_name});

if [ -z ${unit_image_id} ]; then
    # check if using unit configuration file
    if [ ! -f "${self_root}/${unit_name%/}/${unit_configfile}" ]; then
        echo_FAILURE "failed!"
        echo "the configure file ${unit_configfile} does not exist, please check and run the script again!"
        exit 1
    else
        source "${self_root}/${unit_name}/${unit_configfile}"
    fi
    unit_image_id=$(get_docker_imageid ${unit_repo_name});
    unit_name=${unit_repo_name};

    if [ -z ${unit_image_id} ]; then
        # if the image still cannot find
        echo_FAILURE "failed!"
        echo "the image still unable to find in docker repository, please rebuild the image!"
        exit 1
    fi
else
    unit_name_part="${unit_name##*/}";
    unit_container_name="${unit_name_part%:*}-$(($RANDOM % 1000))"
fi
echo_SUCCESS "Done!"

# process arguments
# remove first element $unit_name from $@
shift;

if [[ "$1" == "remove" || "$1" == "rm" ]]; then
    remove_docker_containers ${unit_name};
    shift;
fi

# docker run options
if [ -z "$1" ]; then
    docker_run_args="--detach ";
else
    docker_run_args="$@ ";
fi

# automatically remove the container when it exists
docker_run_args+="--rm ";

# exposed ports
if [ ! -z "${unit_exposed_ports}" ]; then
    for unit_port in ${unit_exposed_ports}; do
        docker_run_args+="--publish ${unit_port}:${unit_port} ";
    done
fi

# container name and image
docker_run_args+="--name ${unit_container_name} ${unit_name}";

# execute container
docker run ${docker_run_args};
