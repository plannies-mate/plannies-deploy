# frozen_string_literal: true

require_relative '../lib/authorities_generator'
require_relative '../lib/authority_generator'
require_relative '../lib/scrapers_generator'
require_relative '../lib/scraper_generator'

namespace :generate do
  desc 'Generate all reports'
  task all: %i[singleton authorities authority_pages scrapers scraper_pages] do
    puts 'All reports generated successfully'
  end

  desc 'Generate authorities index page'
  task :authorities do
    AuthoritiesGenerator.generate
  end

  desc 'Generate individual authority pages'
  task :authority_pages do
    AuthorityGenerator.generate_all
  end

  desc 'Generate scrapers index page'
  task :scrapers do
    ScrapersGenerator.generate
  end

  desc 'Generate individual scraper pages'
  task :scraper_pages do
    ScraperGenerator.generate_all
  end
end
