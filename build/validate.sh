#!/bin/bash

# Validate files, aggregate error messages and display at the end.

. build/inc/validate-common.sh

errors=()

# Clear validation errors
cat /dev/null >.validation-errors

function list {
	perl -e 'print join("\n\t", @ARGV);' $@
	echo
}

function cleanup {
	rm .validation-errors
}

trap cleanup EXIT TERM

echo "Checking PHP for syntax errors..."
for path in ${FILES[@]}; do
	for file in `find $path -name '*.php'`; do
		if ! php -l $file 2>>.validation-errors; then
			errors+=($file)
		fi
	done
done

if [ ! -z $errors ]; then
	echo -n "There were errors in the following files:
	"

	list ${errors[@]}

	cat .validation-errors

	exit 1
fi

vendor/bin/phpcs ${PHPCS_ARGS[@]}
