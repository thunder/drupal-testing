#!/usr/bin/env bash

# Check requirements.
_stage_requirements() {
    printf "Check requirements\n\n"

    if [[ ${DRUPAL_TESTING_DATABASE_ENGINE} != 'sqlite' ]] && ! port_is_open "${DRUPAL_TESTING_DATABASE_HOST}" "${DRUPAL_TESTING_DATABASE_PORT}"; then
        printf "Error: Database is not running, or configured incorrectly.\n"
        exit 1
    fi

}
