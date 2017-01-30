#!/bin/bash

# Execute SSH with a keyfile. Use GIT_SSH environment variable when invoking
# git commands to use this script file instead.

# Specify GIT_KEYFILE path to specify a private key to use for authentication.
if [[ ! -z "$GIT_KEYFILE" ]]; then
	ssh -i $GIT_KEYFILE $*

# Or just use the default identity
else
	ssh $*
fi
