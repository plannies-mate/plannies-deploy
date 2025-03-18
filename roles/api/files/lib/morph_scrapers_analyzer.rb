# frozen_string_literal: true

require 'mechanize'
require 'json'
require 'fileutils'
require_relative '../app/helpers/application_helper'
require_relative 'scraper_base'

# Singleton Class to extract a list of Morph Scrapers from Authority details
class MorphScrapersAnalyzer
  extend ApplicationHelper
  include Singleton

  # Return the list of all scrapers from main planning alerts page
  # @example:
  # [
  #   {
  #      "name": "multiple_epathway_scraper",
  #       "morph_url": "https://morph.io/planningalerts-scrapers/multiple_epathway_scraper",
  #       "github_url": "https://github.com/planningalerts-scrapers/multiple_epathway_scraper",
  #       "authorities":
  #         ["campbelltown", ...]
  #   },
  #   ...
  # ]

  def all
    scrapers.values
  end

  # Find a scraper by morph_url or name
  def find(morph_url_or_name)
    name = morph_url_or_name.split('/').last
    scrapers.fetch(name)
  end

  private

  def scrapers
    return @scrapers if @scrapers

    @scrapers = {}
    Authority.all.each do |authority|
      name = authority.morph_url.split('/').last
      if @scrapers.key?(name)
        @scrapers[name].authorities << authority
      else
        @scrapers[name] = MorphScraper.new(authority)
      end
    end
    @scrapers
  end

  def reset!
    @scrapers = nil
  end

end
