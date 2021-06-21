#!/usr/bin/env bash

_stage_deprecation() {
    printf "Checking for deprecations.\n\n"

    local project_location
    local composer_bin_dir

    project_location=$(get_project_location)
    composer_bin_dir=$(get_composer_bin_directory)

    if ${DRUPAL_TESTING_TEST_DEPRECATION}; then
        cp phpstan.neon "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
        cd "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}" || exit
        "${composer_bin_dir}/phpstan" analyse --memory-limit "${PHPSTAN_MEMORY_LIMIT}" "${project_location}"
        cd - || exit
    fi
}
