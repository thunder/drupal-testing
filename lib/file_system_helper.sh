#!/usr/bin/env bash

# Parameter is optional shellcheck disable=SC2120
get_distribution_docroot() {
    local absolute=${1:-true}
    local docroot="web"

    if [[ ${DRUPAL_TESTING_COMPOSER_PROJECT} =~ ^(thunder|BurdaMagazinOrg)/thunder-project.* ]]; then
        docroot="docroot"
    fi

    if [[ ${DRUPAL_TESTING_DOCROOT} != "" ]]; then
        docroot="${DRUPAL_TESTING_DOCROOT}"
    fi

    if ${absolute}; then
        echo "${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY}/${docroot}"
    else
        echo "${docroot}"
    fi
}

get_project_location() {
    local docroot
    local project_type_test_location=""

    docroot=$(get_distribution_docroot true)

    if [[ ${DRUPAL_TESTING_TEST_LOCATION} != "" ]]; then
        project_type_test_location="${docroot}/${DRUPAL_TESTING_TEST_LOCATION}"
    else
        case ${DRUPAL_TESTING_PROJECT_TYPE} in
        drupal-module)
            project_type_test_location="${docroot}/modules/contrib/${DRUPAL_TESTING_PROJECT_NAME}"
            ;;
        drupal-profile)
            project_type_test_location="${docroot}/profiles/contrib/${DRUPAL_TESTING_PROJECT_NAME}"
            ;;
        drupal-theme)
            project_type_test_location="${docroot}/themes/contrib/${DRUPAL_TESTING_PROJECT_NAME}"
            ;;
        *)
            project_type_test_location="${docroot}"
            ;;
        esac
    fi
    echo "${project_type_test_location}"
}
