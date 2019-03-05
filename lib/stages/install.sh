#!/usr/bin/env bash

_stage_install() {
    printf "Installing project\n\n"

    local docroot=$(get_distribution_docroot)
    local composer_bin_dir=$(get_composer_bin_directory)
    local drush="${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${composer_bin_dir}/drush  --root=${docroot}}"

    PHP_OPTIONS="-d sendmail_path=$(which true)"

    if [[ ${DRUPAL_TRAVIS_PROJECT_TYPE} = "project" ]]; then
        ${drush} --verbose --db-url=${SIMPLETEST_DB} --existing-config --yes site-install
    else
        local profile="minimal"
        ${drush} -v --db-url=${SIMPLETEST_DB} --yes site-install ${profile}
    fi

    ${drush} pm-enable simpletest
}
