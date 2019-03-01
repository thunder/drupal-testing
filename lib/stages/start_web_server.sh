#!/usr/bin/env bash

_stage_start_web_server() {
    printf "Starting web server\n\n"

    local composer_bin_dir=$(get_composer_bin_directory)
    local docroot=$(get_distribution_docroot)
    local drush="${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${composer_bin_dir}/drush  --root=${docroot}"

    if  ! port_is_open ${DRUPAL_TRAVIS_HTTP_HOST} ${DRUPAL_TRAVIS_HTTP_PORT} ; then
        ${drush} runserver "http://${DRUPAL_TRAVIS_HTTP_HOST}:${DRUPAL_TRAVIS_HTTP_PORT}" >/dev/null 2>&1 &
        wait_for_port ${DRUPAL_TRAVIS_HTTP_HOST} ${DRUPAL_TRAVIS_HTTP_PORT}
    fi
}

