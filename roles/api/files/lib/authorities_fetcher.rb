# frozen_string_literal: true

require 'mechanize'
require 'json'
require 'fileutils'
require_relative '../app/helpers/application_helper'
require_relative 'scraper_base'

# Class to scrape authority list from PlanningAlerts website
class AuthoritiesFetcher
  include ApplicationHelper
  include ScraperBase

  AUTHORITIES_URL = 'https://www.planningalerts.org.au/authorities'

  def output_file
    File.join(data_dir, 'authorities.json')
  end

  def temp_output_file
    "#{output_file}.new".freeze
  end

  def etag_file
    "#{output_file}.etag".freeze
  end

  def authorities_dir
    File.join(data_dir, 'authorities')
  end

  # Return the list of all authorities from main planning alerts page
  def self.all
    JSON.parse(File.read(output_file)) if File.size?(output_file)
  end

  # Return the find of an authority
  #
  # @example:
  #     {
  #       "state": "NSW",
  #       "name": "Albury City Council",
  #       "url": "https://www.planningalerts.org.au/authorities/albury",
  #       "short_name": "albury",
  #       "possibly_broken": true,
  #       "population": 56093
  #     }
  def self.authority(short_name)
    all&.find { |a| a['short_name'] == short_name }
  end

  def initialize
    @agent = create_agent
    FileUtils.mkdir_p(authorities_dir)
  end

  def fetch
    changed = false
    with_error_handling('authority list fetching') do
      log "Fetching authority data from #{AUTHORITIES_URL}"

      page = fetch_page_with_etag(AUTHORITIES_URL, etag_file)

      if page.nil?
        raise 'No cached data available and no new content received' unless File.exist?(output_file)
      else
        changed = true
        authorities = parse_authorities(page)

        # Save to temporary file first to ensure atomic operation
        atomic_write_json(authorities, output_file)
        log "Successfully saved #{authorities.size} all"
      end
      changed
    end
  end

  private

  def parse_authorities(page)
    authorities = []
    rows = page.search('table tbody tr')

    rows.each do |row|
      record = {}
      cells = row.search('td')
      next if cells.empty? || cells.length < 3

      authority_cell = cells[1]
      authority_link = authority_cell.at('a')
      next unless authority_link

      record['state'] = extract_text(cells[0])
      record['name'] = extract_text(authority_link)
      record['url'] = authority_link['href']
      record['short_name'] = record['url'].split('/').last
      record['possibly_broken'] = !authority_cell.at('div.bg-yellow').nil?
      record['population'] = extract_number(cells[2].text)
      authorities << record
    end

    authorities
  end
end
