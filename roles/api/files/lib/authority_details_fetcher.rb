# frozen_string_literal: true

require 'mechanize'
require 'json'
require 'fileutils'
require_relative '../app/helpers/application_helper'
require_relative 'scraper_base'

# Class to fetch and parse detailed information for a single authority
class AuthorityDetailsFetcher
  include ApplicationHelper
  include ScraperBase

  BASE_URL = 'https://www.planningalerts.org.au/authorities/'

  def details_dir 
    File.join(data_dir, 'authority_details')
  end

  # Returns find for an authority
  #
  # @example:
  #   {
  #     "short_name": "banyule",
  #     "morph_url": "https://morph.io/planningalerts-scrapers/multiple_civica",
  #     "github_url": "https://github.com/planningalerts-scrapers/multiple_civica",
  #     "last_log": "0 applications found for Bayside City Council (Victoria), VIC with date from 2025-03-11\nTook 0 s to import applications from Bayside City Council (Victoria), VIC",
  #     "app_count": 0,
  #     "import_time": "0 s"
  #   }
  def self.find(short_name)
    output_file = File.join(details_dir, "#{short_name}.json")
    JSON.parse(File.read(output_file)) if File.size?(output_file)
  end

  def initialize(agent = nil)
    @agent = agent || create_agent
    FileUtils.mkdir_p(details_dir)
  end

  def fetch(short_name)
    with_error_handling('authority find fetching') do
      changed = false
      raise(ArgumentError, 'Must supply short_name') if short_name.to_s.empty?

      output_file = File.join(details_dir, "#{short_name}.json")
      etag_file = "#{output_file}.etag"
      url = "#{BASE_URL}#{short_name}/under_the_hood"

      page = fetch_page_with_etag(url, etag_file)

      if page.nil?
        raise "No cached data available and no new content received for #{short_name}" unless File.exist?(output_file)
      else
        changed = true
        details = parse_details(page, short_name)

        atomic_write_json(details, output_file)
        log "Successfully saved find for #{short_name}"
      end
      changed
    end
  end

  private

  def parse_details(page, short_name)
    details = { short_name: short_name }

    # Extract morph.io URL - look for 'Watch the scraper' link
    page.links.each do |link|
      if link.text.strip.include?('Watch the scraper')
        details['morph_url'] = link.href
      elsif link.text.strip.include?('Fork the scraper on Github')
        details['github_url'] = link.href
      end
    end

    # Extract the recent import logs
    import_section = page.search('section#import')
    if import_section&.any?
      # Look for pre tag with logs
      pre_text = (import_section.at('pre')&.text || '').to_s.strip
      unless pre_text.empty?
        details['last_log'] = pre_text

        # Additionally extract some useful data from the log
        if (match = pre_text.match(/(\d+) applications found/))
          details['app_count'] = match[1].to_i
        end

        if (match = pre_text.match(/Took (\d+(\.\d+)? \w*) to import/))
          details['import_time'] = match[1]
        end
      end
    end

    raise("MISSING morph_url FROM: #{details.inspect}") if details['morph_url'].to_s.empty?
    raise("MISSING github_url FROM: #{details.inspect}") if details['github_url'].to_s.empty?

    details
  end
end
