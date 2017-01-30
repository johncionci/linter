#!/bin/bash -ex

. build/inc/common.sh

## Run tests!
echo "Running Automated Tests..."

files="$*"

pushd .
dbpass=$(upsearch .dbpass)
popd

# Look for a DB passwords file outside of the workspace.
if [[ -f "$dbpass" ]]; then
	. "$dbpass"
fi

# Use reasonable defaults for non-blank DB auth
DB_USER=${WP_DB_USER:-root}
DB_PASSWORD=${WP_DB_PASS:-}
DB_HOST=${DB_HOST:-localhost}

# Make sure env variables are set before attempting anything else
set_environment

# Keep track so we can remove the DB when we are done
echo "Using testing database $TEST_DB_NAME..."

if [[ $TEST_DB_NAME = $DB_NAME ]]; then
	echo "Won't use same TEST_DB_NAME=$TEST_DB_NAME as DB_NAME=$DB_NAME"
	exit 1
fi

# If a testing database already exists, we want to first drop it
if [[ ! -z $(\mysql --user=$DB_USER --password=$DB_PASSWORD -e "SHOW DATABASES LIKE \"$TEST_DB_NAME\"") ]]; then
	WP_ENV=testing wp db drop --yes
fi

# Create a test database
WP_ENV=testing wp db create

# Checkout WP test framework
if [[ ! -d tests ]]; then
	echo "Installing tests..."
	svn co --quiet http://develop.svn.wordpress.org/trunk/tests wp-tests
fi

# Make sure the site is built
brunch build --production

# Debug tests by passing in TEST_XDEBUG variable
if [[ ! -z "$TEST_XDEBUG" ]]; then
	export XDEBUG_CONFIG="IDEKEY='$TEST_XDEBUG'"
fi

if [[ ! -z "$files" ]]; then
	filters="--filter='$files'"
fi

# Clear the test result space
rm -rf tests/results && mkdir tests/results

if test -n "$(find tests/phpunit -maxdepth 1 -name 'test*php' -print -quit)"; then
	echo "Running PHPUnit tests... "

	# Finally, run the tests!
	export TEST_DB_NAME

	for i in tests/phpunit/test*php; do
		output="tests/results/`date +'%s'`".xml

		echo "Running tests in $i..."

		phpunit --log-junit="$output" $filters $i
	done

	echo "Done"

	echo "Generated " `ls -l results/|wc -l` " reports"
fi
