# frozen_string_literal: true

require 'mechanize'
require 'json'
require 'fileutils'
require_relative '../app/helpers/application_helper'
require_relative 'scraper_base'

# Class to fetch and parse detailed information for a single authority
class AuthorityStatsFetcher
  include ApplicationHelper
  include ScraperBase

  BASE_URL = 'https://www.planningalerts.org.au/authorities/'

  def stats_dir
    File.join(data_dir, 'authority_stats')
  end

  # Returns stats for an authority
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
  def self.stats(short_name)
    output_file = File.join(stats_dir, "#{short_name}.json")
    JSON.parse(File.read(output_file)) if File.size?(output_file)
  end

  def initialize(agent = nil)
    @agent = agent || create_agent
    FileUtils.mkdir_p(stats_dir)
  end

  def fetch(short_name)
    with_error_handling('authority stats fetching') do
      changed = false
      raise(ArgumentError, 'Must supply short_name') if short_name.to_s.empty?

      output_file = File.join(stats_dir, "#{short_name}.json")
      etag_file = "#{output_file}.etag"
      url = "#{BASE_URL}#{short_name}"

      page = fetch_page_with_etag(url, etag_file)

      if page.nil?
        raise "No cached data available and no new content received for #{short_name}" unless File.exist?(output_file)
      else
        changed = true
        stats = parse_stats(page, short_name)

        atomic_write_json(stats, output_file)
        log "Successfully saved stats for #{short_name}"
      end
      changed
    end
  end

  private

  def parse_stats(page, short_name)
    stats = { short_name: short_name }

    # Find the applications section
    apps_section = page.search('section.py-12').detect do |section|
      section.at('h2')&.text&.strip&.include?('Applications collected')
    end
    return stats.merge('error' => 'Could not find applications section') unless apps_section

    error_p = apps_section.at('p.mt-8.text-xl.text-navy')
    if error_p&.text&.include?('something might be wrong')
      stats['warning'] = true
      # Extract the "last received" text if present
      last_received_match = error_p.text.match(/last new application was received ([^.]+)\./)
      stats['last_received'] = last_received_match[1]&.strip if last_received_match
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
        stats['week_count'] = count
      elsif label_text.include?('in the last month')
        stats['month_count'] = count
      elsif (added_match = label_text.match(/since ([^(]+).*when this authority was first added/))
        stats['total_count'] = count
        stats['added'] = added_match[1].strip
      elsif label_text.include?('median') && label_text.include?('per week')
        stats['median_per_week'] = count
      end
    end
    stats
  end
end
