# frozen_string_literal: true

require_relative 'application_controller'

# Health Controller
class HealthController < ApplicationController
  include StatusHelper

  # Return health information in a json object
  get '/' do
    status = load_status

    # Check if the scraper has run in the last 25 hours
    last_check = status['last_check']
    health_status = 'ok'
    message = 'API is operational'

    if last_check
      last_check_time = begin
                          Time.parse(last_check)
                        rescue StandardError
                          nil
                        end
      if last_check_time && (Time.now - last_check_time) > (25 * 60 * 60)
        health_status = 'warning'
        message = 'Scraper data is stale (not run in past 25 hours)'
      end
    else
      health_status = 'warning'
      message = 'Scraper has never run'
    end

    json(
      status: health_status,
      message: message,
      time: Time.now.iso8601
    )
  end
end
