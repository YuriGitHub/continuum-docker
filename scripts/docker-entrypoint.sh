#!/usr/bin/env bash
set -e


if [[ -z "${CONTINUUM_HOME}" || -z "$(which ctm-start-services)" ]]; then
    echo "CONTINUUM_HOME not set or start script not found"
    exit 1
fi

CONFIG_FILE=/etc/continuum/continuum.yaml
if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "Configuration file not found or not writable"
    exit 1
fi

# This should not be here since it's only in the context of running in Ossum,
# but it provides a sanity check when starting the container to let the
# operator know the status of Ossum config.
if [[ -n "${OSSUM}" ]]; then
    if [[ -z ${OSSUM_JWT_ISSUER} \
        || -z ${OSSUM_JWT_AUDIENCE} \
        || -z ${OSSUM_OAUTH_URL} \
        || -z ${OSSUM_OAUTH_CLIENT_ID} \
        || -z ${OSSUM_OAUTH_SECRET} \
        || -z ${OSSUM_OAUTH_USERNAME} \
        || -z ${OSSUM_OAUTH_PASSWORD} \
        || -z ${CONTINUUM_MONGODB_NAME} \
        || -z ${CONTINUUM_MONGODB_REPLICASET_HOSTS} \
        || -z ${CONTINUUM_MONGODB_REPLICASET_NAME} \
        || -z ${CONTINUUM_MONGODB_USERNAME} \
        || -z ${CONTINUUM_MONGODB_PASSWORD} \
        || -z ${CONTINUUM_MONGODB_AUTH} \
        || -z ${CONTINUUM_MONGODB_SSL} \
        || -z ${CONTINUUM_ENCRYPTION_KEY} \
        || -z ${APPLICATION_URL} \
        ]]; then
            echo "Ossum environment is not complete"
    fi
fi

# ############################################################################
# Go through the environment and check to see with settings get applied in
# the config file as not every setting has environment variable support at
# runtime
# Find references to the available settings:
# https://community.versionone.com/VersionOne_Continuum/Administration/General_Settings/Configuration_Reference
# ############################################################################
add_setting() {
    local setting=$1
    local value=$2
    if [[ -n "${value}" ]]; then
        echo "  ${setting}: ${value}" >> ${CONFIG_FILE}
    fi
}

add_setting ui_debug ${UI_LOG_LEVEL}
add_setting jobhandler_debug ${JOB_HANDLER_LOG_LEVEL}
add_setting repopoller_debug ${REPO_POLLER_LOG_LEVEL}
add_setting rest_api_enable_basicauth ${BASIC_AUTH}
add_setting ui_enable_tokenauth ${TOKEN_AUTH}
add_setting msghub_enabled ${MSGHUB}
add_setting rest_api_allowed_origins ${APPLICATION_URL}
add_setting ui_external_url ${UI_EXTERNAL_URL}
add_setting msghub_external_url ${MSGHUB_EXTERNAL_URL}

# ############################################################################
# Database initialization and update
# ############################################################################
echo "Preparing database configuration"

# Remove mongodb_database setting from config file if environment contains 
# database name to use. 
if [[ -n "${CONTINUUM_MONGODB_NAME}" ]]; then
    sed -i "/mongodb_database/d" ${CONFIG_FILE}
fi

if [[ -n "${CONTINUUM_ENCRYPTION_KEY}" ]]; then
    # Encryption encryption key with default key
    encrypted_encryption_key=$(${CONTINUUM_HOME}/common/install/ctm-encrypt "${CONTINUUM_ENCRYPTION_KEY}" "")
    # Replace encryption key with key from environment.
    sed -i "s|^\s\skey:.*$|  key: ${encrypted_encryption_key}|" ${CONFIG_FILE}
fi

if [[ -n "${MONOLITH}" ]]; then
    if [[ -z "$(which mongod)" ]]; then
        echo "Attempting to run as monolith but could not find MongoDB"
        exit 1
    fi
    echo "Starting MongoDB"
    run_mongo="mongod --bind_ip localhost --port 27017 --dbpath /data/db"
    $(${run_mongo}) &
fi

# On upgrades init_mongodb.py will run again, running into a
# DuplicateKeyError, failing to change the admin db password out from
# under you, which is the behavior we want.
# We want to add something more robust than relying on the exception
echo "Initializing and running database upgrades"
${CONTINUUM_HOME}/common/install/init_mongodb.py || ${CONTINUUM_HOME}/common/updatedb.py || true

# File corruption always causing login issues.
shelf_file=/var/continuum/ui/cskuisession.shelf
if [[ -f ${shelf_file} ]]; then
    rm -f ${shelf_file}
fi

if [[ -f /etc/continuum/service.conf ]]; then
    cat /etc/continuum/service.conf
fi

ctm-start-services

if [[ -n "${OSSUM}" ]]; then
    # This creates a worker oauth user in the database via Continuum API.
    #
    # Currently the is_shared_asset_manager and is_system_administrator
    # properties are not set in Continuum due to missing functionality.
    #
    # One will have to manually log in and update the user via the UI.
    #
    # This call uses the dafault username and password for the administrator.
    # This means the call won't work if the password isn't correct, Continuum
    # prompts to to change the administrator password on initial login.
    #
    if [[ -n "${OSSUM_OAUTH_USERNAME}" && -n "${OSSUM_OAUTH_PASSWORD}" ]]; then
        echo "Setting up OAUTH user, service will restart after"
        sleep 5s
        curl -s -d "{\"user\": \"${OSSUM_OAUTH_USERNAME}\", \
            \"name\": \"${OSSUM_OAUTH_USERNAME}\", \
            \"teams\": \"Default:Team Administrator\", \
            \"role\": \"Administrator\", \
            \"email\": \"${OSSUM_OAUTH_USERNAME}\", \
            \"password\": \"${OSSUM_OAUTH_PASSWORD}\", \
            \"forcechange\": 0, \
            \"is_shared_asset_manager\": \"true\", \
            \"is_system_administrator\": \"true\", \
            \"get_token\": \"true\"}" \
            -H "Authorization: Basic $(echo -n "administrator:password" | base64)" \
            -H "Content-Type: application/json" \
            -X POST http://localhost:8080/api/create_user \
            && sleep 1s \
            && ctm-restart-services
    else
        echo "Not setting up OAUTH user"
    fi
fi

logs=/var/continuum/log
tail -F \
    ${logs}/ctm-ui.log \
    ${logs}/ctm-core.log \
    ${logs}/ctm-jobhandler.log \
    ${logs}/ctm-msghub.log \
    ${logs}/ctm-poller.log

exec "$@"
