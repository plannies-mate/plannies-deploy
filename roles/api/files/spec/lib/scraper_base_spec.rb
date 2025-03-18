# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/scraper_base'

RSpec.describe ScraperBase do
  let(:test_class) do
    Class.new do
      extend ApplicationHelper
      extend ScraperBase
    end
  end

  describe '#create_agent' do
    it 'creates a Mechanize agent with standard settings' do
      agent = test_class.create_agent
      
      expect(agent).to be_a(Mechanize)
      expect(agent.user_agent).to include('Plannies-Mate')
      expect(agent.robots).to eq(:all)
      expect(agent.history.max_size).to eq(1)
    end
  end
  
  describe '#force?' do
    context 'when FORCE environment variable is set' do
      before { ENV['FORCE'] = 'true' }
      after { ENV['FORCE'] = nil }
      
      it 'returns true' do
        expect(test_class.force?).to be true
      end
    end
    
    context 'when FORCE environment variable is not set' do
      before { ENV['FORCE'] = nil }
      
      it 'returns false' do
        expect(test_class.force?).to be false
      end
    end
  end
  
  describe '#debug?' do
    context 'when DEBUG environment variable is set' do
      before { ENV['DEBUG'] = 'true' }
      after { ENV['DEBUG'] = nil }
      
      it 'returns true' do
        expect(test_class.debug?).to be true
      end
    end
    
    context 'when DEBUG environment variable is not set' do
      before { ENV['DEBUG'] = nil }
      
      it 'returns false' do
        expect(test_class.debug?).to be false
      end
    end
  end
  
  describe '#fetch_page_with_etag' do
    let(:url) { 'https://example.com/test' }
    let(:etag_file) { '/tmp/test.etag' }
    let(:data_file) { '/tmp/test' }
    let(:agent) { instance_double('Mechanize') }
    let(:page) { instance_double('Mechanize::Page') }
    
    before do
      allow(test_class).to receive(:create_agent).and_return(agent)
      allow(test_class).to receive(:log)
      allow(agent).to receive(:get).and_return(page)
      allow(page).to receive(:code).and_return('200')
      allow(page).to receive(:body).and_return('test content')
      allow(page).to receive(:header).and_return({})
      allow(File).to receive(:mtime).and_return(Time.now)
      
      # Default to not having files
      allow(File).to receive(:exist?).and_return(false)
      allow(File).to receive(:read).and_return('')
      allow(File).to receive(:write)
      allow(FileUtils).to receive(:mkdir_p)
    end
    
    it 'fetches a page without etag when no etag file exists' do
      expect(agent).to receive(:get).with(url, [], nil, {})
      
      result = test_class.fetch_page_with_etag(url, etag_file, agent)
      expect(result).to eq(page)
    end
    
    context 'when etag file exists' do
      before do
        allow(File).to receive(:exist?).with(etag_file).and_return(true)
        allow(File).to receive(:exist?).with(data_file).and_return(true)
        allow(File).to receive(:read).with(etag_file).and_return('etag123')
      end
      
      it 'includes the etag in the request headers' do
        expect(agent).to receive(:get).with(url, [], nil, { 'If-None-Match' => 'etag123' })
        
        test_class.fetch_page_with_etag(url, etag_file, agent)
      end
      
      context 'when the server returns 304 Not Modified' do
        before do
          allow(page).to receive(:code).and_return('304')
        end
        
        it 'logs that the content is unchanged and returns nil' do
          expect(test_class).to receive(:log).with(/unchanged/)
          
          result = test_class.fetch_page_with_etag(url, etag_file, agent)
          expect(result).to be_nil
        end
      end
      
      context 'when the server returns a new etag' do
        before do
          allow(page).to receive(:header).and_return({ 'etag' => 'new-etag' })
        end
        
        it 'updates the etag file' do
          expect(FileUtils).to receive(:mkdir_p)
          expect(File).to receive(:write).with(etag_file, 'new-etag')
          
          test_class.fetch_page_with_etag(url, etag_file, agent)
        end
      end
    end
    
    context 'with forced refresh' do
      before do
        allow(test_class).to receive(:force?).and_return(true)
        allow(File).to receive(:exist?).with(etag_file).and_return(true)
        allow(File).to receive(:exist?).with(data_file).and_return(true)
      end
      
      it 'does not use the etag' do
        expect(agent).to receive(:get).with(url, [], nil, {})
        
        test_class.fetch_page_with_etag(url, etag_file, agent)
      end
    end
    
    context 'when the server returns an error code' do
      before do
        allow(page).to receive(:code).and_return('500')
      end
      
      it 'raises an error' do
        expect {
          test_class.fetch_page_with_etag(url, etag_file, agent)
        }.to raise_error(/Unaccepted response code: 500/)
      end
    end
    
    context 'when the server returns an empty body' do
      before do
        allow(page).to receive(:body).and_return('')
      end
      
      it 'raises an error' do
        expect {
          test_class.fetch_page_with_etag(url, etag_file, agent)
        }.to raise_error(/Empty response/)
      end
    end
  end
  
  describe '#atomic_write_json' do
    let(:data) { { 'test' => 'data' } }
    let(:filename) { '/tmp/test.json' }
    let(:temp_file) { "#{filename}.new" }
    
    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(File).to receive(:write)
      allow(FileUtils).to receive(:mv)
    end
    
    it 'creates the directory if needed' do
      expect(FileUtils).to receive(:mkdir_p).with('/tmp')
      
      test_class.atomic_write_json(data, filename)
    end
    
    it 'writes the data to a temporary file' do
      expect(File).to receive(:write).with(temp_file, JSON.pretty_generate(data))
      
      test_class.atomic_write_json(data, filename)
    end
    
    it 'moves the temporary file to the target filename' do
      expect(FileUtils).to receive(:mv).with(temp_file, filename)
      
      test_class.atomic_write_json(data, filename)
    end
    
    it 'returns true on success' do
      expect(test_class.atomic_write_json(data, filename)).to be true
    end
    
    context 'when an error occurs' do
      before do
        allow(File).to receive(:write).and_raise(StandardError.new('test error'))
      end
      
      it 'logs the error and returns false' do
        expect(test_class).to receive(:log).with(/test error/)
        expect(test_class.atomic_write_json(data, filename)).to be false
      end
    end
  end
  

  describe '#extract_text' do
    it 'strips whitespace and normalizes spacing' do
      node = double('Node', text: "  This   is a \n\n test  string  ")
      expect(test_class.extract_text(node)).to eq('This is a test string')
    end
    
    it 'handles nil nodes' do
      expect(test_class.extract_text(nil)).to be_nil
    end
  end
  
  describe '#extract_number' do
    it 'extracts numeric characters' do
      expect(test_class.extract_number('Population: 123,456')).to eq(123456)
    end
    
    it 'handles nil inputs' do
      expect(test_class.extract_number(nil)).to be_nil
    end
  end
end
