# frozen_string_literal: true

require_relative '../lib/planning_alert_authorities'

namespace :analyze do
  desc 'Fetch and process planning authority data from PlanningAlerts'
  task :authorities do
    authorities_scraper = PlanningAlertAuthorities.new
    if authorities_scraper.fetch_and_process
      puts "Successfully updated planning authorities data"
    else
      puts "Failed to update planning authorities data"
      exit 1
    end
  end
end
