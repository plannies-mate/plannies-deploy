# frozen_string_literal: true

require_relative 'application_helper'

# Helper methods and CONSTANTS
module StatusHelper
  include ApplicationHelper

  STATUS_FILE = File.join(DATA_DIR, 'scrape_status.json')
  TRIGGER_FILE = File.join(DATA_DIR, 'trigger_scrape')

  def load_status
    if File.size?(STATUS_FILE)
      JSON.parse(File.read(STATUS_FILE))
    else
      default_status('missing')
    end
  rescue StandardError => e
    log "ERROR: #{e.message}"
    default_status('error')
  end

  def default_status(status = 'unknown')
    {
      'last_check' => nil,
      'github_check' => nil,
      'morph_check' => nil,
      'status' => status,
      'job_pending' => false
    }
  end

  def update_status(status_update)
    status = load_status
    status.merge!(status_update)

    File.write(STATUS_FILE, JSON.pretty_generate(status))
  end

  def save_status(status)
    FileUtils.mkdir_p(DATA_DIR)

    File.write(STATUS_FILE, JSON.pretty_generate(status))
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
