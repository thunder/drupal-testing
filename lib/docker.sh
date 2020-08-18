#!/usr/bin/env bash

# Functions to manage docker container

# Test if docker container exist, might be running or stopped
function container_exists() {
    [[ $(docker_is_installed) ]] && [[ "$(docker ps -a -q -f name=^/"${1}"\$)" ]]
}

# Test if container is running
function container_is_running() {
    [[ "$(docker ps -q -f name=^/"${1}"\$)" ]]
}

# Test if a container exists, but is stopped
function container_is_stopped() {
    [[ "$(docker ps -aq -f status=exited -f name=^/"${1}"\$)" ]]
}

# Test docker container health status
function get_container_health() {
    docker inspect --format "{{json .State.Health.Status }}" "${1}"
}

# Wait till docker container is fully started
function wait_for_container() {
    local container=${1}

    printf "Waiting for container %s." "${container}"

    while
        local status
        status=$(get_container_health "${container}")
        [[ ${status} != '"healthy"' ]]
    do
        if [[ ${status} == '"unhealthy"' ]]; then
            printf "Container %s failed to start. \n" "${container}"
            exit 1
        fi
        printf "."
        sleep 1
    done

    printf "Container started!\n"
}

# Check if docker is installed.
function docker_is_installed() {
  [[ -x "$(command -v docker)" ]]
}
