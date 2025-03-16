# frozen_string_literal: true

require_relative '../lib/planning_alert_authorities'

namespace :fetch do
  desc 'Fetch all information from remote sites'
  task all: %i[authorities authority_details] do
    puts 'Finished' 
  end

  desc 'Fetch planning authority list from PlanningAlerts'
  task :authorities do
    authorities_scraper = PlanningAlertAuthorities.new
    authorities_scraper.fetch
  end

  desc 'Fetch planning authority details from PlanningAlerts'
  task :authority_details do
    authorities = PlanningAlertAuthorities.authorities
    fetcher = AuthorityDetailsFetcher.new
    authorities.each do |authority|
      fetcher.fetch(authority['short_name'])
    end
  end

  desc 'Fetch details for a specific authority by short_name'
  task :authority_detail, [:short_name] do |_t, args|
    short_name = args[:short_name]

    authority = PlanningAlertAuthorities.authority(short_name)

    unless authority
      puts "Error: Authority with short_name #{short_name.inspect} not found"
      exit 1
    end

    puts "Fetching details for #{authority['name']} (#{short_name})..."
    fetcher = AuthorityDetailsFetcher.new

    if fetcher.fetch(short_name)
      puts "Successfully fetched details for #{short_name}"
    else
      puts "Failed to fetch details for #{short_name}"
      exit 1
    end
  end

  # TODO:
  #   desc 'Fetch planning authority under the hood details from PlanningAlerts'
  #   task :authority_details do
  #     authorities = PlanningAlertAuthorities.authorities
  #     fetcher = AuthorityDetailsFetcher.new
  #     authorities.each do |authority|
  #       fetcher.fetch(authority['short_name'])
  #     end
  #   end
  #
  #   desc 'Fetch details for a specific authority by short_name'
  #   task :authority_detail, [:short_name] do |_t, args|
  #     short_name = args[:short_name]
  #
  #     authority = PlanningAlertAuthorities.authority(short_name)
  #
  #     unless authority
  #       puts "Error: Authority with short_name #{short_name.inspect} not found"
  #       exit 1
  #     end
  #
  #     puts "Fetching details for #{authority['name']} (#{short_name})..."
  #     fetcher = AuthorityDetailsFetcher.new
  #
  #     if fetcher.fetch(short_name)
  #       puts "Successfully fetched details for #{short_name}"
  #     else
  #       puts "Failed to fetch details for #{short_name}"
  #       exit 1
  #     end
  #   end
end
