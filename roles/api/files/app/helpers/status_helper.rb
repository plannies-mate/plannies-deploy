# frozen_string_literal: true

require_relative 'application_helper'

# Helper methods and CONSTANTS
# use `extend StatusHelper` so everything become class methods
module StatusHelper
  include ApplicationHelper

  def roundup_request_file
    File.join(data_dir, 'roundup_request.dat')
  end

  def roundup_requested?
    File.exist?(roundup_request_file)
  end

  def roundup_requested=(value)
    if value
      File.write(roundup_request_file, Time.now.to_s)
    else
      FileUtils.rm_f(roundup_request_file)
    end
  end

  def roundup_status_file
    File.join(data_dir, 'roundup_status.json')
  end

  # Loads current status
  # @example:
  #   {
  #     'last_roundup' => 'Time in iso format',
  #     'status' => 'terse status'
  #   }
  def load_status
    if File.size?(roundup_status_file)
      JSON.parse(File.read(roundup_status_file))
    else
      default_status('missing')
    end
  rescue StandardError => e
    log "ERROR: #{e.message}"
    default_status('error')
  end

  def default_status(status = 'unknown')
    {
      'last_roundup' => nil,
      'status' => status
    }
  end

  def update_status(status_update)
    save_status(load_status.merge(status_update))
  end

  def save_status(status)
    FileUtils.mkdir_p(data_dir)

    File.write(roundup_status_file, JSON.pretty_generate(status))
  end

  # Helper for human-readable time differences
  def time_ago_in_words(from_time)
    distance_in_seconds = (Time.now - from_time).round
    case distance_in_seconds
    when 0..10
      'just now'
    when 10..99.94 * 60
      "#{(distance_in_seconds / 60.0).round(1)} minutes ago"
    else
      "#{(distance_in_seconds / 3600.0).round(1)} hours ago"
    end
  end
end
