# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/scrapers_generator'

RSpec.describe ScrapersGenerator do
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
    FileUtils.rm_rf(described_class.site_dir)
  end

  describe '.generate' do
    it 'generates a scrapers index page' do
      described_class.generate

      output_file = File.join(described_class.site_dir, 'scrapers.html')
      expect(File).to exist(output_file)

      # Check content includes scraper info
      content = File.read(output_file)

      # Get expected data to verify content
      analyzer = MorphScrapersAnalyzer.instance
      multi_scrapers = analyzer.all.select { |s| s.authorities.size > 1 }
      custom_scrapers = analyzer.all.select { |s| s.authorities.size == 1 }

      # Content should include section headers
      expect(content).to include('Multi-Authority Scrapers') if multi_scrapers.any?
      expect(content).to include('Custom Scrapers') if custom_scrapers.any?

      # Content should include at least one scraper name
      analyzer.all.first(3).each do |scraper|
        expect(content).to include(CGI.escape_html(scraper.name))
      end
    end
  end
end
