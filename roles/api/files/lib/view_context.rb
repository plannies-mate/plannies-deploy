# frozen_string_literal: true

require 'slim'
require 'json'
require 'fileutils'
require 'date'

# Class for View context and helpers
class ViewContext
  attr_reader :views_dir

  def initialize(views_dir)
    @views_dir = views_dir
  end

  def number_with_delimiter(number)
    return number if number.nil?

    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
  end

  # Format a date nicely
  def format_date(date_string)
    return date_string if date_string.nil?

    begin
      date = Date.parse(date_string.to_s)
      date.strftime('%d %b %Y')
    rescue StandardError
      date_string
    end
  end

  # Add word break opportunities (<wbr>) after specified punctuation
  # Particularly useful for long identifiers with underscore/hyphen separators
  # @param str [String] the string to process
  # @param chars [String] characters after which to insert <wbr> tags
  # @return [String] the string with <wbr> tags inserted
  def add_word_breaks(str, chars = '-_.')
    return str if str.nil? || str.empty?

    # Escape characters for use in regex
    escaped_chars = Regexp.escape(chars)
    # Insert <wbr> after each specified character
    str.gsub(/([#{escaped_chars}])/, '\1<wbr>')
  end

  # Get CSS class based on status
  def status_class(warning)
    warning ? 'status-warning' : 'status-ok'
  end

  # Add a method to render slim partials
  def slim(template_path, options = {})
    locals = options[:locals] || {}

    template_path = template_path.to_s.sub(/^:/, '')

    full_path = AuthoritiesGenerator.add_slim_extensions File.join(@views_dir, template_path)
    template = Slim::Template.new(full_path, pretty: true)

    template.render(self, locals)
  end

  def summarize_authorities(authorities)
    bad_count = authorities.count { |a| a.warning? }
    "#{bad_count} have warnings"
  end

  # Convert text description of time passed (e.g., "over 2 years ago") to months
  # @param time_text [String] text description like "2 months ago"
  # @return [Float] estimated number of months
  def time_ago_to_months(time_text)
    return 0.0 if time_text.to_s.empty?

    # Clean up the text and remove "ago"
    text = time_text.downcase.sub(/\s+ago\z/, '').sub(/\Aabout\s+/, '')

    multiplier = 1.0

    value = if text =~ /(\d+)/
              $1.to_f
            else
              1.0 # Default if no number (e.g., "about a month")
            end

    # Apply multipliers for different time units
    if text.include?('year')
      multiplier = 12.0
    elsif text.include?('month')
      multiplier = 1.0
    elsif text.include?('day')
      multiplier = 12.0 / 365.0 # Approximate
    elsif text.include?('week')
      multiplier = 12.0 * 7.0 / 365.0 # Approximate
    end

    # Apply modifiers
    if text.include?('almost')
      value -= 0.25
    elsif text.include?('over') || text.include?('more than')
      value += 0.25
    end

    # Calculate final value
    value * multiplier
  end
end
