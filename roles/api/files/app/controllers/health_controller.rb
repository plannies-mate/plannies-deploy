# frozen_string_literal: true

require_relative 'application_controller'

# Health Controller
class HealthController < ApplicationController
  extend StatusHelper

  # Return health information in a json object
  get '/' do
    status = self.class.load_status

    # Check if the scraper has run in the last 25 hours
    last_roundup = status['last_roundup']
    health_status = 'ok'
    message = 'API is operational'

    if last_roundup
      last_roundup_time = begin
                          Time.parse(last_roundup)
                        rescue StandardError
                          nil
                        end
      seconds_in_25hours = (25 * 60 * 60)
      if last_roundup_time.nil?
        health_status = 'warning'
        message = 'Scraper has invalid run time'
      elsif last_roundup_time < Time.now - seconds_in_25hours
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
