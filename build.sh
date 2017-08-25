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

## Shell Opts ----------------------------------------------------------------
set -e

## Vars ----------------------------------------------------------------------
_self_name=$(basename $0);
_self_root="$( if [ "$( echo "${0%/*}" )" != "$( echo "${0}" )" ] ; then cd "$( echo "${0%/*}" )"; fi; pwd )";
container_conf="container.conf"
image_dockerfile="Dockerfile"

# enable debug
debug_mode="on";

## Functions -----------------------------------------------------------------
#
# Load scripts Library
#
info_block "Checking for required libraries." 2> /dev/null ||
    source "${_self_root}/scripts_library.sh";

#
# show help message
#
function show_help_message () {
    printf "\n"
    printf 'usage: %s [OPTIONS] PATH | URL \n' "${_self_name}"
    printf "\n"
    printf "%s\n" "build or download docker image from [PATH] or [URL]."
    printf "\n"
    printf "%s\n" "Options"
    printf "\t%s\n" "-h, --help:            Prints Help"
    printf "\n"
}
#
# return docker image ID if exists
#
function get_docker_imageid () {
    local _image=(${1//:/ });
    local _image_name=${_image[0]};
    local _image_tag=${_image[1]};

    # to get number of elements in an array, using ${#array[@]}
    # set _image_tag as 'latest' if no tat been find.
    if [ "${_image_name}" == "<none>" ]; then
        _image_tag="<none>";
    elif [ "${_image_name}" != "<none>" ] && [ -z "${_image_tag}" ]; then
        _image_tag="latest";
    fi

    local _image_id=$(docker images | awk -v name="${_image_name}" -v tag="${_image_tag}" '($1 == name) && ($2 == tag) {print $3}');
    if [ ! -z "${_image_id}" ]; then
        echo "${_image_id}";
    fi
}
#
# remove related containers if exists
#
function remove_related_containers () {
    local _image=(${1//:/ });
    local _image_name=${_image[0]};
    local _image_tag=${_image[1]};

    # set _image_tag as 'latest' if no tat been find.
    if [ "${_image_name}" == "<none>" ]; then
        _image_tag="<none>";
    elif [ "${_image_name}" != "<none>" ] && [ -z "${_image_tag}" ]; then
        _image_tag="latest";
    fi

    log_debug "image_name in function-remove_related_containers:  ${_image_name}"
    log_debug "image_tag in function-remove_related_containers:   ${_image_tag}"

    # stop running containers
    local _cont_running=$(docker ps | awk -v name="${_image_name}:${_image_tag}" '$2 == name {print $1}');
    if [ ! -z "${_cont_running}" ]; then
        for _cont_id in ${_cont_running}; do
            log_warning "Stopping related container - ${_cont_id} ...";
            docker stop ${_cont_id} > /dev/null;
        done
    fi

    # remove all related containers
    local _cont_related=$(docker ps -a | awk -v name="${_image_name}:${_image_tag}" '$2 == name {print $1}');
    if [ ! -z "${_cont_related}" ]; then
        for _cont_id in ${_cont_related}; do
            log_warning "Removing related container - ${_cont_id} ...";
            docker rm --force ${_cont_id} > /dev/null;
        done
    fi
}
#
# remove exists docker image
#
function remove_exist_image () {
    local _image=${1}

    log_debug "image name in function-remove_exist_image:  ${_image}"

    local _image_ids=$(get_docker_imageid "${_image}");

    log_debug "imageID in function-remove_exist_image:  ${_image_id}"

    if [ ! -z "${_image_ids}" ]; then
        for _image_id in ${_image_ids}; do
            remove_related_containers "${_image_id}"
            log_warning "Removing ${_image} (id: ${_image_id}) image ..."
            docker rmi --force "${_image_id}" > /dev/null
        done
    else
        exit_fail "Cannot find ${_image} in local repository ..."
    fi
}
#
# Update Dockerfile
#
function update_dockerfile () {
    local _dockerfile="$1";
    IFS=","

    if [ -f "${_dockerfile}" ]; then
        log_info "Updating ${image_dockerfile} ..."

        # update exposed ports
        if [ ! -z "${container_ports_exposed}" ]; then
            _vars=""
            for _var in ${container_ports_exposed}; do
                # get value with trimmed leading and trailing whitespace.
                _vars+=$(echo "${_var}" | awk '{gsub(/^ +| +$/,"")} {print $0}')" ";
            done
            # remove last whitespace from variables
            _vars=${_vars::-1};

            log_debug "ports will update in dockerfile: ${_vars} ..."

            sed -i 's#_===EXPOSE_PORTS===_#'"${_vars}"'#g' "${_dockerfile}"
        else
            sed -i 's#^EXPOSE.*##g' "${_dockerfile}"
        fi

        # update exposed volumes
        if [ ! -z "${container_volume_exposed}" ]; then
            _vars=""
            for _var in ${container_volume_exposed}; do
                # get value with trimmed leading and trailing whitespace.
                _vars+="\"$(echo "${_var}" | awk '{gsub(/^ +| +$/,"")} {print $0}')\",";
            done
            # remove last whitespace from variables
            _vars=${_vars::-1};

            log_debug "volume will update to dockerfile: ${_vars} ..."

            sed -i 's#_===EXPOSE_VOLUME===_#'"${_vars}"'#g' "${_dockerfile}"
        else
            sed -i 's#^VOLUME.*##g' "${_dockerfile}"
        fi
    else
        exit_fail "Cannot find ${image_dockerfile} in given directory ...";
    fi
    # unset IFS Separator
    unset IFS;
}
#
# show docker image information
#
function show_image_info () {
    local _image=(${1//:/ });
    local _image_name=${_image[0]};
    local _image_tag=${_image[1]};

    # set _image_tag as 'latest' if no tat been find.
    if [ "${_image_name}" == "<none>" ]; then
        _image_tag="<none>";
    elif [ "${_image_name}" != "<none>" ] && [ -z "${_image_tag}" ]; then
        _image_tag="latest";
    fi

    docker images | egrep "REPOSITORY|${_image_name}";
}

## Main -----------------------------------------------------------------------
# parsing arguments
# use -gt 0 to consume one or more arguments per pass in the loop (e.g.
# some arguments don't have a corresponding value to go with it such
# as in the --default example).
# arg_optional_
while [ $# -gt 0 ]; do
    _key="$1"
    case "$_key" in
        -h|--help)
            show_help_message;
            exit 0;
            ;;
        *)
            _arg_positionals+=("$1");
            ;;
    esac
    shift
done

_arg_names=('_arg_docker_image')
if [ ${#_arg_positionals[@]} -lt 1 ]; then
    exit_fail "Not enough positional arguments - we require the docker name or PATH for Docerfile."
fi

if [ ${#_arg_positionals[@]} -gt 1 ]; then
    exit_fail "There weere spurious positional arguments - we only require the docker name or PATH for Docerfile."
fi

for (( _arg_ii = 0; _arg_ii < ${#_arg_positionals[@]}; _arg_ii++ )); do
    eval "${_arg_names[_arg_ii]}=\${_arg_positionals[_arg_ii]}" || exit_fail "Error during arguments parsing."
done

log_debug "args: _arg_docker_image = ${_arg_docker_image}"

log_info "check if ${_arg_docker_image} exist in local repository"
image_id=$(get_docker_imageid "${_arg_docker_image}")

log_debug "imageID for image name ${_arg_docker_image}:     ${image_id}"

if [ -z "${image_id}" ] && [ ! -f "${_self_root}/${_arg_docker_image}/${container_conf}" ]; then
    log_error "Cannot find ${_arg_docker_image} in local repository, try to get from public ..."
    #todo: pull image from public
    exit_fail;
elif [ -f "${_self_root}/${_arg_docker_image}/${container_conf}" ] && [ -z "${image_id}" ]; then
    source "${_self_root}/${_arg_docker_image}/${container_conf}";

    log_debug "image name going to check: ${image_repo_name}."

    image_id=$(get_docker_imageid "${image_repo_name}");

    log_debug "imageID for ${image_repo_name}: ${image_id}"

    if [ ! -z "${image_id}" ]; then
        log_warning "Remove exist image before building ..."
        remove_exist_image "${image_repo_name}"
    fi

    if [ ! -f "${_self_root}/${_arg_docker_image}/${image_dockerfile}" ]; then
        exit_fail "Cannot find ${image_dockerfile} in given directory ...";
    fi

    # updating ${image_dockerfile}
    update_dockerfile "${_self_root}/${_arg_docker_image}/${image_dockerfile}"

    # switch to working directory and build
    pushd "${_self_root}/${_arg_docker_image%/}"
        log_info "Bulding image ${image_repo_name} ..."
        docker build -t "${image_repo_name}" .
    popd

    if [ ! -z "$(get_docker_imageid "<none>")" ]; then
        log_info "Removing <none> images ..."
        remove_exist_image "<none>:<none>"
    fi

    # show image information
    show_image_info "${image_repo_name}"

elif [ ! -z "${image_id}" ]; then
    exit_fail "The image ${_arg_docker_image} does exist in local repository with ID: ${image_id}!!!"
fi
