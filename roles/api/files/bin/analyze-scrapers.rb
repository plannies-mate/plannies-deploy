#!/usr/bin/env ruby
# frozen_string_literal: true

# Periodic script to check for and process scraper trigger
# Intended to be run via cron
# Recommended:
#   */15 1-23 * * * /var/www/api/bin/analyze-scrapers.rb if-requested >> /var/www/api/log/analyze-scrapers.log 2>&1
#   0 0 * * *  mv -f /var/www/api/log/analyze-scrapers.log /var/www/api/log/analyze-scrapers.log.1
#   15 0 * * * /var/www/api/bin/analyze-scrapers.rb run > /var/www/api/log/analyze-scrapers.log 2>&1

require 'json'
require 'fileutils'
require 'time'
require 'net/http'
require 'bundler/setup'
require_relative '../app/helpers/application_helper'

# Analyse Scraper Details from various sites
class ScraperAnalyzer
  extend ApplicationHelper

  def initialize
    FileUtils.mkdir_p(DATA_DIR)
  end



  def run(force = false)
    if force || should_run?
      perform_analysis
    else
      log 'No analysis needed at this time'
    end
  end

  def check_if_requested
    if File.exist?(TRIGGER_FILE)
      log 'Trigger file found, starting analysis'
      FileUtils.rm(TRIGGER_FILE)
      perform_analysis
    else
      log 'No trigger file found, skipping analysis'
    end
  end

  private

  def should_run?
    # Check if trigger file exists
    return true if File.exist?(TRIGGER_FILE)

    # Check if we need to run based on time
    if File.exist?(STATUS_FILE)
      status = load_status
      last_check = status['last_check']

      if last_check.nil? || last_check == 'null'
        log 'No previous check found, running initial analysis'
        return true
      else
        begin
          last_check_time = Time.parse(last_check)
          time_diff = Time.now - last_check_time

          # Run if more than 24 hours have passed
          if time_diff > 24 * 60 * 60
            log 'Last check was more than 24 hours ago, running scheduled analysis'
            return true
          end
        rescue => e
          log "Error parsing last check time: #{e.message}, running analysis"
          return true
        end
      end
    else
      log 'Status file not found, running initial analysis'
      return true
    end

    false
  end
  
  def perform_analysis
    log 'Starting scraper analysis'

    # Update status to running
    update_status({
                    'status' => 'running',
                    'job_pending' => false
                  })

    begin
      # Check GitHub repositories
      log 'Checking GitHub repositories...'
      github_data = check_github_repos

      # Check Morph.io scrapers
      log 'Checking Morph.io scrapers...'
      morph_data = check_morph_scrapers

      # Process and combine data
      log 'Processing collected data...'
      # process_data(github_data, morph_data)

      # Update status to completed with timestamps
      now = Time.now.utc.iso8601
      update_status({
                      'last_check' => now,
                      'github_check' => now,
                      'morph_check' => now,
                      'status' => 'completed'
                    })

      log 'Analysis completed successfully'
    rescue => e
      log "Error during analysis: #{e.message}"
      log e.backtrace.join("\n")

      update_status({
                      'status' => 'error',
                      'error' => e.message
                    })
    end
  end

  def check_github_repos
    # This would be your actual GitHub API interaction
    # For now, just return a placeholder
    log 'TODO: Implement GitHub repo checking'

    # Example implementation:
    # uri = URI('https://api.github.com/orgs/planningalerts-scrapers/repos')
    # response = Net::HTTP.get(uri)
    # JSON.parse(response)

    { 'repos' => [] }
  end

  def check_morph_scrapers
    # This would be your actual Morph.io API interaction
    # For now, just return a placeholder
    log 'TODO: Implement Morph.io scraper checking'

    # Example implementation:
    # uri = URI('https://morph.io/api/scrapers')
    # request = Net::HTTP::Get.new(uri)
    # request['Authorization'] = "Bearer #{ENV['MORPH_API_KEY']}"
    # response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    #   http.request(request)
    # end
    # JSON.parse(response.body)

    { 'scrapers' => [] }
  end

  def process_data(github_data, morph_data)
    # This would combine and process data from both sources
    # For now, just log
    log 'TODO: Implement data processing logic'

    # You would implement logic here to:
    # 1. Match scrapers to repositories
    # 2. Check scraper status
    # 3. Generate reports
    # 4. Save processed data to files
  end
end

# Main execution
if __FILE__ == $0
  analyzer = ScraperAnalyzer.new

  case ARGV[0]
  when 'run'
    analyzer.run(true)
  when 'if-requested'
    analyzer.check_if_requested
  else
    puts "Usage: #{$0} [run|if-requested]"
    puts '  run: Force a full analysis run'
    puts '  if-requested: Only run if trigger file exists'
    exit 1
  end
end
