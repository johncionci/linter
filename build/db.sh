#!/bin/bash -e

# Save to or update from the bundled SQL DB dump

# If the vagrant command exists, assume we are outside of the vagrant
if type vagrant > /dev/null 2>&1; then
	vagrant ssh -c "/vagrant/build/db.sh $@"
	exit 0
fi

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" #dir where this file lives

# get our project env vars
. "$dir/project.env"

# resolve file name
if [ -n "$2" ]; then
	file="$PWD/$2"
else
	file="$dir/sql/$PROJECT_SLUG.sql"
fi

cd $dir

wp="../vendor/bin/wp"

case $1 in

	# import an SQL file to overwrite existing DB
	"import" )
		if [ -f "$file" ]; then
			# empty the DB
			$wp db reset --yes
			$wp db import "$file"
		else
			echo "Import file $file not found."
			exit 1
		fi
	;;

	# export db to SQL file
	"export" )
		mkdir -p "$(dirname $file)"
		if [ -f "$file" ]; then
			cp -f "$file" "$(dirname "$file")/.$(basename "$file").orig"
		fi
		$wp db export "$file"
	;;

	* )
		cat <<-DOG
			Usage: $0 <import|export> [filename]

			If omitted, filename reflects the project slug, i.e. 'sql/$PROJECT_SLUG.sql'
		DOG
		exit 1
	;;

esac
