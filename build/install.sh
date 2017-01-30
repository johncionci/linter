#!/bin/bash -e

##
## Install the environment necessary to build.
##
echo "Installing..."

mkdir -p vendor/bin
PATH=$PWD/vendor/bin:$PATH

# Force our own version of composer
if [[ ! -x vendor/bin/composer ]]; then
	# Install composer into this space
	echo 'Downloading and installing composer'
	curl -sS https://getcomposer.org/installer | php -- --install-dir=vendor/bin --filename="composer"
fi

composer self-update
composer install

# Ensure the wp-cli dependency was installed by composer
if [[ ! -f vendor/bin/wp ]]; then
	curl https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o vendor/bin/wp

	chmod +x vendor/bin/wp
fi

npm install

# Check if npm installed brunch successfully
if [[ ! -x node_modules/brunch/bin/brunch ]]; then
	echo "No 'brunch' executable: Did npm install fail?"
	exit 1
fi

# Build assets with brunch
node_modules/brunch/bin/brunch build
