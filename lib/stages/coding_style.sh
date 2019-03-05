#!/usr/bin/env bash

# Test coding styles
_stage_coding_style() {
    if ! ${DRUPAL_TRAVIS_TEST_CODING_STYLES}; then
        return
    fi

    if ${DRUPAL_TRAVIS_TEST_PHP}; then
        __test_php_coding_styles
    fi

    if ${DRUPAL_TRAVIS_TEST_JAVASCRIPT}; then
        __test_javascript_coding_styles
    fi
}

__test_php_coding_styles() {
    printf "Checking php coding styles\n\n"

    phpcs -p --standard=Drupal --extensions=php,module,inc,install,test,profile,theme --ignore=${DRUPAL_TRAVIS_PHPCS_IGNORE_PATTERN} .
    phpcs -p --standard=DrupalPractice --extensions=php,module,inc,install,test,profile,theme --ignore=${DRUPAL_TRAVIS_PHPCS_IGNORE_PATTERN} .
}

__test_javascript_coding_styles() {
        if ! [[ -f .eslintrc ]]; then
            printf "${YELLOW}No .eslintrc file found. Skipping javascript coding style test.${TRANSPARENT}\n\n"
            return;
        fi

        printf "Checking javascript coding styles\n\n"

        if ! [[ -x "$(command -v eslint)" ]]; then
            npm install -g eslint
        fi

        eslint .
}
