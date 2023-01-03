#!/usr/bin/env bash

_stage_install() {

    printf "Installing project\n\n"

    local docroot
    local drush
    local installed_version
    local major_version
    local minor_version

    docroot=$(get_distribution_docroot)
    drush="composer exec -- drush --root=${docroot}"

    cd "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}" || exit
    installed_version=$(composer show 'drupal/core' | grep 'versions' | grep -o -E '[^ ]+$')
    major_version="$(cut -d'.' -f1 <<<"${installed_version}")"
    minor_version="$(cut -d'.' -f2 <<<"${installed_version}")"
    cd - || exit

    # Copy default settings and append config sync directory.
    local sites_directory="${docroot}/sites/${DRUPAL_TESTING_SITES_DIRECTORY}"
    cp "${docroot}/sites/default/default.settings.php" "${sites_directory}/settings.php"
    echo "\$settings['skip_permissions_hardening'] = TRUE;" >> "${sites_directory}/settings.php"
    if [[ ${major_version} -gt 8 ]] || [[ ${minor_version} -gt 7 ]]; then
        echo "\$settings['config_sync_directory'] = '${DRUPAL_TESTING_CONFIG_SYNC_DIRECTORY}';" >>"${sites_directory}/settings.php"
    else
        echo "\$config_directories = [ CONFIG_SYNC_DIRECTORY => '${DRUPAL_TESTING_CONFIG_SYNC_DIRECTORY}' ];" >>"${sites_directory}/settings.php"
    fi

    cd "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}" || exit
    if [ "${DRUPAL_TESTING_INSTALL_FROM_CONFIG}" = true ]; then
        ${drush} --verbose --db-url="${SIMPLETEST_DB}" --sites-subdir="${DRUPAL_TESTING_SITES_DIRECTORY}" --yes --existing-config site-install
    else
        ${drush} --verbose --db-url="${SIMPLETEST_DB}" --sites-subdir="${DRUPAL_TESTING_SITES_DIRECTORY}" --yes site-install "${DRUPAL_TESTING_TEST_PROFILE}" "${DRUPAL_TESTING_INSTALLATION_FORM_VALUES}"
    fi
    cd - || exit

    cd "${docroot}" || exit
    if [[ ${DRUPAL_TESTING_TEST_DUMP_FILE} == *.php  ]]; then
        php core/scripts/db-tools.php dump-database-d8-mysql --database-url "${SIMPLETEST_DB}" >"${docroot}/${DRUPAL_TESTING_TEST_DUMP_FILE}"
    elif [[ ${DRUPAL_TESTING_TEST_DUMP_FILE} == *.tar.gz ]]; then
        php core/scripts/db-tools.php dump-database-d8-mysql --database-url "${SIMPLETEST_DB}" >"sites/default/database-dump.php"
        # Gzip sites/default files directory but exclude config_*, php and styles directories.
        tar -czf "${docroot}/${DRUPAL_TESTING_TEST_DUMP_FILE}" --exclude='config_*' --exclude='php' --exclude='styles' --directory='sites/default' files database-dump.php
    fi
    cd - || exit

}
