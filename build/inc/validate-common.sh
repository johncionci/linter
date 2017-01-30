# The SHA for the specific version of WPCS
WPCS_REVISION=2e27757829cde21bca916b11cfcfa867c42b255e

# Validate only the following paths by default:
FILES=(
	web/*.php
	web/app
)

# And ignore these files (Not used when files are specified
# as arguments):
IGNORE=(
	web/app/plugins
	web/app/mu-plugins
)

# Override FILES and reset IGNORE when CLI arguments are present
if [[ ! -z "$*" ]]; then
	FILES=($*)
	IGNORE=
fi

# Ensure dependencies are installed
if [[ ! -x vendor/bin/phpcs ]]; then
  echo "PHPCS required. Please run build/install.sh"
  exit
fi

if [[ ! -d wpcs ]]; then
  echo "Checking out WP coding standards..."
  git clone -b master https://github.com/WordPress-Coding-Standards/WordPress-Coding-Standards.git wpcs
fi

pushd wpcs;
git checkout $WPCS_REVISION
popd

vendor/bin/phpcs --config-set installed_paths wpcs

# Configure PHPCS
PHPCS_ARGS=(
	--standard=build/ruleset.xml
	--extensions=php
)

for i in ${IGNORE[@]}; do
	PHPCS_ARGS+=("--ignore=$i")
done

PHPCS_ARGS+=("-n")
PHPCS_ARGS+=("-s")
PHPCS_ARGS+=(${FILES[@]})
