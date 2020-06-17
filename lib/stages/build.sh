#!/usr/bin/env bash

# Build the project
_stage_build() {
    printf "Building the project.\n\n"

    local docroot
    local installed_version
    local major_version
    
    docroot=$(get_distribution_docroot)

    # Install all dependencies
    cd "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}" || exit

    if ${DRUPAL_TESTING_MIN_BUILD}; then
        composer update --prefer-lowest
    else 
        composer install
    fi

    # We can cleanup the name change now.
    composer config name "${DRUPAL_TESTING_COMPOSER_NAME}" --working-dir="${DRUPAL_TESTING_PROJECT_BASEDIR}"

    installed_version=$(composer show 'drupal/core' | grep 'versions' | grep -o -E '[^ ]+$')
    major_version="$(cut -d'.' -f1 <<<"${installed_version}")"

    # Back to previous directory.
    cd - || exit

    if [[ ${major_version} -gt 8 ]]; then
        # Apply core patch
        cd "${docroot}" || exit
        wget https://www.drupal.org/files/issues/2020-06-08/3143604-8_0.patch
        patch -p1 < 3143604-8_0.patch
        cd - || exit
    fi

}
