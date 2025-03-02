#!/usr/bin/env bash
# Use this file as reference on what you can configure. You can set each of these variables in the environment
# to override the default values.

# Set ${CI} to false on non CI builds, for github actions we need to provide a fallback. Github does not support the CI environment variable.
CI=${CI:-${GITHUB_ACTIONS:-false}}

# Generate more verbose output, defaults to false. Can also be set to true by providing the -v parameter to the invoking command.
DRUPAL_TESTING_VERBOSE=${DRUPAL_TESTING_VERBOSE:-false}

# The composer project to use. defaults to the drupal/recommended-project. But e.g. Distribution specific projects can be used instead.
DRUPAL_TESTING_COMPOSER_PROJECT=${DRUPAL_TESTING_COMPOSER_PROJECT:-"drupal/recommended-project"}

# The drupal version to test against. This can be any valid composer version string, but only drupal versions greater 8.6
# are supported. By default, we use the most recent stable version.
DRUPAL_TESTING_DRUPAL_VERSION=${DRUPAL_TESTING_DRUPAL_VERSION:-$(git ls-remote --tags --sort=-version:refname https://github.com/drupal/core.git | grep -E -o '[0-9]+\.[0-9]\.[0-9]+$' | head -n1)}

# The version of the composer project to use.
DRUPAL_TESTING_COMPOSER_PROJECT_VERSION=${DRUPAL_TESTING_COMPOSER_PROJECT_VERSION:-${DRUPAL_TESTING_DRUPAL_VERSION}}

# The directory, where the project is located. On travis this is set to TRAVIS_BUILD_DIR otherwise defaults to the current directory
DRUPAL_TESTING_PROJECT_BASEDIR=${DRUPAL_TESTING_PROJECT_BASEDIR:-${TRAVIS_BUILD_DIR:-$(pwd)}}

# The type of the project, could be "drupal-module" "drupal-theme" "drupal-profile" or "project".
DRUPAL_TESTING_PROJECT_TYPE=${DRUPAL_TESTING_PROJECT_TYPE:-$(jq -er '.type // "project"' "${DRUPAL_TESTING_PROJECT_BASEDIR}"/composer.json)}

# Setting this to a filename, creates a dump from an installation, that can be used by all tests, instead of reinstalling
# for every test. This is currently supported only by the thunder distribution.
# The behavior differs based on the file extension:
# - .php: Only the database php dump will be created and used.
# - .tar.gz: A tar will be created, that contains the database php dump and the files directory.
DRUPAL_TESTING_TEST_DUMP_FILE=${DRUPAL_TESTING_TEST_DUMP_FILE:-""}

# The drupal profile that is used in the tests.
DRUPAL_TESTING_TEST_PROFILE=${DRUPAL_TESTING_TEST_PROFILE:-minimal}

# If set to true, drush will install from exported config, otherwise the DRUPAL_TESTING_TESTING_PROFILE will be used on install.
DRUPAL_TESTING_INSTALL_FROM_CONFIG=${DRUPAL_TESTING_INSTALL_FROM_CONFIG:-false}

# The composer name of the current project, if not specified, it will be read from the composer.json.
DRUPAL_TESTING_COMPOSER_NAME=${DRUPAL_TESTING_COMPOSER_NAME:-$(jq -r .name "${DRUPAL_TESTING_PROJECT_BASEDIR}/composer.json")}

# The project name, if not provided, the "installer-name" property of the composer extra section is used.
# Fallback value is the second part of the composer name will be use. E.g. If the composer name is
# vendor/myproject the project name will be myproject.
DRUPAL_TESTING_PROJECT_NAME=${DRUPAL_TESTING_PROJECT_NAME-$(jq -r --arg FALLBACK "$(echo "${DRUPAL_TESTING_COMPOSER_NAME}" | cut -d '/' -f 2)" '.extra."installer-name" // $FALLBACK' "${DRUPAL_TESTING_PROJECT_BASEDIR}/composer.json")}

# The phpunit configuration file to use. Defaults to docroot/core/phpunit.xml.dist
DRUPAL_TESTING_TEST_CONFIGURATION=${DRUPAL_TESTING_TEST_CONFIGURATION:-""}

# Path for phpunit to search for test files. Default is the current project folder.
DRUPAL_TESTING_TEST_PATH=${DRUPAL_TESTING_TEST_PATH:-""}

# The phpunit test group. To provide multiple groups, concatenate them with comma:
# E.g. DRUPAL_TESTING_TEST_GROUP="mygroup1,mygroup2"
DRUPAL_TESTING_TEST_GROUP=${DRUPAL_TESTING_TEST_GROUP:-""}

# The phpunit test groups to exclude. To provide multiple groups, concatenate them with comma:
# E.g. DRUPAL_TESTING_TEST_GROUP_EXCLUDE="mygroup1,mygroup2"
DRUPAL_TESTING_TEST_GROUP_EXCLUDE=${DRUPAL_TESTING_TEST_GROUP_EXCLUDE:-""}

# The phpunit testsuite. To provide multiple suites, concatenate them with comma:
# E.g. DRUPAL_TESTING_TEST_SUITE="functional,kernel"
DRUPAL_TESTING_TEST_SUITE=${DRUPAL_TESTING_TEST_SUITE:-""}

# Boolean value if coding styles should be tested with burdamagazinorg/thunder-dev-tools.
# By default coding styles are tested.
DRUPAL_TESTING_TEST_CODING_STYLES=${DRUPAL_TESTING_TEST_CODING_STYLES:-true}

# The phpunit test filter to restrict the tests.
DRUPAL_TESTING_TEST_FILTER=${DRUPAL_TESTING_TEST_FILTER:-""}

# Boolean value if javascript coding style should be tested.
# By default javascript coding styles are tested.
DRUPAL_TESTING_TEST_JAVASCRIPT=${DRUPAL_TESTING_TEST_JAVASCRIPT:-true}

# Boolean value if php coding style should be tested.
# By default php coding styles are tested.
DRUPAL_TESTING_TEST_PHP=${DRUPAL_TESTING_TEST_PHP:-true}

# Boolean value if deprecation testing should be done.
DRUPAL_TESTING_TEST_DEPRECATION=${DRUPAL_TESTING_TEST_DEPRECATION:-test -f phpstan.neon}

# The files pattern to ignore when testing php coding styles.
DRUPAL_TESTING_PHPCS_IGNORE_PATTERN=${DRUPAL_TESTING_PHPCS_IGNORE_PATTERN:-*/vendor/*,*/core/*,*/autoload.php,*.md}

# The base directory for all generated files. Into this diretory will be drupal installed and temp files stored.
# This directory gets removed after successful tests.
DRUPAL_TESTING_TEST_BASE_DIRECTORY=${DRUPAL_TESTING_TEST_BASE_DIRECTORY:-/tmp/test/${DRUPAL_TESTING_PROJECT_NAME}}

# The web servers document root directory.
DRUPAL_TESTING_DOCROOT=${DRUPAL_TESTING_DOCROOT:-""}

# Sites directory used by multisite installations.
DRUPAL_TESTING_SITES_DIRECTORY=${DRUPAL_TESTING_SITES_DIRECTORY:-default}

# The directory, where drupal will be installed, defaults to ${DRUPAL_TESTING_TEST_BASE_DIRECTORY}/install
# This directory gets removed after successful tests.
DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY=${DRUPAL_TESTING_DRUPAL_INSTALLATION_DIRECTORY:-${DRUPAL_TESTING_TEST_BASE_DIRECTORY}/install}

# The version of the project to upgrade from.
DRUPAL_TESTING_UPGRADE_VERSION=${DRUPAL_TESTING_UPGRADE_VERSION:-""}

# The version of the composer project to upgrade from.
DRUPAL_TESTING_UPGRADE_COMPOSER_PROJECT_VERSION=${DRUPAL_TESTING_UPGRADE_COMPOSER_PROJECT_VERSION:-""}

# The path to the git checkout under test.
DRUPAL_TESTING_WORKSPACE=${DRUPAL_TESTING_WORKSPACE:-${GITHUB_WORKSPACE}}

# The version of Drush to use prior to upgrading.
DRUPAL_TESTING_UPGRADE_DRUSH_VERSION=${DRUPAL_TESTING_UPGRADE_DRUSH_VERSION:-"10.3.6"}

# The location where the project will be copied to and the version to upgrade
# from will be checkout out here.
DRUPAL_TESTING_UPGRADE_DRUPAL_INSTALLATION_DIRECTORY=${DRUPAL_TESTING_UPGRADE_DRUPAL_INSTALLATION_DIRECTORY:-${DRUPAL_TESTING_TEST_BASE_DIRECTORY}/old_install}

# The directory, where the tests are located relative to the docroot. This will default to the project directory.
DRUPAL_TESTING_TEST_LOCATION=${DRUPAL_TESTING_TEST_LOCATION:-""}

# The directory, where lock files for finished stages will be saved, defaults to ${DRUPAL_TESTING_TEST_BASE_DIRECTORY}/finished-stages.
# This directory gets removed after successful tests.
DRUPAL_TESTING_LOCK_FILES_DIRECTORY=${DRUPAL_TESTING_LOCK_FILES_DIRECTORY:-${DRUPAL_TESTING_TEST_BASE_DIRECTORY}/finished-stages}

# The web server host. Defaults to 127.0.0.1
DRUPAL_TESTING_HTTP_HOST=${DRUPAL_TESTING_HTTP_HOST:-127.0.0.1}

# The web server port. Defaults to 8888
DRUPAL_TESTING_HTTP_PORT=${DRUPAL_TESTING_HTTP_PORT:-8888}

# Use selenium to spawn chromedriver. On CI environments we want to do that, to be able to use the selenium docker.
# On local development calling chromedriver directly is more straight forward.
DRUPAL_TESTING_USE_SELENIUM=${DRUPAL_TESTING_USE_SELENIUM:-${CI}}

# The selenium chrome docker version to use. defaults to the latest version.
DRUPAL_TESTING_SELENIUM_CHROME_VERSION=${DRUPAL_TESTING_SELENIUM_CHROME_VERSION:-"latest"}

# The chromedriver version to use. Defaults to the latest version. This is only used, for direct chromedriver calls.
# When selenium is used, specify DRUPAL_TESTING_SELENIUM_CHROME_VERSION instead.
DRUPAL_TESTING_CHROMEDRIVER_VERSION=${DRUPAL_TESTING_CHROMEDRIVER_VERSION:-$(curl --silent https://chromedriver.storage.googleapis.com/LATEST_RELEASE_87)}

# The selenium host. Defaults to the web server host.
DRUPAL_TESTING_SELENIUM_HOST=${DRUPAL_TESTING_SELENIUM_HOST:-${DRUPAL_TESTING_HTTP_HOST}}

# The selenium port. Defaults to 4444.
DRUPAL_TESTING_SELENIUM_PORT=${DRUPAL_TESTING_SELENIUM_PORT:-4444}

# The name for the selenium docker container. Defaults to selenium-for-drupal-tests
DRUPAL_TESTING_SELENIUM_DOCKER_NAME=${DRUPAL_TESTING_SELENIUM_DOCKER_NAME:-selenium-for-drupal-tests}

# The database host. Defaults to the web server host.
DRUPAL_TESTING_DATABASE_HOST=${DRUPAL_TESTING_DATABASE_HOST:-${DRUPAL_TESTING_HTTP_HOST}}

# The database port. Defaults to 3306.
DRUPAL_TESTING_DATABASE_PORT=${DRUPAL_TESTING_DATABASE_PORT:-3306}

# The database user. Defaults to testing.
DRUPAL_TESTING_DATABASE_USER=${DRUPAL_TESTING_DATABASE_USER:-testing}

# The database name. Defaults to drupaltesting
DRUPAL_TESTING_DATABASE_NAME=${DRUPAL_TESTING_DATABASE_NAME:-testing}

# The database password for ${DRUPAL_TESTING_DATABASE_USER}, empty by default.
DRUPAL_TESTING_DATABASE_PASSWORD=${DRUPAL_TESTING_DATABASE_PASSWORD:-""}

# The database engine to use. Could be sqlite or mysql, postgres might be possible, but is not tested.
# If sqlite is used, no further configuration is necessary, otherwise you might need to set the variables
# DRUPAL_TESTING_DATABASE_HOST, DRUPAL_TESTING_DATABASE_PORT, DRUPAL_TESTING_DATABASE_USER, DRUPAL_TESTING_DATABASE_PASSWORD
#  and DRUPAL_TESTING_DATABASE_PASSWORD
DRUPAL_TESTING_DATABASE_ENGINE=${DRUPAL_TESTING_DATABASE_ENGINE:-"sqlite"}

# By default all created files are deleted after successful test runs, you can disable this behaviour by setting
# this to true.
DRUPAL_TESTING_CLEANUP=${DRUPAL_TESTING_CLEANUP:-true}

# The directory where the configuration for the installation with existing config is located.
DRUPAL_TESTING_CONFIG_SYNC_DIRECTORY=${DRUPAL_TESTING_CONFIG_SYNC_DIRECTORY:-"../config/sync"}

# Additional form values for the installation profile. This is uses by drush site-install.
DRUPAL_TESTING_INSTALLATION_FORM_VALUES=${DRUPAL_TESTING_INSTALLATION_FORM_VALUES:-"install_configure_form.enable_update_status_module=NULL"}

# Set this flag to true, to pass the --prefer-lowest parameter to composer. With this parameter, the minimal installable
# versions of dependencies are installed.
DRUPAL_TESTING_MIN_BUILD=${DRUPAL_TESTING_MIN_BUILD:-false}

# The symfony environment variable to ignore deprecations, for possible values see symfony documentation.
# The default value is "week" to ignore any deprecation notices.
export SYMFONY_DEPRECATIONS_HELPER=${SYMFONY_DEPRECATIONS_HELPER-weak}

# The url that simpletest will use.
export SIMPLETEST_BASE_URL=${SIMPLETEST_BASE_URL:-http://${DRUPAL_TESTING_HTTP_HOST}:${DRUPAL_TESTING_HTTP_PORT}}

# The driver args for webdriver.
export MINK_DRIVER_ARGS_WEBDRIVER=${MINK_DRIVER_ARGS_WEBDRIVER-"[\"chrome\", {\"chromeOptions\": {\"w3c\": false } }, \"http://${DRUPAL_TESTING_SELENIUM_HOST}:${DRUPAL_TESTING_SELENIUM_PORT}/wd/hub\"]"}

# Increase composer memory limit.
export COMPOSER_MEMORY_LIMIT=${COMPOSER_MEMORY_LIMIT:-"-1"}

# Memory limit for phpstan.
export PHPSTAN_MEMORY_LIMIT=${PHPSTAN_MEMORY_LIMIT:-"300M"}

# Enable parallel testing with paratest.
export DRUPAL_TESTING_PARALLEL_TESTING=${DRUPAL_TESTING_PARALLEL_TESTING:-false}

# Number of parallel processes for paratest.
export DRUPAL_TESTING_PARALLEL_TESTING_PROCESSES=${DRUPAL_TESTING_PARALLEL_TESTING_PROCESSES:-2}

# Have parallel testing of functions, not test classes.
export DRUPAL_TESTING_PARALLEL_TESTING_PER_FUNCTION=${DRUPAL_TESTING_PARALLEL_TESTING_PER_FUNCTION:-false}

# Use wrapper runner.
export DRUPAL_TESTING_PARALLEL_TESTING_WRAPPER_RUNNER=${DRUPAL_TESTING_PARALLEL_TESTING_WRAPPER_RUNNER:-false}

if [[ ${DRUPAL_TESTING_DATABASE_ENGINE} == 'sqlite' ]]; then
    export SIMPLETEST_DB=${SIMPLETEST_DB:-${DRUPAL_TESTING_DATABASE_ENGINE}://${DRUPAL_TESTING_DATABASE_HOST}/${DRUPAL_TESTING_TEST_BASE_DIRECTORY}/${DRUPAL_TESTING_DATABASE_NAME}.sqlite}
else
    export SIMPLETEST_DB=${SIMPLETEST_DB:-${DRUPAL_TESTING_DATABASE_ENGINE}://${DRUPAL_TESTING_DATABASE_USER}:${DRUPAL_TESTING_DATABASE_PASSWORD}@${DRUPAL_TESTING_DATABASE_HOST}:${DRUPAL_TESTING_DATABASE_PORT}/${DRUPAL_TESTING_DATABASE_NAME}}
fi
