# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../lib/authority_details_fetcher'

RSpec.describe AuthorityDetailsFetcher do
  describe '#fetch', vcr: { cassette_name: 'authority_details/sydney' } do
    let(:fetcher) { AuthorityDetailsFetcher.new }
    let(:test_data_dir) { File.join(Dir.tmpdir, 'authority_details_test') }
    let(:short_name) { 'sydney' }

    before do
      allow(described_class).to receive(:data_dir).and_return(test_data_dir)
      FileUtils.mkdir_p(test_data_dir)
    end

    after do
      FileUtils.rm_rf(test_data_dir)
    end

    it 'fetches and processes authority details' do
      result = fetcher.fetch(short_name)
      expect(result).to be true

      # Verify the file was created
      details_dir = File.join(test_data_dir, 'authority_details')
      output_file = File.join(details_dir, "#{short_name}.json")
      expect(File.exist?(output_file)).to be true

      # Verify the content
      details = JSON.parse(File.read(output_file))
      expect(details).to include('short_name', 'morph_url', 'github_url')
      expect(details['short_name']).to eq(short_name)
      expect(details['morph_url']).to include('morph.io')
      expect(details['github_url']).to include('github.com')
    end

    it 'requires a short_name' do
      expect { fetcher.fetch('') }.to raise_error(ArgumentError)
    end
  end

  describe '.find' do
    it 'returns authority details from the JSON file' do
      # Create a test file
      test_dir = File.join(Dir.tmpdir, 'authority_details_test')
      details_dir = File.join(test_dir, 'authority_details')
      FileUtils.mkdir_p(details_dir)

      short_name = 'test_authority'
      test_file = File.join(details_dir, "#{short_name}.json")

      test_data = {
        'short_name' => short_name,
        'morph_url' => 'https://morph.io/test/scraper',
        'github_url' => 'https://github.com/test/scraper'
      }

      File.write(test_file, JSON.generate(test_data))

      # Stub the details_dir method to return our test directory
      allow(AuthorityDetailsFetcher).to receive(:details_dir).and_return(details_dir)

      # Test the method
      result = AuthorityDetailsFetcher.find(short_name)
      expect(result).to eq(test_data)

      # Clean up
      FileUtils.rm_rf(test_dir)
    end

    it 'returns nil if the file does not exist' do
      allow(AuthorityDetailsFetcher).to receive(:details_dir).and_return('/nonexistent')
      expect(AuthorityDetailsFetcher.find('test')).to be_nil
    end
  end
end
