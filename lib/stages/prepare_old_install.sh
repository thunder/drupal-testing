#!/usr/bin/env bash

_stage_prepare_old_install() {
    local docroot
    docroot=$(get_distribution_docroot false)

    # When we test a full project, all we need is the project files itself.
    if [[ ${DRUPAL_TESTING_PROJECT_TYPE} != "drupal-profile" ]]; then
        printf "prepare_upgrade is only useful for profiles\n"
        exit 1
    fi

    # Checkout the profile and get the version we want to upgrade from.
    mkdir -p ${DRUPAL_TESTING_UPGRADE_DRUPAL_INSTALLATION_DIRECTORY}
    cp -R ${DRUPAL_TESTING_WORKSPACE} ${DRUPAL_TESTING_UPGRADE_DRUPAL_INSTALLATION_DIRECTORY}
    git -C ${DRUPAL_TESTING_UPGRADE_DRUPAL_INSTALLATION_DIRECTORY} checkout ${DRUPAL_TESTING_UPGRADE_VERSION}

    printf "Prepare composer.json\n\n"

    # Build is based on drupal project
    composer create-project "${DRUPAL_TESTING_COMPOSER_PROJECT}":"${DRUPAL_TESTING_UPGRADE_COMPOSER_PROJECT_VERSION}" "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}" --no-interaction --no-install

    composer config "minimum-stability" dev --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    composer config "prefer-stable" true --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"

    # Reorder repositories, to make sure, local path is first.
    composer config repositories.0 path "${DRUPAL_TESTING_UPGRADE_DRUPAL_INSTALLATION_DIRECTORY}" --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"

    jq '.repositories[0].options = {}' "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}""/composer.json" | awk 'BEGIN{RS="";getline<"-";print>ARGV[1]}' "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}""/composer.json"
    jq '.repositories[0].options.symlink = false' "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}""/composer.json" | awk 'BEGIN{RS="";getline<"-";print>ARGV[1]}' "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}""/composer.json"

    composer config repositories.1 composer https://asset-packagist.org --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    composer config repositories.2 composer https://packages.drupal.org/8 --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"

    # Enable patching
    composer require cweagans/composer-patches --no-update --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    composer config extra.enable-patching true --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"

    composer require drush/drush:${DRUSH_VERSION} --prefer-lowest --no-update --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"

    # Allow required plugins
    composer config allow-plugins.cweagans/composer-patches true --no-plugins --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    composer config allow-plugins.drupal/core-composer-scaffold true --no-plugins --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    composer config allow-plugins.drupal/core-project-message true --no-plugins --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    composer config allow-plugins.composer/installers true --no-plugins --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    composer config allow-plugins.oomphinc/composer-installers-extender true --no-plugins --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    composer config allow-plugins.dealerdirect/phpcodesniffer-composer-installer true --no-plugins --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    composer config allow-plugins.phpstan/extension-installer true --no-plugins --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"

    # Install the lowest versions of everything.
    composer install --prefer-lowest --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
}
