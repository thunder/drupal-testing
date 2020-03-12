#!/usr/bin/env bash

download_chromedriver() {
    printf "Downloading Chromedriver\n\n"
    # Only 64 bit OS supported. If you have a 32 bit OS install and start chromedriver on your own.
    # make sure, you start it the following way:
    # chromedriver --port=${DRUPAL_TESTING_SELENIUM_PORT} --url-base=/wd/hub
    local filename="chromedriver_linux64.zip"

    if [[ ${OSTYPE} == "darwin"* ]]; then
        filename="chromedriver_mac64.zip"
    fi

    mkdir -p "${DRUPAL_TESTING_TEST_BASE_DIRECTORY}"
    wget -q -O "${DRUPAL_TESTING_TEST_BASE_DIRECTORY}"/"${filename}" https://chromedriver.storage.googleapis.com/"${DRUPAL_TESTING_CHROMEDRIVER_VERSION}"/"${filename}"
    unzip -o "${DRUPAL_TESTING_TEST_BASE_DIRECTORY}"/"${filename}" -d "${DRUPAL_TESTING_TEST_BASE_DIRECTORY}"
    rm "${DRUPAL_TESTING_TEST_BASE_DIRECTORY}"/"${filename}"
}

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
        export thunderDumpFile=${docroot}/${DRUPAL_TESTING_TEST_DUMP_FILE}
    fi

    if [[ ${DRUPAL_TESTING_TEST_FILTER} ]]; then
        test_selection="${test_selection} --filter ${DRUPAL_TESTING_TEST_FILTER}"
    fi

    if ! port_is_open "${DRUPAL_TESTING_SELENIUM_HOST}" "${DRUPAL_TESTING_SELENIUM_PORT}"; then
        printf "Starting web driver\n"

        if ${DRUPAL_TESTING_USE_SELENIUM} = true; then
            docker run --detach --net host --name "${DRUPAL_TESTING_SELENIUM_DOCKER_NAME}" --volume "${DRUPAL_TESTING_PROJECT_BASEDIR}":/project --volume /dev/shm:/dev/shm selenium/standalone-chrome:"${DRUPAL_TESTING_SELENIUM_CHROME_VERSION}"
        else
            download_chromedriver
            "${DRUPAL_TESTING_TEST_BASE_DIRECTORY}"/chromedriver --port="${DRUPAL_TESTING_SELENIUM_PORT}" --url-base=/wd/hub &
        fi

        wait_for_port "${DRUPAL_TESTING_SELENIUM_HOST}" "${DRUPAL_TESTING_SELENIUM_PORT}"
    fi

    local runtest="php ${phpunit} --verbose --debug --configuration ${docroot}/core ${test_selection} ${project_location}"

    eval "${runtest}" || exit 1
}
