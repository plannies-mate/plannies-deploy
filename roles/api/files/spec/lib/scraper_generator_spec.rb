# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/scraper_generator'

RSpec.describe ScraperGenerator do
  before(:all) do
    # Set up the test data
    DataSupport.link_data
    # Reset the Authority cache to use linked data
    Authority.reset!
    # Reset the MorphScrapersAnalyzer instance
    MorphScrapersAnalyzer.instance.send(:reset!) if MorphScrapersAnalyzer.instance.respond_to?(:reset!, true)
  end

  after(:all) do
    # Clean up test data and output
    DataSupport.cleanup
    FileUtils.rm_rf(ApplicationHelper.site_dir)
  end

  describe '.generate' do
    it 'generates a page for a single scraper' do
      # Get the first scraper from the test data
      analyzer = MorphScrapersAnalyzer.instance
      scraper = analyzer.all.first
      expect(scraper).not_to be_nil

      # Generate the page for this scraper
      described_class.generate(scraper)
      
      output_file = File.join(described_class.site_dir, "scrapers/#{scraper.name}.html")
      expect(File).to exist(output_file)
      
      # Check content includes scraper info
      content = File.read(output_file)
      expect(content).to include(scraper.name)
      expect(content).to include(scraper.morph_url)
      expect(content).to include(scraper.github_url) if scraper.github_url
    end
  end

  describe '.generate_all' do
    it 'generates pages for all scrapers' do
      described_class.generate_all
      
      # Check that a page was generated for each scraper
      analyzer = MorphScrapersAnalyzer.instance
      analyzer.all.each do |scraper|
        output_file = File.join(described_class.site_dir, "scrapers/#{scraper.name}.html")
        expect(File).to exist(output_file)
      end
    end
  end
end
