#!/usr/bin/env bash

if  ${TRAVIS} = true ; then
    export MINK_DRIVER_ARGS_WEBDRIVER=${MINK_DRIVER_ARGS_WEBDRIVER-"[\"chrome\", null, \"http://${DRUPAL_TRAVIS_SELENIUM_HOST}:${DRUPAL_TRAVIS_SELENIUM_PORT}/wd/hub\"]"}
else
    export MINK_DRIVER_ARGS_WEBDRIVER=${MINK_DRIVER_ARGS_WEBDRIVER-"[\"chrome\", null, \"http://${DRUPAL_TRAVIS_SELENIUM_HOST}:${DRUPAL_TRAVIS_SELENIUM_PORT}\"]"}
fi

