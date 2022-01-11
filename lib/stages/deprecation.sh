#!/usr/bin/env bash

_stage_deprecation() {
    if [ "${DRUPAL_TESTING_TEST_DEPRECATION}" = true ]; then
        printf "Checking for deprecations.\n\n"

        local project_location

        project_location=$(get_project_location)

        if [ ! -f "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}/phpstan.neon" ]; then
            cp phpstan.neon "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
        fi

        cd "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}" || exit
        composer exec phpstan -- analyse --memory-limit "${PHPSTAN_MEMORY_LIMIT}" "${project_location}"
        cd - || exit
    fi
}
