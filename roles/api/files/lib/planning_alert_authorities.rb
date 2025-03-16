# frozen_string_literal: true

require 'mechanize'
require 'json'
require 'fileutils'
require_relative '../app/helpers/application_helper'
require_relative 'scraper_base'
require_relative 'authority_details_fetcher'

# Class to scrape authority data from PlanningAlerts website
class PlanningAlertAuthorities
  include ApplicationHelper
  include ScraperBase

  AUTHORITIES_URL = 'https://www.planningalerts.org.au/authorities'
  OUTPUT_FILE = File.join(DATA_DIR, 'planning_alert_authorities.json')
  TEMP_OUTPUT_FILE = "#{OUTPUT_FILE}.new".freeze
  ETAG_FILE = "#{OUTPUT_FILE}.etag".freeze
  AUTHORITIES_DIR = File.join(DATA_DIR, 'planning_alert_authorities')

  def initialize
    @agent = create_agent
    FileUtils.mkdir_p(AUTHORITIES_DIR)
  end

  def fetch_and_process(options = {})
    changed = false
    fetch_details = options.fetch(:fetch_details, true)

    with_error_handling('authority list fetching') do
      log "Fetching authority data from #{AUTHORITIES_URL}"

      page = fetch_page_with_etag(AUTHORITIES_URL, ETAG_FILE)

      # If we didn't get new content but have existing data, return success
      if page.nil?
        if File.exist?(OUTPUT_FILE)
          log 'Using existing authority data'
          return changed unless fetch_details
        else
          log 'No cached data available and no new content received'
          return changed
        end
        authorities = JSON.parse(File.read(OUTPUT_FILE))['authorities'] || {}
      else
        changed = true
        authorities = parse_authorities(page)

        # Save to temporary file first to ensure atomic operation
        atomic_write_json({
                            'authorities' => authorities,
                            'last_updated' => Time.now.utc.iso8601,
                            'source' => AUTHORITIES_URL
                          }, OUTPUT_FILE)
      end

      # Fetch details for each authority if requested
      if fetch_details && !authorities.empty?
        fetcher = AuthorityDetailsFetcher.new(@agent)
        authorities.each do |authority|
          log "Fetching details for #{authority['name']} (#{authority['short_name']})"
          fetcher.fetch_and_save_details(authority)
          # Add a small delay to avoid overwhelming the server
        end
      end

      log "Successfully processed #{authorities.size} authorities"
      true
    end
  end

  private

  def parse_authorities(page)
    authorities = []

    # Find all table rows in the authorities table (skip header row)
    rows = page.search('table tbody tr')

    rows.each do |row|
      cells = row.search('td')
      next if cells.empty? || cells.length < 3

      # Extract data from cells
      state = extract_text(cells[0])

      # Authority name and link
      authority_cell = cells[1]
      authority_link = authority_cell.at('a')
      next unless authority_link

      authority_name = extract_text(authority_link)
      authority_url = authority_link['href']

      # Extract short_name from URL
      short_name = authority_url.split('/').last

      # Check if possibly broken
      possibly_broken = !authority_cell.at('div.bg-yellow').nil?

      # Population
      population = extract_number(cells[2].text)

      authorities << {
        'state' => state,
        'name' => authority_name,
        'url' => authority_url,
        'short_name' => short_name,
        'possibly_broken' => possibly_broken,
        'population' => population
      }
    end

    authorities
  end
end
