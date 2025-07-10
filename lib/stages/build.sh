#!/usr/bin/env bash

# Build the project
_stage_build() {
    printf "Building the project.\n\n"

    local composer_arguments=""

    if ${DRUPAL_TESTING_MIN_BUILD}; then
        composer_arguments="--prefer-lowest"
    fi

    # require the project, we want to test. To make sure, that the local version is used, we rename the project first
    local testing_project_name=drupal-testing-"${DRUPAL_TESTING_COMPOSER_NAME}"
    composer config name "${testing_project_name}" --working-dir="${DRUPAL_TESTING_PROJECT_BASEDIR}"
    composer remove "${DRUPAL_TESTING_COMPOSER_NAME}" --no-update --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    composer require "${testing_project_name}@dev:*" --no-update --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"

    # Install all dependencies
    cd "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}" || exit
    composer update ${composer_arguments}

    # We can cleanup the name change now.
    composer config name "${DRUPAL_TESTING_COMPOSER_NAME}" --working-dir="${DRUPAL_TESTING_PROJECT_BASEDIR}"

    # Back to previous directory.
    cd - || exit
}
