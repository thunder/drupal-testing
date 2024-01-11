#!/usr/bin/env bash

_stage_prepare_build() {
    local docroot
    docroot=$(get_distribution_docroot false)

    # When we test a full project, all we need is the project files itself.
    if [[ ${DRUPAL_TESTING_PROJECT_TYPE} == "project" ]]; then
        rsync --archive --exclude=".git" "${DRUPAL_TESTING_PROJECT_BASEDIR}"/ "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
        return
    fi

    printf "Prepare composer.json\n\n"

    # Build is based on drupal project
    composer create-project "${DRUPAL_TESTING_COMPOSER_PROJECT}":"${DRUPAL_TESTING_COMPOSER_PROJECT_VERSION}" "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}" --no-interaction --no-install

    composer config "minimum-stability" dev --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    composer config "prefer-stable" true --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"

    if [[ ${DRUPAL_TESTING_PROJECT_TYPE} != "drupal-profile" ]]; then
      composer require drupal/core:"${DRUPAL_TESTING_DRUPAL_VERSION}" --no-update --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
      composer require drupal/core-dev:"${DRUPAL_TESTING_DRUPAL_VERSION}" --dev --no-update --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
      composer require drupal/core-recommended:"${DRUPAL_TESTING_DRUPAL_VERSION}" --no-update --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    fi

    # Add asset-packagist for projects, that require frontend assets
    if ! composer_repository_exists "https://asset-packagist.org"; then
        composer config extra."installer-types".0 bower-asset --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
        composer config extra."installer-types".1 npm-asset --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"

        jq '.extra."installer-paths"."'"${docroot}"'/libraries/{$name}" += ["type:bower-asset", "type:npm-asset"]' "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}""/composer.json" >"${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}""/composer.tmp"
        mv "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}""/composer.tmp" "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}""/composer.json"

        composer require oomphinc/composer-installers-extender --no-update --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    fi

    composer require drush/drush:"^11.2.0" --no-update --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    composer require phpspec/prophecy-phpunit:^2 --dev --no-update --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"

    # Require phpstan.
    if [ "${DRUPAL_TESTING_TEST_DEPRECATION}" = true ]; then
        composer require mglaman/phpstan-drupal:^1.1 --dev --no-update --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
        composer require phpstan/phpstan-deprecation-rules:^1.0 --dev --no-update --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    fi

    # Paratest.
    if [ "${DRUPAL_TESTING_PARALLEL_TESTING}" = true ]; then
        composer require brianium/paratest:^6.3 --dev --no-update --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    fi

    # Reorder repositories, to make sure, local path is first.
    composer config repositories.0 path "${DRUPAL_TESTING_PROJECT_BASEDIR}" --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"

    jq '.repositories[0].options = {}' "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}""/composer.json" | awk 'BEGIN{RS="";getline<"-";print>ARGV[1]}' "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}""/composer.json"
    jq '.repositories[0].options.symlink = false' "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}""/composer.json" | awk 'BEGIN{RS="";getline<"-";print>ARGV[1]}' "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}""/composer.json"

    composer config repositories.1 composer https://asset-packagist.org --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    composer config repositories.2 composer https://packages.drupal.org/8 --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"

    # Enable patching
    composer require cweagans/composer-patches --no-update --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    composer config extra.enable-patching true --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"

    # Use jq to find all dev dependencies of the project and add them to root composer file.
    for dev_dependency in $(jq -r '.["require-dev"?] | keys[] as $k | "\($k):\(.[$k])"' "${DRUPAL_TESTING_PROJECT_BASEDIR}"/composer.json); do
        composer require "${dev_dependency}" --dev --no-update --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    done

    # Allow required plugins
    composer config allow-plugins.cweagans/composer-patches true --no-plugins --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    composer config allow-plugins.drupal/core-composer-scaffold true --no-plugins --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    composer config allow-plugins.drupal/core-project-message true --no-plugins --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    composer config allow-plugins.composer/installers true --no-plugins --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    composer config allow-plugins.oomphinc/composer-installers-extender true --no-plugins --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    composer config allow-plugins.dealerdirect/phpcodesniffer-composer-installer true --no-plugins --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    composer config allow-plugins.phpstan/extension-installer true --no-plugins --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
}
