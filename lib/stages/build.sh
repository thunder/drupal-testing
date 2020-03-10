#!/usr/bin/env bash

# Build the project
_stage_build() {
    printf "Building the project.\n\n"

    local docroot
    local composer_arguments=""
    local installed_version
    local major_version
    local minor_version

    docroot=$(get_distribution_docroot)

    if ${DRUPAL_TESTING_MIN_BUILD}; then
        composer_arguments="--prefer-lowest"
    fi

    # Install all dependencies
    cd "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}" || exit
    composer update ${composer_arguments}

    installed_version=$(composer show 'drupal/core' | grep 'versions' | grep -o -E '[^ ]+$')
    major_version="$(cut -d'.' -f1 <<<"${installed_version}")"
    minor_version="$(cut -d'.' -f2 <<<"${installed_version}")"

    # Require core-dev based on installed core version
    composer require drupal/core-dev:"${installed_version}" --no-update
    composer update ${composer_arguments}

    # Back to previous directory.
    cd - || exit

    # Copy default settings and append config sync directory.
    local sites_directory="${docroot}/sites/default"
    cp "${sites_directory}/default.settings.php" "${sites_directory}/settings.php"
    if [[ ${major_version} -gt 8 ]] || [[ ${minor_version} -gt 7 ]]; then
        echo "\$settings['config_sync_directory'] = '${DRUPAL_TESTING_CONFIG_SYNC_DIRECTORY}';" >>"${sites_directory}/settings.php"
    else
        echo "\$config_directories = [ CONFIG_SYNC_DIRECTORY => '${DRUPAL_TESTING_CONFIG_SYNC_DIRECTORY}' ];" >>"${sites_directory}/settings.php"
    fi
}
