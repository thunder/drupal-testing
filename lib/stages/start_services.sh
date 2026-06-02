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

        if [ "${DRUPAL_TESTING_USE_SELENIUM}"  = true ]; then
            docker run --detach --net host --name "${DRUPAL_TESTING_SELENIUM_DOCKER_NAME}" --volume "${DRUPAL_TESTING_PROJECT_BASEDIR}":/project --volume /dev/shm:/dev/shm selenium/standalone-chrome:"${DRUPAL_TESTING_SELENIUM_CHROME_VERSION}"
            wait_for_port "${DRUPAL_TESTING_SELENIUM_HOST}" "${DRUPAL_TESTING_SELENIUM_PORT}"
            # Wait for Selenium node to register — port open ≠ Chrome node ready.
            local selenium_status_url="http://${DRUPAL_TESTING_SELENIUM_HOST}:${DRUPAL_TESTING_SELENIUM_PORT}/status"
            local ready_count=0
            until curl -sf "${selenium_status_url}" | grep -q '"ready":true'; do
                sleep 2
                ready_count=$((ready_count + 1))
                if [[ ${ready_count} -gt 15 ]]; then
                    printf "Error: Selenium node did not become ready in time.\n" 1>&2
                    exit 1
                fi
            done
        elif command -v chromedriver > /dev/null 2>&1; then
            # Use system ChromeDriver (pre-installed on GitHub Actions runners).
            chromedriver --port="${DRUPAL_TESTING_SELENIUM_PORT}" --url-base=/wd/hub &
            wait_for_port "${DRUPAL_TESTING_SELENIUM_HOST}" "${DRUPAL_TESTING_SELENIUM_PORT}"
        else
            download_chromedriver
            "${DRUPAL_TESTING_TEST_BASE_DIRECTORY}"/chromedriver --port="${DRUPAL_TESTING_SELENIUM_PORT}" --url-base=/wd/hub &
            wait_for_port "${DRUPAL_TESTING_SELENIUM_HOST}" "${DRUPAL_TESTING_SELENIUM_PORT}"
        fi
    fi

    if ! port_is_open "${DRUPAL_TESTING_HTTP_HOST}" "${DRUPAL_TESTING_HTTP_PORT}"; then
        cd "${docroot}" || exit
        php -S "${DRUPAL_TESTING_HTTP_HOST}":"${DRUPAL_TESTING_HTTP_PORT}" .ht.router.php >/dev/null 2>&1 &
        cd - || exit
        wait_for_port "${DRUPAL_TESTING_HTTP_HOST}" "${DRUPAL_TESTING_HTTP_PORT}" 30
    fi
}
