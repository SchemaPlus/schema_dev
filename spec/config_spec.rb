describe SchemaDev::Config do

  it "computes matrix without db" do
    config = get_config(ruby: %W[1.9.3 2.1.5], rails: %W[4.0 4.1])
    expect(config.matrix).to match_array [
      { ruby: "1.9.3", rails: "4.0" },
      { ruby: "1.9.3", rails: "4.1" },
      { ruby: "2.1.5", rails: "4.0" },
      { ruby: "2.1.5", rails: "4.1" },
    ]
  end

  it "computes matrix without db" do
    config = get_config(ruby: %W[1.9.3 2.1.5], rails: %W[4.0 4.1], db: %W[sqlite3 postgresql])
    expect(config.matrix).to match_array [
      { ruby: "1.9.3", rails: "4.0", db: "sqlite3" },
      { ruby: "1.9.3", rails: "4.0", db: "postgresql" },
      { ruby: "1.9.3", rails: "4.1", db: "sqlite3" },
      { ruby: "1.9.3", rails: "4.1", db: "postgresql" },
      { ruby: "2.1.5", rails: "4.0", db: "sqlite3" },
      { ruby: "2.1.5", rails: "4.0", db: "postgresql" },
      { ruby: "2.1.5", rails: "4.1", db: "sqlite3" },
      { ruby: "2.1.5", rails: "4.1", db: "postgresql" },
    ]
  end

  it "excludes explicit elements from matrix" do
    config = get_config(ruby: %W[1.9.3 2.1.5], rails: %W[4.0 4.1], db: %W[sqlite3 postgresql],
                        exclude: [
                          { ruby: "1.9.3", rails: "4.1", db: "postgresql" },
                          { ruby: "2.1.5", rails: "4.0", db: "sqlite3" } ]
                       )
    expect(config.matrix).to match_array [
      { ruby: "1.9.3", rails: "4.0", db: "sqlite3" },
      { ruby: "1.9.3", rails: "4.0", db: "postgresql" },
      { ruby: "1.9.3", rails: "4.1", db: "sqlite3" },
      # { ruby: "1.9.3", rails: "4.1", db: "postgresql" },
      # { ruby: "2.1.5", rails: "4.0", db: "sqlite3" },
      { ruby: "2.1.5", rails: "4.0", db: "postgresql" },
      { ruby: "2.1.5", rails: "4.1", db: "sqlite3" },
      { ruby: "2.1.5", rails: "4.1", db: "postgresql" },
    ]
  end

  it "excludes slices from matrix" do
    config = get_config(ruby: %W[1.9.3 2.1.5], rails: %W[4.0 4.1], db: %W[sqlite3 postgresql],
                        exclude: [
                          { ruby: "1.9.3", rails: "4.1"},
                          { ruby: "2.1.5", db: "sqlite3" } ]
                       )
    expect(config.matrix).to match_array [
      { ruby: "1.9.3", rails: "4.0", db: "sqlite3" },
      { ruby: "1.9.3", rails: "4.0", db: "postgresql" },
      #{ ruby: "1.9.3", rails: "4.1", db: "sqlite3" },
      #{ ruby: "1.9.3", rails: "4.1", db: "postgresql" },
      #{ ruby: "2.1.5", rails: "4.0", db: "sqlite3" },
      { ruby: "2.1.5", rails: "4.0", db: "postgresql" },
      #{ ruby: "2.1.5", rails: "4.1", db: "sqlite3" },
      { ruby: "2.1.5", rails: "4.1", db: "postgresql" },
    ]
  end
  
end
