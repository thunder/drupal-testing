#!/usr/bin/env bash

_stage_prepare_upgrade() {
    local docroot
    docroot=$(get_distribution_docroot false)

    # When we test a full project, all we need is the project files itself.
    if [[ ${DRUPAL_TESTING_PROJECT_TYPE} != "drupal-profile" ]]; then
        printf "prepare_upgrade is only useful for profiles\n"
        exit 1
    fi

    printf "Prepare composer.json to upgrade to version under test\n\n"

    # Add asset-packagist for projects, that require frontend assets
    if ! composer_repository_exists "https://asset-packagist.org"; then
        composer config extra."installer-types".0 bower-asset --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
        composer config extra."installer-types".1 npm-asset --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"

        jq '.extra."installer-paths"."'"${docroot}"'/libraries/{$name}" += ["type:bower-asset", "type:npm-asset"]' "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}""/composer.json" >"${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}""/composer.tmp"
        mv "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}""/composer.tmp" "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}""/composer.json"

        composer require oomphinc/composer-installers-extender --no-update --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    fi

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

    # Set the path repository back to the project under test.
    composer config repositories.0 path "${DRUPAL_TESTING_PROJECT_BASEDIR}" --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"

    # Use jq to find all dev dependencies of the project and add them to root composer file.
    for dev_dependency in $(jq -r '.["require-dev"?] | keys[] as $k | "\($k):\(.[$k])"' "${DRUPAL_TESTING_PROJECT_BASEDIR}"/composer.json); do
        composer require "${dev_dependency}" --dev --no-update --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"
    done

    # Use the latest drush.
    composer require drush/drush --no-update --working-dir="${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}"

}
