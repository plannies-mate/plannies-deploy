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

  def initialize(agent = nil)
    @agent = agent || create_agent
    FileUtils.mkdir_p(AUTHORITIES_DIR)
  end

  def fetch_and_save_details(authority)
    with_error_handling('authority details fetching') do
      return false unless authority && authority['short_name']

      short_name = authority['short_name']
      output_file = File.join(AUTHORITIES_DIR, "#{short_name}.json")
      etag_file = "#{output_file}.etag"

      # Construct URL
      url = "#{BASE_URL}#{short_name}"

      # Fetch page with ETag support
      page = fetch_page_with_etag(url, etag_file)

      # If we didn't get new content but have existing data, return success
      if page.nil? && File.exist?(output_file)
        log "Using existing data for #{short_name}"
        return true
      elsif page.nil?
        log "No cached data available and no new content received for #{short_name}"
        return false
      end

      # Process the page
      details = parse_details(page, authority)

      # Save details to file atomically
      atomic_write_json(details, output_file)

      log "Successfully saved details for #{short_name}"
      true
    end
  end

  private

  def parse_details(page, authority)
    # Start with the basic authority info
    details = authority.clone

    # Find the applications section
    apps_section = page.search('section.py-12').detect do |section|
      section.at('h2')&.text&.strip&.include?('Applications collected')
    end

    return details.merge('error' => 'Could not find applications section') unless apps_section

    # Check for "something might be wrong" message
    error_p = apps_section.at('p.mt-8.text-xl.text-navy')

    if error_p&.text&.include?('something might be wrong')
      details['warning'] = true
      # Extract the "last received" text if present
      last_received_match = error_p.text.match(/last new application was received ([^.]+)\./)
      details['last_received'] = last_received_match[1]&.strip if last_received_match
    end

    # Extract counts from table
    counts = {}
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
        counts['week_count'] = count
      elsif label_text.include?('in the last month')
        counts['month_count'] = count
      elsif (added_match = label_text.match(/since ([^(]+).*when this authority was first added/))
        counts['total_count'] = count
        counts['added'] = added_match[1].strip
      elsif label_text.include?('median') && label_text.include?('per week')
        counts['median_per_week'] = count
      end
    end

    # Merge the counts into the details
    details.merge(counts)
  end
end
