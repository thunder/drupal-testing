#!/usr/bin/env bash

_stage_run_tests() {
    printf "Running tests\n\n"

    local docroot
    local test_location
    docroot=$(get_distribution_docroot)
    test_location=$(get_project_location)

    local test_selection=""
    local phpunit="composer exec -- phpunit --debug"

    if [ "${DRUPAL_TESTING_PARALLEL_TESTING}" = true ]; then
        phpunit="composer exec -- paratest -p "${DRUPAL_TESTING_PARALLEL_TESTING_PROCESSES}
        if [ "${DRUPAL_TESTING_PARALLEL_TESTING_PER_FUNCTION}" = true ]; then
          phpunit=${phpunit}" -f"
        fi
        if [ "${DRUPAL_TESTING_PARALLEL_TESTING_WRAPPER_RUNNER}" = true ]; then
          phpunit=${phpunit}" --runner WrapperRunner"
        fi
    fi

    if [[ ${DRUPAL_TESTING_TEST_GROUP} ]]; then
        test_selection="${test_selection} --group ${DRUPAL_TESTING_TEST_GROUP}"
    fi

    if [[ ${DRUPAL_TESTING_TEST_GROUP_EXCLUDE} ]]; then
        test_selection="${test_selection} --exclude-group ${DRUPAL_TESTING_TEST_GROUP_EXCLUDE}"
    fi

    if [[ ${DRUPAL_TESTING_TEST_SUITE} ]]; then
        test_selection="${test_selection} --testsuite ${DRUPAL_TESTING_TEST_SUITE}"
        test_location=""
    fi

    if [[ ${DRUPAL_TESTING_TEST_PATH} ]]; then
        test_location="${DRUPAL_TESTING_TEST_PATH}"
    fi

    if [[ ${DRUPAL_TESTING_TEST_DUMP_FILE} != "" ]]; then
        # Database needs to be initialized, if the run was split into a build and a test run.
        if [[ -x "$(command -v mysql)" ]]; then
            mysql --host="${DRUPAL_TESTING_DATABASE_HOST}" --port="${DRUPAL_TESTING_DATABASE_PORT}" --user="${DRUPAL_TESTING_DATABASE_USER}" --password="${DRUPAL_TESTING_DATABASE_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS ${DRUPAL_TESTING_DATABASE_NAME};"
        fi
        export thunderDumpFile=${docroot}/${DRUPAL_TESTING_TEST_DUMP_FILE}
    fi

    if [[ ${DRUPAL_TESTING_TEST_FILTER} ]]; then
        test_selection="${test_selection} --filter ${DRUPAL_TESTING_TEST_FILTER}"
    fi

    local runtest="${phpunit} --verbose --configuration ${docroot}/core ${test_selection} ${test_location}"

    cd "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}" || exit
    eval "COMPOSER_PROCESS_TIMEOUT=0 ${runtest}" || exit 1
    cd - || exit
}
