#!/usr/bin/env bash

# Functions to manage docker container

# Test if docker container exist, might be running or stopped
function container_exists {
    local container=${1}
    [[ "$(docker ps -a -q -f name=^${container}$)" ]]
}

# Test if container is running
function container_is_running {
    local container=${1}
    [[ "$(docker ps -q -f name=^${container}$)" ]]
}

# Test if a container exists, but is stopped
function container_is_stopped {
    local container=${1}
    [[ "$(docker ps -aq -f status=exited -f name=^${container}$)" ]]
}

# Test docker container health status
function get_container_health {
    local container=${1}
    docker inspect --format "{{json .State.Health.Status }}" ${container}
}

# Wait till docker container is fully started
function wait_for_container {
    local container=${1}

    printf "Waiting for container ${container}."

    while local status=$(get_container_health ${container}); [[ ${status} != "\"healthy\"" ]]; do
        if [[ ${status} == "\"unhealthy\"" ]]; then
            printf "Container ${container} failed to start. \n"
            exit 1
        fi
        printf "."
        sleep 1
    done

    printf "Container started!\n"
}
