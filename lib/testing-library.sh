#!/usr/bin/env bash

get_distribution_docroot() {
    case ${DISTRIBUTION} in
        "thunder")
            docroot="docroot"
        ;;
        *)
            docroot="web"
    esac

    echo ${docroot}
}

get_composer_bin_dir() {
    if [ ! -f ${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/composer.json ]; then
        echo "${DISTRIBUTION} was not installed correctly, please run create-project first."
        exit 1
    fi

    local composer_bin_dir=${THUNDER_TRAVIS_COMPOSER_BIN_DIR:-$(jq -er '.config."bin-dir" // "vendor/bin"' ${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/composer.json)}

    echo ${composer_bin_dir}
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
    COMPOSER_MEMORY_LIMIT=-1 composer install --working-dir=${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
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

    composer require webflo/drupal-core-require-dev:${THUNDER_TRAVIS_DRUPAL_VERSION} --dev --no-update --working-dir=${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}

    require_local_project
    composer_install
}

install_project() {
    local distribution=${1-"drupal"}
    local composer_bin_dir=$(get_composer_bin_dir)
    local drush="${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${composer_bin_dir}/drush  --root=${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/$(get_distribution_docroot)"
    local profile=""
    local additional_drush_parameter=""

    if [ ! -f ${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/$(get_distribution_docroot)/index.php ]; then
        echo "${distribution} was not installed correctly, please run create-project first."
        exit 1
    fi

    case ${distribution} in
        "drupal")
            profile="minimal"
        ;;
        "thunder")
            profile="thunder"
            additional_drush_parameter="thunder_module_configure_form.install_modules_thunder_demo=NULL"
        ;;
    esac

    mysql -e "CREATE DATABASE IF NOT EXISTS ${THUNDER_TRAVIS_MYSQL_DATABASE};"

    /usr/bin/env PHP_OPTIONS="-d sendmail_path=$(which true)" ${drush} site-install ${profile} --db-url=${SIMPLETEST_DB}  --yes additional_drush_parameter
    ${drush} pm-enable simpletest
}

start_services() {
    local docroot=${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/$(get_distribution_docroot)

    if [ ! -f ${docroot}/index.php ]; then
        echo "${distribution} was not installed correctly, please run create-project first."
        exit 1
    fi

    cd ${docroot}

    php -S ${THUNDER_TRAVIS_HOST}:${THUNDER_TRAVIS_HTTP_PORT} .ht.router.php &>/dev/null &
    nc -z -w 20 ${THUNDER_TRAVIS_HOST} ${THUNDER_TRAVIS_HTTP_PORT}

    cd ${THUNDER_TRAVIS_PROJECT_BASEDIR}

    docker run -d -v ${THUNDER_TRAVIS_PROJECT_BASEDIR}:/project --shm-size 256m --net=host selenium/standalone-chrome:${THUNDER_TRAVIS_SELENIUM_CHROME_VERSION}
}

run_tests() {
    local test_selection
    local docroot=$(get_distribution_docroot)
    local composer_bin_dir=$(get_composer_bin_dir)
    local phpunit=${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${composer_bin_dir}/phpunit
    local settings_file=${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${docroot}/sites/default/settings.php

    if [ ! -f ${phpunit} ]; then
        echo "${DISTRIBUTION} was not installed correctly, please run create-project first."
        exit 1
    fi

    if ! nc -z ${THUNDER_TRAVIS_HOST} ${THUNDER_TRAVIS_HTTP_PORT} 2>/dev/null; then
        echo "The web server has not been started."
        exit 1
    fi

    if [ ${THUNDER_TRAVIS_TEST_GROUP} ]; then
       test_selection="--group ${THUNDER_TRAVIS_TEST_GROUP}"
    fi

    php ${phpunit} --verbose -c ${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${docroot}/core ${test_selection} || exit 1
}
