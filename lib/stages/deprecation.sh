#!/usr/bin/env bash

_stage_deprecation() {
    printf "Checking for deprecations.\n\n"

    local project_location=$(get_project_location)

    if ${DRUPAL_TRAVIS_TEST_DEPRECATION}; then
        cp phpstan.neon ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
        cd ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
        vendor/bin/phpstan analyse --memory-limit 300M ${project_location}
        cd -
    fi
}
