# frozen_string_literal: true

# Authority details collected from various sources, uniquely identified by short_name
#
# * Lazy load details and/or stats when needed
# * Relies on Fetcher classes being called to populate the json files
class Authority
  attr_reader :short_name, :name, :url, :state, :possibly_broken, :population

  def self.all
    @all ||= AuthoritiesFetcher.all.map { |a| Authority.new(a) }
  end

  def initialize(attributes)
    @short_name = attributes['short_name'] || raise(ArgumentError, 'short_name is required')
    @name = attributes['name'] || raise(ArgumentError, 'name is required')
    @url = attributes['url'] || raise(ArgumentError, 'url is required')
    @state = attributes['state']
    @possibly_broken = attributes['possibly_broken'] || false
    @population = attributes['population']
    @attributes = attributes
  end

  # Equal if its name, planning alerts url and state matches
  #
  # The other details (possibly_broken, population, details and stats) may differ
  def ==(other)
    short_name == other.short_name &&
      name == other.name &&
      url == other.url &&
      state == other.state
  end

  alias eql? ==

  def morph_scraper
    MorphScrapersAnalyzer.instance.find(morph_url)
  end

  # Details hash if available
  def details
    @details ||= AuthorityDetailsFetcher.find(short_name) || {}
  end

  # Stats hash if available
  def stats
    @stats ||= AuthorityStatsFetcher.find(short_name) || {}
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
