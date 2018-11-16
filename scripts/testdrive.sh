#!/usr/bin/env bash
set -ex

build_images() {
    # This will build the image locally and pull the remaining images to run.
    # Eventually is should pull the Continuum image too, I'm just iterating to
    # find the best way to do that without adding more docker-composes

    # Builds Continuum
    docker-compose -f prod/docker-compose.yml build --no-cache
    # Pulls MongoDB and other services for demo
    docker-compose -f prod/docker-compose.yml pull mongodb smtp
    docker-compose -f testlab/docker-compose.yml pull jenkins gitlab
}

start_services() {
    # Setup environment
    #export UI_EXTERNAL_URL="something"
#    docker-compose -f prod/docker-compose.yml up
    docker-compose -f prod/docker-compose.yml -f testlab/docker-compose.yml up smtp continuum mongodb jenkins gitlab
}

while [[ $# > 0 ]]; do
    key="$1"
    case "$key" in
        --build)
            build=true
            ;;
        --start)
            start=true
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

if [ -n "$build" ]; then
    echo Building images
    build_images
fi

if [ -n "$start" ]; then
    echo Starting services
    start_services
fi
