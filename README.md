# Phalcon CI Installer

[![CircleCI](https://img.shields.io/circleci/token/e0f3c984c936d88ad20ca9db4112f032d27930af/project/techpivot/phalcon-ci-installer/master.svg?label=circleci&style=flat-square)](https://circleci.com/gh/techpivot/phalcon-ci-installer)
[![Travis CI](https://img.shields.io/travis/techpivot/phalcon-ci-installer/master.svg?label=travisci&style=flat-square)](https://travis-ci.org/techpivot/phalcon-ci-installer)
[![Scrutinizer](https://img.shields.io/scrutinizer/build/g/filp/whoops.svg?label=scrutinizer&style=flat-square)](https://scrutinizer-ci.com/g/techpivot/phalcon-ci-installer/)
[![Shippable](https://img.shields.io/shippable/561c5b621895ca44741d44c7.svg?style=flat-square)](https://app.shippable.com/projects/56204d941895ca44741e1583)
[![Codeship](https://codeship.com/projects/d6305600-55cf-0133-0a31-0ebfbd542ed0/status?branch=master)](https://codeship.com/projects/109153)

[![Latest Version](https://img.shields.io/packagist/v/techpivot/phalcon-ci-installer.svg?style=flat-square)](https://packagist.org/packages/techpivot/phalcon-ci-installer)
[![Total Downloads](https://img.shields.io/packagist/dt/techpivot/phalcon-ci-installer.svg?style=flat-square)](https://packagist.org/packages/techpivot/phalcon-ci-installer)
[![Software License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://raw.githubusercontent.com/techpivot/phalcon-ci-installer/master/LICENSE)


Composer integration for PHP applications to install the [Phalcon](https://phalconphp.com) framework as an extension in the PHP runtime for various hosted CI services including CircleCI, TravisCI, ScrutinizerCI, Shippable and Codeship.


## Features
* Phalcon extension loaded in PHP runtime
* Native cache support to prevent rebuilding Phalcon from source
* Auto-detection of latest tagged Phalcon version
* Install specific Phalcon versions, tags and releases _(Since 1.0.2)_
* Supports PHP7 and Phalcon 2.1.x _(Since 1.0.4)_


## Version Compatibility

The following table outlines general compability of Phalcon inside various CI environments. 

| PHP CI Version | Phalcon Version(s) | CI Environment |
|:---------------|:-------------------|:---------------|
| 5.3            | ✖   (Not supported)            | - |
| 5.4            | ✔   `master`, `2.0.x`, `2.1.x` | ✔ CircleCI, TravisCI, ScrutinizerCI, Shippable, Codeship |
| 5.5            | ✔   `master`, `2.0.x`, `2.1.x` | ✔ CircleCI, TravisCI, ScrutinizerCI, Shippable, Codeship |
| 5.6            | ✔   `master`, `2.0.x`, `2.1.x` | ✔ CircleCI, TravisCI, ScrutinizerCI, Shippable, Codeship |
| 7.0            | ✔   `2.1.x`                    | ✔ CircleCI, TravisCI, ScrutinizerCI, Shippable, Codeship |


## Installation

1. Add the `techpivot/phalcon-ci-installer` repository into the **require-dev** section of your `composer.json` as follows:

  ```json
    "require-dev": {
        "techpivot/phalcon-ci-installer": "~1.0"
    }
  ```
1. Update your CI script to execute the **vendor/bin/install-phalcon.sh** installer in the 
relevant section. See the examples below for various CI providers.


## Options

The installer takes one optional argument that can be used to specify a specific branch or tag.

Examples:

```bash
# Install latest version from default branch
vendor/bin/install-phalcon.sh

# Install latest revision from branch "2.1.x"
vendor/bin/install-phalcon.sh 2.1.x

# Install specific release tag "phalcon-v2.0.9"
vendor/bin/install-phalcon.sh phalcon-v2.0.9
```

> **Note:** The Phalcon CI installer is designed to cache the resulting binaries that correspond to the Phalcon/PHP version. 
Specifing a release or tagged version will result in the best performance as subsequent builds (depending on CI 
container/settings)  will be cached. Building from a branch (including the default master option) will result in a 
Phalcon rebuild every time the installer detects a new version that is not yet cached.


## CI Environments


### CircleCI

**`circle.yml`**
```yml
machine:
  php:
    version: 5.6.14

dependencies:
  cache_directories:
    - vendor
    - ~/cphalcon

  post:
    - vendor/bin/install-phalcon.sh phalcon-v2.0.13

test:
  override:
    - vendor/bin/phpunit
```

> **Note:** In order to cache data for faster builds, ensure the `cache_directories` directives are specified as outlined above.

<!-- -->
> **Note:** Ensure that the `vendor/bin/circleci-install-phalcon.sh` is executed in the **post** phase, which will allow for the inclusion of the `techpivot/phalcon-ci-installer` repository during the composer installation at inference or override phase.

<!-- -->
> **Reference:** CircleCI PHP Versions – [Ubuntu 14.04](https://circleci.com/docs/build-image-trusty/#php) • [Ubuntu 12.04](https://circleci.com/docs/build-image-precise/#php)


### TravisCI

**`.travis.yml`**
```yml
language: php

php:
  - 5.4
  - 5.5
  - 5.6
  - 7.0

cache:
  directories:
    - vendor
    - ~/.composer/cache
    - ~/cphalcon

before_install:
  - composer install --prefer-source --no-interaction
  - vendor/bin/install-phalcon.sh 2.1.x

script:
  - vendor/bin/phpunit

notifications:
  email: false
```

> **Note:** Multiple PHP versions can be specified and each one will be cached independently; however, the phalcon target ref (branch or tag) will be applied for all builds

<!-- -->
> **Reference:** [TravisCI PHP Versions](https://docs.travis-ci.com/user/languages/php#Choosing-PHP-versions-to-test-against)


### ScrutinizerCI

**`.scrutinizer.yml`**
```yml
build:
    environment:
        php:
            version: 7.0.8

    cache:
        directories:
            - ~/cphalcon

    dependencies:
        override:
            - composer install --prefer-source --no-interaction
        after: 
            - vendor/bin/install-phalcon.sh 2.1.x
```

> **Note:** No need to include the `vendor/` cache directory as this is cached automatically.

<!-- -->
> **Reference:** [ScrutinizerCI PHP Versions](https://scrutinizer-ci.com/docs/configuration/build#php)


### Shippable

**`shippable.yml`**
```yml
language: php
php:
  - 7.0

before_install:
  - composer self-update
  - composer install --prefer-source --no-interaction
  - vendor/bin/install-phalcon.sh 2.1.x

before_script:
  - mkdir -p shippable/codecoverage
  - mkdir -p shippable/testresults

script:
  - vendor/bin/phpunit --log-junit shippable/testresults/junit.xml --coverage-xml shippable/codecoverage
```

<!-- -->
> **Reference:** [Shippable PHP Versions](http://docs.shippable.com/ci_languages/#php)


### Codeship
Sample **Setup Commands**

```bash
phpenv local 5.6
php --version
composer install --prefer-source --no-interaction
vendor/bin/install-phalcon.sh
```

> **Reference:** [Codeship CI PHP Versions](https://codeship.com/documentation/languages/php/#versions)
