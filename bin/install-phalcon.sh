#!/usr/bin/env bash

set -e
START_TIME=$(date +%s.%3N)


# Ensure that this is being run inside a CI container

if [ "${CI}" != "true" ]; then
    echo "This script is designed to run inside a CI container only. Exiting"
    exit 1
fi


PHALCON_DIR=${HOME}/cphalcon
PHP_VER=$(phpenv version-name)
EXT_DIR=$(find ${HOME}/.phpenv/versions/${PHP_VER}/lib/php/extensions -type d -name 'no-debug*')  
CACHED_MODULE=${PHALCON_DIR}/build/64bits/modules/phalcon-${PHP_VER}.so

# Prior to building, attempt to enable phalcon from a cached dependency 
# which may have been set via the CI environment YML declaration. This is
# important as it helps improve performance for fast builds.

if [ -d "${PHALCON_DIR}" ]; then
    cd ${PHALCON_DIR}
    
    LOCAL=$(git rev-parse @ 2>/dev/null || true)
    REMOTE=$(git rev-parse @{u} 2>/dev/null || true)
    echo "Phalcon Version [ Cached: ${LOCAL} ] [ Latest: ${REMOTE} ]"
    
    if [ "${LOCAL}" == "${REMOTE}" ] && [ -f ${CACHED_MODULE} ]; then
        echo "Phalcon extension up-to-date. Enabling cached version ..."
        cp ${CACHED_MODULE} ${EXT_DIR}/phalcon.so
        echo "extension=phalcon.so" > ${HOME}/.phpenv/versions/${PHP_VER}/etc/conf.d/phalcon.ini
        ELAPSED_TIME=$(python -c "print round(($(date +%s.%3N) - ${START_TIME}), 3)")
        echo "Phalcon extension enabled in ${ELAPSED_TIME} sec"
        exit
    elif [ "${LOCAL}" == "${REMOTE}" ]; then
        echo "No cached Phalcon version available for PHP ${PHP_VER}."
        echo "Rebuilding Phalcon ..."
    else
        echo "Phalcon extension out-of date."
        echo "Rebuilding Phalcon ..."
    fi
else
    echo "Building Phalcon ..."
fi


# Clone Phalcon

cd ${HOME}
if [ -d "${PHALCON_DIR}" ]; then
	# Existing repository exists. Clone into a temporary location instead of removing 
	# the existing phalcon cached repository to ensure that we can properly override
	# the cache. Also, Shippable has issues with `rm --recursive`.
	TMP_PHALCON_CLONE_DIR=$(mktemp -d)
	git clone --depth=1 https://github.com/phalcon/cphalcon.git ${TMP_PHALCON_CLONE_DIR}
	
	# Shippable cache is not centralized. Permission errors will result from the AUFS docker lock
	if [ "${SHIPPABLE}" != "true" ]; then
		cp ${TMP_PHALCON_CLONE_DIR}/. ${PHALCON_DIR} -R
	else
		PHALCON_DIR=${TMP_PHALCON_CLONE_DIR}
	fi
else
	# Clone the updated Phalcon source directly into the cached phalcon directory
	git clone --depth=1 https://github.com/phalcon/cphalcon.git ${PHALCON_DIR}
fi


# Build Phalcon

echo "Building Phalcon ..."
cd ${PHALCON_DIR}/build


# Codeship has issues with the phpenv not being setup correctly even when specified. Ensure that
# the correct version adds the required binaries to the PATH prior to the global phpenv.
PATH=${HOME}/.phpenv/versions/${PHP_VER}/bin:${PATH}
./install
echo "extension=phalcon.so" > ${HOME}/.phpenv/versions/${PHP_VER}/etc/conf.d/phalcon.ini


# Cache the executable specific to the PHP version which will allow for multiple CI environments
# to properly reuse the cache

mv ${PHALCON_DIR}/build/64bits/modules/phalcon.so ${PHALCON_DIR}/build/64bits/modules/phalcon-${PHP_VER}.so
echo "Cached phalcon extension [ phalcon-${PHP_VER}.so ] for future builds."


ELAPSED_TIME=$(python -c "print round(($(date +%s.%3N) - ${START_TIME}), 3)")
echo "Phalcon extension compiled and installed in ${ELAPSED_TIME} sec"