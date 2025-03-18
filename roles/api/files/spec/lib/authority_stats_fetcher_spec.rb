# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../lib/authority_stats_fetcher'

RSpec.describe AuthorityStatsFetcher do
  describe '#fetch', vcr: { cassette_name: 'authority_stats/sydney' } do
    let(:fetcher) { AuthorityStatsFetcher.new }
    let(:test_data_dir) { File.join(Dir.tmpdir, 'authority_stats_test') }
    let(:short_name) { 'sydney' }

    before do
      allow(described_class).to receive(:data_dir).and_return(test_data_dir)
      FileUtils.mkdir_p(test_data_dir)
    end

    after do
      FileUtils.rm_rf(test_data_dir)
    end

    it 'fetches and processes authority stats' do
      result = fetcher.fetch(short_name)
      expect(result).to be true

      # Verify the file was created
      stats_dir = File.join(test_data_dir, 'authority_stats')
      output_file = File.join(stats_dir, "#{short_name}.json")
      expect(File.exist?(output_file)).to be true

      # Verify the content
      stats = JSON.parse(File.read(output_file))
      expect(stats).to include('short_name')
      expect(stats['short_name']).to eq(short_name)

      # Check for expected stats fields
      expect(stats).to have_key('week_count')
      expect(stats).to have_key('month_count')
      expect(stats).to have_key('total_count')
    end

    it 'requires a short_name' do
      expect { fetcher.fetch('') }.to raise_error(ArgumentError)
    end
  end

  describe '.stats' do
    it 'returns authority stats from the JSON file' do
      # Create a test file
      test_dir = File.join(Dir.tmpdir, 'authority_stats_test')
      stats_dir = File.join(test_dir, 'authority_stats')
      FileUtils.mkdir_p(stats_dir)

      short_name = 'test_authority'
      test_file = File.join(stats_dir, "#{short_name}.json")

      test_data = {
        'short_name' => short_name,
        'warning' => false,
        'week_count' => 42,
        'month_count' => 156,
        'total_count' => 2500
      }

      File.write(test_file, JSON.generate(test_data))

      # Stub the stats_dir method to return our test directory
      allow(AuthorityStatsFetcher).to receive(:stats_dir).and_return(stats_dir)

      # Test the method
      result = AuthorityStatsFetcher.find(short_name)
      expect(result).to eq(test_data)

      # Clean up
      FileUtils.rm_rf(test_dir)
    end

    it 'returns nil if the file does not exist' do
      allow(AuthorityStatsFetcher).to receive(:stats_dir).and_return('/nonexistent')
      expect(AuthorityStatsFetcher.find('test')).to be_nil
    end
  end
end
