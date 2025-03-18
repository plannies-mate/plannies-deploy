# frozen_string_literal: true

require 'mechanize'
require 'json'
require 'fileutils'
require_relative '../app/helpers/application_helper'
require_relative 'scraper_base'

# Class to scrape authority list from PlanningAlerts website
class AuthoritiesFetcher
  extend ApplicationHelper
  extend ScraperBase

  AUTHORITIES_URL = 'https://www.planningalerts.org.au/authorities'

  def self.output_file
    File.join(data_dir, 'authorities.json')
  end

  def self.temp_output_file
    "#{output_file}.new".freeze
  end

  def self.etag_file
    "#{output_file}.etag".freeze
  end

  def self.authorities_dir
    File.join(data_dir, 'authorities')
  end

  # Return the list of all authorities from main planning alerts page
  def self.all
    if File.size?(output_file)
      JSON.parse(File.read(output_file))
    else
      []
    end
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

  def initialize(agent = nil)
    @agent = agent || self.class.create_agent
    FileUtils.mkdir_p(self.class.authorities_dir)
  end

  def fetch
    changed = false
    self.class.log "Fetching authority data from #{AUTHORITIES_URL}"

    page = self.class.fetch_page_with_etag(AUTHORITIES_URL, self.class.etag_file)

    if page.nil?
      unless self.class.recent_file?(self.class.output_file)
        raise 'No recent cached data available and no new content received'
      end
    else
      changed = true
      authorities = parse_authorities(page)

      # Save to temporary file first to ensure atomic operation
      self.class.atomic_write_json(authorities, self.class.output_file)
      self.class.log "Successfully saved #{authorities.size} all"
    end
    changed
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

      record['state'] = self.class.extract_text(cells[0])
      record['name'] = self.class.extract_text(authority_link)
      record['url'] = authority_link['href']
      record['short_name'] = record['url'].split('/').last
      record['possibly_broken'] = !authority_cell.at('div.bg-yellow').nil?
      record['population'] = self.class.extract_number(cells[2].text)
      authorities << record
    end

    authorities
  end
end
