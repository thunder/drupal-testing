#!/usr/bin/env bash


_stage_run_tests() {
    printf "Running tests\n\n"

    local test_selection=""
    local docroot=$(get_distribution_docroot)
    local composer_bin_dir=$(get_composer_bin_directory)
    local phpunit=${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${composer_bin_dir}/phpunit
    local project_location=$(get_project_location)

    if [[ ${DRUPAL_TRAVIS_TEST_GROUP} ]]; then
       test_selection="--group ${DRUPAL_TRAVIS_TEST_GROUP}"
    fi

    php ${phpunit} --verbose --debug --configuration ${docroot}/core ${test_selection} ${project_location} || exit 1
}
