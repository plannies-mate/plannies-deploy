# frozen_string_literal: true

require_relative '../lib/planning_alert_authorities'
require_relative '../lib/authority_details_fetcher'
require_relative '../lib/authority_stats_fetcher'

namespace :fetch do
  desc 'Fetch all information from remote sites'
  task all: %i[authorities statistics details] do
    puts 'Finished'
  end

  desc 'Fetch planning authority list from PlanningAlerts'
  task :authorities do
    authorities_scraper = PlanningAlertAuthorities.new
    authorities_scraper.fetch
  end

  desc 'Fetch planning authority statistics from PlanningAlerts'
  task :statistics do
    authorities = PlanningAlertAuthorities.authorities
    fetcher = AuthorityStatsFetcher.new
    authorities.each do |authority|
      fetcher.fetch(authority['short_name'])
    end
  end

  desc 'Fetch the statistics for a specific authority by short_name'
  task :statistic, [:short_name] do |_t, args|
    short_name = args[:short_name]

    authority = PlanningAlertAuthorities.authority(short_name)

    unless authority
      puts "Error: Authority with short_name #{short_name.inspect} not found"
      exit 1
    end

    puts "Fetching details for #{authority['name']} (#{short_name})..."
    fetcher = AuthorityStatsFetcher.new

    fetcher.fetch(short_name)
  end

  desc 'Fetch planning authority under the hood details from PlanningAlerts'
  task :details do
    authorities = PlanningAlertAuthorities.authorities
    fetcher = AuthorityDetailsFetcher.new
    authorities.each do |authority|
      fetcher.fetch(authority['short_name'])
    end
  end

  desc 'Fetch under the hood details for a specific authority by short_name'
  task :detail, [:short_name] do |_t, args|
    short_name = args[:short_name]

    authority = PlanningAlertAuthorities.authority(short_name)

    unless authority
      puts "Error: Authority with short_name #{short_name.inspect} not found"
      exit 1
    end

    puts "Fetching details for #{authority['name']} (#{short_name})..."
    fetcher = AuthorityDetailsFetcher.new

    fetcher.fetch(short_name)
  end
end
