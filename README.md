# Test Drupal projects with travis

[![Build Status](https://travis-ci.com/thunder/travis.svg?branch=master)](https://travis-ci.com/thunder/travis)

# Versions

[![Latest Stable Version](https://poser.pugx.org/thunder/travis/v/stable)](https://packagist.org/packages/thunder/travis) 
[![Latest Unstable Version](https://poser.pugx.org/thunder/travis/v/unstable)](https://packagist.org/packages/thunder/travis)

# About

Use this package to simplify your drupal module testing on travis. This will run all your standard drupal test on travis
and additionally check your source code for drupal coding style guidelines.

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
All you need to do is to copy the .travis.yaml.dist to your project root folder and rename it to .travis.yaml.
If your module meets all the prerequisites, you should be done. Otherwise you might need to provide some environment variables.
See below for possible configurations.   

# Differences to LionsAd/drupal_ti
While the general approach is very similar to drupal_ti, we differ in some regards.
 
 - If you want to run deprecated TestBase classes, or if you want to run behat tests, use drupal_ti.
 - When using WebDriverTestBase and Drupal > 8.6 (which needs selenium instead of phantom.js) use this package.
 - If you want a simple travis.yml file, that works without any configuration, use this package.
 - You can directly use this for quickly running the tests locally as well! All you need is php command line client, composer, chromedriver and docker (or mysql running natively).
   If you have all this installed on your local machine, just do <code>composer global require thunder/travis</code> add the global 
   composer directory to your $PATH and call <code>test-drupal-project</code> from within your modules directory. Everything will be build, installed
   and tested automatically.
 
# Configuration

We try to run without configuration as much as possible, but we still have a lot of configuration options, if your module
requires some special treatment, or if your testing environment is not travis (or travis changed some default values)
or if you want to split up the testing process into multiple steps.

## Steps
The simplest way to run the tests is to just call <code>test_drupal_module</code> in your .travis.yml. 
This will do everything, but it is actually divided into several steps which can be called separately by providing the
step as a parameter: <code>test_drupal_module build</code> would call the build step and any steps that the build step
depends on. Steps, that have already been executed will not be called again on subsequent call. So, if you call
<code>test_drupal_module start_web_server</code> next, all steps up to the build step will not be executed.

The steps are the following:

### setup
Setup the testing environment. Starts selenium and mysql if necessary and tweaks php on travis 

### coding_style
Tests php and javascript coding styles

### prepare_build
Creates a drupal project and modifies the composer.json to contain the required modules.

### build
Builds the drupal installation with drupal project, adds all dependencies from the module and calls composer install.

### install
Installs drupal with the minimal profile, as required by simpletest module. Enables simpletest module

### start_web_server
Starts a webserver pointing to the installed drupal.

### run_tests
Runs the tests
  
This is also the order of the step dependencies, coding_style depends on prepare, build depends on coding_style and
prepare, and so on.

A very common use case for splitting the execution into steps is, to stop after the build step, and add custom build
operations (e.g. downloading dependencies, that cannot be installed by composer) and the continue later.
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
      - composer global require thunder/travis

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
informations). Variables can be set in the env section of the .travis.yml.

## Available variables

Find all defined variables in [configuration.sh](https://github.com/thunder/travis/blob/master/configuration.sh)

Some interesting variables are:

- DRUPAL_TRAVIS_PROJECT_BASEDIR

The directory, where the project is located. On travis this is set to TRAVIS_BUILD_DIR otherwise defaults to the current directory

- DRUPAL_TRAVIS_COMPOSER_NAME

The composer name of the current project, if not specified, it will be read from the composer.json.

- DRUPAL_TRAVIS_PROJECT_NAME

The project name, if not provided, the second part of the composer name will be use. E.g. If the composer name is
vendor/myproject the project name will be myproject. This will be used as default test group

- DRUPAL_TRAVIS_TEST_GROUP

The phpunit test group, defaults to the value of ${DRUPAL_TRAVIS_PROJECT_NAME}. To provide multiple groups,
concatenate them with comma:  DRUPAL_TRAVIS_TEST_GROUP="mygroup1,mygroup2"

- DRUPAL_TRAVIS_TEST_CODING_STYLES

Boolean value if coding styles should be tested with burdamagazinorg/thunder-dev-tools.
By default coding styles are tested.

- DRUPAL_TRAVIS_TEST_JAVASCRIPT
- DRUPAL_TRAVIS_TEST_PHP

Boolean value if javascript and php coding styles should be tested.
By default all coding styles are tested.


- DRUPAL_TRAVIS_TEST_BASE_DIRECTORY

The base directory for all generated files. Into this diretory will be drupal installed and temp files stored.
This directory gets removed after successful tests.

- DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY

The directory, where drupal will be installed, defaults to ${DRUPAL_TRAVIS_TEST_BASE_DIRECTORY}/install
This directory gets removed after successful tests.

- DRUPAL_TRAVIS_HTTP_HOST
- DRUPAL_TRAVIS_HTTP_PORT

The web server host and port. Defaults to 127.0.0.1 and 8888

- DRUPAL_TRAVIS_SELENIUM_CHROME_VERSION

The selenium chrome docker version to use. defaults to the latest version.

- DRUPAL_TRAVIS_SELENIUM_HOST
- DRUPAL_TRAVIS_SELENIUM_PORT

The selenium host and port. Defaults to the web server host and port 4444.

- DRUPAL_TRAVIS_DATABASE_HOST
- DRUPAL_TRAVIS_DATABASE_PORT
- DRUPAL_TRAVIS_DATABASE_USER
- DRUPAL_TRAVIS_DATABASE_PASSWORD
- DRUPAL_TRAVIS_DATABASE_NAME

The database information. Defaults to the web server host, port 3306, user travis and empty password.
This is the default configuration for the travis php environment. The database name is set to drupaltesting.
If you run your tests locally, you might want to change these to your local mysql installation.

- DRUPAL_TRAVIS_CLEANUP

By default all created files are deleted after successful test runs, you can disable this behaviour by setting
this to false.

- SYMFONY_DEPRECATIONS_HELPER

The symfony environment variable to ignore deprecations, for possible values see
[PHPUnit Bridge documentation](https://symfony.com/doc/3.4/components/phpunit_bridge.html).
The default value is "week" to ignore any deprecation notices.

- MINK_DRIVER_ARGS_WEBDRIVER

The driver args for webdriver. When testing locally, we use chromedriver, which uses a different URL than 
the selenium hub, that is used for travis runs, that is why we provide different defaults for travis / local tests.

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
      - composer global require thunder/travis

    script:
      - test-drupal-project
