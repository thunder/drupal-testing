#!/usr/bin/env bash

# Test coding styles
_stage_coding_style() {
    if ! ${DRUPAL_TESTING_TEST_CODING_STYLES}; then
        return
    fi

    if ${DRUPAL_TESTING_TEST_PHP}; then
        __test_php_coding_styles
    fi

    if ${DRUPAL_TESTING_TEST_JAVASCRIPT}; then
        __test_javascript_coding_styles
    fi
}

__test_php_coding_styles() {
    printf "Checking php coding styles\n\n"

    phpcs -ps --standard=Drupal --extensions=php,module,inc,install,test,profile,theme --ignore="${DRUPAL_TESTING_PHPCS_IGNORE_PATTERN}" .
    phpcs -ps --standard=DrupalPractice --extensions=php,module,inc,install,test,profile,theme --ignore="${DRUPAL_TESTING_PHPCS_IGNORE_PATTERN}" .
}

__test_javascript_coding_styles() {
    if ! [[ -f .eslintrc ]]; then
        printf "%sNo .eslintrc file found. Skipping javascript coding style test.%s\n\n" "${YELLOW}" "${TRANSPARENT}"
        return
    fi

    printf "Checking javascript coding styles\n\n"

    if ! [[ -x "$(command -v npm)" ]]; then
        printf "npm not found, please install npm to test javascript coding styles\n"
        return
    fi

    if ! [[ -x "$(command -v eslint)" ]]; then
        npm install -g eslint
    fi

    # Install ESLint requirements
    if [[ $(npm list -g | grep -c eslint-config-drupal-bundle) -eq 0 ]]; then
        npm install -g eslint-config-drupal-bundle
    fi

    eslint .
}
