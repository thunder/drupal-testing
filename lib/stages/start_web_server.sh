#!/usr/bin/env bash

_stage_start_web_server() {
    printf "Starting web server\n\n"

    local docroot
    docroot=$(get_distribution_docroot)

    if ! port_is_open "${DRUPAL_TESTING_HTTP_HOST}" "${DRUPAL_TESTING_HTTP_PORT}"; then
        php -S "${DRUPAL_TESTING_HTTP_HOST}":"${DRUPAL_TESTING_HTTP_PORT}" -t "${docroot}" >/dev/null 2>&1 &
        wait_for_port "${DRUPAL_TESTING_HTTP_HOST}" "${DRUPAL_TESTING_HTTP_PORT}" 30
    fi
}