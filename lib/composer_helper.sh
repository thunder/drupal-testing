#!/usr/bin/env bash

function composer_repository_exists() {
  local repository_url=${1}

  # Use jq to find all defined repositories in composer.json.
  for url in $(jq '.repositories | keys[] as $k | "\(.[$k] | .url)"' "${DRUPAL_TRAVIS_DRUPAL_INSTALLATION_DIRECTORY}""/composer.json"); do
      if [[ ${url} = '"'${repository_url}'"' ]]; then
        true
        return
      fi
  done

  false
}
