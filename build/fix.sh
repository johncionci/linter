#!/bin/bash

# Automatically fix the fixable violations found in PHP code using phpcbf.

. build/inc/validate-common.sh

vendor/bin/phpcbf ${PHPCS_ARGS[@]}
