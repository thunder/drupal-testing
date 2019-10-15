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
    local phpunit=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${composer_bin_dir}/phpunit

    if [[ ${DRUPAL_TRAVIS_TEST_GROUP} ]]; then
       test_selection="--group ${DRUPAL_TRAVIS_TEST_GROUP}"
    fi

    if [[ ${DRUPAL_TRAVIS_TEST_FILTER} ]]; then
       test_selection="${test_selection} --filter ${DRUPAL_TRAVIS_TEST_FILTER}"
    fi

    local runtest="php ${phpunit} --verbose --debug --configuration ${docroot}/core ${test_selection} ${project_location}"

    eval "${runtest}" || exit 1
}
