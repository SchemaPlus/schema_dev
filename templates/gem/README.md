[![Gem Version](https://badge.fury.io/rb/%GEM_NAME%.svg)](http://badge.fury.io/rb/%GEM_NAME%)
[![Build Status](https://secure.travis-ci.org/SchemaPlus/%GEM_NAME%.svg)](http://travis-ci.org/SchemaPlus/%GEM_NAME%)
[![Coverage Status](https://img.shields.io/coveralls/SchemaPlus/%GEM_NAME%.svg)](https://coveralls.io/r/SchemaPlus/%GEM_NAME%)
[![Dependency Status](https://gemnasium.com/lomba/%GEM_NAME%.svg)](https://gemnasium.com/SchemaPlus/%GEM_NAME%)

# %GEM_MODULE%

TODO: Write a gem description

%GEM_MODULE% is part of the [SchemaPlus](https://github.com/SchemaPlus/) family of Ruby on Rails extension gems.

## Installation

In your application's Gemfile

```ruby
gem "%GEM_NAME%"
```
## Compatibility

%GEM_MODULE% is tested on:

<!-- SCHEMA_DEV: MATRIX -->

## Usage

TODO: Write usage instructions here

## History

*   See [CHANGELOG](CHANGELOG.md) for per-version release notes.

## Development & Testing

Are you interested in contributing to %GEM_MODULE%?  Thanks!  Please follow the standard protocol: fork, feature branch, develop, push, and issue pull request.

Some things to know about to help you develop and test:

* **schema_dev**:  %GEM_MODULE% uses [schema_dev](https://github.com/SchemaPlus/schema_dev) to
  facilitate running rspec tests on the matrix of ruby, rails, and database
  versions that the gem supports, both locally and on
  [travis-ci](http://travis-ci.org/SchemaPlus/%GEM_NAME%)

  To to run rspec locally on the full matrix, do:

        $ schema_dev bundle install
        $ schema_dev rspec

  You can also run on just one configuration at a time;  For info, see `schema_dev --help` or the [schema_dev](https://github.com/SchemaPlus/schema_dev) README.

  The matrix of configurations is specified in `schema_dev.yml` in
  the project root.

* **schema_monkey**: %GEM_MODULE% extends ActiveRecord using
  [schema_monkey](https://github.com/SchemaPlus/schema_monkey)'s extension API and protocols -- see its README for details.  If your contribution needs any additional monkey patching that isn't already supported by [schema_monkey](https://github.com/SchemaPlus/schema_monkey), please head over there and submit a PR.
