# Pre Commit Linter

Pre Commit Linter is a WordPress project.

## Installation

Run `build/install.sh` to install dependencies.

## Development Quick Start (Vagrant)

Quickly jump into development using a virtual machine provisioned by Vagrant. This will attempt to retrieve a pre-rendered environment.

### Requirements:

* Vagrant 1.5+
* Ansible 2.0+

This repository includes a Vagrantfile that spins up a local test environment that listens on the hostname `pre-commit-linter.dev`. Make sure that you have the `vagrant-hostmanager` plugin installed in order to reap the benefits of the automatically provisioned hostname.

Install the plugin as follows:

```sh
$ vagrant plugin install vagrant-hostmanager
```

You should now be able to invoke a Vagrant environment which can be accessed at
`pre-commit-linter.dev` with `vagrant up`.

## Development Medium-Speed Start (Local \*AMP Stack)

This is for environments running local Apache and MySQL servers, serving the site directly from `web/` in the repository.

### Requirements:

* PHP 5.3+
* Node 0.10+
* NPM 1.4+
* MySQL 5.5+ Server
* Apache 2.4+

Set up a VirtualHost in Apache that points to `web/` in this repository and serves at the hostname you put in `WP_HOME`. Then define, at minimum, the following variables in `build/build.env`:

```sh
WP_HOME=     # The deployment home URL – Required!
DB_USER=     # The database user, defaults to `root`
DB_PASSWORD= # The database password, defaults to ``
DB_NAME=     # The database name, defaults to `Pre Commit Linter_db`
```

For example,

```sh
WP_HOME=http://pre-commit-linter.dev
DB_USER=root
DB_PASSWORD=
DB_NAME=pre-commit-linter_db
```

You can define any WP other constant in this file and it will be set up in the deployed environment.

Any of these variables can be given through the environment of the WordPress process, either through the shell when using `wp-cli`, or through the webserver.

## Development Slow Start

This repository also includes the capability to manage deployments of installs automatically via Apache VirtualHosts. This is more advanced usage that is depended upon by the Jenkins set up.

```sh
# Copy and edit build configuration file
~/$ cp build/build.env.sample build/build.env

# Set at minimum, DB_USER, DB_PASSWORD, DB_HOST
~/pre-commit-linter$ vi build/build.env

# Build site: Install dependencies, validate PHP, run unit tests
~/pre-commit-linter$ ./build-and-test.sh

# Deploy site to local install specified in build.env.
~/pre-commit-linter$ ./build-and-test.sh local

# Deploy site to a specific install name
~/pre-commit-linter$ INSTALL_NAME=myinstall ./build-and-test.sh
```

## Deployment Targets

Arbitrary deployment scripts can be specified in the `build/` directory. These script take the form of `build/deploy-$target.sh`, where `$target` is the name of the deployment target. This target can be specified as an argument to the CI `./build-and-test.sh` script, or as an environment variable in `DEPLOY_ENVIRONMENT`. These scripts are called with the deploy environment as an argument, so the same script can be used for multiple environments by using symlinks.

## Compiling Assets

Pre Commit Linter uses `brunch` for building asset files, and `bower` to manage
front-end dependencies.

Asset files are compiled as follows:

| Source File        | Compiled File                                         |
| ------------------ | ----------------------------------------------------- |
| src/scss/*.scss    | web/app/themes/pre-commit-linter/assets/css/styles.css |
| src/js/*.js        | web/app/themes/pre-commit-linter/assets/js/main.js     |
| bower_components/* | web/app/themes/pre-commit-linter/assets/js/vendor.js   |

To build the assets run `brunch build` in the project root. To have brunch watch
for changes and automatically compile them, run `brunch watch` in the project
root.

To install bower dependencies, run `bower install <library>`.

### BrowserSync
[BrowserSync](http://www.browsersync.io/) allows you to do synchronised browser testing.
It *should* just work with the predetermined configuration ( but that never happens ) so to review the configuration
refer to [BrowserSync Docs](http://www.browsersync.io/docs/)

#### BrowserSync Usage
Simply run `brunch w` as you normally would it BrowserSync will open a new browser tab/window at the local Vagrant address.
To view synchronization on other devices grab your systems IP address and add the default port of 3000 to the url
for example 192.168.5.186:3000 - enjoy!

## Build Scripts.

This repository provides a variety of files. These build scripts should be run at the root of the repository, using the full relative path. Many scripts accepts arguments in the form `[files...]`, which is a list of one or more paths which will be processed recursively.

##### `./build-and-test.sh [target]`

The top-level CI script. Install, lint, validate, test, and possibly deploy the project if a deployment target argument is given. Deployment to `[target]` is provided by the script `build/deploy-$target.sh`.

##### `build/install.sh`

Detect that Node and NPM dependencies are satisfied. Install and update PHP dependencies specified in `composer.json`.

##### `build/lint.sh [files...]`

Syntax-check all PHP files.

##### `build/phpcs.sh [files...]`

Check that all PHP code meets coding standards with PHP CodeSniffer.

##### `build/validate.sh [files...]`

Lint and CodeSniffer all PHP code. Equivalent to running `build/lint.sh` followed by `build/phpcs.sh`.

##### `build/fix.sh [files...]`

Automatically fix any fixable coding violations found with PHP CodeSniffer. This is not done as part of any build process, as it affects version-controlled code.

##### `build/test.sh [filters]`

Run all tests.

Checks out WordPress testing suite to `web/tests` if it does not exist. Will create a testing database using the database provided in the `TEST_DB_NAME` build environment variable, or will use a randomly-generated database name if `TEST_DB_NAME` is not defined.

If a randomly-generated database name is used, its name will be stored in the file `.db-cache` for re-use in future runs of this script.

You can filter which tests are run with arguments.

##### `build/deploy.sh [target]`

Build the site for deployment and deploy it to staging, production or locally. Deployment targets are:

* `production` – Deploy to production environment. For WP Engine, requires git push access with a keyfile specified by `GIT_KEYFILE`, defaulting to `~/.ssh/id_rsa.pre-commit-linter`.

* `staging` – Deploy to staging environment. Also requires a keyfile.

* `local` – Deploy to a local instance according to the build environment. This is equivalent to executing `build//deploy-local.sh`.

##### `build/deploy-local.sh`

Deploy the site code to a local install.

##### `build/clean.sh [databases]`

Clean the local environment, removing wordpress test files and results, and all test databases found in `.db-cache`. If a databases argument is given, only delete matching databases.
