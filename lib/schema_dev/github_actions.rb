# frozen_string_literal: true

require 'pathname'
require 'yaml'

require_relative 'gemfile_selector'

module SchemaDev
  module GithubActions
    extend self

    WORKFLOW_FILE = '.github/workflows/prs.yml'

    HEADER = <<~YAML
      # This file was auto-generated by the schema_dev tool, based on the data in
      #                 ./schema_dev.yml
      # Please do not edit this file; any changes will be overwritten next time
      # schema_dev gets run.
    YAML

    BASIC_WORKFLOW = {
      name:        'CI PR Builds',
      on:          {
        push:         {
          branches: %w[master],
        },
        pull_request: nil,
      },
      concurrency: {
        group:                '${{ github.head_ref }}',
        'cancel-in-progress': true,
      }
    }.freeze

    BASIC_JOB = { 'runs-on': 'ubuntu-latest' }.freeze

    BASIC_ENV = {
      BUNDLE_GEMFILE: '${{ github.workspace }}/gemfiles/activerecord-${{ matrix.activerecord }}/Gemfile.${{ matrix.db }}'
    }.freeze

    FINISH_STEPS = [
      {
        name: 'Coveralls Finished',
        if:   '${{ !env.ACT }}',
        uses: 'coverallsapp/github-action@master',
        with: {
          'github-token':      '${{ secrets.GITHUB_TOKEN }}',
          'parallel-finished': true,
        }
      }
    ].freeze

    STEPS = {
      start:  [
                {
                  uses: 'actions/checkout@v2',
                },
                {
                  name: 'Set up Ruby',
                  uses: 'ruby/setup-ruby@v1',
                  with: {
                    'ruby-version':  '${{ matrix.ruby }}',
                    'bundler-cache': true,
                  },
                },
                {
                  name: 'Run bundle update',
                  run:  'bundle update',
                },
              ],
      test:   [
                {
                  name: 'Run tests',
                  run:  'bundle exec rake spec',
                }
              ],
      finish: [
                {
                  name: 'Coveralls Parallel',
                  if:   '${{ !env.ACT }}',
                  uses: 'coverallsapp/github-action@master',
                  with: {
                    'github-token': '${{ secrets.GITHUB_TOKEN }}',
                    'flag-name':    'run-${{ matrix.ruby }}-${{ matrix.activerecord }}-${{ matrix.db }}-${{ matrix.dbversion }}',
                    parallel:       true,
                  }
                }
              ],
    }.freeze

    DB_ENV = {
      postgresql: {
        POSTGRESQL_DB_HOST: '127.0.0.1',
        POSTGRESQL_DB_USER: 'schema_plus_test',
        POSTGRESQL_DB_PASS: 'database',
      },
      mysql2:     {
        MYSQL_DB_HOST: '127.0.0.1',
        MYSQL_DB_USER: 'root',
        MYSQL_DB_PASS: 'database',
      },
    }.freeze

    DB_STARTUP = {
      postgresql: [
                    {
                      name: 'Start Postgresql',
                      if:   "matrix.db == 'postgresql'",
                      run:  <<~BASH
                        docker run --rm --detach \\
                          -e POSTGRES_USER=$POSTGRESQL_DB_USER \\
                          -e POSTGRES_PASSWORD=$POSTGRESQL_DB_PASS \\
                          -p 5432:5432 \\
                          --health-cmd "pg_isready -q" \\
                          --health-interval 5s \\
                          --health-timeout 5s \\
                          --health-retries 5 \\
                          --name database postgres:${{ matrix.dbversion }}
                      BASH
                    },
                  ],
      mysql2:     [
                    {
                      name: 'Start Mysql',
                      if:   "matrix.db == 'mysql2'",
                      run:  <<~BASH
                        docker run --rm --detach \\
                          -e MYSQL_ROOT_PASSWORD=$MYSQL_DB_PASS \\
                          -p 3306:3306 \\
                          --health-cmd "mysqladmin ping --host=127.0.0.1 --password=$MYSQL_DB_PASS --silent" \\
                          --health-interval 5s \\
                          --health-timeout 5s \\
                          --health-retries 5 \\
                          --name database mysql:5.6
                      BASH
                    }
                  ],
    }.freeze

    DB_SETUP_NEEDED    = %w[postgresql mysql2].freeze
    DB_SETUP           = [
      {
        name: 'Wait for database to start',
        if:   "(matrix.db == 'postgresql' || matrix.db == 'mysql2')",
        run:  <<~BASH
          COUNT=0
          ATTEMPTS=20
          until [[ $COUNT -eq $ATTEMPTS ]]; do
            [ "$(docker inspect -f {{.State.Health.Status}} database)" == "healthy" ] && break
            echo $(( COUNT++ )) > /dev/null
            sleep 2
          done
        BASH
      },
      {
        name: 'Create testing database',
        if:   "(matrix.db == 'postgresql' || matrix.db == 'mysql2')",
        run:  'bundle exec rake create_ci_database',
      },
    ].freeze
    DB_TEARDOWN_NEEDED = %w[postgresql mysql2].freeze
    DB_TEARDOWN        = [
      {
        name: 'Shutdown database',
        if:   "always() && (matrix.db == 'postgresql' || matrix.db == 'mysql2')",
        run:  'docker stop database',
      }
    ].freeze

    def build(config)
      matrix, env = build_matrices(config)
      db_setup    = []
      db_teardown = []
      config.db.each do |db|
        db_setup.concat DB_STARTUP.fetch(db.to_sym, [])
      end
      db_setup.concat(DB_SETUP) if config.db.any? { |e| DB_SETUP_NEEDED.include?(e) }
      db_teardown.concat(DB_TEARDOWN) if config.db.any? { |e| DB_TEARDOWN_NEEDED.include?(e) }

      strategy = {
        'fail-fast': false,
        matrix:      matrix,
      }

      steps = [
        *STEPS[:start],
        *db_setup,
        *STEPS[:test],
        *db_teardown,
        *STEPS[:finish],
      ]

      {}.tap do |workflow|
        workflow.merge!(BASIC_WORKFLOW)
        workflow[:jobs] = {
          test:   {}.merge(BASIC_JOB)
                    .merge({
                             strategy: strategy,
                             env:      env,
                             steps:    steps
                           }.compact),
          finish: {
                    needs: 'test'
                  }.merge(BASIC_JOB)
                   .merge(steps: FINISH_STEPS)
        }
      end.deep_stringify_keys
    end

    def build_matrices(config)
      include_skip = false

      matrix = {
        ruby:         config.ruby,
        activerecord: config.activerecord,
        db:           [*config.db],
        dbversion:    [],
        exclude:      [],
        include:      [],
      }

      if config.exclude.any?
        matrix[:exclude] = config.exclude.map(&:to_hash).reject { |e| e.key?(:dbversion) }
      end

      env = {}.merge(BASIC_ENV)
      config.db.each do |db|
        env.merge!(DB_ENV.fetch(db.to_sym, {}))
      end

      if config.db.include?('postgresql')
        include_skip = true
        matrix[:db].delete('postgresql')
        config.matrix(db: 'postgresql', with_dbversion: true).map do |entry|
          matrix[:include] << entry
        end
      end

      if include_skip
        matrix[:db] << 'skip'
        matrix[:dbversion] << 'skip'
        matrix[:exclude] << { db: 'skip', dbversion: 'skip' }
      end

      [
        matrix.reject { |_, val| val.empty? },
        env
      ]
    end

    def update(config)
      filepath = Pathname.new(WORKFLOW_FILE)
      filepath.dirname.mkpath
      newworkflow = build(config)
      oldworkflow = YAML.safe_load(filepath.read) rescue nil
      if oldworkflow != newworkflow
        yaml_output = newworkflow.to_yaml(line_width: -1)
        # fix for some broken libyaml implementations (< 0.2.5)
        yaml_output.gsub!('pull_request: ', 'pull_request:')
        filepath.write HEADER + yaml_output
        return true
      end
      false
    end
  end
end
