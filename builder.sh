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
    local v_mount="";

    if [ -f "${v_file}" ]; then
        echo_WARNING -n "--> Updating Dockerfile ... "

        # ports exposed to host
        if [ ! -z "${unit_exposed_ports}" ]; then
            sed -i 's#_===EXPOSE_PORTS===_#'"${unit_exposed_ports}"'#g' "${v_file}"
        else
            sed -i 's/^EXPOSE.*//g' "${v_file}"
        fi

        # exposed volume
        IFS=','
        if [ ! -z "${unit_exposed_volume}" ]; then
            for unit_volume in ${unit_exposed_volume}; do
                # add volume with trimed leading and trailing whitespace
                v_mount+="\"$(echo "${unit_volume}" | awk '{gsub(/^ +| +$/,"")} {print $0}' )\",";
            done
            # remove last comma from variable
            v_mount=${v_mount::-1};

            sed -i 's#_===EXPOSE_VOLUME===_#'"${v_mount}"'#g' "${v_file}"
        else
            sed -i 's/^VOLUME.*//g' "${v_file}"
        fi

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
    fi
}

## Main -----------------------------------------------------------------------
# verify and load docker unit configuration
if [ ! -f "${self_root}/${unit_name%/}/${unit_configfile}" ]; then
    echo "the configure file ${unit_configfile} does not exist, please check and run the script again!"
    exit 1
else
    source "${self_root}/${unit_name}/${unit_configfile}"
fi

# verify docker unit Dockerfile
if [ ! -f "${self_root}/${unit_name%/}/${unit_dockerfile}" ]; then
    echo "the ${unit_dockerfile} does not exist, please check and run the script again!"
    exit 1
else
    unit_working_root="${self_root}/${unit_name%/}"
fi

# begin to build
echo_WARNING "--> Building image ${unit_repo_name} ... "

# remove existing image if necessary
remove_docker_image ${unit_repo_name}
remove_docker_image "<none>"

update_dockerfile "${unit_working_root}/${unit_dockerfile}"

# switch to working directory and build the image
pushd "${unit_working_root}"
    docker build -t ${unit_repo_name} .
popd

echo_SUCCESS "--> Building completed! here is the image:"
show_image_info ${unit_repo_name}
