require 'schema_dev/runner'

describe SchemaDev::Runner do

  it "creates gemfiles" do
    config = get_config(ruby: "2.1.3", rails: "4.0", db: "sqlite3")
    runner = SchemaDev::Runner.new(config)
    in_tmpdir do
      expect{ runner.gemfiles }.to output("* Created gemfiles\n").to_stdout
      expect(Pathname.new("gemfiles")).to be_directory
    end
  end

  it "creates travis" do
    config = get_config(ruby: "2.1.3", rails: "4.0", db: "sqlite3")
    runner = SchemaDev::Runner.new(config)
    in_tmpdir do
      expect{ runner.travis }.to output("* Updated .travis.yml\n").to_stdout
      expect(Pathname.new(".travis.yml")).to be_file
    end
  end

  Selectors = {
    'chruby-exec' => "SHELL=`which bash` chruby-exec ruby-#{RUBY_VERSION} --",
    'rvm' => "rvm #{RUBY_VERSION} do",
    'rbenv' => "RBENV_VERSION=#{RUBY_VERSION}"
  }

  Selectors.each do |selector, selection_command|

    describe "matrix (#{selector})" do
      before(:each) do
        # mocking RubySelector to find selector
        SchemaDev::RubySelector._reset
        Selectors.keys.each do |k|
          allow(SchemaDev::RubySelector).to receive(:system).with("which -s #{k}").and_return k == selector
        end
        allow_any_instance_of(SchemaDev::RubySelector::Rbenv).to receive(:`).with("rbenv versions --bare").and_return RUBY_VERSION

        # mocking execution
        original_popen2e = Open3.method(:popen2e)
        allow(Open3).to receive(:popen2e) { |cmd, &block| 
          cmd = case cmd
                when /false$/ then "false"
                when /true$/ then "true"
                else cmd.sub(/.*echo/, "echo")
                end
          original_popen2e.call(cmd, &block)
        }
      end

      let(:config) { get_config(ruby: RUBY_VERSION, rails: "4.0", db: %W[sqlite3 postgresql]) }
      let(:runner) { SchemaDev::Runner.new(config) }


      let(:expected_output) { <<ENDOUTPUT.strip }
* Updated .travis.yml


*** ruby #{RUBY_VERSION} - rails 4.0 - db sqlite3 [1 of 2]

* /usr/bin/env BUNDLE_GEMFILE=gemfiles/rails-4.0/Gemfile.sqlite3 #{selection_command} %{cmd}
%{output}

*** ruby #{RUBY_VERSION} - rails 4.0 - db postgresql [2 of 2]

* /usr/bin/env BUNDLE_GEMFILE=gemfiles/rails-4.0/Gemfile.postgresql #{selection_command} %{cmd}
%{output}
ENDOUTPUT

      it "runs successfully" do
        in_tmpdir do
          expect{ runner.run("true") }.to output(expected_output % {cmd: 'true', output: nil}).to_stdout
        end
      end

      it "reports error exits" do
        in_tmpdir do
          expect{ runner.run("false") }.to output(expected_output % {cmd: 'false', output: nil} + <<-ENDERR).to_stdout

*** 2 failures:
\truby #{RUBY_VERSION} - rails 4.0 - db sqlite3
\truby #{RUBY_VERSION} - rails 4.0 - db postgresql
          ENDERR
        end
      end

      it "reports error messages" do
        in_tmpdir do
          expect{ runner.run("echo", "LoadError") }.to output(expected_output % {cmd: 'echo LoadError', output: "LoadError\n"} + <<-ENDERR).to_stdout

*** 2 failures:
\truby #{RUBY_VERSION} - rails 4.0 - db sqlite3
\truby #{RUBY_VERSION} - rails 4.0 - db postgresql
          ENDERR
        end
      end
    end
  end
end
