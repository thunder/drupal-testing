#!/usr/bin/env bash

_stage_install() {

    printf "Installing project\n\n"

    local docroot
    local composer_bin_dir
    local drush

    docroot=$(get_distribution_docroot)
    composer_bin_dir=$(get_composer_bin_directory)
    drush="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}/${composer_bin_dir}/drush  --root=${docroot}"

    if ${DRUPAL_TESTING_INSTALL_FROM_CONFIG} = true; then
        ${drush} --verbose --db-url="${SIMPLETEST_DB}" --yes --existing-config site-install
    else
        ${drush} --verbose --db-url="${SIMPLETEST_DB}" --yes site-install "${DRUPAL_TESTING_TEST_PROFILE}" "${DRUPAL_TESTING_INSTALLATION_FORM_VALUES}"
    fi

    if [[ ${DRUPAL_TESTING_TEST_DUMP_FILE} != "" ]]; then
        cd "${docroot}" || exit
        php core/scripts/db-tools.php dump-database-d8-mysql >"${docroot}/${DRUPAL_TESTING_TEST_DUMP_FILE}"
        cd - || exit
    fi
}
