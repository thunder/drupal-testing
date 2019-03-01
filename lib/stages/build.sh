#!/usr/bin/env bash

# Build the project
_stage_build() {
    printf "Building the project.\n\n"

    # Install all dependencies
    COMPOSER_MEMORY_LIMIT=-1 composer install --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}

    # Make sure, we have drupal scaffold files. Composer install should have taken care of it, but
    # this sometimes fails.
    composer drupal:scaffold --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}

    # Move downloaded frontend libraries to the correct folder within the webroot. This is necessary, because the
    # drupal project composer.json does not provide the necessary configuration to do so.
    local libraries=$(get_distribution_docroot)/libraries;
    mkdir ${libraries}

    if [[ -d ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/vendor/bower-asset ]]; then
        mv ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/vendor/bower-asset/* ${libraries}
    fi

    if [[ -d ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/vendor/npm-asset ]]; then
        mv ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/vendor/npm-asset/* ${libraries}
    fi
}
