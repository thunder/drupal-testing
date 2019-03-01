#!/usr/bin/env bash

function port_is_open() {
	local host=${1}
	local port=${2}

    $(nc -z "${host}" "${port}")
}

function wait_for_port() {
	local host=${1}
	local port=${2}
	local max_count=${3:-10}

	local count=1
	until port_is_open ${host} ${port}; do
		sleep 1
		if [[ ${count} -gt ${max_count} ]]
		then
			printf "Error: Timeout while waiting for port ${port} on host ${host}.\n" 1>&2
			exit 1
		fi
		count=$[count+1]
	done
}
