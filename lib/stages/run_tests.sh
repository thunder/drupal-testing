#!/usr/bin/env bash

_stage_run_tests() {
    printf "Running tests\n\n"

    local docroot
    local composer_bin_dir
    local project_location
    docroot=$(get_distribution_docroot)
    composer_bin_dir=$(get_composer_bin_directory)
    project_location=$(get_project_location)

    local test_selection=""
    local phpunit=${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}/${composer_bin_dir}/phpunit

    if [[ ${DRUPAL_TESTING_TEST_GROUP} ]]; then
        test_selection="${test_selection} --group ${DRUPAL_TESTING_TEST_GROUP}"
    fi

    if [[ -f ${docroot}/${DRUPAL_TESTING_TEST_DUMP_FILE} ]]; then
        # Database needs to be initialized, if the run was split into a build and a test run.
        mysql --host="${DRUPAL_TESTING_DATABASE_HOST}" --port="${DRUPAL_TESTING_DATABASE_PORT}" --user="${DRUPAL_TESTING_DATABASE_USER}" --password="${DRUPAL_TESTING_DATABASE_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS ${DRUPAL_TESTING_DATABASE_NAME};"
        export thunderDumpFile=${docroot}/${DRUPAL_TESTING_TEST_DUMP_FILE}
    fi

    if [[ ${DRUPAL_TESTING_TEST_FILTER} ]]; then
        test_selection="${test_selection} --filter ${DRUPAL_TESTING_TEST_FILTER}"
    fi

    local runtest="php ${phpunit} --verbose --debug --configuration ${docroot}/core ${test_selection} ${project_location}"

    eval "${runtest}" || exit 1
}
