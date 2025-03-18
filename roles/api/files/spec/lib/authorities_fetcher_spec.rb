# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../lib/authorities_fetcher'

RSpec.describe AuthoritiesFetcher do
  describe '#fetch', vcr: { cassette_name: 'authorities_list' } do
    let(:fetcher) { AuthoritiesFetcher.new }
    let(:test_data_dir) { File.join(Dir.tmpdir, 'authorities_fetcher_test') }
    
    before do
      allow(described_class).to receive(:data_dir).and_return(test_data_dir)
      FileUtils.mkdir_p(test_data_dir)
    end
    
    after do
      FileUtils.rm_rf(test_data_dir)
    end
    
    it 'fetches and processes planning authorities' do
      result = fetcher.fetch
      expect(result).to be true
      
      # Verify the file was created
      output_file = File.join(test_data_dir, 'authorities.json')
      expect(File.exist?(output_file)).to be true
      
      # Verify the content
      authorities = JSON.parse(File.read(output_file))
      expect(authorities).to be_an(Array)
      expect(authorities.size).to be > 10 # Should have many authorities
      
      # Check the structure of authorities
      authorities.each do |authority|
        expect(authority).to include('state', 'name', 'url', 'short_name')
        expect(authority['state']).to be_a(String)
        expect(authority['name']).to be_a(String)
        expect(authority['url']).to include('https://www.planningalerts.org.au/authorities/')
        expect(authority['short_name']).to be_a(String)
        expect(authority).to have_key('population')
      end
    end
  end
  
  describe '.all' do
    it 'returns authorities from the JSON file' do
      # Create a test file
      test_dir = File.join(Dir.tmpdir, 'authorities_test')
      FileUtils.mkdir_p(test_dir)
      test_file = File.join(test_dir, 'authorities.json')
      
      test_data = [
        { 'short_name' => 'test1', 'name' => 'Test 1', 'url' => 'https://example.com/1' },
        { 'short_name' => 'test2', 'name' => 'Test 2', 'url' => 'https://example.com/2' }
      ]
      
      File.write(test_file, JSON.generate(test_data))
      
      # Stub the output_file method to return our test file
      allow(AuthoritiesFetcher).to receive(:output_file).and_return(test_file)
      
      # Test the method
      result = AuthoritiesFetcher.all
      expect(result).to eq(test_data)
      
      # Clean up
      FileUtils.rm_rf(test_dir)
    end
    
    it 'returns nil if the file does not exist' do
      allow(AuthoritiesFetcher).to receive(:output_file).and_return('/nonexistent/file.json')
      expect(AuthoritiesFetcher.all).to be_empty
    end
  end
end
