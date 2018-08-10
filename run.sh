#!/usr/bin/env bash

SERVICE_CONFIG_FILE="/etc/continuum/service.conf"

if [ -f "${SERVICE_CONFIG_FILE}" ]; then
    if [ ! -z "${SERVICE}"]; then
        echo "service ${SERVICE}" >> ${SERVICE_CONFIG_FILE}
    fi
fi


${CONTINUUM_HOME}/common/bin/ctm-start-services && \
tail -f /var/continuum/log/ctm-ui.log
