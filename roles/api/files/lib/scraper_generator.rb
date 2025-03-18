# frozen_string_literal: true

require 'tilt'
require 'slim'

require_relative '../app/helpers/application_helper'
require_relative 'authority'
require_relative 'generator_base'
require_relative 'morph_scraper'
require_relative 'morph_scrapers_analyzer'

# Generates `data_dir/scrapers/#{morph_scraper.name}.html`
class ScraperGenerator
  extend GeneratorBase
  extend ApplicationHelper

  def self.generate(scraper)
    locals = {
      scraper: scraper,
      title: scraper.name
    }

    render_template('scraper', "scrapers/#{scraper.name}", locals)
    log "Generated scraper page for #{scraper.name}"
  end

  # Generate pages for all scrapers
  def self.generate_all
    analyzer = MorphScrapersAnalyzer.instance
    analyzer.all.each do |scraper|
      generate(scraper)
    end
    log 'Generated all scraper pages'
  end
end
