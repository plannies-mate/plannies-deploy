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
  AUTHORITIES_DIR = File.join(DATA_DIR, 'planning_alert_authorities')

  # Returns details for an authority
  #
  # @example:
  #   {
  #     "short_name": "banyule",
  #     "warning": true,
  #     "last_received": "about 3 years ago",
  #     "week_count": 0,
  #     "month_count": 0,
  #     "total_count": 2055,
  #     "added": "14 dec 2009",
  #     "median_per_week": 7
  #   }
  def self.details(short_name)
    output_file = File.join(AUTHORITIES_DIR, "#{short_name}.json")
    JSON.parse(File.read(output_file)) if File.size?(output_file)
  end

  def initialize(agent = nil)
    @agent = agent || create_agent
    FileUtils.mkdir_p(AUTHORITIES_DIR)
  end

  def fetch(short_name)
    with_error_handling('authority details fetching') do
      changed = false
      raise(ArgumentError, 'Must supply short_name') if short_name.to_s.empty?

      output_file = File.join(AUTHORITIES_DIR, "#{short_name}.json")
      etag_file = "#{output_file}.etag"
      url = "#{BASE_URL}#{short_name}"

      page = fetch_page_with_etag(url, etag_file)

      if page.nil?
        raise "No cached data available and no new content received for #{short_name}" unless File.exist?(output_file)
      else
        changed = true
        details = parse_details(page, short_name)

        atomic_write_json(details, output_file)
        log "Successfully saved details for #{short_name}"
      end
      changed
    end
  end

  private

  def parse_details(page, short_name)
    details = { short_name: short_name }

    # Find the applications section
    apps_section = page.search('section.py-12').detect do |section|
      section.at('h2')&.text&.strip&.include?('Applications collected')
    end
    return details.merge('error' => 'Could not find applications section') unless apps_section

    error_p = apps_section.at('p.mt-8.text-xl.text-navy')
    if error_p&.text&.include?('something might be wrong')
      details['warning'] = true
      # Extract the "last received" text if present
      last_received_match = error_p.text.match(/last new application was received ([^.]+)\./)
      details['last_received'] = last_received_match[1]&.strip if last_received_match
    end

    # Extract counts from table
    apps_section.search('tr').each do |row|
      # Extract the number from the first cell
      count_cell = row.at('td')
      next unless count_cell

      count = extract_number(count_cell.text)

      # Extract the label from the second cell
      label_cell = row.at('th')
      next unless label_cell

      label_text = extract_text(label_cell).downcase

      if label_text.include?('in the last week')
        details['week_count'] = count
      elsif label_text.include?('in the last month')
        details['month_count'] = count
      elsif (added_match = label_text.match(/since ([^(]+).*when this authority was first added/))
        details['total_count'] = count
        details['added'] = added_match[1].strip
      elsif label_text.include?('median') && label_text.include?('per week')
        details['median_per_week'] = count
      end
    end
    details
  end
end
