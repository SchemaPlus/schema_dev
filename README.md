# SchemaDev

[![Gem Version](https://badge.fury.io/rb/schema_dev.svg)](http://badge.fury.io/rb/schema_dev)
[![Build Status](https://secure.travis-ci.org/SchemaPlus/schema_dev.svg)](http://travis-ci.org/SchemaPlus/schema_dev)
[![Coverage Status](https://img.shields.io/coveralls/SchemaPlus/schema_dev.svg)](https://coveralls.io/r/SchemaPlus/schema_dev)

Development tools for the SchemaPlus family of gems.

Provides support for working with multiple ruby versions, ActiveRecord, and db versions.  In particular provides a command `schema_dev` for running rspec (or whatever) on the matrix or  a slice or element of it.  It also auto-generates the `.travis.yml` file for [travis-ci](https://travis-ci.org) testing.

## Creating a new gem for the SchemaPlus family

The `schema_dev` script has a generator for new gems:

	$ gem install schema_dev
	$ schema_dev gem new_gem_name
	
Similar to `bundle gem`, this creates a skeleton structure for a new gem.  The structure includes appropriate dependencies on [schema_monkey](https://github.com/SchemaPlus/schema_monkey) and on `schema_dev` itself, and creates an initial `schema_dev.yml` file, etc.
	

## Usage

### schema_dev.yml

The client gem needs a file `schema_dev.yml` in it's root, which specifies the testing matrix among other things.

* `ruby`:  A single version of ruby, or a list of ruby versions.
* `activerecord`: A single version of ActiveRecord, or a list of ActiveRecord versions
* `db`:  A single db adapter, or a list of db adapters.
* `quick`: (Optional) Hash listing the version of ruby, activerecord, and db to use with `--quick` option.  If not specified, the default is to use the last entry in each list.

If you change this file, it's a good idea to run `schema_dev freshen`

### Ruby selection

You must have one of [chruby](https://github.com/postmodern/chruby), [rbenv](https://github.com/sstephenson/rbenv) or [rvm](http://rvm.io) installed and working.  Within it, have available whichever ruby versions you want to test.

### Database

Of course you must have installed whichever database(s) you want to test.

For PostgreSQL and MySQL the tests need a db user with permissions to create and access databases: The default username used by the specs is 'schema_plus' for both PostgreSQL and MySQL; you can change them via:

        $ export POSTGRESQL_DB_USER = pgusername
        $ export MYSQL_DB_USER = mysqlusername

For PostgreSQL and MySQL you must explicitly create the databases used by the tests:

        $ rake create_databases  # creates postgresql and/or mysql as needed

## Running The Tests

In the root directory, you can run, e.g.,

    $ schema_dev bundle install  # or schema_dev bundle update
    $ schema_dev rspec

Which will run those commands over the whole matrix.  You can also specify slices, via any combination of `--ruby`, `--activerecord` and `--db`

    $ schema_dev rspec --ruby 2.1.3 --activerecord 4.0

For convenience you can also use `--quick` to run just one as specified in `schema_dev.yml`

If you want to pass extra arguments to a command, make sure to use `--` to avoid them being processed by `schema_dev`.  e.g.

	$ schema_dev rspec --quick -- -e 'select which spec'

For interactive debugging you may want to run rspec directly from the shell rather than through`schema_dev` (which doesn't give you an interactive ptty).  schema_dev echoes each command being run, preceded by a `*`.  E.g.

	$ schema_dev rspec --quick -- -e 'select which spec' -n

	*** ruby 2.1.5 - activerecord 4.2 - db postgresql [1 of 1]

	* /usr/bin/env BUNDLE_GEMFILE=gemfiles/activerecord-4.2/Gemfile.postgresql SHELL=`which bash` chruby-exec ruby-2.1.5 -- bundle exec rspec -e select\ which\ spec


There's no hidden environment setup; so you can copy and paste the command line into a shell:

	$ /usr/bin/env BUNDLE_GEMFILE=gemfiles/activerecord-4.2/Gemfile.postgresql SHELL=`which bash` chruby-exec ruby-2.1.5 -- bundle exec rspec -e select\ which\ spec

	
For more info, see

    $ schema_dev help
    $ schema_dev help rspec   # etc.

## Auto-generated/updated files

Whenever you run a `schema_dev` matrix command, it first freshens the various generated files; you can also run `schema_dev freshen` manually.

### gemfiles

The client gem will contain a "gemfiles" subdirectory tree containing the matrix of
possible gemfiles; this entire tree gets created/updated automatically, and should be checked into the git repo.

Note that freshening the gemfiles happens automatically whenever you run a schema_dev matrix command, and blows away any previous files.  So you should not attempt to change any files in `gemfiles/*`

If you need to include extra specifications in the Gemfile (e.g. to specify a path for a gem), you can create a file `Gemfile.local` in the project root, and its contents will be included in the Gemfile.

### .travis.yml

The `.travis.yml` file gets created automatically.  Don't edit it by hand.

### README.md

`schema_dev` generates markdown describing the text matrix, and inserts it into the README.md, in a block guarded by markdown comments

    [//]: # SCHEMA_DEV: MATRIX
    .
    .
    .
    [//]: # SCHEMA_DEV: MATRIX


## Behind-the-scenes

#### Rspec

The client gem's`spec/spec_helper` includes this

    require 'schema_dev/rspec'
    SchemaDev::Rspec.setup

This will take care of starting up `schema_monkey`, connecting to the test database appropriately, and and setting up logging to a file specific to the test matrix cell.

#### Rake

The client gem's `Rakefile` includes:

    require 'schema_dev/tasks'

Which defines the rake task `create_databases` and also a task for travis-ci
