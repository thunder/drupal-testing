#!/usr/bin/env bash

# Setup the environment, and start services
_stage_setup() {
    printf "Setup environment\n\n"

    if  ! port_is_open ${DRUPAL_TRAVIS_SELENIUM_HOST} ${DRUPAL_TRAVIS_SELENIUM_PORT} ; then
        printf "Starting web driver\n"
        if ${TRAVIS} = true; then
            docker run --detach --net host --name ${DRUPAL_TRAVIS_SELENIUM_DOCKER_NAME} --volume /dev/shm:/dev/shm selenium/standalone-chrome:${DRUPAL_TRAVIS_SELENIUM_CHROME_VERSION}
        else
            chromedriver --port=${DRUPAL_TRAVIS_SELENIUM_PORT} &
        fi
        wait_for_port ${DRUPAL_TRAVIS_SELENIUM_HOST} ${DRUPAL_TRAVIS_SELENIUM_PORT}
    fi

    if  ! port_is_open ${DRUPAL_TRAVIS_DATABASE_HOST} ${DRUPAL_TRAVIS_DATABASE_PORT} ; then
        printf "Starting database\n"
        # We start a docker container, they need a password set so we set one now if none was given.
        # We do not generally provide a default password, because already running database instances might have no
        # password. This is e.g. the case for the default travis database.
        local docker_database_password=${DRUPAL_TRAVIS_DATABASE_PASSWORD:-123456}
        docker run --detach --publish ${DRUPAL_TRAVIS_DATABASE_PORT}:3306 --name ${DRUPAL_TRAVIS_DATABASE_DOCKER_NAME} --env "MYSQL_USER=${DRUPAL_TRAVIS_DATABASE_USER}" --env "MYSQL_PASSWORD=${docker_database_password}" --env "MYSQL_DATABASE=${DRUPAL_TRAVIS_DATABASE_NAME}" --env "MYSQL_ALLOW_EMPTY_PASSWORD=true" mysql/mysql-server:5.7
        wait_for_container ${DRUPAL_TRAVIS_DATABASE_DOCKER_NAME}
    fi

    if [[ -x "$(command -v phpenv)" ]]; then
        printf "Configure php\n"
        phpenv config-rm xdebug.ini || true
    fi
}
