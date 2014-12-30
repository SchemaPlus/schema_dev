# SchemaDev

[![Gem Version](https://badge.fury.io/rb/schema_dev.svg)](http://badge.fury.io/rb/schema_dev)
[![Build Status](https://secure.travis-ci.org/SchemaPlus/schema_dev.svg)](http://travis-ci.org/SchemaPlus/schema_dev)
[![Coverage Status](https://img.shields.io/coveralls/SchemaPlus/schema_dev.svg)](https://coveralls.io/r/SchemaPlus/schema_dev)

Development tools for the SchemaPlus family of gems.

Provides support for working with multiple ruby versions, rails adapaters, and db versions.  In particular provides a command `schema_dev` for running rspec (or whatever) on the matrix or  a slice or element of it.  It also auto-generates the `.travis.yml` file for [travis-ci](https://travis-ci.org) testing.

## Installation

Include this as a development dependency in the client gem's `<ame>.gemfile`:

    s.add_development_dependency "schema_dev"

## Setup

#### `schema_dev.yml`

The client gem needs a file `schema_dev.yml` in it's root, which specifies the testing matrix among other things.

* `ruby`:  A single version of ruby, or a list of ruby versions.
* `rails`: A single version of rails, or a list of rails versions
* `db`:  A single db adapter, or a list of db adapters.
* `quick`: (Optional) Hash listing the version of ruby, rails, and db to use with `--quick` option.  If not specified, the default is to use the last entry in each list.

#### Gemfiles

The client gem must contain a "gemfiles" directory containing the matrix of
possible gemfiles; Generate it by running

        $ schema_dev gemfiles

This directory should be checked in to the git repo.

`schema_dev gemfiles` only generates gemfiles for the versions of rails &
db listed in `schema_dev.yml`.  If you change the listed versions you'll
need to re-generate.

Note that generating the gemfiles blows away any previous files.  If you had made
local changes for some reason, you'll need to rely on git to recover them.

    
#### Rspec

The client gem should include this in its `spec/spec_helper`

    require 'schema_dev/rspec'
    SchemaDev::Rspec.setup_db
    
This will take care of connecting to the test database appropriately, and will set up logging to a file specific to the test matrix cell.

#### Rake

The client gem should include this in its `Rakefile`:

    require 'schema_dev/tasks'

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

    $ schema_dev bundle install
    $ schema_dev rspec

Which will run those commands over the whole matrix.  You can also specify slices, via any combination of `--ruby`, `--rails` and `--db`

    $ schema_dev rspec --ruby 2.1.3 --rails 4.0

For convenience you can also use `--quick` to run just one as specified in `schema_dev.yml`

If you want to pass extra arguments to a command, make sure to use `--` to avoid them being processed by `schema_dev`.  e.g.

	$ schema_dev rspec --quick -- -e 'select which spec'
	
For more info, see

    $ schema_dev help
    $ schema_dev help rspec   # etc.

## Generating `.travis.yml`

To keep things in sync `.travis.yml` gets automatically updated whenever you run `schema_dev matrix` or any of its shorthands.  There's also a command to just explicitly update `.travis.yml`

    $ schema_dev travis
