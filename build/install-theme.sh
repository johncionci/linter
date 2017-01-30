#!/usr/bin/env bash -e

cd "${BASH_SOURCE%/*}"

. project.env

cd ..

target="web/app/themes/$PROJECT_SNAKE"

echo "Downloading theme files to $target"
git clone --depth 1 https://github.com/Automattic/_s.git "$target"

pushd "$target"
	echo "Deleting unneeded files"
	rm -rf .git sass .jscsrc .jshintignore .travis.yml CONTRIBUTING.md codesniffer.ruleset.xml README.md readme.txt style.css
popd

echo "Replacing _s references with '$PROJECT_SNAKE' in theme files"
find "$target" -type f -iname '*.php' -exec sed -i '' "s/'_s'/'$PROJECT_SNAKE'/g;s/_s_/${PROJECT_SNAKE}_/g;s/ _s/ $PROJECT_NAME/g;s/_s-/$PROJECT_SLUG-/g" {} \;

echo "Generating style.css file"
cat <<STYLE > "$target/style.css"
/*
Theme Name: $PROJECT_NAME
Author: Oomph, Inc.
Author URI: http://www.oomphinc.com/
Description: Our lovely theme for $PROJECT_NAME!
Version: 1.0.0
Text Domain: $PROJECT_SNAKE
*/

STYLE

echo "Downloading SCSS Scaffold files to src/scss"
git clone --depth 1 git@github.com:oomphinc/scss-scaffold.git src/scss
rm -rf src/scss/.git
mv src/scss/.scss-lint.yml .

echo "Downloading Bourbon to src/scss/libraries"
svn export https://github.com/thoughtbot/bourbon/tags/v4.2.6/app/assets/stylesheets src/scss/libraries/bourbon -q

echo "Downloading Neat to src/scss/libraries"
svn export https://github.com/thoughtbot/neat/tags/v1.7.2/app/assets/stylesheets src/scss/libraries/neat -q

echo 'Fin.'
