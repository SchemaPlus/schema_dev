# frozen_string_literal: true

require 'schema_dev/github_actions'

describe SchemaDev::GithubActions do
  subject do
    in_tmpdir do
      described_class.update(get_config(config))
      Pathname.new(described_class::WORKFLOW_FILE).read
    end
  end

  let(:config) { {} }

  context 'when only having sqlite3 enabled' do
    let(:config) do
      {
        ruby: [2.5],
        activerecord: [5.2, 6.0],
        db: %w[sqlite3]
      }
    end

    it 'creates a workflow file containing setup for just sqlite3' do
      is_expected.to eq described_class::HEADER + <<~YAML
        ---
        name: CI PR Builds
        'on':
          push:
            branches:
            - master
          pull_request:
        concurrency:
          group: ci-${{ github.ref }}
          cancel-in-progress: true
        jobs:
          test:
            runs-on: ubuntu-latest
            strategy:
              fail-fast: false
              matrix:
                ruby:
                - '2.5'
                activerecord:
                - '5.2'
                - '6.0'
                db:
                - sqlite3
            env:
              BUNDLE_GEMFILE: "${{ github.workspace }}/gemfiles/activerecord-${{ matrix.activerecord }}/Gemfile.${{ matrix.db }}"
            steps:
            - uses: actions/checkout@v2
            - name: Set up Ruby
              uses: ruby/setup-ruby@v1
              with:
                ruby-version: "${{ matrix.ruby }}"
                bundler-cache: true
            - name: Run bundle update
              run: bundle update
            - name: Run tests
              run: bundle exec rake spec
            - name: Coveralls Parallel
              if: "${{ !env.ACT }}"
              uses: coverallsapp/github-action@master
              with:
                github-token: "${{ secrets.GITHUB_TOKEN }}"
                flag-name: run-${{ matrix.ruby }}-${{ matrix.activerecord }}-${{ matrix.db }}-${{ matrix.dbversion }}
                parallel: true
          finish:
            needs: test
            runs-on: ubuntu-latest
            steps:
            - name: Coveralls Finished
              if: "${{ !env.ACT }}"
              uses: coverallsapp/github-action@master
              with:
                github-token: "${{ secrets.GITHUB_TOKEN }}"
                parallel-finished: true
      YAML
    end
  end

  context 'when ruby 3 is included with AR < 6.0' do
    let(:config) do
      {
        ruby: [2.5, 3.0],
        activerecord: [5.2, 6.0],
        db: %w[sqlite3]
      }
    end

    it 'automatically excludes old AR on ruby 3' do
      is_expected.to eq described_class::HEADER + <<~YAML
        ---
        name: CI PR Builds
        'on':
          push:
            branches:
            - master
          pull_request:
        concurrency:
          group: ci-${{ github.ref }}
          cancel-in-progress: true
        jobs:
          test:
            runs-on: ubuntu-latest
            strategy:
              fail-fast: false
              matrix:
                ruby:
                - '2.5'
                - '3.0'
                activerecord:
                - '5.2'
                - '6.0'
                db:
                - sqlite3
                exclude:
                - ruby: '3.0'
                  activerecord: '5.2'
            env:
              BUNDLE_GEMFILE: "${{ github.workspace }}/gemfiles/activerecord-${{ matrix.activerecord }}/Gemfile.${{ matrix.db }}"
            steps:
            - uses: actions/checkout@v2
            - name: Set up Ruby
              uses: ruby/setup-ruby@v1
              with:
                ruby-version: "${{ matrix.ruby }}"
                bundler-cache: true
            - name: Run bundle update
              run: bundle update
            - name: Run tests
              run: bundle exec rake spec
            - name: Coveralls Parallel
              if: "${{ !env.ACT }}"
              uses: coverallsapp/github-action@master
              with:
                github-token: "${{ secrets.GITHUB_TOKEN }}"
                flag-name: run-${{ matrix.ruby }}-${{ matrix.activerecord }}-${{ matrix.db }}-${{ matrix.dbversion }}
                parallel: true
          finish:
            needs: test
            runs-on: ubuntu-latest
            steps:
            - name: Coveralls Finished
              if: "${{ !env.ACT }}"
              uses: coverallsapp/github-action@master
              with:
                github-token: "${{ secrets.GITHUB_TOKEN }}"
                parallel-finished: true
      YAML
    end
  end

  context 'when AR 7.0 is included with Ruby < 2.7' do
    let(:config) do
      {
        ruby: [2.5, 2.7],
        activerecord: [6.0, 7.0],
        db: %w[sqlite3]
      }
    end

    it 'automatically excludes Ruby < 2.7 for AR 7.0' do
      is_expected.to eq described_class::HEADER + <<~YAML
        ---
        name: CI PR Builds
        'on':
          push:
            branches:
            - master
          pull_request:
        concurrency:
          group: ci-${{ github.ref }}
          cancel-in-progress: true
        jobs:
          test:
            runs-on: ubuntu-latest
            strategy:
              fail-fast: false
              matrix:
                ruby:
                - '2.5'
                - '2.7'
                activerecord:
                - '6.0'
                - '7.0'
                db:
                - sqlite3
                exclude:
                - ruby: '2.5'
                  activerecord: '7.0'
            env:
              BUNDLE_GEMFILE: "${{ github.workspace }}/gemfiles/activerecord-${{ matrix.activerecord }}/Gemfile.${{ matrix.db }}"
            steps:
            - uses: actions/checkout@v2
            - name: Set up Ruby
              uses: ruby/setup-ruby@v1
              with:
                ruby-version: "${{ matrix.ruby }}"
                bundler-cache: true
            - name: Run bundle update
              run: bundle update
            - name: Run tests
              run: bundle exec rake spec
            - name: Coveralls Parallel
              if: "${{ !env.ACT }}"
              uses: coverallsapp/github-action@master
              with:
                github-token: "${{ secrets.GITHUB_TOKEN }}"
                flag-name: run-${{ matrix.ruby }}-${{ matrix.activerecord }}-${{ matrix.db }}-${{ matrix.dbversion }}
                parallel: true
          finish:
            needs: test
            runs-on: ubuntu-latest
            steps:
            - name: Coveralls Finished
              if: "${{ !env.ACT }}"
              uses: coverallsapp/github-action@master
              with:
                github-token: "${{ secrets.GITHUB_TOKEN }}"
                parallel-finished: true
      YAML
    end
  end

  context 'when notify is passed' do
    let(:config) do
      {
        ruby: [2.5],
        activerecord: [5.2],
        db: %w[sqlite3],
        notify: 'me@example.com'
      }
    end

    around do |ex|
      suppress_stdout_stderr(&ex)
    end

    it 'outputs a warning' do
      expect { subject }.to output(/Notify is no longer supported/).to_stderr
    end

    it 'does not include it in the workflow' do
      is_expected.to eq described_class::HEADER + <<~YAML
        ---
        name: CI PR Builds
        'on':
          push:
            branches:
            - master
          pull_request:
        concurrency:
          group: ci-${{ github.ref }}
          cancel-in-progress: true
        jobs:
          test:
            runs-on: ubuntu-latest
            strategy:
              fail-fast: false
              matrix:
                ruby:
                - '2.5'
                activerecord:
                - '5.2'
                db:
                - sqlite3
            env:
              BUNDLE_GEMFILE: "${{ github.workspace }}/gemfiles/activerecord-${{ matrix.activerecord }}/Gemfile.${{ matrix.db }}"
            steps:
            - uses: actions/checkout@v2
            - name: Set up Ruby
              uses: ruby/setup-ruby@v1
              with:
                ruby-version: "${{ matrix.ruby }}"
                bundler-cache: true
            - name: Run bundle update
              run: bundle update
            - name: Run tests
              run: bundle exec rake spec
            - name: Coveralls Parallel
              if: "${{ !env.ACT }}"
              uses: coverallsapp/github-action@master
              with:
                github-token: "${{ secrets.GITHUB_TOKEN }}"
                flag-name: run-${{ matrix.ruby }}-${{ matrix.activerecord }}-${{ matrix.db }}-${{ matrix.dbversion }}
                parallel: true
          finish:
            needs: test
            runs-on: ubuntu-latest
            steps:
            - name: Coveralls Finished
              if: "${{ !env.ACT }}"
              uses: coverallsapp/github-action@master
              with:
                github-token: "${{ secrets.GITHUB_TOKEN }}"
                parallel-finished: true
      YAML
    end
  end

  context 'when only having postgresql enabled' do
    let(:config) do
      {
        ruby: [2.5],
        activerecord: [5.2, 6.0],
        db: %w[postgresql]
      }
    end

    it 'creates a workflow file containing setup for just postgresql' do
      is_expected.to eq described_class::HEADER + <<~YAML
        ---
        name: CI PR Builds
        'on':
          push:
            branches:
            - master
          pull_request:
        concurrency:
          group: ci-${{ github.ref }}
          cancel-in-progress: true
        jobs:
          test:
            runs-on: ubuntu-latest
            strategy:
              fail-fast: false
              matrix:
                ruby:
                - '2.5'
                activerecord:
                - '5.2'
                - '6.0'
                db:
                - skip
                dbversion:
                - skip
                exclude:
                - db: skip
                  dbversion: skip
                include:
                - ruby: '2.5'
                  activerecord: '5.2'
                  db: postgresql
                  dbversion: '9.6'
                - ruby: '2.5'
                  activerecord: '6.0'
                  db: postgresql
                  dbversion: '9.6'
            env:
              BUNDLE_GEMFILE: "${{ github.workspace }}/gemfiles/activerecord-${{ matrix.activerecord }}/Gemfile.${{ matrix.db }}"
              POSTGRESQL_DB_HOST: 127.0.0.1
              POSTGRESQL_DB_USER: schema_plus_test
              POSTGRESQL_DB_PASS: database
            steps:
            - uses: actions/checkout@v2
            - name: Set up Ruby
              uses: ruby/setup-ruby@v1
              with:
                ruby-version: "${{ matrix.ruby }}"
                bundler-cache: true
            - name: Run bundle update
              run: bundle update
            - name: Start Postgresql
              if: matrix.db == 'postgresql'
              run: |
                docker run --rm --detach \\
                  -e POSTGRES_USER=$POSTGRESQL_DB_USER \\
                  -e POSTGRES_PASSWORD=$POSTGRESQL_DB_PASS \\
                  -p 5432:5432 \\
                  --health-cmd "pg_isready -q" \\
                  --health-interval 5s \\
                  --health-timeout 5s \\
                  --health-retries 5 \\
                  --name database postgres:${{ matrix.dbversion }}
            - name: Wait for database to start
              if: "(matrix.db == 'postgresql' || matrix.db == 'mysql2')"
              run: |
                COUNT=0
                ATTEMPTS=20
                until [[ $COUNT -eq $ATTEMPTS ]]; do
                  [ "$(docker inspect -f {{.State.Health.Status}} database)" == "healthy" ] && break
                  echo $(( COUNT++ )) > /dev/null
                  sleep 2
                done
            - name: Create testing database
              if: "(matrix.db == 'postgresql' || matrix.db == 'mysql2')"
              run: bundle exec rake create_ci_database
            - name: Run tests
              run: bundle exec rake spec
            - name: Shutdown database
              if: always() && (matrix.db == 'postgresql' || matrix.db == 'mysql2')
              run: docker stop database
            - name: Coveralls Parallel
              if: "${{ !env.ACT }}"
              uses: coverallsapp/github-action@master
              with:
                github-token: "${{ secrets.GITHUB_TOKEN }}"
                flag-name: run-${{ matrix.ruby }}-${{ matrix.activerecord }}-${{ matrix.db }}-${{ matrix.dbversion }}
                parallel: true
          finish:
            needs: test
            runs-on: ubuntu-latest
            steps:
            - name: Coveralls Finished
              if: "${{ !env.ACT }}"
              uses: coverallsapp/github-action@master
              with:
                github-token: "${{ secrets.GITHUB_TOKEN }}"
                parallel-finished: true
      YAML
    end
  end

  context 'when only having mysql2 enabled' do
    let(:config) do
      {
        ruby: [2.5],
        activerecord: [5.2, 6.0],
        db: %w[mysql2]
      }
    end

    it 'creates a workflow file containing setup for just mysql2' do
      is_expected.to eq described_class::HEADER + <<~YAML
        ---
        name: CI PR Builds
        'on':
          push:
            branches:
            - master
          pull_request:
        concurrency:
          group: ci-${{ github.ref }}
          cancel-in-progress: true
        jobs:
          test:
            runs-on: ubuntu-latest
            strategy:
              fail-fast: false
              matrix:
                ruby:
                - '2.5'
                activerecord:
                - '5.2'
                - '6.0'
                db:
                - mysql2
            env:
              BUNDLE_GEMFILE: "${{ github.workspace }}/gemfiles/activerecord-${{ matrix.activerecord }}/Gemfile.${{ matrix.db }}"
              MYSQL_DB_HOST: 127.0.0.1
              MYSQL_DB_USER: root
              MYSQL_DB_PASS: database
            steps:
            - uses: actions/checkout@v2
            - name: Set up Ruby
              uses: ruby/setup-ruby@v1
              with:
                ruby-version: "${{ matrix.ruby }}"
                bundler-cache: true
            - name: Run bundle update
              run: bundle update
            - name: Start Mysql
              if: matrix.db == 'mysql2'
              run: |
                docker run --rm --detach \\
                  -e MYSQL_ROOT_PASSWORD=$MYSQL_DB_PASS \\
                  -p 3306:3306 \\
                  --health-cmd "mysqladmin ping --host=127.0.0.1 --password=$MYSQL_DB_PASS --silent" \\
                  --health-interval 5s \\
                  --health-timeout 5s \\
                  --health-retries 5 \\
                  --name database mysql:5.6
            - name: Wait for database to start
              if: "(matrix.db == 'postgresql' || matrix.db == 'mysql2')"
              run: |
                COUNT=0
                ATTEMPTS=20
                until [[ $COUNT -eq $ATTEMPTS ]]; do
                  [ "$(docker inspect -f {{.State.Health.Status}} database)" == "healthy" ] && break
                  echo $(( COUNT++ )) > /dev/null
                  sleep 2
                done
            - name: Create testing database
              if: "(matrix.db == 'postgresql' || matrix.db == 'mysql2')"
              run: bundle exec rake create_ci_database
            - name: Run tests
              run: bundle exec rake spec
            - name: Shutdown database
              if: always() && (matrix.db == 'postgresql' || matrix.db == 'mysql2')
              run: docker stop database
            - name: Coveralls Parallel
              if: "${{ !env.ACT }}"
              uses: coverallsapp/github-action@master
              with:
                github-token: "${{ secrets.GITHUB_TOKEN }}"
                flag-name: run-${{ matrix.ruby }}-${{ matrix.activerecord }}-${{ matrix.db }}-${{ matrix.dbversion }}
                parallel: true
          finish:
            needs: test
            runs-on: ubuntu-latest
            steps:
            - name: Coveralls Finished
              if: "${{ !env.ACT }}"
              uses: coverallsapp/github-action@master
              with:
                github-token: "${{ secrets.GITHUB_TOKEN }}"
                parallel-finished: true
      YAML
    end
  end

  context 'when only having postgresql with multiple DB versions' do
    let(:config) do
      {
        ruby: [2.5],
        activerecord: [5.2, 6.0],
        db: %w[postgresql],
        dbversions: { postgresql: [9.6, 10] }
      }
    end

    it 'creates a workflow file containing setup for just postgresql' do
      is_expected.to eq described_class::HEADER + <<~YAML
        ---
        name: CI PR Builds
        'on':
          push:
            branches:
            - master
          pull_request:
        concurrency:
          group: ci-${{ github.ref }}
          cancel-in-progress: true
        jobs:
          test:
            runs-on: ubuntu-latest
            strategy:
              fail-fast: false
              matrix:
                ruby:
                - '2.5'
                activerecord:
                - '5.2'
                - '6.0'
                db:
                - skip
                dbversion:
                - skip
                exclude:
                - db: skip
                  dbversion: skip
                include:
                - ruby: '2.5'
                  activerecord: '5.2'
                  db: postgresql
                  dbversion: '9.6'
                - ruby: '2.5'
                  activerecord: '5.2'
                  db: postgresql
                  dbversion: '10'
                - ruby: '2.5'
                  activerecord: '6.0'
                  db: postgresql
                  dbversion: '9.6'
                - ruby: '2.5'
                  activerecord: '6.0'
                  db: postgresql
                  dbversion: '10'
            env:
              BUNDLE_GEMFILE: "${{ github.workspace }}/gemfiles/activerecord-${{ matrix.activerecord }}/Gemfile.${{ matrix.db }}"
              POSTGRESQL_DB_HOST: 127.0.0.1
              POSTGRESQL_DB_USER: schema_plus_test
              POSTGRESQL_DB_PASS: database
            steps:
            - uses: actions/checkout@v2
            - name: Set up Ruby
              uses: ruby/setup-ruby@v1
              with:
                ruby-version: "${{ matrix.ruby }}"
                bundler-cache: true
            - name: Run bundle update
              run: bundle update
            - name: Start Postgresql
              if: matrix.db == 'postgresql'
              run: |
                docker run --rm --detach \\
                  -e POSTGRES_USER=$POSTGRESQL_DB_USER \\
                  -e POSTGRES_PASSWORD=$POSTGRESQL_DB_PASS \\
                  -p 5432:5432 \\
                  --health-cmd "pg_isready -q" \\
                  --health-interval 5s \\
                  --health-timeout 5s \\
                  --health-retries 5 \\
                  --name database postgres:${{ matrix.dbversion }}
            - name: Wait for database to start
              if: "(matrix.db == 'postgresql' || matrix.db == 'mysql2')"
              run: |
                COUNT=0
                ATTEMPTS=20
                until [[ $COUNT -eq $ATTEMPTS ]]; do
                  [ "$(docker inspect -f {{.State.Health.Status}} database)" == "healthy" ] && break
                  echo $(( COUNT++ )) > /dev/null
                  sleep 2
                done
            - name: Create testing database
              if: "(matrix.db == 'postgresql' || matrix.db == 'mysql2')"
              run: bundle exec rake create_ci_database
            - name: Run tests
              run: bundle exec rake spec
            - name: Shutdown database
              if: always() && (matrix.db == 'postgresql' || matrix.db == 'mysql2')
              run: docker stop database
            - name: Coveralls Parallel
              if: "${{ !env.ACT }}"
              uses: coverallsapp/github-action@master
              with:
                github-token: "${{ secrets.GITHUB_TOKEN }}"
                flag-name: run-${{ matrix.ruby }}-${{ matrix.activerecord }}-${{ matrix.db }}-${{ matrix.dbversion }}
                parallel: true
          finish:
            needs: test
            runs-on: ubuntu-latest
            steps:
            - name: Coveralls Finished
              if: "${{ !env.ACT }}"
              uses: coverallsapp/github-action@master
              with:
                github-token: "${{ secrets.GITHUB_TOKEN }}"
                parallel-finished: true
      YAML
    end
  end

  context 'when only having postgresql with multiple DB versions with excludes' do
    let(:config) do
      {
        ruby: [2.5],
        activerecord: [5.2, 6.0],
        db: %w[postgresql],
        dbversions: { postgresql: [9.6, 10] },
        exclude: [{ db: 'postgresql', dbversion: 9.6, activerecord: 5.2 }]
      }
    end

    it 'creates a workflow file containing setup for just postgresql' do
      is_expected.to eq described_class::HEADER + <<~YAML
        ---
        name: CI PR Builds
        'on':
          push:
            branches:
            - master
          pull_request:
        concurrency:
          group: ci-${{ github.ref }}
          cancel-in-progress: true
        jobs:
          test:
            runs-on: ubuntu-latest
            strategy:
              fail-fast: false
              matrix:
                ruby:
                - '2.5'
                activerecord:
                - '5.2'
                - '6.0'
                db:
                - skip
                dbversion:
                - skip
                exclude:
                - db: skip
                  dbversion: skip
                include:
                - ruby: '2.5'
                  activerecord: '5.2'
                  db: postgresql
                  dbversion: '10'
                - ruby: '2.5'
                  activerecord: '6.0'
                  db: postgresql
                  dbversion: '9.6'
                - ruby: '2.5'
                  activerecord: '6.0'
                  db: postgresql
                  dbversion: '10'
            env:
              BUNDLE_GEMFILE: "${{ github.workspace }}/gemfiles/activerecord-${{ matrix.activerecord }}/Gemfile.${{ matrix.db }}"
              POSTGRESQL_DB_HOST: 127.0.0.1
              POSTGRESQL_DB_USER: schema_plus_test
              POSTGRESQL_DB_PASS: database
            steps:
            - uses: actions/checkout@v2
            - name: Set up Ruby
              uses: ruby/setup-ruby@v1
              with:
                ruby-version: "${{ matrix.ruby }}"
                bundler-cache: true
            - name: Run bundle update
              run: bundle update
            - name: Start Postgresql
              if: matrix.db == 'postgresql'
              run: |
                docker run --rm --detach \\
                  -e POSTGRES_USER=$POSTGRESQL_DB_USER \\
                  -e POSTGRES_PASSWORD=$POSTGRESQL_DB_PASS \\
                  -p 5432:5432 \\
                  --health-cmd "pg_isready -q" \\
                  --health-interval 5s \\
                  --health-timeout 5s \\
                  --health-retries 5 \\
                  --name database postgres:${{ matrix.dbversion }}
            - name: Wait for database to start
              if: "(matrix.db == 'postgresql' || matrix.db == 'mysql2')"
              run: |
                COUNT=0
                ATTEMPTS=20
                until [[ $COUNT -eq $ATTEMPTS ]]; do
                  [ "$(docker inspect -f {{.State.Health.Status}} database)" == "healthy" ] && break
                  echo $(( COUNT++ )) > /dev/null
                  sleep 2
                done
            - name: Create testing database
              if: "(matrix.db == 'postgresql' || matrix.db == 'mysql2')"
              run: bundle exec rake create_ci_database
            - name: Run tests
              run: bundle exec rake spec
            - name: Shutdown database
              if: always() && (matrix.db == 'postgresql' || matrix.db == 'mysql2')
              run: docker stop database
            - name: Coveralls Parallel
              if: "${{ !env.ACT }}"
              uses: coverallsapp/github-action@master
              with:
                github-token: "${{ secrets.GITHUB_TOKEN }}"
                flag-name: run-${{ matrix.ruby }}-${{ matrix.activerecord }}-${{ matrix.db }}-${{ matrix.dbversion }}
                parallel: true
          finish:
            needs: test
            runs-on: ubuntu-latest
            steps:
            - name: Coveralls Finished
              if: "${{ !env.ACT }}"
              uses: coverallsapp/github-action@master
              with:
                github-token: "${{ secrets.GITHUB_TOKEN }}"
                parallel-finished: true
      YAML
    end
  end

  context 'when configured multiple DBs' do
    let(:config) do
      {
        ruby: [2.5, 3.0],
        activerecord: [5.2, 6.0],
        db: %w[sqlite3 mysql2 postgresql]
      }
    end

    it 'creates a workflow file containing the complex setup' do
      is_expected.to eq described_class::HEADER + <<~YAML
        ---
        name: CI PR Builds
        'on':
          push:
            branches:
            - master
          pull_request:
        concurrency:
          group: ci-${{ github.ref }}
          cancel-in-progress: true
        jobs:
          test:
            runs-on: ubuntu-latest
            strategy:
              fail-fast: false
              matrix:
                ruby:
                - '2.5'
                - '3.0'
                activerecord:
                - '5.2'
                - '6.0'
                db:
                - sqlite3
                - mysql2
                - skip
                dbversion:
                - skip
                exclude:
                - ruby: '3.0'
                  activerecord: '5.2'
                - db: skip
                  dbversion: skip
                include:
                - ruby: '2.5'
                  activerecord: '5.2'
                  db: postgresql
                  dbversion: '9.6'
                - ruby: '2.5'
                  activerecord: '6.0'
                  db: postgresql
                  dbversion: '9.6'
                - ruby: '3.0'
                  activerecord: '6.0'
                  db: postgresql
                  dbversion: '9.6'
            env:
              BUNDLE_GEMFILE: "${{ github.workspace }}/gemfiles/activerecord-${{ matrix.activerecord }}/Gemfile.${{ matrix.db }}"
              MYSQL_DB_HOST: 127.0.0.1
              MYSQL_DB_USER: root
              MYSQL_DB_PASS: database
              POSTGRESQL_DB_HOST: 127.0.0.1
              POSTGRESQL_DB_USER: schema_plus_test
              POSTGRESQL_DB_PASS: database
            steps:
            - uses: actions/checkout@v2
            - name: Set up Ruby
              uses: ruby/setup-ruby@v1
              with:
                ruby-version: "${{ matrix.ruby }}"
                bundler-cache: true
            - name: Run bundle update
              run: bundle update
            - name: Start Mysql
              if: matrix.db == 'mysql2'
              run: |
                docker run --rm --detach \\
                  -e MYSQL_ROOT_PASSWORD=$MYSQL_DB_PASS \\
                  -p 3306:3306 \\
                  --health-cmd "mysqladmin ping --host=127.0.0.1 --password=$MYSQL_DB_PASS --silent" \\
                  --health-interval 5s \\
                  --health-timeout 5s \\
                  --health-retries 5 \\
                  --name database mysql:5.6
            - name: Start Postgresql
              if: matrix.db == 'postgresql'
              run: |
                docker run --rm --detach \\
                  -e POSTGRES_USER=$POSTGRESQL_DB_USER \\
                  -e POSTGRES_PASSWORD=$POSTGRESQL_DB_PASS \\
                  -p 5432:5432 \\
                  --health-cmd "pg_isready -q" \\
                  --health-interval 5s \\
                  --health-timeout 5s \\
                  --health-retries 5 \\
                  --name database postgres:${{ matrix.dbversion }}
            - name: Wait for database to start
              if: "(matrix.db == 'postgresql' || matrix.db == 'mysql2')"
              run: |
                COUNT=0
                ATTEMPTS=20
                until [[ $COUNT -eq $ATTEMPTS ]]; do
                  [ "$(docker inspect -f {{.State.Health.Status}} database)" == "healthy" ] && break
                  echo $(( COUNT++ )) > /dev/null
                  sleep 2
                done
            - name: Create testing database
              if: "(matrix.db == 'postgresql' || matrix.db == 'mysql2')"
              run: bundle exec rake create_ci_database
            - name: Run tests
              run: bundle exec rake spec
            - name: Shutdown database
              if: always() && (matrix.db == 'postgresql' || matrix.db == 'mysql2')
              run: docker stop database
            - name: Coveralls Parallel
              if: "${{ !env.ACT }}"
              uses: coverallsapp/github-action@master
              with:
                github-token: "${{ secrets.GITHUB_TOKEN }}"
                flag-name: run-${{ matrix.ruby }}-${{ matrix.activerecord }}-${{ matrix.db }}-${{ matrix.dbversion }}
                parallel: true
          finish:
            needs: test
            runs-on: ubuntu-latest
            steps:
            - name: Coveralls Finished
              if: "${{ !env.ACT }}"
              uses: coverallsapp/github-action@master
              with:
                github-token: "${{ secrets.GITHUB_TOKEN }}"
                parallel-finished: true
      YAML
    end
  end
end
