#!/usr/bin/env bash
set -e -o pipefail

script_parent_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
repo_dir="$(realpath "${script_parent_dir:?}/..")"

ARGS_FILE="${repo_dir:?}/config/ARGS"
PACKAGES_INSTALL_FILE="${repo_dir:?}/config/PACKAGES_INSTALL"

args_file_as_build_args() {
    local prefix=""
    if [[ "$1" == "docker-flags" ]]; then
        prefix="--build-arg "
        while IFS="=" read -r key value; do
            echo -n "${prefix}$key=\"$value\" "
        done < ${ARGS_FILE:?}
    else
        while IFS="=" read -r key value; do
            echo "$key=$value"
        done < ${ARGS_FILE:?}
    fi
}

packages_to_install() {
    while IFS="=" read -r key value; do
        echo -n "$key=$value "
    done < "${PACKAGES_INSTALL_FILE:?}"
}

github_env_dump() {
    args_file_as_build_args
    echo "PACKAGES_TO_INSTALL=$(packages_to_install)"
}

if [[ "$1" == "docker-flags" ]]; then
    # --build-arg format used with the docker build command.
    args_file_as_build_args $1
    echo -n "--build-arg PACKAGES_TO_INSTALL=\"$(packages_to_install)\" "
else
    # Convert the build args into a multi-line format
    # that will be accepted by Github workflows.
    output=$(github_env_dump)
    output="${output//'%'/'%25'}"
    output="${output//$'\n'/'%0A'}"
    output="${output//$'\r'/'%0D'}"
    echo -e "::set-output name=build_args::$output"
fi
