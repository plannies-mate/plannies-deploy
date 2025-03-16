# frozen_string_literal: true

require_relative '../lib/planning_alert_authorities'

namespace :analyze do
  desc 'Fetch and process planning authority data from PlanningAlerts'
  task :authorities do
    authorities_scraper = PlanningAlertAuthorities.new
    if authorities_scraper.fetch_and_process
      puts 'Successfully updated planning authorities data'
    else
      puts 'Failed to update planning authorities data'
      exit 1
    end
  end

  desc 'Fetch only the authority list without details'
  task :authorities_list do
    puts 'Fetching authorities list only (without details)...'
    authorities_scraper = PlanningAlertAuthorities.new
    if authorities_scraper.fetch_and_process(fetch_details: false)
      puts 'Successfully updated planning authorities list'
    else
      puts 'Failed to update planning authorities list'
      exit 1
    end
  end

  desc 'Fetch details for a specific authority by short_name'
  task :authority_detail, [:short_name] do |_t, args|
    short_name = args[:short_name]

    if short_name.nil? || short_name.empty?
      puts 'Error: You must provide a short_name parameter'
      puts 'Usage: rake analyze:authority_detail[short_name]'
      exit 1
    end

    # Load the authorities list
    authorities_file = File.join(ApplicationHelper::DATA_DIR, 'planning_alert_authorities.json')
    unless File.exist?(authorities_file)
      puts 'Error: Authorities list not found. Run analyze:authorities_list first.'
      exit 1
    end

    authorities_data = JSON.parse(File.read(authorities_file))
    authority = authorities_data['authorities'].find { |a| a['short_name'] == short_name }

    unless authority
      puts "Error: Authority with short_name '#{short_name}' not found"
      exit 1
    end

    puts "Fetching details for #{authority['name']} (#{short_name})..."
    fetcher = AuthorityDetailsFetcher.new

    if fetcher.fetch_and_save_details(authority)
      puts "Successfully fetched details for #{short_name}"
    else
      puts "Failed to fetch details for #{short_name}"
      exit 1
    end
  end
end
