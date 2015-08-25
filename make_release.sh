#!/bin/bash

SYSTEM_CONFIG=${SYSTEM_CONFIG:-"./system-config/conf.tar.gz"}

if [ -f "${SYSTEM_CONFIG}" ]; then
    rm "${SYSTEM_CONFIG}"
fi
cd system-config && tar -czf conf.tar.gz *
