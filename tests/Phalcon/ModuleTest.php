<?php

namespace TechPivot\PhalconCiInstaller\Tests\Phalcon;

use Phalcon\Version;
use PHPUnit_Framework_TestCase;

class ModuleTest extends PHPUnit_Framework_TestCase
{

    public function testModuleLoaded()
    {
        $this->assertTrue(in_array('phalcon', get_loaded_extensions()),
            'Phalcon extension not properly loaded');

        $this->assertGreaterThanOrEqual(2, Version::getPart(Version::VERSION_MAJOR),
            'Invalid Phalcon version: "' . Version::get() . '"');
    }

}