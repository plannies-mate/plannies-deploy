# frozen_string_literal: true

require_relative 'application_controller'

# Analyze Controller
class AnalyzeController < ApplicationController
  include StatusHelper

  get '/' do
    status = load_status

    # Add extra info about how long ago checks happened
    formatted_status = status.clone

    %w[last_check github_check morph_check].each do |check|
      if status[check]
        begin
          check_time = Time.parse(status[check])
          time_ago = time_ago_in_words(check_time)
          formatted_status["#{check}_ago"] = time_ago
        rescue StandardError
          formatted_status["#{check}_ago"] = 'unknown'
        end
      else
        formatted_status["#{check}_ago"] = 'never'
      end
    end

    json(formatted_status)
  end

  # Trigger scrape endpoint
  post '/' do
    FileUtils.mkdir_p(File.dirname(TRIGGER_FILE))
    # Create trigger file
    File.write(TRIGGER_FILE, Time.now.iso8601)

    # Update status
    status = load_status
    status['job_pending'] = true
    save_status(status)

    json(
      success: true,
      message: 'Scrape job triggered',
      status: status
    )
  end
end
