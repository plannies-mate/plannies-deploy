# frozen_string_literal: true

require 'mechanize'
require 'json'
require 'fileutils'
require 'time'

# Module providing common functionality for web scrapers
module ScraperBase
  # Create a standardized Mechanize agent
  def create_agent
    agent = Mechanize.new
    agent.user_agent = 'Plannies-Mate/1.0'
    agent.robots = :all
    agent.history.max_size = 1
    agent
  end

  def force?
    !ENV['FORCE'].to_s.empty?
  end

  def debug?
    !ENV['DEBUG'].to_s.empty?
  end

  # Fetch a page with conditional GET using ETags
  def fetch_page_with_etag(url, etag_file, agent = nil)
    agent ||= @agent || create_agent

    headers = {}
    # only use etag when both etag and data files exists and FORCE is not set and etag file is recent
    etag = nil
    week_ago = Time.now - 7 * 24 * 60 * 60
    data_file = etag_file.sub(/\.etag\z/, '')
    if File.exist?(etag_file) && File.exist?(data_file) && !force? && File.mtime(etag_file) > week_ago
      etag = File.read(etag_file).strip
      headers['If-None-Match'] = etag if etag && !etag.empty?
    end

    begin
      started = Time.now
      page = agent.get(url, [], nil, headers)
      took = Time.now - started
      log "DEBUG: Delaying #{(took * 2).round(3)}s for #{url}" if debug?
      sleep(took)

      http_code = page.code.to_i
      if http_code == 304
        log "NOTE: Remote content unchanged for #{url}"
      elsif ![200, 203].include?(http_code)
        raise("ERROR: Unaccepted response code: #{http_code} for #{url}")
      elsif page.body.empty?
        raise("ERROR: Empty response for #{url}")
      else
        # Store the new ETag for future requests if its changed
        if page.header['etag'] && page.header['etag'].strip != etag
          FileUtils.mkdir_p(File.dirname(etag_file))
          File.write(etag_file, page.header['etag'])
        end

        page
      end
    end
  end

  # Write JSON to a file atomically
  def atomic_write_json(data, filename)
    temp_file = "#{filename}.new"
    FileUtils.mkdir_p(File.dirname(filename))

    File.write(temp_file, JSON.pretty_generate(data))
    FileUtils.mv(temp_file, filename)
    true
  rescue StandardError => e
    log "ERROR: Writing to file #{filename} failed: #{e.message}"
    false
  end

  # Standardized logging
  def log(message)
    timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
    puts "#{timestamp} - #{message}"
  end

  # Execute a block with error handling
  def with_error_handling(task_name)
    yield
  rescue StandardError => e
    log "Error during #{task_name}: #{e.message}"
    log e.backtrace&.join("\n")
    false
  end

  # Extract text from a node, stripping off leading and trailing white space and 
  # condensing white space in the middle to single spaces
  def extract_text(node)
    node&.text&.strip&.gsub(/\s\s+/, ' ')
  end

  # Extract an integer number from text, ignoring non-digit characters except periods (.)
  def extract_number(text)
    text&.gsub(/[^\d.]+/, '')&.to_i
  end
end
