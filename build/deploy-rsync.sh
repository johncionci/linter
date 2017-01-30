#!/bin/bash

# Plz copy this script and customize these values for your deployment targets.
TARGET_USER=$USER
TARGET_PATH=/var/www/pre-commit-linter

# You can specify TARGET and TARGETS here instead of command line arguments
# TARGET=
# TARGETS=

# Generic deployment of the site and theme to a remote host (or hosts) via rsync
# over ssh, when no modifications to web/ are necessary. This script is meant to
# be copied for each deployment target.
#
# Usage:
#   deploy-rsync.sh [[user@]target[:path]] [targets...]
#
# Where 'target' is the destination host, which may also specify the SSH username
# and target path. If 'targets...' is provided, 'target'
# becomes a simple label for the group, and 'targets...' indicates multiple
# destination hosts which are assumed to all have the same target path and
# authentication key.
#
# Alternatively, you can specify TARGET and TARGETS as environment variables
# to use instead of arguments given on the command line.
usage() {
	cat <<-XXX
	Usage: $0 [[user@]target[:path]] [targets...]

	Deploy production-ready site from web/. to given target host or host group.

	Specify TARGET or TARGETS as environment variables to override arguments.
	XXX

	exit 1
}

if [ ! -z "$1" ]; then
	TARGET=${TARGET:-$1}
	shift
fi

if [[ $TARGET = *@* ]]; then
	TARGET_USER=`echo $TARGET | cut -d@ -f 1`
	TARGET=`echo $TARGET | cut -d@ -f 2`
fi

if [[ $TARGET = *:* ]]; then
	TARGET_PATH=`echo $TARGET | cut -d: -f 2`
	TARGET=`echo $TARGET | cut -d: -f 1`
fi

if [ -z "$TARGET" ]; then
	echo "No target specified!" && echo
	usage
fi

echo "Deploying site to $TARGET_USER@$TARGET:$TARGET_PATH"

TARGETS=${TARGETS:-$*}

if [ -z "$TARGETS" ]; then
	TARGETS=$TARGET
fi

# Install dependencies unless specifically instructed not to
if [ -z "$NOINSTALL" ]; then
	build/install.sh
fi

. build/inc/common.sh

# The directory to stage build files in,
DEPLOY_PATH=deploy

# The keyfile for this deployment
DEPLOY_KEYFILE=~/.ssh/id_rsa.$TARGET_USER@$TARGET

if [ ! -f $DEPLOY_KEYFILE ]; then
	echo "Looks like you need to create a key to deploy to $TARGET! Let me help you..."

	set -x
	ssh-keygen -f $DEPLOY_KEYFILE
	set +x

	echo "Great, now give the following public key to the admin of the '$TARGET' target and tell him to add it to the following hosts:"

	for TARGET in $TARGETS; do
		echo "* $TARGET_USER@$TARGET"
	done

	cat $DEPLOY_KEYFILE.pub

	exit 1
fi

# Stand up the deployment path
DEPLOY_STAGE=$DEPLOY_PATH/$TARGET

mkdir -p $DEPLOY_STAGE

# Install the root site, skipping the theme and composer dependencies
rsync -vr --exclude app/themes/pre-commit-linter --exclude ".*" --exclude=vendor --delete web/. $DEPLOY_STAGE/.

# Copy the composer files to build production version
cp composer.{json,lock} $DEPLOY_STAGE/.

# Ensure install production dependencies are installed
pushd $DEPLOY_STAGE
composer install --no-dev --no-interaction --no-progress --no-scripts --optimize-autoloader
popd

# Install the theme, allow it to exclude its own files in .deploy.exclude
mkdir -p $DEPLOY_STAGE/app/themes/pre-commit-linter

if [ -f web/app/themes/pre-commit-linter/.deploy.exclude ]; then
	rsync_theme_args="--exclude-from web/app/themes/pre-commit-linter/.deploy.exclude"
fi

rsync -vr $rsync_theme_args --delete web/app/themes/pre-commit-linter/. $DEPLOY_STAGE/app/themes/pre-commit-linter/.

# Deploy to all targets
for DEPLOY_TARGET in $TARGETS; do
	echo "Deploying site at $WP_HOME to $DEPLOY_TARGET..."

	if [ -f build/$TARGET.deploy.exclude ]; then
		rsync_args="--exclude-from=build/$TARGET.deploy.exclude"
	elif [ -f build/rsync.exclude ]; then
		rsync_args="--exclude-from=build/rsync.exclude"
	fi

	set -x

	# --filter argument prevents .env from being deleted
	rsync -Lvr --filter="P .env" -e "ssh -i $DEPLOY_KEYFILE -o 'StrictHostKeyChecking no'" $rsync_args --delete $DEPLOY_STAGE/. $TARGET_USER@$DEPLOY_TARGET:$TARGET_PATH
done
