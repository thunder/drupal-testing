#!/usr/bin/env bash

# Build the project
_stage_build() {
    printf "Building the project.\n\n"

    local docroot=$(get_distribution_docroot)
    local libraries=${docroot}/libraries

    # Install all dependencies
    cd ${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}
    composer update

    local installed_version=$(composer show 'drupal/core' | grep 'versions' | grep -o -E '[^ ]+$')
    local major_version="$(cut -d'.' -f1 <<<"${installed_version}")"
    local minor_version="$(cut -d'.' -f2 <<<"${installed_version}")"

    # When we are having Drupal 9 or if we are on at least Drupal 8.8, use core scaffold. Otherwise use the legacy scaffolding.
    if [[ "${major_version}" -gt 8 ]] || [[ "${minor_version}" -gt 7 ]]; then
        composer require drupal/core-composer-scaffold
    else
        composer require drupal-composer/drupal-scaffold
    fi
    composer drupal:scaffold

    # Back to previous directory.
    cd -

    # Copy default settings and append config sync directory.
    local sites_directory="${docroot}/sites/default"
    cp "${sites_directory}/default.settings.php" "${sites_directory}/settings.php"
    if [[ "${major_version}" -gt 8 ]] || [[ "${minor_version}" -gt 7 ]]; then
        echo "\$settings['config_sync_directory'] = '${DRUPAL_TESTING_CONFIG_SYNC_DIRECTORY}';" >>${sites_directory}/settings.php
    else
        echo "\$config_directories = [ CONFIG_SYNC_DIRECTORY => '${DRUPAL_TESTING_CONFIG_SYNC_DIRECTORY}' ];" >>${sites_directory}/settings.php
    fi
}
