#!/usr/bin/env bash

# Build the project
_stage_build() {
    printf "Building the project.\n\n"

    local composer_arguments=""

    if ${DRUPAL_TESTING_MIN_BUILD}; then
        composer_arguments="--prefer-lowest"
    fi

    # require the project, we want to test. To make sure, that the local version is used, we rename the project first
    local testing_project_name=drupal-testing-"${DRUPAL_TESTING_COMPOSER_NAME}"
    composer config name "${testing_project_name}" --working-dir="${DRUPAL_TESTING_PROJECT_BASEDIR}"
    composer remove "${DRUPAL_TESTING_COMPOSER_NAME}" --no-update --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    composer require "${testing_project_name}:*" --no-update --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"

    # Install all dependencies
    cd "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}" || exit
    composer update ${composer_arguments}

    local installed_version
    local major_version
    local minor_version
    installed_version=$(composer show 'drupal/core' | grep 'versions' | grep -o -E '[^ ]+$')
    major_version="$(cut -d'.' -f1 <<<"${installed_version}")"
    minor_version="$(cut -d'.' -f2 <<<"${installed_version}")"
    if [[ ${major_version} -gt 8 ]]; then
        composer require phpspec/prophecy-phpunit:^2 --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
        # Apply core patch
        local docroot
        docroot=$(get_distribution_docroot)
        cd "${docroot}" || exit
        if [[ ${minor_version} -lt 3 ]]; then

          wget https://www.drupal.org/files/issues/2021-10-05/3240601%2B3240813-9.2.x.patch -O 3240601.patch
          patch -p1 < 3240601.patch

          wget https://www.drupal.org/files/issues/2021-11-03/3032275-78.patch
          patch -p1 < 3032275-78.patch
        fi
        cd - || exit
    fi


    # We can cleanup the name change now.
    composer config name "${DRUPAL_TESTING_COMPOSER_NAME}" --working-dir="${DRUPAL_TESTING_PROJECT_BASEDIR}"

    # Back to previous directory.
    cd - || exit
}
