# frozen_string_literal: true

require 'tilt'
require 'slim'

require_relative '../app/helpers/application_helper'
require_relative 'authority'
require_relative 'generator_base'
require_relative 'morph_scraper'
require_relative 'morph_scrapers_analyzer'

# Generates `data_dir/scrapers.html`
class ScrapersGenerator
  extend GeneratorBase
  extend ApplicationHelper

  def self.generate
    analyzer = MorphScrapersAnalyzer.instance
    scrapers = analyzer.all
    
    # Group scrapers by type
    multi_scrapers = scrapers.select { |s| s.authorities.size > 1 }
                            .sort_by { |s| -s.authorities.size }
    
    custom_scrapers = scrapers.select { |s| s.authorities.size == 1 }
                             .sort_by { |s| s.name.downcase }
    
    orphaned_scrapers = scrapers.select { |s| s.authorities.empty? }
                               .sort_by { |s| s.name.downcase }
    
    locals = { 
      multi_scrapers: multi_scrapers, 
      custom_scrapers: custom_scrapers, 
      orphaned_scrapers: orphaned_scrapers,
      title: "Scrapers"
    }

    render_template('scrapers', 'scrapers', locals)
    log "Generated scrapers index page with #{scrapers.size} scrapers"
  end
end
