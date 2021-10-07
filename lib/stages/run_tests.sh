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
    local phpunit=""

    if ${DRUPAL_TESTING_PARALLEL_TESTING}; then
        phpunit=${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}/${composer_bin_dir}/paratest" -p "${DRUPAL_TESTING_PARALLEL_TESTING_PROCESSES}
        if ${DRUPAL_TESTING_PARALLEL_TESTING_PER_FUNCTION}; then
          phpunit=${phpunit}" -f"
        fi
        if ${DRUPAL_TESTING_PARALLEL_TESTING_WRAPPER_RUNNER}; then
          phpunit=${phpunit}" --runner WrapperRunner"
        fi
    else
        phpunit=${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}/${composer_bin_dir}/phpunit" --debug"
    fi

    if [[ ${DRUPAL_TESTING_TEST_GROUP} ]]; then
        test_selection="${test_selection} --group ${DRUPAL_TESTING_TEST_GROUP}"
    fi

    if [[ ${DRUPAL_TESTING_TEST_GROUP_EXCLUDE} ]]; then
        test_selection="${test_selection} --exclude-group ${DRUPAL_TESTING_TEST_GROUP_EXCLUDE}"
    fi

     if [[ -f ${docroot}/${DRUPAL_TESTING_TEST_DUMP_FILE} ]]; then
        # Database needs to be initialized, if the run was split into a build and a test run.
         if [[ -x "$(command -v mysql)" ]]; then
            mysql --host="${DRUPAL_TESTING_DATABASE_HOST}" --port="${DRUPAL_TESTING_DATABASE_PORT}" --user="${DRUPAL_TESTING_DATABASE_USER}" --password="${DRUPAL_TESTING_DATABASE_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS ${DRUPAL_TESTING_DATABASE_NAME};"
         fi
        export thunderDumpFile=${docroot}/${DRUPAL_TESTING_TEST_DUMP_FILE}
    fi

    if [[ ${DRUPAL_TESTING_TEST_FILTER} ]]; then
        test_selection="${test_selection} --filter ${DRUPAL_TESTING_TEST_FILTER}"
    fi

    local runtest="php ${phpunit} --verbose --configuration ${docroot}/core ${test_selection} ${project_location}"

    eval "${runtest}" || exit 1
}
