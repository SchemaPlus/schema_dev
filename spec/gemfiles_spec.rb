require 'schema_dev/gemfiles'

describe SchemaDev::Gemfiles do

  it "copies listed files" do
    config = get_config(ruby: %W[1.9.3 2.1.5], rails: %W[4.0 4.1], db: %[sqlite3 postgresql])
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do

        SchemaDev::Gemfiles.build(config)

        src = SchemaDev::Gemfiles::TEMPLATES_ROOT + "gemfiles"
        diff = `diff -rq #{src} gemfiles 2>&1`.split("\n")
        
        # expect copy not to have entry for rails not in config
        diff.reject!{ |d| d =~ %r[Only in #{src}: rails-(.*)] and not config.rails.include? $1 }
        
        # expect copy not to have entry for db not in config
        diff.reject!{ |d| d =~ %r[Only in #{src}.*: Gemfile.(.*)] and not config.db.include? $1 }

        expect(diff).to be_empty
      end
    end
  end
end
        

