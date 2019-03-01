#!/usr/bin/env bash

_stage_install() {
    printf "Installing project\n\n"

    local composer_bin_dir=$(get_composer_bin_directory)
    local drush="${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}/${composer_bin_dir}/drush  --root=$(get_distribution_docroot)"
    local profile="minimal"

    PHP_OPTIONS="-d sendmail_path=$(which true)"
    ${drush} site-install ${profile} -v --db-url=${SIMPLETEST_DB} --yes
    ${drush} pm-enable simpletest
}
