# Test Drupal projects

[![Build Status](https://travis-ci.com/thunder/drupal-testing.svg?branch=master)](https://travis-ci.com/thunder/drupal-testing)

# Versions

[![Latest Stable Version](https://poser.pugx.org/thunder/drupal-testing/v/stable)](https://packagist.org/packages/thunder/drupal-testing) 
[![Latest Unstable Version](https://poser.pugx.org/thunder/drupal-testing/v/unstable)](https://packagist.org/packages/thunder/drupal-testing)

# About

Use this package to simplify your drupal project testing. This will run all your standard drupal test and additionally 
check your source code for drupal coding style guidelines. It can be used to locally run those tests, or on CI platforms
like travis or in github actions. 

# Prerequisites

To get the most out of this package you should consider to add a few things to your module

## Add your module name to the @group annotation of your test classes.

If your module is called "my_module" add the following annotation to your test classes:

    /**
     * Tests for my_module.
     *
     * @group my_module
     */
    class MyModuleTest extends ...

## Add a composer.json to your module. 
We use that file to automate different things. We parse the module name from it and we will automatically download 
required drupal modules before running the tests.

A composer.json could look like the following:

    {
        "name": "drupal/my_module",
        "description": "The description of my_module",
        "type": "drupal-module",
        "license": "GPL-2.0-or-later",
        "require": {
            "drupal/another_module": "^2.0"
        }
    }

## Do not use deprecated TestBase classes
Only not deprecated (as of drupal 8.6) TestBase classes are tested. Especially the deprecated JavascriptTestBase
is not supported, please use WebDriverTestBase instead. See [JavascriptTestBase is deprecated in favor of WebDriverTestBase](https://www.drupal.org/node/2945059)

# Setup
Make sure, that you have bash 4 installed or greater. On most systems this will be the case. But on MacOS you need to
update the build-in bash with homebrew. 

Other requirements:

    - [jq](https://stedolan.github.io/jq/)
    - PHP > 7.2 + extensions needed by Drupal + sqlite extension, if no other database is used.
    - [composer](https://getcomposer.org/)
    - [node + npm](https://nodejs.org/en/)
 
For using drupal-testing on travis all you need to do is to copy the [.travis.yaml.dist](https://github.com/thunder/drupal-testing/blob/master/.travis.yml.dist) 
to your project root folder and rename it to .travis.yaml. If your module meets all the prerequisites, you should be done. Otherwise you might need to provide some environment variables.
See below for possible configurations.   

# Differences to LionsAd/drupal_ti
While the general approach is very similar to drupal_ti, we differ in some regards.
 
 - If you want to run deprecated TestBase classes, or if you want to run behat tests, use drupal_ti.
 - When using WebDriverTestBase and Drupal > 8.6 (which needs selenium instead of phantom.js) use this package.
 - If you want a simple travis.yml file, that works without any configuration, use this package.
 - You can directly use this for quickly running the tests locally and on other CI environments as well! Just do 
   <code>composer global require thunder/drupal-testing</code> add the global composer directory to your $PATH and call 
   <code>test-drupal-project</code> from within your modules directory. Everything will be build, installed and tested
   automatically.
 
# Configuration

We try to run without configuration as much as possible. But we still have a lot of configuration options, if your module
requires some special treatment, or if your testing environment is not travis/github (or they changed some default values).

## Steps
The simplest way to run the tests is to just call <code>test_drupal_project</code> in your .travis.yml. 
This will do everything, but it is actually divided into several steps which can be called separately by providing the
step as a parameter: <code>test_drupal_project build</code> would call the build step and any steps that the build step
depends on. Steps, that have already been executed will not be called again on subsequent call. So, if you call
<code>test_drupal_project start_services</code> next, all steps up to the build step will not be executed.

The steps are the following:

### requirements
Check if testing requirements are met. 

### coding_style
Tests php and javascript coding styles

### prepare_build
Creates a drupal project and modifies the composer.json to contain the required modules.

### build
Builds the drupal installation with drupal project, adds all dependencies from the module and calls composer install.

### install
Installs drupal with the minimal profile or the one that has been configured.

### start_services
Starts a services required for testing. Starts web server and selenium.

### run_tests
Runs the tests
  
This is also the order of the step dependencies, coding_style depends on prepare, build depends on coding_style and
prepare, and so on.

A very common use case for splitting the execution into steps is to stop after the build step, and add custom build
operations (e.g. downloading dependencies, that cannot be installed by composer) and then continue later.
An example for such a custom .travis.yml would be:

    language: php
    sudo: required

    cache:
      apt: true
      directories:
      - "$HOME/.composer/cache"
      - "$HOME/.drush/cache"
      - "$HOME/.npm"

    php:
      - 7.2

    branches:
      only:
        - /^8\.([0-9]+|x)\-[0-9]+\.([0-9]+|x)$/

    env:
      global:
        - PATH="$PATH:$HOME/.composer/vendor/bin"

    before_install:
      - composer global require thunder/drupal-testing

    install:
      - test-drupal-project build
      # Download something to the ccurrent directory.
      - wget -qO- https://www.some-domain.com/some-needed-dependency.tar.gz | tar xvz

    script:
      # this continues after the build step and finishes testing.
      - test-drupal-project

# Environment variables

You can configure your tests with several environment variables, most of them are only needed, if you want to run the
tests in different environments then travis. You can change database credentials, server hosts and ports, some
installation paths and the test setup. All those variables should work out of the box when running on travis with
a module, that has a correct composer.json and the test group set to the module name (see prerequisites for more
information). Variables can be set in the env section of the .travis.yml.

## Available variables

Find all defined variables in [configuration.sh](https://github.com/thunder/drupal-testing/blob/master/configuration.sh)

Some interesting variables are:

- DRUPAL_TESTING_PROJECT_BASEDIR

The directory, where the project is located. On travis this is set to TRAVIS_BUILD_DIR otherwise defaults to the current
directory.

- DRUPAL_TESTING_COMPOSER_NAME

The composer name of the current project, if not specified, it will be read from the composer.json.

- DRUPAL_TESTING_PROJECT_NAME

The project name, if not provided, the second part of the composer name will be use. E.g. If the composer name is
vendor/myproject the project name will be myproject. This will be used as default test group.

- DRUPAL_TESTING_TEST_GROUP

The phpunit test group, defaults to the value of ${DRUPAL_TESTING_PROJECT_NAME}. To provide multiple groups,
concatenate them with comma:  DRUPAL_TESTING_TEST_GROUP="mygroup1,mygroup2"

- DRUPAL_TESTING_TEST_FILTER

Only runs tests whose name matches the given regular expression pattern. 
Example: DRUPAL_TESTING_TEST_FILTER=TestCaseClass::testMethod

- DRUPAL_TESTING_TEST_CODING_STYLES

Boolean value if coding styles should be tested with burdamagazinorg/thunder-dev-tools.
By default coding styles are tested.

- DRUPAL_TESTING_TEST_JAVASCRIPT
- DRUPAL_TESTING_TEST_PHP

Boolean values if javascript and php coding styles should be tested. By default all coding styles are tested.

- DRUPAL_TESTING_TEST_BASE_DIRECTORY

The base directory for all generated files. Drupal will be installed into this directory. This directory and its 
contents get removed after a successful tests.

- DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY

The directory, where drupal will be installed, defaults to ${DRUPAL_TESTING_TEST_BASE_DIRECTORY}/install
This directory gets removed after successful tests.

- DRUPAL_TESTING_HTTP_HOST
- DRUPAL_TESTING_HTTP_PORT

The web server host and port. Defaults to 127.0.0.1 and 8888

- DRUPAL_TESTING_SELENIUM_CHROME_VERSION

The selenium chrome docker version to use. defaults to the latest version.

- DRUPAL_TESTING_SELENIUM_HOST
- DRUPAL_TESTING_SELENIUM_PORT

The selenium host and port. Defaults to the web server host and port 4444.

- DRUPAL_TESTING_DATABASE_HOST
- DRUPAL_TESTING_DATABASE_PORT
- DRUPAL_TESTING_DATABASE_USER
- DRUPAL_TESTING_DATABASE_PASSWORD
- DRUPAL_TESTING_DATABASE_NAME

The database information. Defaults to the web server host, port 3306, user testing and empty password. The database name
is set to testing. If you run your tests locally, you might want to change these to your local mysql installation.

- DRUPAL_TESTING_CLEANUP

By default all created files are deleted after successful test runs, you can disable this behaviour by setting
this to false.

- SYMFONY_DEPRECATIONS_HELPER

The symfony environment variable to ignore deprecations, for possible values see
[PHPUnit Bridge documentation](https://symfony.com/doc/3.4/components/phpunit_bridge.html).
The default value is "week" to ignore any deprecation notices.

- MINK_DRIVER_ARGS_WEBDRIVER

The driver args for webdriver. You might change this, when running your own chromedriver / selenium instance.

Example .travis.yml with some variables set:

    language: php
    dist: xenial
    
    php:
      - 7.2
    
    services:
      - mysql
    
    cache:
      apt: true
      directories:
      - "$HOME/.composer/cache"
      - "$HOME/.drush/cache"
      - "$HOME/.npm"

    branches:
      only:
        - /^8\.([0-9]+|x)\-[0-9]+\.([0-9]+|x)$/

    env:
      matrix:
        # Add a test matrix where tests are running once with deprecations failing and once without.
        # The test with deprecation warnings is allowed to fail.
        - SYMFONY_DEPRECATIONS_HELPER=weak
        - SYMFONY_DEPRECATIONS_HELPER=0
      global:
        - PATH="$PATH:$HOME/.composer/vendor/bin"

    matrix:
      allow_failures:
        - env: SYMFONY_DEPRECATIONS_HELPER=0

    before_install:
      - composer global require thunder/drupal-testing

    script:
      - test-drupal-project
