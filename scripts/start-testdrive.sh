#!/usr/bin/env bash
set -ex

_build=0
build() {
    # This will build the image locally and pull the remaining images to run.
    # Eventually is should pull the Continuum image too, I'm just iterating to
    # find the best way to do that without adding more docker-composes

    # Builds Continuum
    docker-compose -f prod/docker-compose.yml build
    # Pulls MongoDB and other services for demo
    docker-compose -f prod/docker-compose.yml pull mongodb
#    docker-compose -f testlab/docker-compose.yml pull jenkins gitlab jira
}

_start=0
start() {
    # Setup environment
    #export UI_EXTERNAL_URL="something"
    docker-compose -f prod/docker-compose.yml up
#    docker-compose -f prod/docker-compose.yml -f testlab/docker-compose.yml up continuum mongodb jenkins gitlab jira
}

while [[ $# > 0 ]]; do
    key="$1"
    case "$key" in
        --build)
            _build=1
            ;;
        --start)
            _start=1
            ;;
        --help)
            # Todo
            exit
            ;;
        *)
            echo "Unrecognized argument: $key"
            exit 1
            ;;
    esac
    shift
done

if $_build; then
    build
fi

if $_start; then
    start
fi
