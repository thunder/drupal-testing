#!/usr/bin/env bash

### Helper functions ###

stage_exists() {
    declare -f -F _stage_${1} > /dev/null
    return ${?}
}

stage_dependency() {
    declare -A deps=(
        [run_tests]="install_project"
        [install_project]="start_services"
        [start_services]="build_project"
        [build_project]="test_coding_style"
        [test_coding_style]="prepare_environment"
    )
    echo ${deps[${1}]}
}

get_distribution_docroot() {
    case ${THUNDER_TRAVIS_DISTRIBUTION} in
        "thunder")
            docroot="docroot"
        ;;
        *)
            docroot="web"
    esac

    echo ${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${docroot}
}

get_composer_bin_dir() {
    if [ ! -f ${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/composer.json ]; then
        exit 1
    fi

    local composer_bin_dir=${THUNDER_TRAVIS_COMPOSER_BIN_DIR:-$(jq -er '.config."bin-dir" // "vendor/bin"' ${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/composer.json)}

    echo ${composer_bin_dir}
}

require_local_project() {
    composer config repositories.0 path ${THUNDER_TRAVIS_PROJECT_BASEDIR} --working-dir=${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    composer config repositories.1 composer https://packages.drupal.org/8 --working-dir=${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    composer require ${THUNDER_TRAVIS_COMPOSER_NAME} *@dev --no-update --working-dir=${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
}

composer_install() {
    COMPOSER_MEMORY_LIMIT=-1 composer install --working-dir=${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
}

create_drupal_project() {
    composer create-project drupal-composer/drupal-project:8.x-dev ${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY} --stability dev --no-interaction --no-install
    composer config repositories.assets composer https://asset-packagist.org --working-dir=${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    composer require drupal/core:${THUNDER_TRAVIS_DRUPAL_VERSION} --no-update --working-dir=${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
}

create_thunder_project() {
    composer create-project burdamagazinorg/thunder-project ${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY} --stability dev --no-interaction --no-install
    composer require burdamagazinorg/thunder:${THUNDER_TRAVIS_THUNDER_VERSION} --no-update --working-dir=${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
}

move_assets() {
    local libraries=$(get_distribution_docroot)/libraries;
    mkdir ${libraries}

    if [ -d ${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/vendor/bower-asset ]; then
        mv ${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/vendor/bower-asset/* ${libraries}
    fi
    if [ -d ${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/vendor/npm-asset ]; then
        mv ${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/vendor/npm-asset/* ${libraries}
    fi
}

clean_up() {
    if [ ${THUNDER_TRAVIS_NO_CLEANUP} ]; then
        return
    fi

    docker rm -f -v selenium-for-tests

    chmod u+w -R ${THUNDER_TRAVIS_TEST_BASE_DIRECTORY}
    rm -rf ${THUNDER_TRAVIS_TEST_BASE_DIRECTORY}
}

stage_is_finished() {
    [ -f "${THUNDER_TRAVIS_LOCK_FILES_DIRECTORY}/${1}" ]
}

finish_stage() {
    local stage="${1}"

    if [ ! -d ${THUNDER_TRAVIS_LOCK_FILES_DIRECTORY} ]; then
        mkdir -p ${THUNDER_TRAVIS_LOCK_FILES_DIRECTORY}
    fi

    touch ${THUNDER_TRAVIS_LOCK_FILES_DIRECTORY}/${stage}
}

run_stage() {
    local stage="${1}"

    if stage_is_finished ${stage}; then
        return
    fi

    local dependency=$(stage_dependency ${stage})


    if [ ! -z ${dependency} ]; then
        run_stage ${dependency}
    fi

    # Call the stage function
    _stage_${stage}

    finish_stage ${stage}
}

### The stages. Do not run these directly, use run_stage() to invoke. ###

_stage_prepare_environment() {
    printf "Preparing environment\n\n"

    if [ -x "$(command -v phpenv)" ]; then
        phpenv config-rm xdebug.ini
        # Needed for php 5.6 only. When we drop 5.6 support, this can be removed.
        echo 'always_populate_raw_post_data = -1' >> drupal.php.ini
        phpenv config-add drupal.php.ini
        phpenv rehash
    fi
}

_stage_test_coding_style() {
    printf "Testing coding style\n\n"

    local check_parameters=""

    if ! [ -x "$(command -v eslint)" ]; then
        npm install -g eslint
    fi

    if [ ${THUNDER_TRAVIS_TEST_PHP} == 1 ]; then
        check_parameters="${check_parameters} --phpcs"
    fi

    if [ ${THUNDER_TRAVIS_TEST_JAVASCRIPT} == 1 ]; then
        check_parameters="${check_parameters} --javascript"
    fi

    bash check-guidelines.sh --init
    bash check-guidelines.sh -v ${check_parameters}

    # Propagate possible errors
    local exit_code=${?}
    if [ ${exit_code} -ne 0 ]; then
        exit ${exit_code}
    fi
}

_stage_build_project() {
    printf "Building project\n\n"

    case ${THUNDER_TRAVIS_DISTRIBUTION} in
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
    move_assets
}

_stage_start_services() {
    printf "Starting services\n\n"

    local drupal="core/scripts/drupal"
    local composer_bin_dir=$(get_composer_bin_dir)
    local drush="${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${composer_bin_dir}/drush  --root=$(get_distribution_docroot)"

    ${drush} runserver "http://${THUNDER_TRAVIS_HOST}:${THUNDER_TRAVIS_HTTP_PORT}" >/dev/null 2>&1  &
    nc -z -w 20 ${THUNDER_TRAVIS_HOST} ${THUNDER_TRAVIS_HTTP_PORT}

    docker run --detach --net host --name selenium-for-tests --volume /dev/shm:/dev/shm selenium/standalone-chrome:${THUNDER_TRAVIS_SELENIUM_CHROME_VERSION}
}

_stage_install_project() {
    printf "Installing project\n\n"

    local composer_bin_dir=$(get_composer_bin_dir)
    local drush="${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${composer_bin_dir}/drush  --root=$(get_distribution_docroot)"
    local profile=""
    local additional_drush_parameter=""

    case ${THUNDER_TRAVIS_DISTRIBUTION} in
        "drupal")
            profile="minimal"
        ;;
        "thunder")
            profile="thunder"
            additional_drush_parameter="thunder_module_configure_form.install_modules_thunder_demo=NULL"
        ;;
    esac

    PHP_OPTIONS="-d sendmail_path=$(which true)"
    ${drush} site-install ${profile} --db-url=${SIMPLETEST_DB} --yes additional_drush_parameter
    ${drush} pm-enable simpletest
}

_stage_run_tests() {
    printf "Running tests\n\n"

    local test_selection
    local docroot=$(get_distribution_docroot)
    local composer_bin_dir=$(get_composer_bin_dir)
    local phpunit=${THUNDER_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${composer_bin_dir}/phpunit
    local runtests=${docroot}/core/scripts/run-tests.sh
    local settings_file=${docroot}/sites/default/settings.php

    if [ ${THUNDER_TRAVIS_TEST_GROUP} ]; then
       test_selection="--group ${THUNDER_TRAVIS_TEST_GROUP}"
    fi

    case ${THUNDER_TRAVIS_TEST_RUNNER} in
        "phpunit")
            php ${phpunit} --verbose --debug --configuration ${docroot}/core ${test_selection} ${docroot}/modules/contrib/${THUNDER_TRAVIS_PROJECT_NAME} || exit 1
        ;;
        "run-tests")
            php ${runtests} --php $(which php) --suppress-deprecations --verbose --color --url http://${THUNDER_TRAVIS_HOST}:${THUNDER_TRAVIS_HTTP_PORT} ${THUNDER_TRAVIS_TEST_GROUP} || exit 1
        ;;
    esac

}
