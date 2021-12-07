require 'schema_dev/gemfiles'

describe SchemaDev::Gemfiles do

  it "copies listed files" do
    config = get_config(ruby: %W[1.9.3 2.1.5], activerecord: %W[5.2 6.0], db: %W[sqlite3 postgresql])
    in_tmpdir do
      expect(SchemaDev::Gemfiles.build(config)).to be_truthy
      expect(relevant_diff(config, "gemfiles")).to be_empty
    end
  end

  it "only copies files once" do
    config = get_config(ruby: %W[1.9.3 2.1.5], activerecord: %W[5.2 6.0], db: %W[sqlite3 postgresql])
    in_tmpdir do
      expect(SchemaDev::Gemfiles.build(config)).to be_truthy
      expect(SchemaDev::Gemfiles.build(config)).to be_falsey
    end
  end

  def relevant_diff(config, dir)
    Dir.mktmpdir do |no_erb_root|
      no_erb_root = Pathname(no_erb_root)
      erb_root = SchemaDev::Templates.root + dir 
      Pathname.glob(erb_root + "**/*").select(&:file?).each do |p|
        d = (no_erb_root+p.relative_path_from(erb_root)).sub_ext('')
        d.dirname.mkpath
        d.write p.read
      end

      diff = `diff -rq #{no_erb_root} #{dir} 2>&1`.split("\n")

      # expect copy not to have entry for activerecord not in config
      diff.reject!{ |d| d =~ %r[Only in #{no_erb_root}: activerecord-(.*)] and not config.activerecord.include? $1 }

      # expect copy not to have entry for db not in config
      diff.reject!{ |d| d =~ %r[Only in #{no_erb_root}.*: Gemfile.(.*)] and not config.db.include? $1 }
    end
  end

end
