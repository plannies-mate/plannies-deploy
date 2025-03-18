# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../lib/morph_scraper'

RSpec.describe MorphScraper do
  let(:authority_attributes) do
    {
      'short_name' => 'test_authority',
      'name' => 'Test Authority',
      'url' => 'https://example.com/test',
      'state' => 'NSW'
    }
  end

  let(:authority) do
    authority = Authority.new(authority_attributes)
    allow(authority).to receive(:morph_url).and_return('https://morph.io/planningalerts-scrapers/test_scraper')
    allow(authority).to receive(:github_url).and_return('https://github.com/planningalerts-scrapers/test_scraper')
    authority
  end

  describe '#initialize' do
    it 'extracts the scraper name from the morph URL' do
      scraper = MorphScraper.new(authority)
      expect(scraper.name).to eq('test_scraper')
    end

    it 'stores the authority in the authorities array' do
      scraper = MorphScraper.new(authority)
      expect(scraper.authorities).to eq([authority])
    end

    it 'stores the morph URL' do
      scraper = MorphScraper.new(authority)
      expect(scraper.morph_url).to eq('https://morph.io/planningalerts-scrapers/test_scraper')
    end

    it 'stores the GitHub URL' do
      scraper = MorphScraper.new(authority)
      expect(scraper.github_url).to eq('https://github.com/planningalerts-scrapers/test_scraper')
    end
  end

  describe '#==' do
    it 'considers scrapers with the same name equal' do
      scraper1 = MorphScraper.new(authority)

      # Create another authority that uses the same scraper
      other_authority = Authority.new(authority_attributes.merge('short_name' => 'other_authority'))
      allow(other_authority).to receive(:morph_url).and_return('https://morph.io/planningalerts-scrapers/test_scraper')
      allow(other_authority).to receive(:github_url).and_return('https://github.com/planningalerts-scrapers/test_scraper')

      scraper2 = MorphScraper.new(other_authority)

      expect(scraper1).to eq(scraper2)
    end

    it 'considers scrapers with different names not equal' do
      scraper1 = MorphScraper.new(authority)

      # Create another authority that uses a different scraper
      other_authority = Authority.new(authority_attributes.merge('short_name' => 'other_authority'))
      allow(other_authority).to receive(:morph_url).and_return('https://morph.io/planningalerts-scrapers/different_scraper')
      allow(other_authority).to receive(:github_url).and_return('https://github.com/planningalerts-scrapers/different_scraper')

      scraper2 = MorphScraper.new(other_authority)

      expect(scraper1).not_to eq(scraper2)
    end
  end

  describe '#eql?' do
    it 'is an alias for ==' do
      scraper = MorphScraper.new(authority)
      expect(scraper.method(:eql?)).to eq(scraper.method(:==))
    end
  end
end
