# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../lib/morph_scrapers_analyzer'
require_relative '../support/data_support'

RSpec.describe MorphScrapersAnalyzer do
  before(:all) do
    # Set up the test data once for all tests
    DataSupport.link_data
    # Make sure the cache uses the linked data
    Authority.reset!
    described_class.instance.send(:reset!)
  end

  after(:all) do
    # Clean up after all tests
    DataSupport.cleanup
  end

  describe '.instance' do
    it 'returns a singleton instance' do
      expect(described_class.instance).to be_a(described_class)
      expect(described_class.instance).to eq(described_class.instance)
    end
  end

  describe '#all' do
    it 'returns a list of MorphScraper objects' do
      scrapers = described_class.instance.all
      expect(scrapers).to be_an(Array)
      expect(scrapers).not_to be_empty
      expect(scrapers.first).to be_a(MorphScraper)
    end

    it 'returns unique scrapers based on name' do
      scrapers = described_class.instance.all
      names = scrapers.map(&:name)
      expect(names).to eq(names.uniq)
    end

    it 'groups authorities using the same scraper' do
      # The example data contains multiple authorities using the same scraper
      analyzer = described_class.instance

      # Find a scraper with multiple authorities (from our fixture data)
      multi_authority_scraper = analyzer.all.find { |s| s.authorities.size > 1 }
      expect(multi_authority_scraper).not_to be_nil

      # Verify the authorities are correctly grouped
      expect(multi_authority_scraper.authorities.size).to be > 1
      expect(multi_authority_scraper.authorities.map(&:short_name)).to include('bathurst', 'armidale')
    end
  end

  describe '#find' do
    let(:analyzer) { described_class.instance }

    it 'finds a scraper by name' do
      # Use a scraper name that exists in our fixture data
      scraper = analyzer.find('multiple_atdis')
      expect(scraper).not_to be_nil
      expect(scraper.name).to eq('multiple_atdis')
    end

    it 'finds a scraper by morph URL' do
      # Use a scraper morph URL that exists in our fixture data
      morph_url = 'https://morph.io/planningalerts-scrapers/multiple_atdis'
      scraper = analyzer.find(morph_url)
      expect(scraper).not_to be_nil
      expect(scraper.morph_url).to eq(morph_url)
    end

    it 'raises KeyError when scraper is not found' do
      expect { analyzer.find('nonexistent_scraper') }.to raise_error(KeyError)
    end
  end

  describe 'integration with Authority class' do
    it 'correctly links authorities to scrapers' do
      # Verify that authorities can find their scrapers
      authority = Authority.all.first

      # Make sure the authority has a morph_url
      expect(authority.morph_url).not_to be_nil

      # Get the scraper for this authority
      scraper = authority.morph_scraper

      # Verify the scraper is correctly linked to the authority
      expect(scraper).not_to be_nil
      expect(scraper).to be_a(MorphScraper)
      expect(scraper.authorities).to include(authority)
    end
  end
end
