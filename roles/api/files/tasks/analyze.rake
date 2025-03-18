# frozen_string_literal: true

require_relative '../lib/analyzer'

namespace :analyze do
  desc 'Run full analysis of scrapers'
  task :all do
    Analyzer.new.run(force: true)
  end

  # desc 'Check for and process pending analysis requests'
  # task :check do
  #   Analyzer.new.run(force: false)
  # end
end
