# roles/api/files/tasks/pages.rake

require 'fileutils'
require 'json'
require 'slim'
require 'tilt'
require_relative '../lib/site_generator'

namespace :generate do
  desc 'Generate static site from data'
  task all: :singleton do
    generator = SiteGenerator.new
    generator.process
  end

  # desc 'Generate site and watch for changes (development)'
  # task :dev do
  #   require_relative '../site/dev_server'
  #   DevServer.run!
  # end
  #
  # desc 'Clean generated files'
  # task :clean do
  #   FileUtils.rm_rf(File.join(SiteGenerator::OUTPUT_DIR, '*'))
  #   puts "Cleaned static site files"
  # end
end