# frozen_string_literal: true

# Application wide Helper methods and CONSTANTS
module ApplicationHelper
  DATA_DIR = File.expand_path('../../data', __dir__)

  def log(message)
    puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - #{message}"
  end
end
