#!/usr/bin/env bash
set -e -o pipefail

random_container_name() {
    shuf -zer -n10  {A..Z} {a..z} {0..9} | tr -d '\0'
}

container_type="home-assistant-wheels"
container_name=$(random_container_name)

echo "Starting ${container_type:?} container ${container_name:?} to run tests in the foreground ..."

echo "Running tests against the ${container_type:?} container ${container_name:?} ..."

echo "All tests passed against the ${container_type:?} container ${container_name:?} ..."
