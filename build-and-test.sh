#!/bin/bash -ex

build/install.sh
build/validate.sh
build/test.sh

# Export relevant environment to deploy.sh
export GIT_KEYFILE
export SETUP_DBDUMP
export SETUP_DBDUMP_PATH
export SETUP_BUILD
export TEMPLATE_SITE
export INSTALL_NAME

# Deploy if arguments are given
if [ ! -z "$1" -o ! -z "$DEPLOY_ENVIRONMENT" ]; then
	export DEPLOY_ENVIRONMENT=${1:-$DEPLOY_ENVIRONMENT}

	NOINSTALL=1 ./build/deploy.sh $DEPLOY_ENVIRONMENT ${@:2}
fi
