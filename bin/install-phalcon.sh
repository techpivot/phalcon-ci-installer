#!/usr/bin/env bash

set -e
START_TIME=$(date +%s.%3N)


# Ensure that this is being run inside a CI container
if [ "${CI}" != "true" ]; then
    echo "This script is designed to run inside a CI container only. Exiting"
    exit 1
fi


PHALCON_INSTALL_REF=${1:-master}
PHP_VER=$(phpenv version-name)
PHP_ENV_DIR=$(dirname $(dirname $(which phpenv)))/versions/${PHP_VER}
PHP_EXT_DIR=${PHP_ENV_DIR}/lib/php/extensions
PHALCON_DIR=${HOME}/cphalcon  
PHALCON_CACHED_MODULE=${PHALCON_DIR}/build/64bits/modules/phalcon-${PHP_VER}.so


# Prior to building, attempt to enable phalcon from a cached dependency 
# which may have been set via the CI environment YML declaration. This is
# important as it helps improve performance for fast builds.
if [ -d "${PHALCON_DIR}" ]; then
    cd ${PHALCON_DIR}
    git checkout ${PHALCON_INSTALL_REF} &> /dev/null
    
    # Debug - Version Check
    LOCAL=$(git rev-parse @ 2>/dev/null || true)
    REMOTE=$(git rev-parse @{u} 2>/dev/null || true)
    if [ "${LOCAL}" == "${REMOTE}" ]; then
        echo -e "Phalcon Version Check: \u2714  [ Cache: ${LOCAL} ] [ Remote: ${REMOTE} ]"
    else
        echo -e "Phalcon Version Check: \u2716  [ Cache: ${LOCAL} ] [ Remote: ${REMOTE} ]"
    fi
    
    # Debug - Module Check
    if [ -f ${PHALCON_CACHED_MODULE} ]; then
        echo -e " Phalcon Module Check: \u2714  ( ${PHALCON_CACHED_MODULE} )"
    else
        echo -e " Phalcon Module Check: \u2716  ( Not available )"
    fi
    
    # Cache success
    if [ -f ${PHALCON_CACHED_MODULE} ] && [ "${LOCAL}" == "${REMOTE}" ]; then
        echo "Phalcon extension up-to-date. Enabling cached version ..."
        cp --verbose ${PHALCON_CACHED_MODULE} ${PHP_EXT_DIR}/phalcon.so
        echo "extension=phalcon.so" > ${PHP_ENV_DIR}/etc/conf.d/phalcon.ini
        ELAPSED_TIME=$(python -c "print round(($(date +%s.%3N) - ${START_TIME}), 3)")
        echo "Phalcon extension enabled in ${ELAPSED_TIME} sec"
        exit
    fi
    
    # No suitable cache module found
    if [ -f ${PHALCON_CACHED_MODULE} ]; then
        echo "Phalcon extension not found."
    else 
        echo "Phalcon extension out-of date."
    fi
    
    if [ "${LOCAL}" != "${REMOTE}" ]; then
        TMP_PHALCON_SAVED_MODULES_DIR=$(mktemp -d)

        # Prior to resetting the current clone, save any other previously cached installations.
        if [ -d "${PHALCON_DIR}/build/64bits/modules" ]; then
            echo "Saving current cached Phalcon module(s) ..."
            for file in "${PHALCON_DIR}/build/64bits/modules"/*; do
                name=${file##*/}
                echo "Found cached file: ${name} ..."
                cp ${PHALCON_DIR}/build/64bits/modules/${name} ${TMP_PHALCON_SAVED_MODULES_DIR}/${name}
            done
        fi
        
        # Now reset and update
        echo "Updating Phalcon to latest revision for ref: ${PHALCON_INSTALL_REF}"
        git reset --hard
        git clean -f
        git pull
        
        # Restore any cached modules
        mkdir -p ${PHALCON_DIR}/build/64bits/modules
        for file in "${TMP_PHALCON_SAVED_MODULES_DIR}"/*; do
            name=${file##*/}
            echo "Restoring cached file: ${name} ..."
            cp ${TMP_PHALCON_SAVED_MODULES_DIR}/${name} ${PHALCON_DIR}/build/64bits/modules/${name} 
        done
    fi

else
    echo "No previous saved Phalcon cache found."

    # Clone the updated Phalcon source directly into the cached phalcon directory
    cd ${HOME}
    git clone --depth=50 https://github.com/phalcon/cphalcon.git ${PHALCON_DIR}
    
    echo "Checking out: ${PHALCON_INSTALL_REF} ..."
    cd ${PHALCON_DIR}
    git checkout ${PHALCON_INSTALL_REF}
fi
    
    
# Build Phalcon. Note that Codeship has issues with the phpenv not being setup correctly even when
# specified. Ensure that the correct version adds the required binaries to the PATH prior to the global phpenv.
echo "Building Phalcon ..."
cd ${PHALCON_DIR}/build
PATH=${PHP_ENV_DIR}/bin:${PATH}
./install
echo "extension=phalcon.so" > ${PHP_ENV_DIR}/etc/conf.d/phalcon.ini


# Cache the executable specific to the PHP version which will allow for multiple CI environments
# to properly reuse the cache
mv ${PHALCON_DIR}/build/64bits/modules/phalcon.so ${PHALCON_CACHED_MODULE}
echo "Cached phalcon extension [ phalcon-${PHP_VER}.so ] for future builds."


ELAPSED_TIME=$(python -c "print round(($(date +%s.%3N) - ${START_TIME}), 3)")
echo "Phalcon extension compiled and installed in ${ELAPSED_TIME} sec"
