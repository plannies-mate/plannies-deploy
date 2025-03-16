# frozen_string_literal: true

require 'mechanize'
require 'json'
require 'fileutils'
require_relative '../app/helpers/application_helper'

# Class to scrape authority data from PlanningAlerts website
class PlanningAlertAuthorities
  include ApplicationHelper

  AUTHORITIES_URL = 'https://www.planningalerts.org.au/authorities'
  OUTPUT_FILE = File.join(DATA_DIR, 'planning_alert_authorities.json')
  TEMP_OUTPUT_FILE = "#{OUTPUT_FILE}.new".freeze

  def initialize
    @agent = Mechanize.new
    @agent.user_agent = 'Plannies-Mate/1.0'
    @agent.robots = :all
    @agent.history.max_size = 1
  end

  def fetch_and_process
    log "Fetching authority data from #{AUTHORITIES_URL}"

    page = fetch_page
    return false unless page

    authorities = parse_authorities(page)

    # Save to temporary file first to ensure atomic operation
    save_authorities(authorities, TEMP_OUTPUT_FILE)

    # Only replace the main file if we successfully saved the temp file
    FileUtils.mv(TEMP_OUTPUT_FILE, OUTPUT_FILE)

    log "Successfully processed #{authorities.size} authorities"
    true
  rescue StandardError => e
    log "Error processing authorities: #{e.message}"
    log e.backtrace&.join("\n")
    false
  end

  private

  def fetch_page
    # Check if we have an ETag stored to potentially avoid fetching the same content twice
    etag_file = "#{OUTPUT_FILE}.etag"
    headers = {}

    if File.exist?(etag_file) && File.exist?(OUTPUT_FILE)
      etag = File.read(etag_file).strip
      headers['If-None-Match'] = etag if etag && !etag.empty?
    end

    begin
      page = @agent.get(AUTHORITIES_URL, [], nil, headers)

      # Store the new ETag for future requests
      File.write(etag_file, page.header['etag']) if page.header['etag']

      page
    rescue Mechanize::ResponseCodeError => e
      raise e unless e.response_code == '304'

      # Not modified, use existing file
      log 'Remote content unchanged (304 Not Modified) - skipping recreation'
      nil
    end
  end

  def parse_authorities(page)
    authorities = []

    # Find all table rows in the authorities table (skip header row)
    rows = page.search('table tbody tr')

    rows.each do |row|
      cells = row.search('td')
      next if cells.empty? || cells.length < 3

      # Extract data from cells
      state = cells[0].text.strip

      # Authority name and link
      authority_cell = cells[1]
      authority_link = authority_cell.at('a')
      next unless authority_link

      authority_name = authority_link.text.strip
      authority_url = authority_link['href']

      # Check if possibly broken
      possibly_broken = !authority_cell.at('div.bg-yellow').nil?

      # Population
      population = cells[2].text.strip.gsub(/\D/, '').to_i

      authorities << {
        'state' => state,
        'name' => authority_name,
        'url' => authority_url,
        'possibly_broken' => possibly_broken,
        'population' => population
      }
    end

    authorities
  end

  def save_authorities(authorities, filename)
    # Ensure the data directory exists
    FileUtils.mkdir_p(File.dirname(filename))

    # Save as formatted JSON
    File.write(filename, JSON.pretty_generate({
                                                'authorities' => authorities,
                                                'last_updated' => Time.now.utc.iso8601,
                                                'source' => AUTHORITIES_URL
                                              }))
  end
end
