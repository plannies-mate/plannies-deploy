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

  # Get CSS class based on status
  def status_class(warning)
    warning ? 'status-warning' : 'status-ok'
  end

  # Add a method to render slim partials
  def slim(template_path, options = {})
    locals = options[:locals] || {}

    template_path = template_path.to_s.sub(/^:/, '')

    full_path = AuthoritiesGenerator.add_slim_extensions File.join(@views_dir, template_path)
    template = Slim::Template.new(full_path)

    template.render(self, locals)
  end
end
