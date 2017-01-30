<?php
// Define our core values.
define( 'WEBROOT', dirname( __DIR__ ) );

function define_wp_constants() {
	// Define the defaults that will be used for each of the constants
	// unless overridden by an environment variable of the same name.
	//
	// Keys with null values will not be defined at all.
	$config_defaults = array(
		// Absolute path to web root
		'ABSPATH' => WEBROOT . '/wp/',

		// Home / Site URL overrides
		'WP_HOME' => 'http://pre-commit-linter.dev',
		'WP_SITEURL' => null,

		// DB connection information
		'DB_NAME' => 'pre_commit_linter_db',
		'DB_USER' => 'root',
		'DB_PASSWORD' => '',
		'DB_HOST' => 'localhost',

		'TEST_DB_NAME' => 'pre_commit_linter_test',
		'TEST_DB_USER' => null,
		'TEST_DB_PASSWORD' => null,
		'TEST_DB_HOST' => null,

		// Functionality flags
		'DISALLOW_FILE_EDIT' => true,
		'DISALLOW_FILE_MODS' => true,
		'DISABLE_WP_CRON' => false,
		'AUTOMATIC_UPDATER_DISABLED' => true,
		'FS_METHOD' => 'direct',
		'WP_CACHE' => false,

		// Debugging flags
		'SAVEQUERIES' => false,
		'SCRIPT_DEBUG' => false,
		'WP_DEBUG' => false,
		'WP_DEBUG_LOG' => false,
		'WP_DEBUG_DISPLAY' => false,
	);

	// Load environment from .env
	try {
		(new Dotenv\Dotenv( WEBROOT ))->load();
	}
	catch( Exception $e ) {
		error_log( "Failed to load environment file: " . $e->getMessage() );
	}

	// Select an environment with WP_ENV env variable.
	define( 'WP_ENV', getenv( 'WP_ENV' ) ?: 'development' );

	// And load additional per-environment configuration
	$environment_config = __DIR__ . '/environments/' . WP_ENV . '.php';

	if ( file_exists( $environment_config ) ) {
		require_once( $environment_config );
	}

	$config = array();

	foreach ( $config_defaults as $config_key => $config_default ) {
		$value = getenv( $config_key );

		if ( false === $value ) {
			$value = $config_default;
		}

		if ( isset( $value ) ) {
			$config[ $config_key ] = $value;
		}
	}

	// Override settings with test settings
	if ( 'testing' === WP_ENV ) {
		foreach ( array_keys( $config ) as $field ) {
			if ( isset( $config[ 'TEST_' . $field ] ) ) {
				$config[ $field ] = $config[ 'TEST_' . $field ];
			}
		}
	}

	// Finally commit to the constants, unless they've already been defined
	foreach ( $config as $config_key => $value ) {
		if ( ! defined( $config_key ) ) {
			define( $config_key, $value );
		}
	}
}

define_wp_constants();

if ( ! defined( 'WP_HOME' ) ) {
	echo "WP_HOME must be configured\n";
	exit(1);
}

if ( ! defined( 'WP_SITEURL' ) ) {
	define( 'WP_SITEURL', WP_HOME . '/wp' );
}

$table_prefix = getenv( 'DB_PREFIX' ) ?: 'wp_';

/**
 * Tie display_errors ini value to WP_DEBUG_DISPLAY
 */
ini_set( 'display_errors', (int) WP_DEBUG_DISPLAY );

/**
 * Custom Content Directory
 */
define( 'CONTENT_DIR', '/app' );
define( 'WP_CONTENT_DIR', WEBROOT . CONTENT_DIR );
define( 'WP_CONTENT_URL', WP_HOME . CONTENT_DIR );

/**
 * Authentication Unique Keys and Salts. Generate these at:
 *
 * https://api.wordpress.org/secret-key/1.1/salt/
 */
define( 'AUTH_KEY', getenv( 'AUTH_KEY' ) );
define( 'SECURE_AUTH_KEY', getenv( 'SECURE_AUTH_KEY' ) );
define( 'LOGGED_IN_KEY', getenv( 'LOGGED_IN_KEY' ) );
define( 'NONCE_KEY', getenv( 'NONCE_KEY' ) );
define( 'AUTH_SALT', getenv( 'AUTH_SALT' ) );
define( 'SECURE_AUTH_SALT', getenv( 'SECURE_AUTH_SALT' ) );
define( 'LOGGED_IN_SALT', getenv( 'LOGGED_IN_SALT' ) );
define( 'NONCE_SALT', getenv( 'NONCE_SALT' ) );
