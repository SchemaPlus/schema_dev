require 'schema_dev/travis'

describe SchemaDev::Travis do

  it "creates travis file" do
    config = get_config(ruby: %W[1.9.3 2.1.5],
                        activerecord: %W[4.0 4.1],
                        db: %W[mysql2 postgresql],
                        exclude: { ruby: "1.9.3", db: "postgresql" },
                        notify: 'me@example.com')
    in_tmpdir do
      SchemaDev::Travis.update(config)
      expect(Pathname.new(".travis.yml").read).to eq <<ENDTRAVIS
# This file was auto-generated by the schema_dev tool, based on the data in
#                 ./schema_dev.yml
# Please do not edit this file; any changes will be overwritten next time
# schema_dev gets run.
---
rvm:
- 1.9.3
- 2.1.5
gemfile:
- gemfiles/activerecord-4.0/Gemfile.mysql2
- gemfiles/activerecord-4.0/Gemfile.postgresql
- gemfiles/activerecord-4.1/Gemfile.mysql2
- gemfiles/activerecord-4.1/Gemfile.postgresql
env: MYSQL_DB_USER=travis
before_script: bundle exec rake create_databases
after_script: bundle exec rake drop_databases
script: bundle exec rake travis
notifications:
  email:
  - me@example.com
jobs:
  exclude:
  - rvm: 1.9.3
    gemfile: gemfiles/activerecord-4.0/Gemfile.postgresql
  - rvm: 1.9.3
    gemfile: gemfiles/activerecord-4.1/Gemfile.postgresql
  include:
  - gemfile: gemfiles/activerecord-4.0/Gemfile.postgresql
    addons:
      postgresql: '9.4'
    env: POSTGRESQL_DB_USER=postgres
  - gemfile: gemfiles/activerecord-4.1/Gemfile.postgresql
    addons:
      postgresql: '9.4'
    env: POSTGRESQL_DB_USER=postgres
ENDTRAVIS
    end
  end

  context 'when only using postgresql and not overriding the version' do
    it "creates travis file using the default PG version" do
      config = get_config(ruby: %W[2.4.0],
                          activerecord: %W[4.1],
                          db: %W[postgresql])
      in_tmpdir do
        SchemaDev::Travis.update(config)
        expect(Pathname.new(".travis.yml").read).to eq <<ENDTRAVIS
# This file was auto-generated by the schema_dev tool, based on the data in
#                 ./schema_dev.yml
# Please do not edit this file; any changes will be overwritten next time
# schema_dev gets run.
---
rvm:
- 2.4.0
gemfile:
- gemfiles/activerecord-4.1/Gemfile.postgresql
env: POSTGRESQL_DB_USER=postgres
addons:
  postgresql: '9.4'
before_script: bundle exec rake create_databases
after_script: bundle exec rake drop_databases
script: bundle exec rake travis
ENDTRAVIS
      end
    end
  end

  context 'when specifying a single postgresql version' do
    it "creates travis file using that as the PG version" do
      config = get_config(ruby: %W[2.4.0],
                          activerecord: %W[4.1],
                          db: %W[mysql2 postgresql],
                          dbversions: {postgresql: %W[9.6]})
      in_tmpdir do
        SchemaDev::Travis.update(config)
        expect(Pathname.new(".travis.yml").read).to eq <<ENDTRAVIS
# This file was auto-generated by the schema_dev tool, based on the data in
#                 ./schema_dev.yml
# Please do not edit this file; any changes will be overwritten next time
# schema_dev gets run.
---
rvm:
- 2.4.0
gemfile:
- gemfiles/activerecord-4.1/Gemfile.mysql2
- gemfiles/activerecord-4.1/Gemfile.postgresql
env: MYSQL_DB_USER=travis
before_script: bundle exec rake create_databases
after_script: bundle exec rake drop_databases
script: bundle exec rake travis
jobs:
  include:
  - gemfile: gemfiles/activerecord-4.1/Gemfile.postgresql
    addons:
      postgresql: '9.6'
    env: POSTGRESQL_DB_USER=postgres
ENDTRAVIS
      end
    end
  end

  context 'when specifying multiple postgresql versions with excludes' do
    it "creates travis file including those variants for postgresql versions" do
      config = get_config(ruby: %W[1.9.3 2.1.5 2.4.0],
                          activerecord: %W[4.0 4.1],
                          db: %W[mysql2 postgresql],
                          dbversions: {postgresql: %W[9.6 10 11]},
                          exclude: [{ ruby: "1.9.3", db: "postgresql" }])
      in_tmpdir do
        SchemaDev::Travis.update(config)
        expect(Pathname.new(".travis.yml").read).to eq <<ENDTRAVIS
# This file was auto-generated by the schema_dev tool, based on the data in
#                 ./schema_dev.yml
# Please do not edit this file; any changes will be overwritten next time
# schema_dev gets run.
---
rvm:
- 1.9.3
- 2.1.5
- 2.4.0
gemfile:
- gemfiles/activerecord-4.0/Gemfile.mysql2
- gemfiles/activerecord-4.0/Gemfile.postgresql
- gemfiles/activerecord-4.1/Gemfile.mysql2
- gemfiles/activerecord-4.1/Gemfile.postgresql
env: MYSQL_DB_USER=travis
before_script: bundle exec rake create_databases
after_script: bundle exec rake drop_databases
script: bundle exec rake travis
jobs:
  exclude:
  - rvm: 1.9.3
    gemfile: gemfiles/activerecord-4.0/Gemfile.postgresql
  - rvm: 1.9.3
    gemfile: gemfiles/activerecord-4.1/Gemfile.postgresql
  include:
  - gemfile: gemfiles/activerecord-4.0/Gemfile.postgresql
    addons:
      postgresql: '9.6'
    env: POSTGRESQL_DB_USER=postgres
  - gemfile: gemfiles/activerecord-4.0/Gemfile.postgresql
    addons:
      postgresql: '10'
      apt:
        packages:
        - postgresql-10
        - postgresql-client-10
    env: POSTGRESQL_DB_USER=postgres
  - gemfile: gemfiles/activerecord-4.0/Gemfile.postgresql
    addons:
      postgresql: '11'
      apt:
        packages:
        - postgresql-11
        - postgresql-client-11
    env: POSTGRESQL_DB_USER=travis PGPORT=5433
  - gemfile: gemfiles/activerecord-4.1/Gemfile.postgresql
    addons:
      postgresql: '9.6'
    env: POSTGRESQL_DB_USER=postgres
  - gemfile: gemfiles/activerecord-4.1/Gemfile.postgresql
    addons:
      postgresql: '10'
      apt:
        packages:
        - postgresql-10
        - postgresql-client-10
    env: POSTGRESQL_DB_USER=postgres
  - gemfile: gemfiles/activerecord-4.1/Gemfile.postgresql
    addons:
      postgresql: '11'
      apt:
        packages:
        - postgresql-11
        - postgresql-client-11
    env: POSTGRESQL_DB_USER=travis PGPORT=5433
ENDTRAVIS
      end
    end
  end

  context 'when specifying only postgresql as the db with versions' do
    it "creates travis file including only addon variants" do
      config = get_config(ruby: %W[2.1.5 2.4.0],
                          activerecord: %W[4.0 4.1],
                          db: %W[postgresql],
                          dbversions: {postgresql: %W[9.6 10 11]})
      in_tmpdir do
        SchemaDev::Travis.update(config)
        expect(Pathname.new(".travis.yml").read).to eq <<ENDTRAVIS
# This file was auto-generated by the schema_dev tool, based on the data in
#                 ./schema_dev.yml
# Please do not edit this file; any changes will be overwritten next time
# schema_dev gets run.
---
rvm:
- 2.1.5
- 2.4.0
gemfile:
- gemfiles/activerecord-4.0/Gemfile.postgresql
- gemfiles/activerecord-4.1/Gemfile.postgresql
before_script: bundle exec rake create_databases
after_script: bundle exec rake drop_databases
script: bundle exec rake travis
jobs:
  include:
  - addons:
      postgresql: '9.6'
    env: POSTGRESQL_DB_USER=postgres
  - addons:
      postgresql: '10'
      apt:
        packages:
        - postgresql-10
        - postgresql-client-10
    env: POSTGRESQL_DB_USER=postgres
  - addons:
      postgresql: '11'
      apt:
        packages:
        - postgresql-11
        - postgresql-client-11
    env: POSTGRESQL_DB_USER=travis PGPORT=5433
ENDTRAVIS
      end
    end
  end

  context 'when specifying multiple postgresql versions' do
    it "creates travis file including those variants for postgresql versions" do
      config = get_config(ruby: %W[2.1.5 2.4.0],
                          activerecord: %W[4.0 4.1],
                          db: %W[mysql2 postgresql],
                          dbversions: {postgresql: %W[9.6 10]})
      in_tmpdir do
        SchemaDev::Travis.update(config)
        expect(Pathname.new(".travis.yml").read).to eq <<ENDTRAVIS
# This file was auto-generated by the schema_dev tool, based on the data in
#                 ./schema_dev.yml
# Please do not edit this file; any changes will be overwritten next time
# schema_dev gets run.
---
rvm:
- 2.1.5
- 2.4.0
gemfile:
- gemfiles/activerecord-4.0/Gemfile.mysql2
- gemfiles/activerecord-4.0/Gemfile.postgresql
- gemfiles/activerecord-4.1/Gemfile.mysql2
- gemfiles/activerecord-4.1/Gemfile.postgresql
env: MYSQL_DB_USER=travis
before_script: bundle exec rake create_databases
after_script: bundle exec rake drop_databases
script: bundle exec rake travis
jobs:
  include:
  - gemfile: gemfiles/activerecord-4.0/Gemfile.postgresql
    addons:
      postgresql: '9.6'
    env: POSTGRESQL_DB_USER=postgres
  - gemfile: gemfiles/activerecord-4.0/Gemfile.postgresql
    addons:
      postgresql: '10'
      apt:
        packages:
        - postgresql-10
        - postgresql-client-10
    env: POSTGRESQL_DB_USER=postgres
  - gemfile: gemfiles/activerecord-4.1/Gemfile.postgresql
    addons:
      postgresql: '9.6'
    env: POSTGRESQL_DB_USER=postgres
  - gemfile: gemfiles/activerecord-4.1/Gemfile.postgresql
    addons:
      postgresql: '10'
      apt:
        packages:
        - postgresql-10
        - postgresql-client-10
    env: POSTGRESQL_DB_USER=postgres
ENDTRAVIS
      end
    end
  end
end
