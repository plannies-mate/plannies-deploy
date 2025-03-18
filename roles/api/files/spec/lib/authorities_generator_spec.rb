# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/authorities_generator'

RSpec.describe AuthoritiesGenerator do
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
    it 'generates an authorities index page' do
      described_class.generate

      output_file = File.join(described_class.site_dir, 'authorities.html')
      expect(File).to exist(output_file)

      # Check content includes authority info
      content = File.read(output_file)
      puts 'CONTENT', content, 'END'
      Authority.all.each do |authority|
        expect(content).to include(CGI::escapeHTML(authority.name))
        expect(content).to include(CGI::escapeHTML(authority.short_name))
      end
    end
  end
end
