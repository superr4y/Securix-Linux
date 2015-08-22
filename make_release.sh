#!/bin/bash

SYSTEM_CONFIG=${SYSTEM_CONFIG:-"./system-config/conf.tar.gz"}

if [ -f "${SYSTEM_CONFIG}" ]; then
    rm "${SYSTEM_CONFIG}"
fi
tar -czf "${SYSTEM_CONFIG}" system-config/*
