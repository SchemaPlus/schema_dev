require 'schema_dev/gemfile_selector'

describe SchemaDev::GemfileSelector do

  it "infers db from env" do
    test_dbname = 'this_is_a_test'
    ENV['BUNDLE_GEMFILE'] = SchemaDev::GemfileSelector.gemfile(activerecord: '4.1', db: test_dbname).to_s
    expect(SchemaDev::GemfileSelector.infer_db).to eq test_dbname
  end
end
