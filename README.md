# Phalcon CI Installer

[![License](http://img.shields.io/:license-mit-blue.svg)](http://doge.mit-license.org)
[![CircleCI](https://circleci.com/gh/techpivot/phalcon-ci-installer.svg?style=shield&circle-token=e0f3c984c936d88ad20ca9db4112f032d27930af)](https://circleci.com/gh/techpivot/phalcon-ci-installer.svg?style=shield&circle-token=e0f3c984c936d88ad20ca9db4112f032d27930af)
[![TravisCI](https://magnum.travis-ci.com/techpivot/phalcon-ci-installer.svg?token=3ojQM7rGxH51knzEpmdK&branch=master)](https://magnum.travis-ci.com/techpivot/phalcon-ci-installer)
[![Shippable](https://img.shields.io/shippable/561c5b621895ca44741d44c7.svg)](https://img.shields.io/shippable/561c5b621895ca44741d44c7.svg)
[![Codeship](https://codeship.com/projects/e65de590-544d-0133-95e2-5675ed16b46f/status?branch=master)](https://codeship.com/projects/108627)


Provides inline script execution support for installing the [Phalcon](https://phalconphp.com) module as an extension in the PHP runtime
of various hosted CI services including TravisCI, CircleCI, Shippable and Codeship.

### Features
* Phalcon extension loaded in PHP runtime
* Native cache support to prevent rebuilding Phalcon from source
* Auto-detection of latest tagged Phalcon version

### Installation

1. Add the `techpivot/phalcon-ci-installer` repository into the **require-dev** section of your `composer.json` as follows:

  ```json
    "require-dev": {
        "techpivot/phalcon-ci-installer": "~1.0"
    }
  ```
1. Update your CI script to execute the **vendor/bin/install-phalcon.sh** installer in the 
relevant section. See the examples below for various CI providers.

## CircleCI

**`circle.yml`**
```yml
machine:
  php:
    version: 5.6.5

dependencies:
  cache_directories:
    - vendor
    - ./../cphalcon

  post:
    - vendor/bin/install-phalcon.sh

test:
  override:
    - vendor/bin/phpunit
```
**CircleCI Notes**
* Ensure that the `bash vendor/bin/circleci-install-phalcon.sh` is executed in the **post** phase, which will allow for the inclusion of the `techpivot/phalcon-ci-installer` repository during the composer installation at inference or override phase.
* In order to cache data for faster builds, ensure the `cache_directories` directives are specified as outlined above.


## TravisCI

**`.travis.yml`**
```yml
language: php

php:
  - 5.5
  - 5.6

cache:
  directories:
    - vendor
    - $HOME/.composer/cache
    - $HOME/cphalcon

before_install:
  - composer install --prefer-source --no-interaction
  - vendor/bin/install-phalcon.sh

script:
  - vendor/bin/phpunit
  
notifications:
  email: false
```
**TravisCI Notes**
* Caching work great with TravisCI. Multiple PHP versions can be specified and each one will be cached independently.

## Shippable

**`shippable.yml`**
```yml
language: php

php:
  - 5.5
  - 5.6

before_install:
  - composer self-update
  - composer install --prefer-source --no-interaction
  - vendor/bin/install-phalcon.sh  

before_script:
  - mkdir -p shippable/codecoverage
  - mkdir -p shippable/testresults

script:
  - vendor/bin/phpunit --log-junit shippable/testresults/junit.xml --coverage-xml shippable/codecoverage
```
**Shipable Notes**
* Centralized caching does not work with Shippable. Presently, there is limited form of caching using the `cache: true`
parameter; however, this does not update after new builds are complete. As a result of this, the only way to flush
the cache is to commit with the **[reset minion]** flag. If Shippable is your primary CI, my recommendation
would be to use a single PHP instance, with `cache: true` and then whenever Phalcon becomes out-of-date, ensure
that the next commit utilizes the **[reset minion]** flag.

## Codeship
Sample **Setup Commands**

```bash
# Set php version through phpenv. 5.3, 5.4, 5.5 & 5.6 available
phpenv local 5.6
# Install dependencies through Composer
composer install --prefer-source --no-interaction
# Install Phalcon
vendor/bin/install-phalcon.sh
```
**Codeship Notes**
* Caching does not work with Codeship directories and therefore Phalcon can not be cached. Build time is approximately 1 min 30 sec
