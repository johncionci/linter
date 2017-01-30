#!/bin/bash

##
# General deployment script.
#
# Accepts target environment [target] [arguments]
#
# Simply calls `build/deploy-$target.sh $target $arguments
##

if [ -z "$1" ]; then
	cat <<-XXX
	Usage: $0 [target]

	Launches the deployment to [target]
	XXX

	exit 1
fi

script="build/deploy-$1.sh"

if [ ! -x $script ]; then
	echo "Deployment script $script is not executable"
	exit 2
fi

export NOINSTALL

$script ${@:2}
