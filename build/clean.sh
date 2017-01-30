#!/bin/bash

## Clean up after a build.
echo "Cleaning..."

. build/inc/common.sh

# Use reasonable defaults for non-blank DB auth
DB_USER=${DB_USER:-root}
DB_HOST=${DB_HOST:-localhost}

echo "Removing generated artifacts..."

echo "Removing test results..."
rm -rf tests/results

pushd web
  echo "Removing WP test framework..."
  if [[ -d tests ]]; then
    rm -rf tests
  fi

  if [[ ! -f .db-cache ]]; then
    echo "No .db-cache, presumably because there are no temporary databases!"
    exit
  fi

  for dbn in `cat .db-cache`; do
    # If there's no argument or the file is in the argument list...
    if [[ -z $* || $* =~ $dbn ]]; then
      echo "Dropping database $dbn...";
      mysql -u $DB_USER -h $DB_HOST --password="$DB_PASSWORD" -e "DROP DATABASE \`$dbn\`;"
    fi
  done

  rm .db-cache
popd
