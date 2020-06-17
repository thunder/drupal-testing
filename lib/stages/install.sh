#!/usr/bin/env bash

_stage_install() {

    printf "Installing project\n\n"

    local docroot
    local composer_bin_dir
    local drush
    local installed_version
    local major_version
    local minor_version

    docroot=$(get_distribution_docroot)
    composer_bin_dir=$(get_composer_bin_directory)
    drush="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}/${composer_bin_dir}/drush  --root=${docroot}"

    cd "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}" || exit
    installed_version=$(composer show 'drupal/core' | grep 'versions' | grep -o -E '[^ ]+$')
    major_version="$(cut -d'.' -f1 <<<"${installed_version}")"
    minor_version="$(cut -d'.' -f2 <<<"${installed_version}")"
    cd - || exit

    # Copy default settings and append config sync directory.
    local sites_directory="${docroot}/sites/default"
    cp "${sites_directory}/default.settings.php" "${sites_directory}/settings.php"
    if [[ ${major_version} -gt 8 ]] || [[ ${minor_version} -gt 7 ]]; then
        echo "\$settings['config_sync_directory'] = '${DRUPAL_TESTING_CONFIG_SYNC_DIRECTORY}';" >>"${sites_directory}/settings.php"
    else
        echo "\$config_directories = [ CONFIG_SYNC_DIRECTORY => '${DRUPAL_TESTING_CONFIG_SYNC_DIRECTORY}' ];" >>"${sites_directory}/settings.php"
    fi


    if ${DRUPAL_TESTING_INSTALL_FROM_CONFIG} = true; then
        ${drush} --verbose --db-url="${SIMPLETEST_DB}" --yes --existing-config site-install
    else
        ${drush} --verbose --db-url="${SIMPLETEST_DB}" --yes site-install "${DRUPAL_TESTING_TEST_PROFILE}" "${DRUPAL_TESTING_INSTALLATION_FORM_VALUES}"
    fi
}
