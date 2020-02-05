#!/usr/bin/env bash

clean_up() {
    printf "Cleaning up test environment.\n\n"

    if container_exists "${DRUPAL_TESTING_SELENIUM_DOCKER_NAME}"; then
        docker rm -f -v "${DRUPAL_TESTING_SELENIUM_DOCKER_NAME}"
    fi

    if [[ -d ${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY} ]]; then
        chmod -R u+w "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
        rm -rf "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    fi

    if [[ -d ${DRUPAL_TESTING_LOCK_FILES_DIRECTORY} ]]; then
        rm -rf "${DRUPAL_TESTING_LOCK_FILES_DIRECTORY}"
    fi

    if [[ -f ${DRUPAL_TESTING_TEST_BASE_DIRECTORY}/chromedriver ]]; then
        killall chromedriver
        rm "${DRUPAL_TESTING_TEST_BASE_DIRECTORY}/chromedriver"
    fi

    if [[ -f ${DRUPAL_TESTING_TEST_BASE_DIRECTORY}/${DRUPAL_TESTING_DATABASE_NAME}.sqlite ]]; then
        rm "${DRUPAL_TESTING_TEST_BASE_DIRECTORY}/${DRUPAL_TESTING_DATABASE_NAME}.sqlite*"
    fi

    if [[ -f ${DRUPAL_TESTING_TEST_BASE_DIRECTORY}/${DRUPAL_TESTING_DATABASE_NAME}.sqlite-shm ]]; then
        rm "${DRUPAL_TESTING_TEST_BASE_DIRECTORY}/${DRUPAL_TESTING_DATABASE_NAME}.sqlite-shm"
    fi

    if [[ -d ${DRUPAL_TESTING_TEST_BASE_DIRECTORY} ]]; then
        rmdir "${DRUPAL_TESTING_TEST_BASE_DIRECTORY}"
    fi
}
