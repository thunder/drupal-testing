#!/usr/bin/env bash

_stage_deprecation() {
    printf "Checking for deprecations.\n\n"

    local project_location=$(get_project_location)

    if ${DRUPAL_TESTING_TEST_DEPRECATION}; then
        cp phpstan.neon ${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}
        cd ${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}
        vendor/bin/phpstan analyse --memory-limit 300M ${project_location}
        cd -
    fi
}
