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
require_relative '../lib/analyzer'

# Main execution
if __FILE__ == $0
  analyzer = Analyzer.new

  case ARGV[0]
  when 'run'
    analyzer.run(force: true)
  when 'if-requested'
    analyzer.check_if_requested
  else
    puts "Usage: #{$0} [run|if-requested]"
    puts '  run: Force a full analysis run'
    puts '  if-requested: Only run if trigger file exists'
    exit 1
  end
end
