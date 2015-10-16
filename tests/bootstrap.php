<?php

// Enable all errors
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);

// Ensure a default date timezone is set
date_default_timezone_set('America/Los_Angeles');

// Include composer with are explicit tests namespace
$loader = require __DIR__ . '/../vendor/autoload.php';
$loader->addPsr4('TechPivot\\PhalconCiInstaller\\Tests\\', __DIR__);