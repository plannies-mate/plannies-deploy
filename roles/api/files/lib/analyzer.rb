# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'time'
require_relative '../app/helpers/status_helper'
require_relative 'authorities_fetcher'

# Analyse Scraper Details from various sites
class Analyzer
  include StatusHelper

  data_dir = File.join(File.dirname(__FILE__), '../data')
  STATUS_FILE = File.join(data_dir, 'scrape_status.json')
  TRIGGER_FILE = File.join(data_dir, 'trigger_scrape')

  def initialize
    FileUtils.mkdir_p(data_dir)
  end

  def run(options = {})
    force = options[:force] || false

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
      # Check PlanningAlerts all
      log 'Checking PlanningAlerts all...'
      planning_alerts_status = AuthoritiesFetcher.new.fetch

      # Check GitHub repositories
      log 'Checking GitHub repositories...'
      # github_data = check_github_repos

      # Check Morph.io scrapers
      log 'Checking Morph.io scrapers...'
      # morph_data = check_morph_scrapers

      # Process and combine data
      log 'Processing collected data...'
      # process_data(github_data, morph_data)

      # Update status to completed with timestamps
      now = Time.now.utc.iso8601
      update_status({
                      'last_check' => now,
                      'github_check' => now,
                      'morph_check' => now,
                      'planning_alerts_check' => planning_alerts_status ? now : nil,
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

  def log(message)
    puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - #{message}"
  end
end
