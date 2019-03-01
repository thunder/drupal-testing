#!/usr/bin/env bash

clean_up() {
    printf "Cleaning up test environment.\n\n"
    if container_exists ${DRUPAL_TRAVIS_SELENIUM_DOCKER_NAME}; then
        docker rm -f -v ${DRUPAL_TRAVIS_SELENIUM_DOCKER_NAME}
    fi

    if container_exists ${DRUPAL_TRAVIS_DATABASE_DOCKER_NAME}; then
        docker rm -f -v ${DRUPAL_TRAVIS_DATABASE_DOCKER_NAME}
    fi

    if [[ -d ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY} ]]; then
        chmod -R u+w ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
        rm -rf ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    fi

    if [[ -d ${DRUPAL_TRAVIS_LOCK_FILES_DIRECTORY} ]]; then
        rm -rf ${DRUPAL_TRAVIS_LOCK_FILES_DIRECTORY}
    fi

    if [[ -d ${DRUPAL_TRAVIS_TEST_BASE_DIRECTORY} ]]; then
        rmdir ${DRUPAL_TRAVIS_TEST_BASE_DIRECTORY}
    fi
}
