#!/usr/bin/env bash

set -e
START_TIME=$(date +%s.%3N)


# Ensure that this is being run inside a CI container
if [ "${CI}" != "true" ]; then
    echo "This script is designed to run inside a CI container only. Exiting"
    exit 1
fi


PHALCON_INSTALL_REF=${1:-master}
PHALCON_DIR=${HOME}/cphalcon
PHALCON_CACHE_DIR=${HOME}/cphalcon/cache
PHP_VER=$(phpenv version-name)
PHP_ENV_DIR=$(dirname $(dirname $(which phpenv)))/versions/${PHP_VER}
PHP_EXT_DIR=$(php-config --extension-dir)


# Prior to building, attempt to enable phalcon from a cached dependency 
# which may have been set via the CI environment YML declaration. This is
# important as it helps improve performance for fast builds.
if [ -d "${PHALCON_DIR}" ]; then
    cd ${PHALCON_DIR}

    TMP_PHALCON_SAVED_MODULES_DIR=$(mktemp -d)

    # Prior to resetting the current clone, save any previously cached modules.
    if [ -d "${PHALCON_CACHE_DIR}" ]; then
        echo "Saving current cached Phalcon module(s) ..."
        for file in "${PHALCON_CACHE_DIR}"/*; do
            if [ -f ${file} ]; then
                name=${file##*/}
                echo "Found cached file: ${name} ..."
                cp ${PHALCON_CACHE_DIR}/${name} ${TMP_PHALCON_SAVED_MODULES_DIR}/${name}
            fi
        done
    fi

    # Now reset and update
    echo "Cleaning Phalcon directory ..."
    git reset --hard
    git clean -f
    git checkout master &> /dev/null
    git pull &> /dev/null

    # Checkout specific ref    
    echo "Updating Phalcon to latest revision for ref: ${PHALCON_INSTALL_REF}"
    set +e
    git checkout ${PHALCON_INSTALL_REF}

    # This could potentially fail for older versions that had a depth limiter from < 1.0.2 of the installer.
    # Handle gracefully and clean the cache automatically.
    if [ $? -ne 0 ]; then
        echo "Unable to checkout specific ref: ${PHALCON_INSTALL_REF}"
        echo "Rebuilding full Phalcon source ..."
        rm -rf ${PHALCON_DIR}
        cd ${HOME}
        git clone https://github.com/phalcon/cphalcon.git ${PHALCON_DIR}
        cd ${PHALCON_DIR}
        
        # Reset pipe to ensure we fail on second attempt with full clone
        set -e
        git checkout ${PHALCON_INSTALL_REF}
    fi
    set -e

    # Restore any cached modules
    mkdir -p ${PHALCON_CACHE_DIR}
    for file in "${TMP_PHALCON_SAVED_MODULES_DIR}"/*; do
        if [ -f ${file} ]; then
            name=${file##*/}
            echo "Restoring saved cached file: ${name} ..."
            cp ${TMP_PHALCON_SAVED_MODULES_DIR}/${name} ${PHALCON_CACHE_DIR}/${name}    
        fi
    done
    rm -rf ${TMP_PHALCON_SAVED_MODULES_DIR}

    # Debug
    LOCAL=$(git rev-parse @ 2>/dev/null || true)
    echo "PHP Version: ${PHP_VER}"
    echo "Phalcon Version: ${LOCAL}"
    
    # Determine if we have the cached module?
    if [ -f "${PHALCON_CACHE_DIR}/phalcon-${PHP_VER}-${LOCAL:0:7}.so" ]; then
        echo -e "\u2714  Found cached module."
        echo "Enabling cached version ..."
        cp --verbose ${PHALCON_CACHE_DIR}/phalcon-${PHP_VER}-${LOCAL:0:7}.so ${PHP_EXT_DIR}/phalcon.so
        echo "extension=phalcon.so" > ${PHP_ENV_DIR}/etc/conf.d/phalcon.ini
        ELAPSED_TIME=$(python -c "print round(($(date +%s.%3N) - ${START_TIME}), 3)")
        echo "Phalcon extension enabled in ${ELAPSED_TIME} sec"
        exit
    else
        echo -e "\u2716  Cache module not available."
    fi
else
    echo "No Phalcon cache available."

    # Clone the updated Phalcon source directly into the cached phalcon directory
    cd ${HOME}
    git clone https://github.com/phalcon/cphalcon.git ${PHALCON_DIR}
    
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
cd ${PHALCON_DIR}
LOCAL=$(git rev-parse @ 2>/dev/null || true)
mkdir -p ${PHALCON_CACHE_DIR}
mv ${PHALCON_DIR}/build/64bits/modules/phalcon.so ${PHALCON_CACHE_DIR}/phalcon-${PHP_VER}-${LOCAL:0:7}.so
echo "Cached phalcon extension [ phalcon-${PHP_VER}-${LOCAL:0:7}.so ] for future builds."


ELAPSED_TIME=$(python -c "print round(($(date +%s.%3N) - ${START_TIME}), 3)")
echo "Phalcon extension compiled and installed in ${ELAPSED_TIME} sec"
