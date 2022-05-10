# frozen_string_literal: true

describe SchemaDev::Config do
  it 'computes matrix' do
    config = get_config(ruby: %w[1.9.3 2.1.5], activerecord: %w[4.0 4.1], db: %w[sqlite3 postgresql])
    expect(config.matrix).to match_array [
      { ruby: '1.9.3', activerecord: '4.0', db: 'sqlite3' },
      { ruby: '1.9.3', activerecord: '4.0', db: 'postgresql' },
      { ruby: '1.9.3', activerecord: '4.1', db: 'sqlite3' },
      { ruby: '1.9.3', activerecord: '4.1', db: 'postgresql' },
      { ruby: '2.1.5', activerecord: '4.0', db: 'sqlite3' },
      { ruby: '2.1.5', activerecord: '4.0', db: 'postgresql' },
      { ruby: '2.1.5', activerecord: '4.1', db: 'sqlite3' },
      { ruby: '2.1.5', activerecord: '4.1', db: 'postgresql' },
    ]
  end

  it 'excludes explicit elements from matrix' do
    config = get_config(ruby: %w[1.9.3 2.1.5], activerecord: %w[4.0 4.1], db: %w[sqlite3 postgresql],
                        exclude: [
                          { ruby: '1.9.3', activerecord: '4.1', db: 'postgresql' },
                          { ruby: '2.1.5', activerecord: '4.0', db: 'sqlite3' }
])
    expect(config.matrix).to match_array [
      { ruby: '1.9.3', activerecord: '4.0', db: 'sqlite3' },
      { ruby: '1.9.3', activerecord: '4.0', db: 'postgresql' },
      { ruby: '1.9.3', activerecord: '4.1', db: 'sqlite3' },
      # { ruby: "1.9.3", activerecord: "4.1", db: "postgresql" },
      # { ruby: "2.1.5", activerecord: "4.0", db: "sqlite3" },
      { ruby: '2.1.5', activerecord: '4.0', db: 'postgresql' },
      { ruby: '2.1.5', activerecord: '4.1', db: 'sqlite3' },
      { ruby: '2.1.5', activerecord: '4.1', db: 'postgresql' },
    ]
  end

  it 'excludes slices from matrix' do
    config = get_config(ruby: %w[1.9.3 2.1.5], activerecord: %w[4.0 4.1], db: %w[sqlite3 postgresql],
                        exclude: [
                          { ruby: '1.9.3', activerecord: '4.1' },
                          { ruby: '2.1.5', db: 'sqlite3' }
])
    expect(config.matrix).to match_array [
      { ruby: '1.9.3', activerecord: '4.0', db: 'sqlite3' },
      { ruby: '1.9.3', activerecord: '4.0', db: 'postgresql' },
      #{ ruby: "1.9.3", activerecord: "4.1", db: "sqlite3" },
      #{ ruby: "1.9.3", activerecord: "4.1", db: "postgresql" },
      #{ ruby: "2.1.5", activerecord: "4.0", db: "sqlite3" },
      { ruby: '2.1.5', activerecord: '4.0', db: 'postgresql' },
      #{ ruby: "2.1.5", activerecord: "4.1", db: "sqlite3" },
      { ruby: '2.1.5', activerecord: '4.1', db: 'postgresql' },
    ]
  end

  it 'uses last cell for --quick' do
    config = get_config(ruby: %w[1.9.3 2.1.5], activerecord: %w[4.0 4.1], db: %w[sqlite3 postgresql])
    expect(config.matrix(quick: true)).to match_array [
      { ruby: '2.1.5', activerecord: '4.1', db: 'postgresql' },
    ]
  end

  it 'excludes variations that are not possible' do
    config = get_config(ruby: %w[2.6 2.7 3.0], activerecord: %w[5.2 6.0 7.0], db: %w[sqlite3])
    expect(config.matrix).to contain_exactly(
      { ruby: '2.6', activerecord: '5.2', db: 'sqlite3' },
      { ruby: '2.6', activerecord: '6.0', db: 'sqlite3' },
      { ruby: '2.7', activerecord: '5.2', db: 'sqlite3' },
      { ruby: '2.7', activerecord: '6.0', db: 'sqlite3' },
      { ruby: '2.7', activerecord: '7.0', db: 'sqlite3' },
      { ruby: '3.0', activerecord: '6.0', db: 'sqlite3' },
      { ruby: '3.0', activerecord: '7.0', db: 'sqlite3' },
    )
  end
end
