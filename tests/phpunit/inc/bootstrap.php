<?php
/**
 * Bootstrap unit tests
 */

// Let base be 3 levels up from the cwd
$base = dirname( dirname( dirname( dirname( __FILE__) ) ) );

require_once $base . '/web/tests/phpunit/includes/functions.php';

function _project_tests_bootstrap() {
    // Switch to another theme
    switch_theme( 'rda' );

    // And load plugin dependencies
    $plugins = array();

    update_option( 'active_plugins', $plugins );
}
tests_add_filter( 'muplugins_loaded', '_project_tests_bootstrap');

require_once $base . '/web/tests/phpunit/includes/bootstrap.php';