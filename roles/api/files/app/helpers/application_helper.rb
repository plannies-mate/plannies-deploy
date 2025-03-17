# frozen_string_literal: true

# Application wide Helper methods and CONSTANTS
module ApplicationHelper
  def log(message)
    puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - #{message}"
  end

  def rack_env
    ENV['RACK_ENV'] || 'development'
  end

  def production?
    rack_env == 'production'
  end

  def site_dir
    production? ? '/var/www/html' : File.expand_path('../../../../../tmp/html', __dir__)
  end

  def data_dir
    File.join(site_dir, 'data')
  end
end
