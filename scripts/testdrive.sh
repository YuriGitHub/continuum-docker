#!/usr/bin/env bash
set -ex

build_images() {
    # Builds Continuum and pulls MongoDB and other services for test drive
    docker-compose -f prod/docker-compose.yml build --no-cache
    docker-compose -f prod/docker-compose.yml pull
#    docker-compose -f testlab/docker-compose.yml pull
}

start_services() {
    local svr=$@
    docker-compose -f prod/docker-compose.yml -f testlab/docker-compose.yml up -d ${svr}
}

while [[ $# > 0 ]]; do
    key="$1"
    case "$key" in
        --build)
            build=true
            ;;
        --start)
            start=true
            services=$2
            shift
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
    start_services $services
fi
