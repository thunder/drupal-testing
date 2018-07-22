#!/usr/bin/env bash

distribution_docroot() {
    case ${DISTRIBUTION} in
        "thunder")
            docroot="docroot"
        ;;
        *)
            docroot="web"
    esac

    echo ${docroot}
}

install_requirements() {
    if ! [ -x "$(command -v eslint)" ]; then
        npm install -g eslint
    fi
}

test_coding_style() {
    local check_parameters=""

    if [ ${THUNDER_TRAVIS_TEST_PHP} == 1 ]; then
        check_parameters="${check_parameters} --phpcs"
    fi

    if [ ${THUNDER_TRAVIS_TEST_JAVASCRIPT} == 1 ]; then
        check_parameters="${check_parameters} --javascript"
    fi

    bash check-guidelines.sh --init
    bash check-guidelines.sh -v ${check_parameters}

    if [ $? -ne 0 ]; then
        return $?
    fi
}

require_local_project() {
    composer config repositories.test_module '{"type": "path", "url": "'${THUNDER_TRAVIS_PROJECT_BASEDIR}'"}' --working-dir=${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    composer require ${THUNDER_TRAVIS_COMPOSER_NAME} --no-update --working-dir=${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
}

composer_install() {
    composer install --optimize-autoloader --apcu-autoloader --working-dir=${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
}

create_drupal_project() {
    composer create-project drupal-composer/drupal-project:8.x-dev ${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY} --stability dev --no-interaction --no-install
    composer require drupal/core:${THUNDER_TRAVIS_DRUPAL_VERSION} --no-update --working-dir=${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
}

create_thunder_project() {
    composer create-project burdamagazinorg/thunder-project ${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY} --stability dev --no-interaction --no-install
    composer require burdamagazinorg/thunder:${THUNDER_TRAVIS_THUNDER_VERSION} --no-update --working-dir=${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
}

create_project() {
    local distribution=${1-"drupal"}

    case ${distribution} in
        "drupal")
            create_drupal_project
        ;;
        "thunder")
            create_thunder_project
        ;;
    esac

    # The folder where composer puts binaries, the default value is read from the projects composer.json
    # TODO: I do not like this here, but we cannot know what the projects bin directory is in the environment.sh
    THUNDER_TRAVIS_COMPOSER_BIN_DIR=${THUNDER_TRAVIS_COMPOSER_BIN_DIR:-`jq -er '.config."bin-dir" // "vendor/bin"' ${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/composer.json`}

    composer require webflo/drupal-core-require-dev:${THUNDER_TRAVIS_DRUPAL_VERSION} --dev --no-update --working-dir=${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}

    require_local_project
    composer_install
}

install_project() {
    local distribution=${1-"drupal"}
    local profile=""

    case ${distribution} in
        "drupal")
            profile="minimal"
        ;;
        "thunder")
            profile="thunder"
        ;;
    esac

    cd ${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/$(distribution_docroot)

    php core/scripts/drupal install ${profile} --no-interaction
    ${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${THUNDER_TRAVIS_COMPOSER_BIN_DIR}/drush en simpletest

    cd ${THUNDER_TRAVIS_PROJECT_BASEDIR}
}

start_services() {
    cd ${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/$(distribution_docroot)

    php core/scripts/drupal server --suppress-login --host=${THUNDER_TRAVIS_SIMPLETEST_HOST} --port=${THUNDER_TRAVIS_SIMPLETEST_PORT} &
    timeout 30 sh -c 'until nc -z $0 $1; do sleep 1; done' ${THUNDER_TRAVIS_SIMPLETEST_HOST} ${THUNDER_TRAVIS_SIMPLETEST_PORT}

    cd ${THUNDER_TRAVIS_PROJECT_BASEDIR}

    docker run -d -v ${THUNDER_TRAVIS_PROJECT_BASEDIR}:/project --shm-size 256m --net=host selenium/standalone-chrome:${THUNDER_TRAVIS_SELENIUM_CHROME_VERSION}
}

run_tests() {
    local test_selection=""
    local docroot=$(distribution_docroot)

    if [ ${THUNDER_TRAVIS_TEST_GROUP} ]; then
        test_selection="--group ${THUNDER_TRAVIS_TEST_GROUP}"
    fi

    chmod u+w ${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${docroot}/sites/default
    chmod u+w ${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${docroot}/sites/default/settings.php
    rm ${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${docroot}/sites/default/settings.php

    php ${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${THUNDER_TRAVIS_COMPOSER_BIN_DIR}/phpunit --verbose -c ${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${docroot}/core ${test_selection}
}
