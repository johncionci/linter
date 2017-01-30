#!/bin/bash -ex

. build/inc/common.sh

##
# Deploy project to WP Engine via `git push`. Accepts a single argument,
# 'production' or 'staging'.
#
# The private key can be specified in the GIT_KEYFILE environment variable,
# defaulting to `~/.ssh/id_rsa.wpengine`
##

export GIT_SSH=$PWD/build/git-ssh.sh

if [ ! -x "$GIT_SSH" ]; then
	echo "GIT_SSH=$GIT_SSH is missing or not executable"
	exit 1
fi

export GIT_KEYFILE=${GIT_KEYFILE:-$HOME/.ssh/id_rsa.$INSTALL_NAME}

if [ ! -f $GIT_KEYFILE ]; then
	echo "GIT_KEYFILE=$GIT_KEYFILE is missing"
	exit 1
fi

# Deploy to environment: 'production' or 'staging'
env=$1

if [ -z "$1" ]; then
	echo "Usage: $0 [production|staging]"
	exit 1
fi

case "$env" in
	production|staging)
		url=git@git.wpengine.com:$env/$INSTALL_NAME.git
		;;
	*)
		echo "Invalid environment: '$env'. Must be 'production' or 'staging'"
		exit 1
		;;
esac

mkdir -p deploy

# Check out the repository
if [ ! -d deploy/$env ]; then
	git clone $url deploy/$env
fi

# Build the site files
brunch build --production
composer install --no-ansi --no-dev --no-interaction --no-progress --no-scripts --optimize-autoloader

# Synchronize built theme files with repository theme
rsync -vr --copy-dirlinks --delete --exclude-from=build/rsync.exclude --exclude-from=build/wpengine.rsync.exclude web/. deploy/$env/.

cd deploy/$env

# Make sure we sync up with other deployments
git pull origin master || true

git add -A .

git status

# Use || true so that this script doesn't fail if there's no commit to be made
# (that is, the working directory is clean)
HOST=${HOST:-$HOSTNAME}

git commit -am "DEPLOY to $env from ${USER}@${HOST}" || true

git push origin master:master

echo "Finished"
