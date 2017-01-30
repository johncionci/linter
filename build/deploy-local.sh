#!/bin/bash

# Install a build locally.

. build/inc/common.sh

echo "Building site $WP_HOME..."

# We might want to just serve right out the WordPress root in this repository
if [ -z "$DEPLOY_PATH" ]; then
	echo "Using repository path $PWD/web for web root"

# If we're linking to the site (for debugging local installs), ensure the link
# exists and is proper Make sure the web root in $DEPLOY_PATH links to our
# proper WP directory
elif [ ! -z "$LINK_DEPLOY" ]; then
	if [ -e $DEPLOY_PATH ]; then
		echo "Deployment target $DEPLOY_PATH already exists."

		if [ $DEPLOY_PATH != "$PWD/web" ]; then
			if [ -L $DEPLOY_PATH ] && [ `readlink $DEPLOY_PATH` != "$PWD/web" ]; then
				echo "ERROR: $DEPLOY_PATH already exists, but does not link to install at $PWD/web"
				exit 3
			elif [ ! -L $DEPLOY_PATH ]; then
				echo "ERROR: $DEPLOY_PATH already exists, but not is not a symlink"
				exit 4
			fi
		fi

		# For existing installs with no template DB specified, don't pull from template site.
		if [ -z "$TEMPLATE_DB_PATH" ]; then
			TEMPLATE_SITE=''
		fi
	else
		echo "Creating link from $DEPLOY_PATH to $PWD/web"
		ln -s "$PWD/web" "$DEPLOY_PATH"
	fi
else
	mkdir -p $DEPLOY_PATH
fi

echo "Writing environment"
set_environment

# Uncomment Rewrite lines in produced .htaccess
echo "Building .htaccess file"
files=()

# Use W3TC .htaccess rules if we're caching
[ ! -z $WP_CACHE ] && files+=(build/w3tc.htaccess)

files+=(build/wp.htaccess)

echo "Writing ${files[@]} to web/wp/.htaccess"
cat ${files[@]} | tee web/.htaccess

if [ ! -z $DEPLOY_PATH ] && [ -z $LINK_DEPLOY ]; then
	echo "Copying site files to $DEPLOY_PATH ..."
	rsync -vr --exclude-from=build/rsync.exclude --delete "$PWD/web/." "$DEPLOY_PATH/."
fi

# Copy the database from the staging site into the staging
# Ensure the database exists
echo "Ensuring database $DB_NAME exists..."
wp db cli || wp db create

# Check that we can at least connect to the database
echo "Ensuring we can connect to databaase..."
if ! $(wp --path=$DEPLOY_PATH db cli </dev/null); then
	echo "Could not connect to the WordPress database"
	exit 8
fi

# Attempt to ensure that wp-content is writable by the webserver (ham-fistedly)
echo "Updating permissions in $DEPLOY_PATH/wp-content..."
chmod -R a+w $DEPLOY_PATH/wp-content 2>/dev/null || true

# If the site is already installed and we're not forcing
# a DB install with SETUP_BUILD...
echo "Checking for installed WordPress..."
if [ ! -z $TEMPLATE_SITE ] && $(wp --path=$DEPLOY_PATH core is-installed); then
	if [ -z $SETUP_BUILD ]; then
		echo "Not installing site from $TEMPLATE_SITE since the site is already installed"
		# ... Then don't pull an existing site in.
		TEMPLATE_SITE=''
	fi
fi

# If there's a TEMPLATE_SITE given, then copy / transform database
if [ ! -z "$TEMPLATE_SITE" ]; then
	TEMPLATE_URL="http://${TEMPLATE_SITE}"

	# Load a new file if if SETUP_DBDUMP or SETUP_DBDUMP_PATH is defined
	if [ ! -z "$TEMPLATE_DB_PATH" ]; then
		# Check if file is compressed using `file` command
		if [[ `file $TEMPLATE_DB_PATH` = *gzip* ]]; then
			command="gunzip -c"
		else
			command="cat"
		fi

		echo "Importing existing database from $TEMPLATE_URL dump in file ${TEMPLATE_DB_PATH}..."
		$command $TEMPLATE_DB_PATH | wp --path=$DEPLOY_PATH db cli
	else
		TEMPLATE_ROOT=${TEMPLATE_ROOT:-"$SITE_ROOT/$TEMPLATE_SITE"}

		echo "Importing existing database from $TEMPLATE_URL with site root in $TEMPLATE_ROOT..."
		wp --path=$TEMPLATE_ROOT db export - | wp --path=$DEPLOY_PATH db cli
	fi

	# Replace instances of template url with deployment url
	echo "Replacing $TEMPLATE_URL with $DEPLOY_URL ..."
	wp --path=$DEPLOY_PATH search-replace $TEMPLATE_URL $DEPLOY_URL
fi

echo "Checking for WordPress install... "
if ! $(wp --path=$DEPLOY_PATH core is-installed); then
	echo "NOTICE: WordPress is set up and configured, but not installed. Please install manually by visiting $DEPLOY_URL or, to install a theme Unit Testing suite, run the script ./install-test-suite.sh"
fi

if [ ! -z "$WP_CACHE" ]; then
	echo "Ensuring w3-total-cache is installed... "
	wp --path=$DEPLOY_PATH plugin install --activate w3-total-cache || true

	cache_path=$DEPLOY_PATH/wp-content/cache

	w3tc_config=$DEPLOY_PATH/wp-content/w3tc-config
	if [ -d $w3tc_config ]; then
		echo "Using existing cache configuration in $w3tc_config ... "
	else
		chmod 777 -R $w3tc_config
		echo "Copying build/w3tc-config to $w3tc_config ... "
		cp -fR build/w3tc-config/. $w3tc_config
	fi

	wp --path=$DEPLOY_PATH w3-total-cache flush
fi

