# frozen_string_literal: true

require_relative 'application_controller'
require_relative '../helpers/status_helper'

# Analyze Controller
class AnalyzeController < ApplicationController
  extend StatusHelper

  get '/' do
    status = self.class.load_status

    # Add extra info about how long ago checks happened
    formatted_status = status.clone

    %w[last_roundup github_check morph_check].each do |check|
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

    content_type :json
    json(formatted_status)
  end

  # Trigger scrape endpoint
  post '/' do
    self.class.roundup_requested = true

    # Update status
    self.class.update_status('roundup_requested' => true, 'status' => 'pending')
    content_type :json
    json(
      success: true,
      message: 'Roundup requested'
    )
  end
end
