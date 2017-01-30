#
# Common functions used by build scripts. Expects that CWD is the root of the
# repository when this is executed.
#

if [ ! -f build/project.env ]; then
	echo "No project environment found. Have you run ./setup.sh?"
	exit 1
fi

. build/project.env

#  Try to load additional build environment
if [ -f build/build.env ]; then
	. build/build.env
fi

WEBENV=web/.env

# Default site title to the project name
WP_SITE_TITLE=${WP_SITE_TITLE:-$PROJECT_NAME}

# Default WordPress username / password when installed with
# install-test-suite.sh
WP_ADMIN_USER=${WP_ADMIN_USER:-admin}
WP_ADMIN_PASS=${WP_ADMIN_PASS:-test}
WP_ADMIN_EMAIL=${WP_ADMIN_EMAIL:-$USER@dev.$PROJECT_SLUG}

# Get the project root for use in scripts
PROJECT_ROOT="$(printf "%q" "$(git rev-parse --show-toplevel)")"

# Compute the rest of the build environment from what's given:

# The base path to install sites
SITE_ROOT=${SITE_ROOT:-/var/www/html}

# The site hostname to deploy, e.g., dev.$PROJECT_SLUG. Is determined automatically
# from GIT_BRANCH if not given
DEPLOY_SITE=${DEPLOY_SITE:-$PROJECT_SLUG}

# The domain to attach new sites to, if DEPLOY_SITE is not given
DEPLOY_DOMAIN=${DEPLOY_DOMAIN:-oomphcloud.com}

DEPLOY_URL="http://${DEPLOY_SITE}"

# Determine the deployment web root
INSTALL_NAME=${INSTALL_NAME:-$DEPLOY_SITE}
DEPLOY_PATH=${DEPLOY_PATH:-}

if [ ! -z "$SETUP_DBDUMP" -o ! -z "$SETUP_DBDUMP_PATH" ]; then
	TEMPLATE_DB_PATH=${SETUP_DBDUMP:-$SETUP_DBDUMP_PATH}

	if [ ! -f "$TEMPLATE_DB_PATH" ]; then
		echo "Template DB file $TEMPLATE_DB_PATH not found!"
		exit 7
	fi
fi

# Use sanitized DEPLOY_SITE as DB_NAME
DB_NAME=${DB_NAME:-${DEPLOY_SITE//\./_}}

# Create test db if necessary. If no db name has been specified, generate
# a random database name, then drop it at the end. If the DB name
# is specified in $DB_NAME, it persists even after the tests finish.
if [[ -z $TEST_DB_NAME ]]; then
	if [[ -f .db-cache ]]; then
		echo "Using database from cache... "
		TEST_DB_NAME=`cat .db-cache`
	else
		TEST_DB_NAME=$PROJECT_SNAKE_$(date "+%Y%m%d")_$RANDOM
	fi

	# Write this temp DB name to the db cache so it can be cleaned up in clean.sh
	echo $TEST_DB_NAME > .db-cache
fi

# Let me use aliases in non-interactive scripts!
shopt -s expand_aliases

# Ensure we're always pointing to the correct WP install
alias wp="$PROJECT_ROOT/vendor/bin/wp"

# Ensure we're always using the right DB user and password
alias mysql="mysql --user=${DB_USER} --password=${DB_PASSWORD}"

# Build tool binary aliases
alias composer="$PROJECT_ROOT/vendor/bin/composer"
alias brunch="$PROJECT_ROOT/node_modules/brunch/bin/brunch"
alias phpunit="$PROJECT_ROOT/vendor/bin/phpunit"

function upsearch() {
	test -e "$1" && echo "$PWD/$1" && return || test / == "$PWD" && return || cd .. && upsearch "$1"
}

function set_environment {
	VARS=(
		WP_HOME

		DB_NAME
		DB_USER
		DB_PASSWORD
		DB_HOST

		TEST_DB_NAME
		TEST_DB_USER
		TEST_DB_PASSWORD
		TEST_DB_HOST

		WP_CACHE

		DISALLOW_FILE_EDIT
		DISABLE_WP_CRON
		AUTOMATIC_UPDATER_DISABLED
		FS_METHOD

		SCRIPT_DEBUG
		WP_DEBUG
		SAVEQUERIES
		WP_DEBUG_LOG
		WP_DEBUG_DISPLAY
	)

	if [[ -f $WEBENV ]]; then
		rm $WEBENV
	fi

	# Pass along only defined values to web/.env
	for var in ${VARS[@]}; do
		eval defined=\${$var+v}
		eval val=\$$var

		if [[ ! -z $defined ]]; then
			tee -a $WEBENV <<-XXX
			$var=$val
			XXX
		fi
	done
}

function install_wp {
	echo "Installing WordPress with default user: $WP_ADMIN_USER / $WP_ADMIN_PASS"

	wp core install --url=$DEPLOY_URL --title="$WP_SITE_TITLE" --admin_user=$WP_ADMIN_USER --admin_password="$WP_ADMIN_PASS" --admin_email=$WP_ADMIN_EMAIL
}
