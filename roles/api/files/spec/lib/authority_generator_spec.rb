# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/authority_generator'

RSpec.describe AuthorityGenerator do
  before(:all) do
    # Set up the test data
    DataSupport.link_data
    # Reset the Authority cache to use linked data
    Authority.reset!
  end

  after(:all) do
    # Clean up test data and output
    DataSupport.cleanup
    FileUtils.rm_rf(described_class.site_dir)
  end

  describe '.generate' do
    it 'generates a page for a single authority' do
      # Get the first authority from the test data
      authority = Authority.all.first
      expect(authority).not_to be_nil

      # Generate the page for this authority
      described_class.generate(authority)
      
      output_file = File.join(described_class.site_dir, "authorities/#{authority.short_name}.html")
      expect(File).to exist(output_file)
      
      # Check content includes authority info
      content = File.read(output_file)
      expect(content).to include(CGI::escape_html(authority.name))
      expect(content).to include(CGI::escape_html(authority.short_name))
      expect(content).to include(CGI::escape_html(authority.url)) if authority.url
    end
  end

  describe '.generate_all' do
    it 'generates pages for all authorities' do
      described_class.generate_all
      
      # Check that a page was generated for each authority
      Authority.all.each do |authority|
        output_file = File.join(described_class.site_dir, "authorities/#{authority.short_name}.html")
        expect(File).to exist(output_file)
      end
    end
  end
end
