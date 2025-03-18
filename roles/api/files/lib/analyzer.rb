# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'time'
require_relative '../app/helpers/status_helper'
require_relative 'authorities_fetcher'

# Analyse Scraper Details from various sites
class Analyzer
  extend StatusHelper

  # def initialize
  #
  # end

  def run(options = {})
    force = options[:force] || false

    if force # || should_run?
      perform_analysis
    else
      self.class.log 'No analysis needed at this time'
    end
  end

  private

  def perform_analysis
    self.class.log 'Starting scraper analysis'

    # Update status to running
    self.class.update_status({ 'status' => 'analyzing' })

    begin
      # Check PlanningAlerts all
      self.class.log 'Checking PlanningAlerts all...'
      # planning_alerts_status = AuthoritiesFetcher.new.fetch

      # Check GitHub repositories
      self.class.log 'Checking GitHub repositories...'
      # github_data = check_github_repos

      # Check Morph.io scrapers
      self.class.log 'Checking Morph.io scrapers...'
      # morph_data = check_morph_scrapers

      # Process and combine data
      self.class.log 'Processing collected data...'
      # process_data(github_data, morph_data)

      # Update status to completed with timestamps
      now = Time.now.utc.iso8601
      self.class.update_status({ 'last_analyzed' => now, 'status' => 'analyzed' })

      self.class.log 'Analysis completed successfully'
    rescue StandardError => e
      self.class.log "Error during analysis: #{e.message}"
      self.class.log e.backtrace&.join("\n")

      self.class.update_status({
                      'status' => 'analyzing failed',
                      'error' => e.message
                    })
      raise e
    end
  end

  def check_github_repos
    # This would be your actual GitHub API interaction
    # For now, just return a placeholder
    self.class.log 'TODO: Implement GitHub repo checking'

    # Example implementation:
    # uri = URI('https://api.github.com/orgs/planningalerts-scrapers/repos')
    # response = Net::HTTP.get(uri)
    # JSON.parse(response)

    { 'repos' => [] }
  end

  def check_morph_scrapers
    # This would be your actual Morph.io API interaction
    # For now, just return a placeholder
    self.class.log 'TODO: Implement Morph.io scraper checking'

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
end
