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

_stage_start_services() {
    printf "Starting services\n\n"

    local docroot
    docroot=$(get_distribution_docroot)


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

    if ! port_is_open "${DRUPAL_TESTING_HTTP_HOST}" "${DRUPAL_TESTING_HTTP_PORT}"; then
        php -S "${DRUPAL_TESTING_HTTP_HOST}":"${DRUPAL_TESTING_HTTP_PORT}" -t "${docroot}" >/dev/null 2>&1 &
        wait_for_port "${DRUPAL_TESTING_HTTP_HOST}" "${DRUPAL_TESTING_HTTP_PORT}" 30
    fi
}
