#!/usr/bin/env bash

### Helper functions ###

stage_exists() {
    declare -f -F _stage_${1} > /dev/null
    return ${?}
}

stage_dependency() {
    declare -A deps=(
        [run_tests]="start_web_server"
        [start_web_server]="install"
        [install]="build"
        [build]="coding_style"
        [coding_style]="prepare"
    )
    echo ${deps[${1}]}
}

function port_is_open() {
	local host=${1}
	local port=${2}

    $(nc -z "${host}" "${port}")
}

function wait_for_port() {
	local host=${1}
	local port=${2}
	local max_count=${3:-10}

	local count=1

	until port_is_open ${host} ${port}; do
		sleep 1
		if [ ${count} -gt ${max_count} ]
		then
			printf "Error: Timeout while waiting for port ${port} on host ${host}.\n" 1>&2
			exit 1
		fi
		count=$[count+1]
	done
}

# Test docker container health status
function get_container_health {
    docker inspect --format "{{json .State.Health.Status }}" $1
}

# Wait till docker container is fully started
function wait_for_container {
    local container=${1}
    printf "Waiting for container ${container}."
    while local status=$(get_container_health ${container}); [ ${status} != "\"healthy\"" ]; do
        if [ ${status} == "\"unhealthy\"" ]; then
            printf "Container ${container} failed to start. \n"
            exit 1
        fi
        printf "."
        sleep 1
    done
    printf " Container started!\n"
}

# This has currently no real meaning, but will be necessary, once we test with thunder_project.
# thunder_project builds into docroot instead of web.
get_distribution_docroot() {
    local docroot="web"

    if [ ${DRUPAL_TRAVIS_DISTRIBUTION} = "thunder" ]; then
        docroot="docroot"
    fi

    echo ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${docroot}
}

get_composer_bin_dir() {
    if [ ! -f ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/composer.json ]; then
        exit 1
    fi

    local composer_bin_dir=${DRUPAL_TRAVIS_COMPOSER_BIN_DIR:-$(jq -er '.config."bin-dir" // "vendor/bin"' ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/composer.json)}

    echo ${composer_bin_dir}
}

require_local_project() {
    composer config repositories.0 path ${DRUPAL_TRAVIS_PROJECT_BASEDIR} --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    composer config repositories.1 composer https://packages.drupal.org/8 --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    composer require ${DRUPAL_TRAVIS_COMPOSER_NAME} *@dev --no-update --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
}

composer_install() {
    COMPOSER_MEMORY_LIMIT=-1 composer install --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
}

create_drupal_project() {
    composer create-project drupal-composer/drupal-project:8.x-dev ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY} --stability dev --no-interaction --no-install
    composer config repositories.assets composer https://asset-packagist.org --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    composer require drupal/core:${DRUPAL_TRAVIS_DRUPAL_VERSION} --no-update --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
}

move_assets() {
    local libraries=$(get_distribution_docroot)/libraries;
    mkdir ${libraries}

    if [ -d ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/vendor/bower-asset ]; then
        mv ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/vendor/bower-asset/* ${libraries}
    fi
    if [ -d ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/vendor/npm-asset ]; then
        mv ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/vendor/npm-asset/* ${libraries}
    fi
}

clean_up() {
    if [ ${DRUPAL_TRAVIS_NO_CLEANUP} ]; then
        return
    fi

    docker rm -f -v selenium-for-tests

    chmod u+w -R ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    rm -rf ${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}
    rm -rf ${DRUPAL_TRAVIS_LOCK_FILES_DIRECTORY}
    rmdir ${DRUPAL_TRAVIS_TEST_BASE_DIRECTORY}
}

stage_is_finished() {
    [ -f "${DRUPAL_TRAVIS_LOCK_FILES_DIRECTORY}/${1}" ]
}

finish_stage() {
    local stage="${1}"

    if [ ! -d ${DRUPAL_TRAVIS_LOCK_FILES_DIRECTORY} ]; then
        mkdir -p ${DRUPAL_TRAVIS_LOCK_FILES_DIRECTORY}
    fi

    touch ${DRUPAL_TRAVIS_LOCK_FILES_DIRECTORY}/${stage}
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

_stage_prepare() {
    printf "Preparing environment\n\n"

    if  ! port_is_open ${DRUPAL_TRAVIS_SELENIUM_HOST} ${DRUPAL_TRAVIS_SELENIUM_PORT} ; then
        printf "Starting selenium\n"
        docker run --detach --net host --name selenium-for-tests --volume /dev/shm:/dev/shm selenium/standalone-chrome:${DRUPAL_TRAVIS_SELENIUM_CHROME_VERSION}
        wait_for_port ${DRUPAL_TRAVIS_SELENIUM_HOST} ${DRUPAL_TRAVIS_SELENIUM_PORT}
    fi

    if  ! port_is_open ${DRUPAL_TRAVIS_DATABASE_HOST} ${DRUPAL_TRAVIS_DATABASE_PORT} ; then
        printf "Starting database\n"
        if [ ${DRUPAL_TRAVIS_DATABASE_PASSWORD} ]; then
            docker run --detach --publish ${DRUPAL_TRAVIS_DATABASE_PORT}:3306 --name database-for-tests --env "MYSQL_USER=${DRUPAL_TRAVIS_DATABASE_USER}" --env "MYSQL_PASSWORD=${DRUPAL_TRAVIS_DATABASE_PASSWORD}" --env "MYSQL_DATABASE=${DRUPAL_TRAVIS_DATABASE_NAME}" --env "MYSQL_ALLOW_EMPTY_PASSWORD=true" mysql/mysql-server:5.7
            wait_for_container database-for-tests
        else
            printf "No database password given. The docker container can only be started, when the environment variable DRUPAL_TRAVIS_DATABASE_PASSWORD is set to an non empty value\n"
            exit 1
        fi
    fi

    if [ -x "$(command -v phpenv)" ]; then
        printf "Configure php\n"
        phpenv config-rm xdebug.ini
        # Needed for php 5.6 only. When we drop 5.6 support, this can be removed.
        echo 'always_populate_raw_post_data = -1' >> drupal.php.ini
        phpenv config-add drupal.php.ini
        phpenv rehash
    fi
}

_stage_coding_style() {
    if ! ${DRUPAL_TRAVIS_TEST_CODING_STYLES}; then
        return
    fi

    local check_parameters=""

    if ! [ -x "$(command -v eslint)" ]; then
        npm install -g eslint
    fi

    if ${DRUPAL_TRAVIS_TEST_PHP}; then
        check_parameters="${check_parameters} --phpcs"
    fi

    if ${DRUPAL_TRAVIS_TEST_JAVASCRIPT}; then
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

_stage_build() {
    printf "Building project\n\n"

    if [ ${TRAVIS} ]; then
        composer global require hirak/prestissimo
    fi

    create_drupal_project

    composer require webflo/drupal-core-require-dev:${DRUPAL_TRAVIS_DRUPAL_VERSION} --dev --no-update --working-dir=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}

    require_local_project
    composer_install
    move_assets
}

_stage_install() {
    printf "Installing project\n\n"

    local composer_bin_dir=$(get_composer_bin_dir)
    local drush="${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${composer_bin_dir}/drush  --root=$(get_distribution_docroot)"
    local profile="minimal"
    local additional_drush_parameter=""

    PHP_OPTIONS="-d sendmail_path=$(which true)"
    ${drush} site-install ${profile} --db-url=${SIMPLETEST_DB} --yes additional_drush_parameter
    ${drush} pm-enable simpletest
}

_stage_start_web_server() {
    printf "Starting web server\n\n"

    local drupal="core/scripts/drupal"
    local composer_bin_dir=$(get_composer_bin_dir)
    local docroot=$(get_distribution_docroot)
    local drush="${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${composer_bin_dir}/drush  --root=${docroot}"


    if  ! port_is_open ${DRUPAL_TRAVIS_HTTP_HOST} ${DRUPAL_TRAVIS_HTTP_PORT} ; then
        ${drush} runserver "http://${DRUPAL_TRAVIS_HTTP_HOST}:${DRUPAL_TRAVIS_HTTP_PORT}" >/dev/null 2>&1 &
        wait_for_port ${DRUPAL_TRAVIS_HTTP_HOST} ${DRUPAL_TRAVIS_HTTP_PORT}
    fi
}

_stage_run_tests() {
    printf "Running tests\n\n"

    local test_selection
    local docroot=$(get_distribution_docroot)
    local composer_bin_dir=$(get_composer_bin_dir)
    local phpunit=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${composer_bin_dir}/phpunit
    local runtests=${docroot}/core/scripts/run-tests.sh
    local settings_file=${docroot}/sites/default/settings.php

    if [ ${DRUPAL_TRAVIS_TEST_GROUP} ]; then
       test_selection="--group ${DRUPAL_TRAVIS_TEST_GROUP}"
    fi

    case ${DRUPAL_TRAVIS_TEST_RUNNER} in
        "phpunit")
            php ${phpunit} --verbose --debug --configuration ${docroot}/core ${test_selection} ${docroot}/modules/contrib/${DRUPAL_TRAVIS_PROJECT_NAME} || exit 1
        ;;
        "run-tests")
            php ${runtests} --php $(which php) --suppress-deprecations --verbose --color --url http://${DRUPAL_TRAVIS_HTTP_HOST}:${DRUPAL_TRAVIS_HTTP_PORT} ${DRUPAL_TRAVIS_TEST_GROUP} || exit 1
        ;;
    esac

}
