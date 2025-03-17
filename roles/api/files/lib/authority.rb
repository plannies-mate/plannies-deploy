# frozen_string_literal: true

# Authority details collected from various sources
class Authority
  attr_reader :id, :short_name, :full_name, :url

  def self.all
    @all ||= AuthoritiesFetcher.all.map_with_index { |a, id| Authority.new(a.merge(id: id)) }
  end

  def initialize(attributes)
    @id = attributes['id']
    @short_name = attributes['short_name'] || raise(ArgumentError, 'short_name is required')
    @full_name = attributes['full_name']
    @url = attributes['url']
    @attributes = attributes
  end

  def details
    @details ||= AuthorityDetailsFetcher.fetch(short_name)
  end

  def stats
    @stats ||= AuthorityStatsFetcher.fetch(short_name)
  end

  # Add explicit methods for commonly accessed attributes
  def morph_url
    details['morph_url']
  end

  def github_url
    details['github_url']
  end

  def last_log
    details['last_log']
  end

  def app_count
    details['app_count']
  end

  def warning?
    stats['warning']
  end

  def last_received
    stats['last_received']
  end

  def week_count
    stats['week_count']
  end

  def month_count
    stats['month_count']
  end

  def total_count
    stats['total_count']
  end

  def added
    stats['added']
  end

  def median_per_week
    stats['median_per_week']
  end

  # You could still provide a way to access any attribute
  def [](key)
    @attributes[key] || details[key] || stats[key]
  end

end
